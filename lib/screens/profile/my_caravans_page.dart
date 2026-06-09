import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../caravans/caravan_edit_page.dart';

class MyCaravansPage extends StatefulWidget {
  const MyCaravansPage({super.key});

  @override
  State<MyCaravansPage> createState() => _MyCaravansPageState();
}

class _MyCaravansPageState extends State<MyCaravansPage> {
  int tab = 0; // 0 pending, 1 active, 2 passive
  bool loading = true;
  List<Map<String, dynamic>> rows = [];

  String get _status {
    if (tab == 0) return 'pending';
    if (tab == 1) return 'active';
    return 'passive';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);

    try {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;
      if (uid == null) {
        if (!mounted) return;
        setState(() {
          rows = [];
          loading = false;
        });
        return;
      }

      final data = await sb
          .from('caravans')
      // ✅ EDIT sayfası için description + images de çekiyoruz
          .select('id, title, city, price, description, images, status, created_at')
          .eq('owner_id', uid)
          .eq('status', _status)
          .order('created_at', ascending: false);

      if (!mounted) return;
      setState(() {
        rows = (data as List).cast<Map<String, dynamic>>();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Karavan ilanların yüklenemedi: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
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

  Future<void> _openEdit(Map<String, dynamic> r) async {
    final res = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CaravanEditPage(
          id: r['id'].toString(),
          initialTitle: (r['title'] ?? '').toString(),
          initialCity: (r['city'] ?? '').toString(),
          initialPrice: (r['price'] ?? 0),
          // ✅ yeni eklenenler:
          initialDesc: (r['description'] ?? '').toString(),
          initialImages: (r['images'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
              const <String>[],
        ),
      ),
    );

    if (res == true) {
      if (!mounted) return;

      // ✅ kullanıcıya net bilgi: edit -> pending
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("İlan güncellendi. Tekrar admin onayına gönderildi (Pending)."),
        ),
      );

      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f5f5),
      appBar: AppBar(
        title: const Text("Benim Karavan İlanlarım"),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              Expanded(
                child: _tabBtn(
                  label: "Pending",
                  active: tab == 0,
                  onTap: () async {
                    setState(() => tab = 0);
                    await _load();
                  },
                ),
              ),
              Expanded(
                child: _tabBtn(
                  label: "Yayında",
                  active: tab == 1,
                  onTap: () async {
                    setState(() => tab = 1);
                    await _load();
                  },
                ),
              ),
              Expanded(
                child: _tabBtn(
                  label: "Pasif",
                  active: tab == 2,
                  onTap: () async {
                    setState(() => tab = 2);
                    await _load();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
          ? _empty()
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final r = rows[i];
          final title = (r['title'] ?? '-').toString();
          final city = (r['city'] ?? '-').toString();
          final status = (r['status'] ?? '-').toString();
          final price = _fmtPrice(r['price']);

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xffe6e6e6)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xfff5f5f5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.rv_hookup, color: Colors.black87),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: _badgeBg(status),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              _statusTr(status),
                              style: TextStyle(
                                color: _badgeFg(status),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        city,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        price,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),

                      Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: () => _openEdit(r),
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text("Düzenle"),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
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
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _empty() {
    final msg = tab == 0
        ? "Onay bekleyen karavan ilanı yok 👌"
        : tab == 1
        ? "Yayında karavan ilanı yok 👌"
        : "Pasif karavan ilanı yok 👌";

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 10),
            Text(
              msg,
              style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}
