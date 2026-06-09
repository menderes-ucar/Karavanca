import 'package:flutter/material.dart';
import '../models/caravan_model.dart';
import '../screens/caravans/caravan_detail_page.dart';
import '../services/caravan_favorites_service.dart';

class CaravanListingCard extends StatelessWidget {
  final CaravanModel listing;
  final CaravanFavoritesService favoritesService;

  const CaravanListingCard({
    super.key,
    required this.listing,
    required this.favoritesService,
  });

  String _formatPrice(int price) {
    final s = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buffer.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buffer.write('.');
    }
    return "${buffer.toString()} ₺";
  }

  @override
  Widget build(BuildContext context) {
    final image = listing.images.isNotEmpty ? listing.images.first : null;

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CaravanDetailPage(
              listing: listing,
              favoritesService: favoritesService,
            ),
          ),
        );
      },
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: image == null
                        ? Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_outlined),
                    )
                        : Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.image_not_supported),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      color: Colors.black54,
                      child: Text(
                        _formatPrice(listing.price),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    listing.city,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
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
