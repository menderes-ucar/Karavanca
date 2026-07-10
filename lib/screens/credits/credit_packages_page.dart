import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/purchase_service.dart';

class CreditPackagesPage extends StatefulWidget {
  const CreditPackagesPage({super.key});

  static const Color main = Color(0xFF00B8C8);

  @override
  State<CreditPackagesPage> createState() => _CreditPackagesPageState();
}

class _CreditPackagesPageState extends State<CreditPackagesPage> {
  final _sb = Supabase.instance.client;
  final _purchase = PurchaseService.instance;

  bool _loading = true;
  bool _buying = false;
  List<Map<String, dynamic>> _packages = [];

  @override
  void initState() {
    super.initState();
    _purchase.onError = (msg) {
      if (!mounted) return;
      setState(() => _buying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    };
    _purchase.onCreditsGranted = (newBalance) {
      if (!mounted) return;
      setState(() => _buying = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kredi eklendi ✅ Yeni bakiyen: $newBalance')),
      );
    };
    _load();
  }

  // ✅ Store'a göre doğru ürün ID kolonunu seç
  String? _productIdFor(Map<String, dynamic> pkg) {
    final isAndroid = !kIsWebSafe && Platform.isAndroid;
    return (isAndroid ? pkg['google_product_id'] : pkg['apple_product_id'])
    as String?;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _sb
          .from('credit_packages')
          .select()
          .eq('is_active', true)
          .order('sort_order');

      final packages = (res as List).cast<Map<String, dynamic>>();

      // ✅ Mağaza ürünlerini çek (Play Console / App Store Connect'te
      // tanımladığın product ID'lerle eşleşir)
      final productIds = packages
          .map(_productIdFor)
          .whereType<String>()
          .toList();

      await _purchase.init(productIds);

      if (!mounted) return;
      setState(() {
        _packages = packages;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Paketler alınamadı: $e')),
      );
    }
  }

  String _formatPrice(int kurus) {
    final tl = kurus / 100;
    return '${tl.toStringAsFixed(2).replaceAll('.', ',')} ₺';
  }

  Future<void> _selectPackage(Map<String, dynamic> pkg) async {
    if (_buying) return;

    if (!_purchase.isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Mağaza şu an kullanılamıyor. Play Store / App Store\'da '
                'ürünlerin tanımlı olduğundan emin ol.',
          ),
        ),
      );
      return;
    }

    final productId = _productIdFor(pkg);

    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bu paket için mağaza ürünü tanımlı değil.')),
      );
      return;
    }

    setState(() => _buying = true);
    await _purchase.buy(productId);
    // NOT: _buying=false işlemi onError/onCreditsGranted callback'lerinde yapılıyor.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFBFC),
      appBar: AppBar(
        backgroundColor: CreditPackagesPage.main,
        foregroundColor: Colors.white,
        title: const Text('Kredi Paketleri'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _packages.isEmpty
          ? const Center(child: Text('Şu an aktif paket bulunmuyor.'))
          : ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _packages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final pkg = _packages[i];
          final isPopular = pkg['is_popular'] == true;

          final productId = _productIdFor(pkg);
          final storeProduct =
          productId != null ? _purchase.productFor(productId) : null;

          // ✅ Mümkünse mağazadan gelen (kullanıcının bölgesine göre lokalize)
          // fiyatı göster, mağaza henüz veri döndürmediyse Supabase'deki fiyatı göster.
          final priceText =
              storeProduct?.price ?? _formatPrice(pkg['price_kurus'] as int);

          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: _buying ? null : () => _selectPackage(pkg),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isPopular
                      ? CreditPackagesPage.main
                      : Colors.black.withOpacity(0.06),
                  width: isPopular ? 2 : 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: CreditPackagesPage.main.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.credit_score,
                        color: CreditPackagesPage.main, size: 28),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              pkg['title']?.toString() ?? '',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                            ),
                            if (isPopular) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: CreditPackagesPage.main,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'EN POPÜLER',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 9,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pkg['credits']} kredi',
                          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (_buying)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Text(
                      priceText,
                      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// Bu proje web hedeflemiyor (Android/iOS), o yüzden sabit false yeterli.
// Eğer ileride web desteği eklersen kIsWeb (flutter/foundation.dart) kullan.
const bool kIsWebSafe = false;