import 'package:flutter/material.dart';
import '../../models/product_model.dart';
import '../../services/admin_push_service.dart';
import '../../services/product_service.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  final _service = ProductService();

  bool loading = true;
  List<ProductModel> all = [];
  int tab = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final data = await _service.adminGetAll();
      if (!mounted) return;
      setState(() => all = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Admin ürünler alınamadı: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  List<ProductModel> get pending =>
      all.where((p) => p.status == 'pending').toList();

  List<ProductModel> get approved =>
      all.where((p) => p.status == 'active' || p.status == 'passive').toList();

  Future<void> _approve(ProductModel p) async {
    final note = await _askNote(
      title: "Approve Notu (opsiyonel)",
      initial: p.adminNote ?? "",
      hint: "Örn: Foto ekle, açıklamayı uzat vs.",
    );

    if (note == null) return;

    try {
      await _service.adminApprove(
        p.id,
        note: note.trim().isEmpty ? null : note.trim(),
      );

      try {
        await AdminPushService().sendToAll(
          title: 'Yeni kamp ürünü yayında 🛒',
          body: '${p.title} • ${p.city}',
          data: {
            'type': 'product',
            'id': p.id,
          },
        );
      } catch (pushError) {
        debugPrint('❌ Product push gönderilemedi: $pushError');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ürün onaylandı ve bildirim gönderildi ✅")),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Approve hata: $e")),
      );
    }
  }

  Future<void> _toggleActive(ProductModel p) async {
    try {
      final next = p.status == 'active' ? 'passive' : 'active';
      await _service.adminSetStatus(p.id, next);
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Durum değiştirme hata: $e")),
      );
    }
  }

  Future<void> _deleteProduct(ProductModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ürün silinsin mi?"),
        content: Text("${p.title} kalıcı olarak silinecek."),
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
      await _service.adminDelete(p.id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Ürün silindi ✅")),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Silme hata: $e")),
      );
    }
  }

  Future<void> _editNote(ProductModel p) async {
    final note = await _askNote(
      title: "Admin Notu",
      initial: p.adminNote ?? "",
      hint: "Not yaz...",
    );
    if (note == null) return;

    await _service.adminSetNote(p.id, note);
    await _load();
  }

  Future<String?> _askNote({
    required String title,
    required String initial,
    required String hint,
  }) async {
    final ctrl = TextEditingController(text: initial);
    final res = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
    ctrl.dispose();
    return res;
  }

  String _fmtDate(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return "${two(dt.day)}.${two(dt.month)}.${dt.year} ${two(dt.hour)}:${two(dt.minute)}";
  }

  Widget _row(ProductModel p, {required List<Widget> actions}) {
    final created = p.createdAt;
    final updated = p.updatedAt;
    final bool isUpdated =
        created != null && updated != null && updated.isAfter(created);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: ListTile(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  p.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (p.status == 'pending' && isUpdated) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFFFE0B2)),
                  ),
                  child: const Text(
                    "GÜNCELLENDİ",
                    style: TextStyle(
                      color: Color(0xFF9A3412),
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),

          subtitle: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (p.images.isNotEmpty) ...[
                  SizedBox(
                    height: 90,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: p.images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final img = p.images[i];

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            img,
                            width: 100,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 100,
                              height: 90,
                              color: Colors.black12,
                              child: const Icon(Icons.broken_image),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  "${p.city} • ${p.categoryTitle}",
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  "status: ${p.status}",
                  style: const TextStyle(color: Colors.black54),
                ),
                if (p.status == 'pending' && isUpdated && updated != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    "Son düzenleme: ${_fmtDate(updated)}",
                    style: const TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (p.adminNote != null && p.adminNote!.trim().isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    "not: ${p.adminNote}",
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          isThreeLine: true,
          trailing: Wrap(spacing: 8, children: actions),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = tab == 0 ? pending : approved;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin • Ürünler"),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              Expanded(
                child: _tabBtn(
                  label: "Pending (${pending.length})",
                  active: tab == 0,
                  onTap: () => setState(() => tab = 0),
                ),
              ),
              Expanded(
                child: _tabBtn(
                  label: "Approved (${approved.length})",
                  active: tab == 1,
                  onTap: () => setState(() => tab = 1),
                ),
              ),
            ],
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
          ? const Center(child: Text("Kayıt yok"))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        itemBuilder: (_, i) {
          final p = list[i];

          if (tab == 0) {
            return _row(
              p,
              actions: [
                IconButton(
                  tooltip: "Sil",
                  onPressed: () => _deleteProduct(p),
                  icon: const Icon(Icons.delete_outline),
                ),
                IconButton(
                  tooltip: "Not",
                  onPressed: () => _editNote(p),
                  icon: const Icon(Icons.edit_note),
                ),
                FilledButton(
                  onPressed: () => _approve(p),
                  child: const Text("Approve"),
                ),
              ],
            );
          }

          return _row(
            p,
            actions: [
              IconButton(
                tooltip: "Sil",
                onPressed: () => _deleteProduct(p),
                icon: const Icon(Icons.delete_outline),
              ),
              IconButton(
                tooltip: "Not",
                onPressed: () => _editNote(p),
                icon: const Icon(Icons.edit_note),
              ),
              OutlinedButton(
                onPressed: () => _toggleActive(p),
                child: Text(
                  p.status == 'active' ? "Pasife al" : "Aktif et",
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tabBtn({
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? Colors.black : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}