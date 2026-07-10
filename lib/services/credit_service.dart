import 'package:supabase_flutter/supabase_flutter.dart';

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
    return _deduct(amount: amount, type: listingType, referenceId: referenceId);
  }

  /// Yeni bir sohbet başlatırken kredi düşer (atomik RPC).
  /// Yetersizse [InsufficientCreditsException] fırlatır.
  /// Dönen değer: işlem sonrası kalan kredi.
  Future<int> deductForMessage({String? referenceId}) async {
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