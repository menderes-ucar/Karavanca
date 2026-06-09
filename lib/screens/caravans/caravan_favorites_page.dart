import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/caravan_model.dart';
import '../../services/caravan_favorites_service.dart';
import '../../services/caravan_service.dart';
import 'caravan_detail_page.dart';

class CaravanFavoritesPage extends StatefulWidget {
  final CaravanFavoritesService favoritesService;

  const CaravanFavoritesPage({
    super.key,
    required this.favoritesService,
  });

  @override
  State<CaravanFavoritesPage> createState() => _CaravanFavoritesPageState();
}

class _CaravanFavoritesPageState extends State<CaravanFavoritesPage> {
  final service = CaravanService();

  bool loading = true;
  List<CaravanModel> all = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    final data = await service.getListings();
    if (!mounted) return;
    setState(() {
      all = data;
      loading = false;
    });
  }

  Widget _smartImage(String path) {
    final p = path.trim();

    final isNetwork =
        p.startsWith('http://') || p.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        p,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
        const Icon(Icons.image_not_supported),
      );
    }

    // storage path ise public url üret
    final sb = Supabase.instance.client;
    final url = sb.storage
        .from('caravan-images') // bucket adını kontrol et
        .getPublicUrl(p);

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
      const Icon(Icons.image_not_supported),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Favoriler")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<Set<String>>(
        valueListenable: widget.favoritesService.favoriteIds,
        builder: (_, favs, __) {
          final items = all.where((c) => favs.contains(c.id)).toList();

          if (items.isEmpty) {
            return const Center(
              child: Text("Henüz favori ilan yok."),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 18),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final c = items[i];
              final img = c.images.isNotEmpty ? c.images.first : null;

              return Card(
                margin: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CaravanDetailPage(
                          listing: c,
                          favoritesService: widget.favoritesService,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(18)),
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (img == null)
                                Container(color: Colors.black12)
                              else
                                _smartImage(img),

                              // ✅ FAVORİ BUTONU (sağ üst)
                              Positioned(
                                top: 6,
                                right: 6,
                                child:
                                ValueListenableBuilder<Set<String>>(
                                  valueListenable:
                                  widget.favoritesService.favoriteIds,
                                  builder: (_, set, __) {
                                    final isFav = set.contains(c.id);

                                    return GestureDetector(
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () {
                                        widget.favoritesService
                                            .toggleFavorite(c.id);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.white
                                              .withOpacity(0.92),
                                          borderRadius:
                                          BorderRadius.circular(999),
                                        ),
                                        child: Icon(
                                          isFav
                                              ? Icons.favorite
                                              : Icons.favorite_border,
                                          size: 20,
                                          color: isFav
                                              ? Colors.red
                                              : Colors.black87,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ✅ ALT BİLGİ KISMI AÇIK YEŞİL
                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC8E6C9),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c.city,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),

                                  // İstersen sonra buraya fiyat / rating vb eklersin
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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