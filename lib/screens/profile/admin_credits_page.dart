import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/credit_service.dart';

class AdminCreditsPage extends StatefulWidget {
  const AdminCreditsPage({super.key});

  @override
  State<AdminCreditsPage> createState() => _AdminCreditsPageState();
}

class _AdminCreditsPageState extends State<AdminCreditsPage> {
  final _sb = Supabase.instance.client;
  final _creditService = CreditService();
  final _searchCtrl = TextEditingController();

  bool _loading = true;
  List<Map<String, dynamic>> _users = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({String? query}) async {
    setState(() => _loading = true);
    try {
      final q = _sb.from('profiles').select('id, full_name, credits, created_at');

      final res = (query == null || query.trim().isEmpty)
          ? await q.order('created_at', ascending: false).limit(100)
          : await q.ilike('full_name', '%${query.trim()}%').limit(100);

      if (!mounted) return;
      setState(() {
        _users = (res as List).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kullanıcılar alınamadı: $e')),
      );
    }
  }

  Future<void> _openAddCreditDialog(Map<String, dynamic> user) async {
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${user['full_name'] ?? 'Kullanıcı'} - Kredi İşlemi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Mevcut kredi: ${user['credits'] ?? 0}'),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(
                labelText: 'Miktar',
                hintText: 'Eklemek için: 10, düşmek için: -10',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Not (opsiyonel)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Uygula'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final amount = int.tryParse(amountCtrl.text.trim());
    if (amount == null || amount == 0) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir miktar gir (0 olamaz)')),
      );
      return;
    }

    try {
      await _creditService.adminAddCredits(
        targetUserId: user['id'] as String,
        amount: amount,
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kredi güncellendi ✅')),
      );
      _load(query: _searchCtrl.text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hata: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kredi Yönetimi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Kullanıcı adı ara...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onSubmitted: (v) => _load(query: v),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: () => _load(query: _searchCtrl.text),
              child: _users.isEmpty
                  ? ListView(
                children: const [
                  SizedBox(height: 80),
                  Center(child: Text('Kullanıcı bulunamadı')),
                ],
              )
                  : ListView.separated(
                itemCount: _users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final u = _users[i];
                  return ListTile(
                    title: Text((u['full_name'] ?? '-').toString()),
                    subtitle: Text('Kredi: ${u['credits'] ?? 0}'),
                    trailing: IconButton(
                      tooltip: 'Kredi yükle/düş',
                      icon: const Icon(Icons.add_card),
                      onPressed: () => _openAddCreditDialog(u),
                    ),
                    onTap: () => _openAddCreditDialog(u),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}