import 'package:flutter/material.dart';
import '../../services/auth_guard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_model.dart';
import '../../services/product_favorites_service.dart';
import '../../widgets/ugc_action_sheet.dart';
import 'product_chat_page.dart';

class ProductDetailPage extends StatelessWidget {
  final ProductModel product;
  final ProductFavoritesService favoritesService;

  const ProductDetailPage({
    super.key,
    required this.product,
    required this.favoritesService,
  });

  String _formatPrice(int price) {
    final s = price.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      b.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) b.write('.');
    }
    return "${b.toString()} ₺";
  }

  String _fmtDate(DateTime? dt) {
    if (dt == null) return "-";
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}.${two(dt.month)}.${dt.year}";
  }

  String _conditionText(String id) {
    switch (id) {
      case 'new':
        return 'Yeni';
      case 'like_new':
        return 'Sıfır Ayarında';
      case 'used':
        return 'Kullanılmış';
      case 'damaged':
        return 'Hasarlı';
      default:
        return id;
    }
  }

  // ✅ network / storage path destekli
  Widget _smartImage(String path) {
    final p = path.trim();
    final isNetwork = p.startsWith('http://') || p.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        p,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.black12,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported),
        ),
      );
    }

    final sb = Supabase.instance.client;
    final url = sb.storage.from('product-images').getPublicUrl(p);

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported),
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Text(label, style: const TextStyle(color: Colors.black54)),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final image = product.images.isNotEmpty ? product.images.first : null;

    // ✅ tür = categoryTitle (UI’da “Tür” diye göstereceğiz)
    final typeText = (product.categoryTitle.trim().isEmpty)
        ? product.categoryId
        : product.categoryTitle;

    // ✅ durum = condition
    final condText = _conditionText(product.condition);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Ürün Detayı"),
        actions: [
          IconButton(
            tooltip: 'Şikayet Et',
            onPressed: () async {
              if (!await AuthGuard.requireAuth(context)) return;
              await UgcActionSheet.report(
                context: context,
                contentType: 'product',
                contentId: product.id,
                reportedUserId: product.ownerId,
                title: 'Ürün İlanını Şikayet Et',
              );
            },
            icon: const Icon(Icons.flag_outlined),
          ),
          ValueListenableBuilder<Set<String>>(
            valueListenable: favoritesService.favoriteIds,
            builder: (_, favs, __) {
              final isFav = favs.contains(product.id);
              return IconButton(
                onPressed: () async {
                  if (!await AuthGuard.requireAuth(context)) return;
                  await favoritesService.toggleFavorite(product.id);
                },
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? Colors.red : null,
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 260,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (image == null)
                  Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_outlined, size: 40),
                  )
                else
                  _smartImage(image),

                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.55),
                      ],
                    ),
                  ),
                ),

                Positioned(
                  right: 14,
                  bottom: 14,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.70),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white.withOpacity(0.15)),
                    ),
                    child: Text(
                      _formatPrice(product.price),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),

                Positioned(
                  left: 14,
                  bottom: 14,
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.92),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.place_outlined, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          product.city,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),

                // ✅ İLAN BİLGİLERİ (fotoğraftaki yapı)
                _sectionCard(
                  title: "İlan Bilgileri",
                  child: Column(
                    children: [
                      _infoRow("İlan Tarihi", _fmtDate(product.createdAt)),
                      _infoRow("Şehir", product.city),
                      _infoRow("Tür", typeText),
                      _infoRow("Durum", condText),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ✅ SATİCI KARTI (aynı)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.black12),
                    boxShadow: const [
                      BoxShadow(
                        blurRadius: 18,
                        color: Color(0x14000000),
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF2F3F5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(Icons.person, color: Colors.black87),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.sellerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 3),
                            const Text(
                              "Satıcı",
                              style: TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            if (!await AuthGuard.requireAuth(context)) return;
                            if (!context.mounted) return;
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductChatPage(product: product),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat_bubble_outline),
                          label: const Text("Mesaj"),
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // ✅ GÜVENLİK İPUÇLARI (fotoğraftaki gibi)
                _sectionCard(
                  title: "Güvenlik İpuçları",
                  child: const Text(
                    "• Satıcıyla yüz yüze görüşmeden kesinlikle para göndermeyin.\n"
                        "• Ürünü görmeden kapora göndermeyi kabul etmeyin.\n"
                        "• Tanımadığınız kişilerle yapılan transferlere dikkat edin.\n"
                        "• Para ödemesi ile ürün teslimini aynı anda yapın.",
                    style: TextStyle(color: Colors.black87, height: 1.35),
                  ),
                ),

                const SizedBox(height: 12),

                // ✅ AÇIKLAMA
                _sectionCard(
                  title: "Açıklama",
                  child: Text(
                    product.description.isEmpty ? "Açıklama yok." : product.description,
                    style: const TextStyle(
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),

                const SizedBox(height: 18),
              ],
            ),
          ),
        ],
      ),
    );
  }
}