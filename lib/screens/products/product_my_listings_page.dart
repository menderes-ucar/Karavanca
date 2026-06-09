import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../services/product_favorites_service.dart';
import 'product_detail_page.dart';
import 'product_edit_page.dart';

class ProductMyListingsPage extends StatefulWidget {
  const ProductMyListingsPage({super.key});

  @override
  State<ProductMyListingsPage> createState() => _ProductMyListingsPageState();
}

class _ProductMyListingsPageState extends State<ProductMyListingsPage> {
  final _service = ProductService();
  final _fav = ProductFavoritesService();

  bool loading = true;
  List<ProductModel> mine = [];
  int tab = 0; // 0 pending, 1 active, 2 passive

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      final data = await _service.getMine();
      if (!mounted) return;
      setState(() => mine = data);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ürün ilanların yüklenemedi: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  List<ProductModel> get pending => mine.where((p) => p.status == 'pending').toList();
  List<ProductModel> get active => mine.where((p) => p.status == 'active').toList();
  List<ProductModel> get passive => mine.where((p) => p.status == 'passive').toList();
  List<ProductModel> get list => tab == 0 ? pending : (tab == 1 ? active : passive);

  Future<void> _openEdit(ProductModel p) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ProductEditPage(
          id: p.id,
          initialTitle: p.title,
          initialCity: p.city,
          initialPrice: p.price,
          initialDesc: p.description,
          initialImages: p.images,
        ),
      ),
    );

    if (res == true) {
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Güncellendi ✅ (pending'e düştü)")),
      );
    }
  }

  String _statusTr(String s) {
    switch (s) {
      case 'pending':
        return 'Onay Bekliyor';
      case 'active':
        return 'Yayında';
      case 'passive':
        return 'Pasif';
      default:
        return s;
    }
  }

  Color _badgeBg(String s) {
    switch (s) {
      case 'pending':
        return const Color(0xFFFFF7ED);
      case 'active':
        return const Color(0xFFECFDF5);
      case 'passive':
        return const Color(0xFFF3F4F6);
      default:
        return const Color(0xFFF3F4F6);
    }
  }

  Color _badgeFg(String s) {
    switch (s) {
      case 'pending':
        return const Color(0xFF9A3412);
      case 'active':
        return const Color(0xFF047857);
      case 'passive':
        return const Color(0xFF374151);
      default:
        return const Color(0xFF374151);
    }
  }

  String _formatPrice(int price) {
    final s = price.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      b.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) b.write('.');
    }
    return "${b.toString()} ₺";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ürün İlanlarım"),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              Expanded(child: _tabBtn("Pending (${pending.length})", tab == 0, () => setState(() => tab = 0))),
              Expanded(child: _tabBtn("Yayında (${active.length})", tab == 1, () => setState(() => tab = 1))),
              Expanded(child: _tabBtn("Pasif (${passive.length})", tab == 2, () => setState(() => tab = 2))),
            ],
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : list.isEmpty
          ? _empty()
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final p = list[i];
          final img = p.images.isNotEmpty ? p.images.first : null;

          return InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProductDetailPage(
                    product: p,
                    favoritesService: _fav,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xffe6e6e6)),
              ),
              child: Row(
                children: [
                  _thumb(img),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                p.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontWeight: FontWeight.w900),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: _badgeBg(p.status),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                _statusTr(p.status),
                                style: TextStyle(
                                  color: _badgeFg(p.status),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${p.city} • ${p.categoryTitle}",
                          style: const TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _formatPrice(p.price),
                          style: const TextStyle(fontWeight: FontWeight.w900),
                        ),
                        if ((p.adminNote ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            "Admin notu: ${p.adminNote}",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),

                        // ✅ DÜZENLE
                        Align(
                          alignment: Alignment.centerRight,
                          child: OutlinedButton.icon(
                            onPressed: () => _openEdit(p),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text("Düzenle"),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              foregroundColor: Colors.black87,
                              side: const BorderSide(color: Color(0xffe6e6e6)),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _tabBtn(String text, bool active, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        color: active ? Colors.black : Colors.transparent,
        child: Text(
          text,
          style: TextStyle(
            color: active ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    final txt = tab == 0
        ? "Onay bekleyen ürün ilanı yok."
        : tab == 1
        ? "Yayında ürün ilanı yok."
        : "Pasif ürün ilanı yok.";
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          txt,
          style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  // ✅ Storage path destekli thumbnail
  Widget _thumb(String? img) {
    final sb = Supabase.instance.client;

    if (img == null || img.trim().isEmpty) {
      return Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.image_outlined),
      );
    }

    final p = img.trim();
    final isHttp = p.startsWith('http://') || p.startsWith('https://');
    final isAsset = p.startsWith('assets/');

    // ✅ storage path ise public url’e çevir
    final url = isHttp
        ? p
        : (isAsset ? p : sb.storage.from('product-images').getPublicUrl(p));

    final child = isAsset
        ? Image.asset(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
    )
        : Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(width: 68, height: 68, child: child),
    );
  }
}
