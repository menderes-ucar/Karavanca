import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';
import 'admin_push_service.dart';

class ProductService {
  final SupabaseClient _sb = Supabase.instance.client;

  static const _bucket = 'product-images';

  bool _isHttp(String s) => s.startsWith('http://') || s.startsWith('https://');
  bool _isAsset(String s) => s.startsWith('assets/');

  String _toDisplayUrl(String pathOrUrl) {
    final p = (pathOrUrl).trim();
    if (p.isEmpty) return '';

    if (_isHttp(p) || _isAsset(p)) return p;

    final url = _sb.storage.from(_bucket).getPublicUrl(p);
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  Map<String, dynamic> _normalizeRow(Map<String, dynamic> m) {
    final imgs = (m['images'] is List)
        ? (m['images'] as List).map((e) => e.toString()).toList()
        : <String>[];

    m = Map<String, dynamic>.from(m);
    m['images'] = imgs.map(_toDisplayUrl).where((x) => x.isNotEmpty).toList();
    return m;
  }

  // FEED: sadece active
  Future<List<ProductModel>> getAll({int limit = 200}) async {
    final res = await _sb
        .from('products')
        .select(
        'id, owner_id, title, category_id, category_title, city, price, description, phone, images, status, admin_note, approved_at, created_at, condition')
        .eq('status', 'active')
        .order('created_at', ascending: false)
        .limit(limit);

    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map((r) => ProductModel.fromMap(_normalizeRow(r))).toList();
  }
  Future<ProductModel?> getById(String id) async {
    final res = await _sb
        .from('products')
        .select(
      'id, owner_id, title, category_id, category_title, city, price, description, phone, images, status, admin_note, approved_at, created_at, condition',
    )
        .eq('id', id)
        .maybeSingle();

    if (res == null) return null;

    return ProductModel.fromMap(
      _normalizeRow(Map<String, dynamic>.from(res)),
    );
  }

  // ADMIN: tüm ürünler
  Future<List<ProductModel>> adminGetAll({int limit = 500}) async {
    final res = await _sb
        .from('products')
        .select(
        'id, owner_id, title, category_id, category_title, city, price, description, phone, images, status, admin_note, approved_at, created_at, condition')
        .order('created_at', ascending: false)
        .limit(limit);

    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map((r) => ProductModel.fromMap(_normalizeRow(r))).toList();
  }

  Future<List<ProductModel>> getMine({int limit = 300}) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return [];

    final res = await _sb
        .from('products')
        .select(
        'id, owner_id, title, category_id, category_title, city, price, description, phone, images, status, admin_note, approved_at, created_at, condition')
        .eq('owner_id', uid)
        .order('created_at', ascending: false)
        .limit(limit);

    final list = (res as List).cast<Map<String, dynamic>>();
    return list.map((r) => ProductModel.fromMap(_normalizeRow(r))).toList();
  }

  // ADMIN: approve -> active + approved_at + admin_note
  Future<void> adminApprove(String productId, {String? note}) async {
    await _sb.from('products').update({
      'status': 'active',
      'approved_at': DateTime.now().toIso8601String(),
      if (note != null) 'admin_note': note,
    }).eq('id', productId);
  }

  // ADMIN: aktif/pasif
  Future<void> adminSetStatus(String productId, String status) async {
    await _sb.from('products').update({'status': status}).eq('id', productId);
  }

  // ADMIN: not güncelle
  Future<void> adminSetNote(String productId, String note) async {
    await _sb.from('products').update({'admin_note': note}).eq('id', productId);
  }
  Future<void> adminDelete(String productId) async {
    await _sb.from('products').delete().eq('id', productId);
  }
  // CREATE
  Future<String> create({
    required String title,
    required String categoryId,
    required String categoryTitle,
    required String city,
    required int price,
    required String description,
    required String condition,
    String? phone,
    List<String> images = const [],
  }) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) throw Exception('Not logged in');

    final row = await _sb
        .from('products')
        .insert({
      'owner_id': uid,
      'status': 'pending',
      'title': title,
      'category_id': categoryId,
      'category_title': categoryTitle,
      'city': city,
      'price': price,
      'description': description,
      'phone': phone,
      'images': images, // storage path listesi (products/...jpg)
      'condition': condition,
    })
        .select('id')
        .single();
    final productId = row['id'] as String;

    await AdminPushService().sendToAdmins(
      title: 'Yeni ürün ilanı var 🛒',
      body: '$title • $city onay bekliyor',
      data: {
        'type': 'admin_product',
        'id': productId,
      },
    );

    return productId;
  }
}