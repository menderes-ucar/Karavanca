class CaravanModel {
  final String id;
  final String ownerId;
  final String status;

  final String title;
  final String city;
  final int price;
  final List<String> images;
  final String categoryId;

  final bool isUrgent;
  final bool isPriceDropped;
  final DateTime createdAt;

  final DateTime? updatedAt; // ✅ EKLENDİ

  final String? sellerName;
  final String? phone;
  final String? description;
  final List<String> features;

  CaravanModel({
    required this.id,
    required this.ownerId,
    required this.status,
    required this.title,
    required this.city,
    required this.price,
    required this.images,
    required this.categoryId,
    this.isUrgent = false,
    this.isPriceDropped = false,
    DateTime? createdAt,
    this.updatedAt, // ✅ EKLENDİ
    this.sellerName,
    this.phone,
    this.description,
    this.features = const [],
  }) : createdAt = createdAt ?? DateTime.now();
}
