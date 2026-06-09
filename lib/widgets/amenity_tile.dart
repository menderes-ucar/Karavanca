import 'package:flutter/material.dart';
import '../models/camp_model.dart';

class AmenityTile extends StatelessWidget {
  final CampAmenity amenity;
  const AmenityTile({super.key, required this.amenity});

  IconData _iconFromKey(String key) {
    switch (key) {
      case 'wc':
        return Icons.wc;
      case 'shower':
        return Icons.shower;
      case 'power':
        return Icons.power;
      case 'wifi':
        return Icons.wifi;
      case 'parking':
        return Icons.local_parking;
      case 'shop':
        return Icons.storefront;
      case 'fire':
        return Icons.local_fire_department;
      case 'security':
        return Icons.security;
      default:
        return Icons.check_circle_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = amenity.available ? Colors.black87 : Colors.black38;

    return Row(
      children: [
        Icon(_iconFromKey(amenity.icon), size: 20, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            amenity.name,
            style: TextStyle(fontWeight: FontWeight.w700, color: color),
          ),
        ),
        Icon(
          amenity.available ? Icons.check : Icons.close,
          size: 18,
          color: amenity.available ? Colors.green : Colors.red,
        ),
      ],
    );
  }
}
