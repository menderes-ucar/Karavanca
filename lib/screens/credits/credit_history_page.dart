import 'package:flutter/material.dart';

import '../../services/credit_service.dart';

class CreditHistoryPage extends StatefulWidget {
  const CreditHistoryPage({super.key});

  static const Color main = Color(0xFF00B8C8);

  @override
  State<CreditHistoryPage> createState() => _CreditHistoryPageState();
}

class _CreditHistoryPageState extends State<CreditHistoryPage> {
  final _creditService = CreditService();

  bool _loading = true;
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final res = await _creditService.getMyTransactions();
      if (!mounted) return;
      setState(() {
        _items = res;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Geçmiş alınamadı: $e')),
      );
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'admin_grant':
        return 'Admin tarafından yüklendi';
      case 'purchase':
        return 'Satın alma';
      case 'signup_bonus':
        return 'Kayıt bonusu';
      case 'listing_caravan':
        return 'Karavan ilanı';
      case 'listing_product':
        return 'Ürün ilanı';
      case 'message_thread':
        return 'Sohbet başlatma';
      case 'refund':
        return 'İade';
      default:
        return type;
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'admin_grant':
        return Icons.admin_panel_settings_outlined;
      case 'purchase':
        return Icons.shopping_cart_outlined;
      case 'signup_bonus':
        return Icons.celebration_outlined;
      case 'listing_caravan':
        return Icons.rv_hookup;
      case 'listing_product':
        return Icons.inventory_2_outlined;
      case 'message_thread':
        return Icons.chat_bubble_outline;
      case 'refund':
        return Icons.replay_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  String _fmtDate(String? iso) {
    if (iso == null) return '-';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '-';
    return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFFBFC),
      appBar: AppBar(
        backgroundColor: CreditHistoryPage.main,
        foregroundColor: Colors.white,
        title: const Text('Kredi Hareketleri'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: _items.isEmpty
            ? ListView(
          children: const [
            SizedBox(height: 100),
            Center(child: Text('Henüz kredi hareketi yok.')),
          ],
        )
            : ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: _items.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (_, i) {
            final tx = _items[i];
            final amount = (tx['amount'] as num?)?.toInt() ?? 0;
            final positive = amount > 0;
            final type = (tx['type'] ?? '').toString();

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withOpacity(0.06)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: (positive ? Colors.green : Colors.red).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      _typeIcon(type),
                      color: positive ? Colors.green : Colors.red,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _typeLabel(type),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _fmtDate(tx['created_at']?.toString()),
                          style: const TextStyle(color: Colors.black54, fontSize: 12),
                        ),
                        if ((tx['note'] ?? '').toString().isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            tx['note'].toString(),
                            style: const TextStyle(color: Colors.black45, fontSize: 12),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    '${positive ? '+' : ''}$amount',
                    style: TextStyle(
                      color: positive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}