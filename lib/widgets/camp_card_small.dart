import 'package:flutter/material.dart';
import '../models/camp_model.dart';
import '../screens/camps/camp_detail_page.dart';
import '../services/camp_favorites_service.dart';

class CampCardSmall extends StatelessWidget {
  final CampModel camp;
  const CampCardSmall({super.key, required this.camp});

  @override
  Widget build(BuildContext context) {
    final fav = CampFavoritesService.I;

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => CampDetailPage(camp: camp)),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    camp.images.isNotEmpty ? camp.images.first : '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.black12),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: ValueListenableBuilder<Set<String>>(
                      valueListenable: fav.favoriteIds,
                      builder: (_, set, __) {
                        final isFav = set.contains(camp.id);
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => fav.toggle(camp.id),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.92),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              size: 18,
                              color: isFav ? Colors.red : Colors.black87,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    camp.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    camp.city,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.black54),
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
