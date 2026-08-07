import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_config.dart';

/// Mağaza (Google Play / App Store) üzerinden kredi satın alma akışını yönetir.
///
/// AKIŞ:
/// 1. init() ile mağaza bağlantısı kontrol edilir, ürünler çekilir.
/// 2. buy() ile satın alma başlatılır -> mağaza kendi ödeme ekranını açar.
/// 3. purchaseStream dinlenir, satın alma tamamlanınca receipt/token
///    Supabase Edge Function'a gönderilip DOĞRULANIR (client'a asla güvenilmez).
/// 4. Doğrulama başarılıysa kredi otomatik eklenir (Edge Function tarafında).
class PurchaseService {
  PurchaseService._internal();
  static final PurchaseService instance = PurchaseService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  final SupabaseClient _sb = Supabase.instance.client;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  bool _available = false;
  Map<String, ProductDetails> _products = {};

  /// UI tarafına satın alma sonucu bildirmek için basit callback'ler.
  void Function(String message)? onError;
  void Function(int newCreditBalance)? onCreditsGranted;

  bool get isAvailable => _available;
  List<ProductDetails> get products => _products.values.toList();

  Future<void> init(List<String> productIds) async {
    _available = await _iap.isAvailable();
    if (!_available) {
      debugPrint('❌ In-app purchase mağazada kullanılabilir değil.');
      return;
    }

    _subscription?.cancel();
    _subscription = _iap.purchaseStream.listen(
      _onPurchaseUpdate,
      onError: (e) => debugPrint('❌ purchaseStream error: $e'),
    );

    if (productIds.isEmpty) return;

    final response = await _iap.queryProductDetails(productIds.toSet());
    if (response.error != null) {
      debugPrint('❌ queryProductDetails error: ${response.error}');
    }
    if (response.notFoundIDs.isNotEmpty) {
      debugPrint(
          '⚠️ Mağazada bulunamayan ürün ID\'leri: ${response.notFoundIDs} '
              '(Play Console / App Store Connect\'te bu ID\'lerle ürün oluşturduğundan emin ol)');
    }

    _products = {for (final p in response.productDetails) p.id: p};
  }

  /// Ürün ID'sine göre store'dan çekilen (lokalize fiyatlı) ürün bilgisini döner.
  ProductDetails? productFor(String productId) => _products[productId];

  Future<void> buy(String productId) async {
    final product = _products[productId];
    if (product == null) {
      onError?.call('Ürün mağazada bulunamadı: $productId');
      return;
    }

    final param = PurchaseParam(productDetails: product);

    // Kredi bir "tüketilebilir" (consumable) üründür — kullanıcı defalarca satın alabilir.
    await _iap.buyConsumable(purchaseParam: param, autoConsume: true);
  }

  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.pending:
          debugPrint('⏳ Satın alma bekleniyor: ${purchase.productID}');
          break;

        case PurchaseStatus.error:
          debugPrint('❌ Satın alma hatası: ${purchase.error}');
          onError?.call(purchase.error?.message ?? 'Satın alma başarısız');
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.canceled:
          debugPrint('ℹ️ Satın alma iptal edildi: ${purchase.productID}');
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;

        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _verifyAndGrant(purchase);
          if (purchase.pendingCompletePurchase) {
            await _iap.completePurchase(purchase);
          }
          break;
      }
    }
  }

  /// ⚠️ KRİTİK: Kredi burada DİREKT eklenmiyor. Satın alma bilgisi
  /// Supabase Edge Function'a gönderiliyor, orada Google/Apple sunucularına
  /// karşı doğrulanıyor, doğrulama geçerse kredi ekleniyor. Client'tan
  /// "satın aldım" demek yeterli olsaydı herkes ücretsiz kredi ekleyebilirdi.
  Future<void> _verifyAndGrant(PurchaseDetails purchase) async {
    try {
      final platform = defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios';

      final res = await _sb.functions.invoke(
        'verify-purchase',
        body: {
          'platform': platform,
          'productId': purchase.productID,
          // Android: purchaseToken, iOS: receipt (verificationData.serverVerificationData)
          'token': purchase.verificationData.serverVerificationData,
        },
      );

      if (res.status != 200) {
        onError?.call('Doğrulama başarısız: ${res.data}');
        return;
      }

      final data = res.data as Map<String, dynamic>;
      final newBalance = (data['newBalance'] as num?)?.toInt();
      if (newBalance != null) {
        onCreditsGranted?.call(newBalance);
      }
    } catch (e) {
      debugPrint('❌ Doğrulama isteği hatası: $e');
      onError?.call('Doğrulama isteği gönderilemedi: $e');
    }
  }

  void dispose() {
    _subscription?.cancel();
  }
}

