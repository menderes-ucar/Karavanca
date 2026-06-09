import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminCampsPage extends StatefulWidget {
  const AdminCampsPage({super.key});

  @override
  State<AdminCampsPage> createState() => _AdminCampsPageState();
}

class _AdminCampsPageState extends State<AdminCampsPage> {
  bool loading = true;
  List<Map<String, dynamic>> rows = [];

  Future<void> _load() async {
    setState(() => loading = true);

    try {
      final data = await Supabase.instance.client
          .from('camps')
          .select('id, name, city, region, status, price_per_night, created_at')
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
        SnackBar(content: Text("Kamp alanları alınamadı: $e")),
      );
    }
  }

  Future<void> _setStatus(String id, String status) async {
    try {
      await Supabase.instance.client
          .from('camps')
          .update({'status': status})
          .eq('id', id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(status == 'active' ? "Aktif edildi ✅" : "Pasife alındı ✅")),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Durum hata: $e")),
      );
    }
  }

  Future<void> _deleteCamp(String id) async {
    if (id.trim().isEmpty) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kamp alanı silinsin mi?"),
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
      await Supabase.instance.client.rpc(
        'admin_delete_camp',
        params: {'p_id': id},
      );

      if (!mounted) return;

      setState(() {
        rows.removeWhere((e) => e['id'].toString() == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kamp alanı silindi ✅")),
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
  void initState() {
    super.initState();
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin • Kamp Alanları"),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
          ? const Center(child: Text("Kamp alanı yok"))
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final r = rows[i];
          final id = (r['id'] ?? '').toString();
          final status = (r['status'] ?? 'active').toString();

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (r['name'] ?? '-').toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text("${r['city'] ?? '-'} / ${r['region'] ?? '-'}"),
                  const SizedBox(height: 6),
                  Text("Status: $status"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _deleteCamp(id),
                          icon: const Icon(Icons.delete_outline),
                          label: const Text("Sil"),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _setStatus(
                            id,
                            status == 'active' ? 'passive' : 'active',
                          ),
                          child: Text(
                            status == 'active' ? "Pasife al" : "Aktif et",
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}