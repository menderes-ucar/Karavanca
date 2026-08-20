import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminReportsPage extends StatefulWidget {
  const AdminReportsPage({super.key});

  @override
  State<AdminReportsPage> createState() => _AdminReportsPageState();
}

class _AdminReportsPageState extends State<AdminReportsPage> {
  final sb = Supabase.instance.client;
  bool loading = true;
  List<Map<String, dynamic>> reports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await sb.from('content_reports')
          .select('id, reporter_id, reported_user_id, content_type, content_id, reason, details, status, created_at, resolved_at')
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        reports = (data as List).cast<Map<String, dynamic>>();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Raporlar alınamadı: $e')));
    }
  }

  Future<void> _resolve(Map<String, dynamic> report, String status) async {
    try {
      if (status == 'removed') {
        final type = report['content_type']?.toString();
        final contentId = report['content_id']?.toString();
        if (contentId != null && contentId.isNotEmpty) {
          if (type == 'message') {
            await sb.from('chat_messages').delete().eq('id', contentId);
          } else if (type == 'caravan') {
            await sb.from('caravans').update({'status': 'passive'}).eq('id', contentId);
          } else if (type == 'product') {
            await sb.from('products').update({'status': 'passive'}).eq('id', contentId);
          } else if (type == 'camp') {
            await sb.from('camps').update({'status': 'passive'}).eq('id', contentId);
          }
        }
      }

      await sb.from('content_reports').update({
        'status': status,
        'resolved_at': DateTime.now().toUtc().toIso8601String(),
        'resolved_by': sb.auth.currentUser?.id,
      }).eq('id', report['id'].toString());
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Rapor güncellenemedi: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('UGC Moderasyon'),
        actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh))],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
          ? const Center(child: Text('Bekleyen rapor yok.'))
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: reports.length,
          itemBuilder: (_, index) {
            final r = reports[index];
            final status = (r['status'] ?? 'pending').toString();
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text('${r['content_type']} • ${r['reason']}', style: const TextStyle(fontWeight: FontWeight.w800))),
                        Chip(label: Text(status)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('İçerik: ${r['content_id']}'),
                    if ((r['reported_user_id'] ?? '').toString().isNotEmpty)
                      Text('Kullanıcı: ${r['reported_user_id']}'),
                    if ((r['details'] ?? '').toString().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(r['details'].toString()),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton(onPressed: () => _resolve(r, 'resolved'), child: const Text('İncelendi')),
                        FilledButton(onPressed: () => _resolve(r, 'removed'), child: const Text('İçeriği Kaldırıldı')),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