/// Yetersiz kredi durumunda fırlatılır. UI tarafında yakalayıp
/// kullanıcıya "kredi yetersiz" ekranı / dialog gösterebilirsin.
class InsufficientCreditsException implements Exception {
  final String message;
  InsufficientCreditsException([this.message = 'Yetersiz kredi']);
  @override
  String toString() => message;
}

class CreditService {
  final SupabaseClient _sb = Supabase.instance.client;

  // ✅ İşlemlerin kredi maliyeti — burayı değiştirerek fiyatları ayarla.
  static const int caravanListingCost = 5;
  static const int productListingCost = 2;
  static const int messageThreadCost = 5; // yeni sohbet başlatma

  /// Giriş yapmış kullanıcının güncel kredisini döner.
  Future<int> getMyCredits() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return 0;

    final row = await _sb
        .from('profiles')
        .select('credits')
        .eq('id', uid)
        .maybeSingle();

    return (row?['credits'] as int?) ?? 0;
  }

  Future<bool> hasEnoughCredits(int amount) async {
    // Kredi sistemi pasifse her zaman yeterli sayılsın
    if (!AppConfig.isCreditSystemActive) return true;

    final current = await getMyCredits();
    return current >= amount;
  }

  /// İlan yayınlarken kredi düşer (atomik RPC).
  /// Yetersizse [InsufficientCreditsException] fırlatır.
  /// Dönen değer: işlem sonrası kalan kredi.
  Future<int> deductForListing({
    required int amount,
    required String listingType, // 'caravan' | 'product'
    String? referenceId,
  }) async {
    if (!AppConfig.isCreditSystemActive) return 0;
    return _deduct(amount: amount, type: listingType, referenceId: referenceId);
  }

  /// Yeni bir sohbet başlatırken kredi düşer (atomik RPC).
  /// Yetersizse [InsufficientCreditsException] fırlatır.
  /// Dönen değer: işlem sonrası kalan kredi.
  Future<int> deductForMessage({String? referenceId}) async {
    if (!AppConfig.isCreditSystemActive) return 0;
    return _deduct(
      amount: messageThreadCost,
      type: 'message',
      referenceId: referenceId,
    );
  }

  Future<int> _deduct({
    required int amount,
    required String type, // 'caravan' | 'product' | 'message'
    String? referenceId,
  }) async {
    if (!AppConfig.isCreditSystemActive) return 0;

    try {
      final res = await _sb.rpc('deduct_listing_credit', params: {
        'p_amount': amount,
        'p_listing_type': type,
        'p_reference_id': referenceId,
      });
      return res as int;
    } on PostgrestException catch (e) {
      if (e.message.contains('Yetersiz kredi')) {
        throw InsufficientCreditsException();
      }
      rethrow;
    }
  }

  /// ADMIN: kullanıcıya manuel kredi yükler / düşer (negatif miktar da olur).
  Future<int> adminAddCredits({
    required String targetUserId,
    required int amount,
    String? note,
  }) async {
    final res = await _sb.rpc('admin_add_credits', params: {
      'p_target_user': targetUserId,
      'p_amount': amount,
      'p_note': note,
    });
    return res as int;
  }

  /// Kullanıcının kendi kredi hareket geçmişi (opsiyonel, ProfileInfoPage'de
  /// gösterebilirsin).
  Future<List<Map<String, dynamic>>> getMyTransactions({int limit = 50}) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return [];

    final res = await _sb
        .from('credit_transactions')
        .select()
        .eq('user_id', uid)
        .order('created_at', ascending: false)
        .limit(limit);

    return (res as List).cast<Map<String, dynamic>>();
  }
}