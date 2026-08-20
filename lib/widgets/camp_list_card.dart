import 'package:flutter/material.dart';
import '../models/camp_model.dart';
import '../services/camp_favorites_service.dart';

class CampListCard extends StatelessWidget {
  final CampModel camp;
  final VoidCallback onTap;

  const CampListCard({super.key, required this.camp, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final fav = CampFavoritesService.I;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
              const BorderRadius.vertical(top: Radius.circular(18)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      camp.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.black12),
                    ),

                    // ✅ FAVORİ BUTONU (sağ üst)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: ValueListenableBuilder<Set<String>>(
                        valueListenable: fav.favoriteIds,
                        builder: (_, set, __) {
                          final isFav = set.contains(camp.id);

                          return GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              fav.toggle(camp.id);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.92),
                                borderRadius: BorderRadius.circular(999),
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
                color: Color(0xFFC8E6C9), // 🌿 istediğin renk
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
                          camp.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          camp.region,
                          style: const TextStyle(
                            color: Colors.black54,
                          ),
                        ),
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
  }
}
