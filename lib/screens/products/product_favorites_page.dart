import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../services/product_favorites_service.dart';
import 'product_detail_page.dart';

class ProductFavoritesPage extends StatefulWidget {
  final ProductFavoritesService favoritesService;
  const ProductFavoritesPage({super.key, required this.favoritesService});

  @override
  State<ProductFavoritesPage> createState() => _ProductFavoritesPageState();
}

class _ProductFavoritesPageState extends State<ProductFavoritesPage> {
  final service = ProductService();
  bool loading = true;
  List<ProductModel> all = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final data = await service.getAll();
    if (!mounted) return;
    setState(() {
      all = data;
      loading = false;
    });
  }

  // ✅ küçük helper: resim (network/asset)
  Widget _smartImage(String path) {
    final p = path.trim();
    final isNetwork = p.startsWith('http://') || p.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        p,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          "assets/images/placeholder.png",
          fit: BoxFit.cover,
        ),
      );
    }

    return Image.asset(
      p,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        "assets/images/placeholder.png",
        fit: BoxFit.cover,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Camp favoriler gibi açık zemin
      backgroundColor: const Color(0xFFF3F5F3),
      appBar: AppBar(title: const Text("Favoriler")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<Set<String>>(
        valueListenable: widget.favoritesService.favoriteIds,
        builder: (_, favs, __) {
          final items = all.where((p) => favs.contains(p.id)).toList();

          if (items.isEmpty) {
            return const Center(child: Text("Favori ürün yok."));
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final p = items[i];
              final img = p.images.isNotEmpty ? p.images.first : null;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailPage(
                          product: p,
                          favoritesService: widget.favoritesService,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      // ✅ yapıyı bozma: camp kart gibi açık kart rengi
                      color: const Color(0xFFF6F7F2),
                      borderRadius: BorderRadius.circular(18),

                      // ✅ daha elit: ince border
                      border: Border.all(
                        color: const Color(0x14000000),
                      ),

                      // ✅ daha elit: yumuşak ama belirgin gölge (2 kat)
                      boxShadow: const [
                        BoxShadow(
                          blurRadius: 22,
                          color: Color(0x22000000),
                          offset: Offset(0, 12),
                        ),
                        BoxShadow(
                          blurRadius: 8,
                          color: Color(0x12000000),
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ✅ üstte büyük foto (camp yapısı)
                        Stack(
                          children: [
                            SizedBox(
                              height: 185,
                              width: double.infinity,
                              child: img == null
                                  ? Container(
                                color: const Color(0xFFEFEFEF),
                                alignment: Alignment.center,
                                child: const Icon(Icons.image_outlined),
                              )
                                  : _smartImage(img),
                            ),

                            // ✅ sağ üst kalp (camp gibi)
                            Positioned(
                              top: 12,
                              right: 12,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () => widget.favoritesService
                                    .toggleFavorite(p.id),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.96),
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0x14000000),
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        blurRadius: 10,
                                        color: Color(0x26000000),
                                        offset: Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Color(0xFFC8E6C9), // istediğin rengi buraya yaz
                    ),
                        // ✅ altta bilgi alanı (camp yapısı)
                          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.title.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14.5,
                                  letterSpacing: 0.3,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                p.city.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  letterSpacing: 0.6,
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),

                              const SizedBox(height: 10),

                              // ✅ campteki rating satırı gibi (modelde rating yoksa da yapı bozulmasın)
                              Row(
                                children: const [
                                  Icon(Icons.star, size: 16, color: Color(0xFFF4B400)),
                                  SizedBox(width: 6),
                                  Text(
                                    "Favori",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
