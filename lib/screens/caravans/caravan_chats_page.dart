import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'caravan_chat_detail_page.dart';

class CaravanChatsPage extends StatefulWidget {
  const CaravanChatsPage({super.key});

  @override
  State<CaravanChatsPage> createState() => _CaravanChatsPageState();
}

class _CaravanChatsPageState extends State<CaravanChatsPage> {
  final sb = Supabase.instance.client;

  bool loading = true;
  String q = "";
  String? errorText;

  List<Map<String, dynamic>> rows = [];

  static const Color kBg = Color(0xFFF3F6F6);
  static const Color kDark = Color(0xFF2E7D32);
  static const Color kAccent = Color(0xFF0F766E);

  String get me => sb.auth.currentUser!.id;

  @override
  void initState() {
    super.initState();
    _load();
  }

  String _timeText(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk';
    if (diff.inHours < 24) return '${diff.inHours} sa';

    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return '$d.$m';
  }

  Map<String, dynamic>? _caravanMap(dynamic v) {
    if (v is Map) return Map<String, dynamic>.from(v);
    if (v is List && v.isNotEmpty && v.first is Map) {
      return Map<String, dynamic>.from(v.first as Map);
    }
    return null;
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      errorText = null;
    });

    try {
      final uid = sb.auth.currentUser?.id;
      if (uid == null) throw "Giriş yapmalısın.";

      final data = await sb
          .from('chat_threads')
          .select(
        'id, caravan_id, seller_id, buyer_id, last_message, updated_at, caravans(title, owner_id)',
      )
          .or('seller_id.eq.$uid,buyer_id.eq.$uid')
          .not('caravan_id', 'is', null)
          .order('updated_at', ascending: false);

      if (!mounted) return;
      setState(() {
        rows = (data as List).cast<Map<String, dynamic>>();
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        loading = false;
        errorText = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = q.trim().toLowerCase();

    final filtered = rows.where((r) {
      final caravan = _caravanMap(r['caravans']);
      final title = (caravan?['title'] ?? '').toString().toLowerCase();
      final last = (r['last_message'] ?? '').toString().toLowerCase();
      return query.isEmpty ? true : title.contains(query) || last.contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Karavan Mesajları",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: kDark,
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
            child: TextField(
              onChanged: (v) => setState(() => q = v),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: "Sohbet ara...",
                hintStyle: const TextStyle(color: Colors.white70),
                prefixIcon: const Icon(Icons.search, color: Colors.white70),
                filled: true,
                fillColor: Colors.white.withOpacity(.13),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : errorText != null
                ? _ErrorState(text: errorText!, onRetry: _load)
                : filtered.isEmpty
                ? const _EmptyState()
                : RefreshIndicator(
              onRefresh: _load,
              child: ListView.builder(
                padding: const EdgeInsets.all(14),
                itemCount: filtered.length,
                itemBuilder: (_, i) {
                  final r = filtered[i];
                  final tid = r['id'].toString();

                  final caravan = _caravanMap(r['caravans']);
                  final caravanTitle =
                  (caravan?['title'] ?? 'Karavan').toString();

                  final updatedAt = DateTime.tryParse(
                    (r['updated_at'] ?? '').toString(),
                  ) ??
                      DateTime.now();

                  final last = (r['last_message'] ?? '')
                      .toString()
                      .trim();

                  final sellerIdFromThread =
                  (r['seller_id'] ?? '').toString();

                  const sellerName = "Satıcı";

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CaravanChatDetailPage(
                              caravanId:
                              (r['caravan_id'] ?? '').toString(),
                              caravanTitle: caravanTitle,
                              sellerId: sellerIdFromThread,
                              sellerName: sellerName,
                              threadId: tid,
                            ),
                          ),
                        );
                        if (!mounted) return;
                        _load();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.black.withOpacity(.06),
                          ),
                          boxShadow: const [
                            BoxShadow(
                              blurRadius: 18,
                              color: Color(0x12000000),
                              offset: Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 66,
                              height: 66,
                              decoration: BoxDecoration(
                                color: kAccent.withOpacity(.10),
                                borderRadius:
                                BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.rv_hookup,
                                color: kAccent,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          caravanTitle,
                                          maxLines: 1,
                                          overflow:
                                          TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: kDark,
                                            fontWeight:
                                            FontWeight.w900,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        _timeText(updatedAt),
                                        style: const TextStyle(
                                          color: Colors.black45,
                                          fontSize: 12,
                                          fontWeight:
                                          FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    last.isEmpty
                                        ? "Yeni sohbet"
                                        : last,
                                    maxLines: 1,
                                    overflow:
                                    TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                      kAccent.withOpacity(.10),
                                      borderRadius:
                                      BorderRadius.circular(999),
                                    ),
                                    child: const Text(
                                      "Karavan ilanı",
                                      style: TextStyle(
                                        color: kAccent,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.chevron_right,
                              color: Colors.black38,
                            ),
                          ],
                        ),
                      ),
                    ),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          "Henüz karavan sohbeti yok.\nBir karavan ilanından mesaj başlatabilirsin.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.black54,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String text;
  final VoidCallback onRetry;

  const _ErrorState({
    required this.text,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 46, color: Colors.red),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: onRetry,
              child: const Text("Tekrar dene"),
            ),
          ],
        ),
      ),
    );
  }
}