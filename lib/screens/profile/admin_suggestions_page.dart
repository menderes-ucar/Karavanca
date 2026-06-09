import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/admin_push_service.dart';

class AdminSuggestionsPage extends StatefulWidget {
  const AdminSuggestionsPage({super.key});

  @override
  State<AdminSuggestionsPage> createState() => _AdminSuggestionsPageState();
}

class _AdminSuggestionsPageState extends State<AdminSuggestionsPage> {
  bool loading = true;
  List<Map<String, dynamic>> rows = [];

  Future<void> _load() async {
    setState(() => loading = true);
    final sb = Supabase.instance.client;

    final data = await sb
        .from('camp_suggestions')
        .select(
      'id, name, city, district, description, phone, website, maps_query, created_by, status, admin_note, approved_at, created_at',
    )
        .isFilter('approved_at', null)
        .order('created_at', ascending: false);

    setState(() {
      rows = (data as List).cast<Map<String, dynamic>>();
      loading = false;
    });
  }

  Future<void> _approve(String id) async {
    final sb = Supabase.instance.client;

    try {
      final current = rows.firstWhere((e) => e['id'].toString() == id);

      await sb.rpc('approve_camp_suggestion', params: {'p_id': id});

      final name = (current['name'] ?? 'Yeni kamp alanı').toString();
      final city = (current['city'] ?? '').toString();

      try {
        await AdminPushService().sendToAll(
          title: 'Yeni kamp alanı yayında 🏕️',
          body: city.trim().isEmpty ? name : '$name • $city',
          data: {
            'type': 'camp',
            'id': id,
          },
        );
      } catch (pushError) {
        debugPrint('❌ Camp push gönderilemedi: $pushError');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kamp onaylandı ve bildirim gönderildi ✅")),
      );

      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Approve hata: $e")),
      );
    }
  }
  Future<void> _deleteSuggestion(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kamp önerisi silinsin mi?"),
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
          .from('camp_suggestions')
          .delete()
          .eq('id', id);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kamp önerisi silindi ✅")),
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

  Widget _line(String title, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text("$title: $value"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin • Kamp Önerileri"),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
          ? const Center(child: Text("Pending öneri yok 👌"))
          : ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: rows.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final r = rows[i];
          final id = (r['id'] ?? '').toString();

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (r['name'] ?? '-').toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "${r['city'] ?? '-'} / ${r['district'] ?? '-'}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  _line("Açıklama", (r['description'] ?? '').toString()),
                  _line("Telefon", (r['phone'] ?? '').toString()),
                  _line("Website", (r['website'] ?? '').toString()),
                  _line("Maps", (r['maps_query'] ?? '').toString()),
                  const SizedBox(height: 10),

                  Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: id.isEmpty ? null : () => _deleteSuggestion(id),
                            icon: const Icon(Icons.delete_outline),
                            label: const Text("Sil"),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: id.isEmpty ? null : () => _deleteSuggestion(id),
                                icon: const Icon(Icons.delete_outline),
                                label: const Text("Sil"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: FilledButton(
                                onPressed: id.isEmpty ? null : () => _approve(id),
                                child: const Text("Kabul Et"),
                              ),
                            ),
                          ],
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
