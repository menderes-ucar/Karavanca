class ProductModel {
  final String id;

  final String ownerId;
  final String title;
  final String categoryId;
  final String categoryTitle;
  final int price;
  final String city;
  final List<String> images;

  final String description;

  final String? phone;
  final String sellerName;

  final String status;
  final String? adminNote;
  final DateTime? approvedAt;
  final DateTime createdAt;

  final DateTime? updatedAt; // ✅ EKLENDİ

  final bool isUrgent;
  final bool isPriceDropped;

  // ✅ EKLENDİ: Durum (new / like_new / used / damaged)
  final String condition;

  ProductModel({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.categoryId,
    required this.categoryTitle,
    required this.price,
    required this.city,
    required this.images,
    required this.description,
    required this.status,
    required this.createdAt,
    this.phone,
    this.sellerName = '',
    this.adminNote,
    this.approvedAt,
    this.updatedAt, // ✅ EKLENDİ
    this.isUrgent = false,
    this.isPriceDropped = false,

    // ✅ EKLENDİ
    this.condition = 'used',
  });

  static String _toStr(dynamic v) => (v ?? '').toString();

  static int _toInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    return int.tryParse(v.toString()) ?? 0;
  }

  static bool _toBool(dynamic v) {
    if (v == null) return false;
    if (v is bool) return v;
    final s = v.toString().toLowerCase();
    return s == 'true' || s == '1' || s == 'yes';
  }

  static DateTime? _toDtNullable(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  static DateTime _toDt(dynamic v) {
    final dt = _toDtNullable(v);
    return dt ?? DateTime.now();
  }

  factory ProductModel.fromMap(Map<String, dynamic> m) {
    final profile =
    (m['profiles'] is Map) ? (m['profiles'] as Map).cast<String, dynamic>() : null;

    final condRaw = _toStr(m['condition']).trim();
    final cond = condRaw.isEmpty ? 'used' : condRaw;

    return ProductModel(
      id: _toStr(m['id']),
      ownerId: _toStr(m['owner_id']),

      title: _toStr(m['title']),
      categoryId: _toStr(m['category_id']),
      categoryTitle: _toStr(m['category_title']),
      city: _toStr(m['city']),
      price: _toInt(m['price']),
      description: _toStr(m['description']),

      phone: m['phone']?.toString(),
      images: (m['images'] is List)
          ? (m['images'] as List).map((e) => e.toString()).toList()
          : <String>[],

      status: _toStr(m['status']).isEmpty ? 'pending' : _toStr(m['status']),
      adminNote: m['admin_note']?.toString(),
      approvedAt: _toDtNullable(m['approved_at']),
      createdAt: _toDt(m['created_at']),

      updatedAt: _toDtNullable(m['updated_at']), // ✅ EKLENDİ

      isUrgent: _toBool(m['is_urgent']),
      isPriceDropped: _toBool(m['is_price_dropped']),

      sellerName: _toStr(profile?['full_name']),

      // ✅ EKLENDİ
      condition: cond,
    );
  }

  Map<String, dynamic> toInsertMap({required String ownerId}) {
    return {
      'owner_id': ownerId,
      'status': 'pending',
      'title': title,
      'category_id': categoryId,
      'category_title': categoryTitle,
      'city': city,
      'price': price,
      'description': description,
      'phone': phone,
      'images': images,

      // ✅ EKLENDİ
      'condition': condition,
    };
  }
}