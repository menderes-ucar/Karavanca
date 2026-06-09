import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/caravan_model.dart';

class CaravanService {
  final SupabaseClient _sb = Supabase.instance.client;

  // ✅ BUCKET ADI (Supabase Storage)
  static const _bucket = 'caravan-images';

  bool _isHttp(String s) => s.startsWith('http://') || s.startsWith('https://');
  bool _isAsset(String s) => s.startsWith('assets/');

  String _toDisplayUrl(String pathOrUrl) {
    final p = (pathOrUrl).trim();
    if (p.isEmpty) return '';

    // zaten url veya asset ise dokunma
    if (_isHttp(p) || _isAsset(p)) return p;

    // ✅ storage path ise public url'e çevir
    final url = _sb.storage.from(_bucket).getPublicUrl(p);

    // ✅ cache bust (foto güncellendi ama eski görünüyor hissini bitirir)
    return '$url?t=${DateTime.now().millisecondsSinceEpoch}';
  }

  // ✅ Eski davranış: tüm ilanlar
  Future<List<CaravanModel>> getListings() async {
    final data = await _sb
        .from('caravans')
        .select('''
          id, owner_id, title, city, price, description, phone, features, images, status, created_at,
          profiles!caravans_owner_id_fkey(full_name)
        ''')
        .order('created_at', ascending: false);

    final rows = (data as List).cast<Map<String, dynamic>>();
    return rows.map(_mapRowToModel).toList();
  }

  // ✅ YENİ: sadece yayındaki ilanlar
  Future<List<CaravanModel>> getActiveCaravans() async {
    final data = await _sb
        .from('caravans')
        .select('''
          id, owner_id, title, city, price, description, phone, features, images, status, created_at,
          profiles!caravans_owner_id_fkey(full_name)
        ''')
        .eq('status', 'active')
        .order('created_at', ascending: false);

    final rows = (data as List).cast<Map<String, dynamic>>();
    return rows.map(_mapRowToModel).toList();
  }
  Future<CaravanModel?> getById(String id) async {
    final data = await _sb
        .from('caravans')
        .select('''
        id, owner_id, title, city, price, description, phone, features, images, status, created_at,
        profiles!caravans_owner_id_fkey(full_name)
      ''')
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;

    return _mapRowToModel(Map<String, dynamic>.from(data));
  }
  // =========================
  // ✅ TEK MAPPER (aynı mantık)
  // =========================
  CaravanModel _mapRowToModel(Map<String, dynamic> r) {
    final features =
        (r['features'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];

    final rawImages =
        (r['images'] as List?)?.map((e) => e.toString()).toList() ??
            const <String>[];

    // ✅ BURASI KRİTİK: storage path -> url
    final imagesDb = rawImages.map(_toDisplayUrl).where((x) => x.isNotEmpty).toList();

    final createdAtRaw = r['created_at']?.toString();
    final createdAt = createdAtRaw == null
        ? DateTime.now()
        : (DateTime.tryParse(createdAtRaw) ?? DateTime.now());

    final status = (r['status'] ?? 'pending').toString().toLowerCase();

    final seller = r['profiles'];
    String? sellerName;

    if (seller is Map) {
      sellerName = seller['full_name']?.toString();
    } else if (seller is List && seller.isNotEmpty) {
      final first = seller.first;
      if (first is Map) {
        sellerName = first['full_name']?.toString();
      }
    }

    final safeSellerName =
    (sellerName?.trim().isNotEmpty == true) ? sellerName!.trim() : "Satıcı";

    return CaravanModel(
      id: r['id'].toString(),
      ownerId: (r['owner_id'] ?? '').toString(),
      status: status,
      title: (r['title'] ?? '').toString(),
      city: (r['city'] ?? '').toString(),
      price: (r['price'] as int?) ?? 0,

      // ✅ default aynı kalsın
      images: imagesDb.isEmpty ? const ['assets/images/karavan.webp'] : imagesDb,

      categoryId: 'car_motor',
      isUrgent: false,
      isPriceDropped: false,
      createdAt: createdAt,
      sellerName: safeSellerName,
      phone: r['phone']?.toString(),
      description: r['description']?.toString(),
      features: features,
    );
  }
}
