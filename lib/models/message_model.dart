class ProductModel {
  final String id;
  final String ownerId;

  final String title;
  final String categoryTitle; // kullanıcı seçer
  final int price;
  final String city;

  final String description;
  final String? phone;
  final List<String> images;

  final String status; // pending | active | passive
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.categoryTitle,
    required this.price,
    required this.city,
    required this.description,
    this.phone,
    required this.images,
    required this.status,
    required this.createdAt,
  });

  static ProductModel fromRow(Map<String, dynamic> r) {
    int _toInt(dynamic v) => v is int ? v : int.tryParse(v?.toString() ?? '') ?? 0;

    List<String> _toList(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();
      return [];
    }

    return ProductModel(
      id: (r['id'] ?? '').toString(),
      ownerId: (r['owner_id'] ?? '').toString(),
      title: (r['title'] ?? '').toString(),
      categoryTitle: (r['category_title'] ?? '').toString(),
      price: _toInt(r['price']),
      city: (r['city'] ?? '').toString(),
      description: (r['description'] ?? '').toString(),
      phone: r['phone']?.toString(),
      images: _toList(r['images']),
      status: (r['status'] ?? 'pending').toString(),
      createdAt: DateTime.tryParse((r['created_at'] ?? '').toString()) ?? DateTime.now(),
    );
  }
}
