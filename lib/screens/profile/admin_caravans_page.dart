import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/admin_push_service.dart';

class AdminCaravansPage extends StatefulWidget {
  const AdminCaravansPage({super.key});

  @override
  State<AdminCaravansPage> createState() => _AdminCaravansPageState();
}

class _AdminCaravansPageState extends State<AdminCaravansPage> {
  bool loading = true;
  List<Map<String, dynamic>> rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }
  static const _bucket = 'caravan-images';

  List<String> _imagesOf(Map<String, dynamic> r) {
    return (r['images'] as List?)?.map((e) => e.toString()).toList() ?? [];
  }

  String _publicUrl(String path) {
    return Supabase.instance.client.storage.from(_bucket).getPublicUrl(path);
  }

  Widget _imageStrip(List<String> images) {
    if (images.isEmpty) {
      return const Text(
        "Fotoğraf yok",
        style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
      );
    }

    return SizedBox(
      height: 82,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final img = images[i];
          final url = img.startsWith('http') ? img : _publicUrl(img);

          return ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              url,
              width: 92,
              height: 82,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 92,
                height: 82,
                color: Colors.black12,
                child: const Icon(Icons.broken_image),
              ),
            ),
          );
        },
      ),
    );
  }
  Future<void> _load() async {
    setState(() => loading = true);

    try {
      final sb = Supabase.instance.client;

      final data = await sb
          .from('caravans')
          .select(
        'id, title, city, price, images, status, created_at, updated_at, approved_at, approved_by, last_approved_at, last_approved_by, owner_id',
      )
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        rows = (data as List).cast<Map<String, dynamic>>();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Yükleme hatası: $e")),
      );
    }
  }

  String _fmtPrice(dynamic v) {
    if (v == null) return "-";
    final n = (v is int) ? v : int.tryParse(v.toString()) ?? 0;
    final s = n.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      b.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) b.write('.');
    }
    return "${b.toString()} ₺";
  }

  DateTime? _dt(dynamic v) {
    if (v == null) return null;
    return DateTime.tryParse(v.toString());
  }

  /// ✅ Profesyonel badge:
  /// - last_approved_at NULL => Yeni İlan (hiç onay almamış)
  /// - last_approved_at var + updated_at > last_approved_at => Güncellendi (tekrar onay)
  Widget _pendingTypeBadge(Map<String, dynamic> r) {
    final lastApprovedAt = _dt(r['last_approved_at']);
    final updatedAt = _dt(r['updated_at']);

    if (lastApprovedAt == null) {
      return _badge(
        text: "Yeni İlan",
        bg: const Color(0xFFECFDF5),
        fg: const Color(0xFF047857),
      );
    }

    if (updatedAt != null && updatedAt.isAfter(lastApprovedAt)) {
      return _badge(
        text: "Güncellendi • Tekrar Onay",
        bg: const Color(0xFFFFF7ED),
        fg: const Color(0xFF9A3412),
      );
    }

    // last_approved var ama updated_at yoksa (eski kayıt vs)
    return _badge(
      text: "Tekrar Onay",
      bg: const Color(0xFFFFF7ED),
      fg: const Color(0xFF9A3412),
    );
  }

  Widget _badge({
    required String text,
    required Color bg,
    required Color fg,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }

  Future<void> _approve(String id) async {
    final sb = Supabase.instance.client;
    final adminId = sb.auth.currentUser?.id;
    final now = DateTime.now().toIso8601String();

    try {
      final current = rows.firstWhere((e) => e['id'].toString() == id);

      await sb.from('caravans').update({
        'status': 'active',
        'approved_at': now,
        'approved_by': adminId,
        'last_approved_at': now,
        'last_approved_by': adminId,
      }).eq('id', id);

      final title = (current['title'] ?? 'Yeni karavan ilanı').toString();
      final city = (current['city'] ?? '').toString();

      try {
        await AdminPushService().sendToAll(
          title: 'Yeni karavan ilanı yayında 🚐',
          body: city.trim().isEmpty ? title : '$title • $city',
          data: {
            'type': 'caravan',
            'id': id,
          },
        );
      } catch (pushError) {
        debugPrint('❌ Karavan push gönderilemedi: $pushError');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Onaylandı ve bildirim gönderildi ✅")),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Approve hata: $e")),
      );
    }
  }
  Future<void> _reject(String id) async {
    final sb = Supabase.instance.client;
    final adminId = sb.auth.currentUser?.id;

    try {
      await sb.from('caravans').update({
        'status': 'passive',

        // pasife alınca approved_at zorunlu değil,
        // istersen dokunma, istersen null yap:
        'approved_at': null,
        'approved_by': null,

        // ✅ last_approved_* kalsın (geçmişi silme)
        // 'last_approved_at': ...  dokunmuyoruz
        // 'last_approved_by': ...  dokunmuyoruz
      }).eq('id', id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pasif yapıldı ✅")),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pasif hata: $e")),
      );
    }
  }
  Future<void> _deleteCaravan(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Karavan ilanı silinsin mi?"),
        content: const Text("Bu işlem geri alınamaz."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Vazgeç"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Sil"),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await Supabase.instance.client
          .from('caravans')
          .delete()
          .eq('id', id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Karavan ilanı silindi ✅")),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Silme hata: $e")),
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin • Karavan İlanları"),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
          ? const Center(child: Text("Pending ilan yok 👌"))
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final r = rows[i];
          final id = r['id'].toString();

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 20,
                  offset: Offset(0, 12),
                  color: Color(0x14000000),
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (r['title'] ?? '-').toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    _pendingTypeBadge(r),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  (r['city'] ?? '-').toString(),
                  style: const TextStyle(
                    color: Colors.black54,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const SizedBox(height: 10),

                _imageStrip(_imagesOf(r)),

                const SizedBox(height: 10),
                Text(
                  _fmtPrice(r['price']),
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _deleteCaravan(id),
                        child: const Text("Sil"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _reject(id),
                        child: const Text("Pasif"),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _approve(id),
                        child: const Text("Approve"),
                      ),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }
}
