import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/product_model.dart';
import 'product_chat_page.dart';

class ProductChatsPage extends StatefulWidget {
  const ProductChatsPage({super.key});

  @override
  State<ProductChatsPage> createState() => _ProductChatsPageState();
}

class _ProductChatsPageState extends State<ProductChatsPage> {
  final sb = Supabase.instance.client;

  bool loading = true;
  String? errorText;
  String q = "";

  List<_ThreadRow> items = [];

  static const Color kBg = Color(0xFFF3F6F6);
  static const Color kDark = Color(0xFF2E7D32);
  static const Color kAccent = Color(0xFF0F766E);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      errorText = null;
    });

    try {
      final uid = sb.auth.currentUser?.id;
      if (uid == null) throw "Giriş yapmalısın.";

      final threads = await sb
          .from('chat_threads')
          .select('id, product_id, seller_id, buyer_id, last_message, updated_at')
          .or('seller_id.eq.$uid,buyer_id.eq.$uid')
          .not('product_id', 'is', null)
          .order('updated_at', ascending: false);

      final tlist = (threads as List).cast<Map<String, dynamic>>();

      if (tlist.isEmpty) {
        setState(() {
          items = [];
          loading = false;
        });
        return;
      }

      final productIds =
      tlist.map((r) => r['product_id'].toString()).toSet().toList();

      final otherIds = <String>{};
      for (final t in tlist) {
        final s = t['seller_id'].toString();
        final b = t['buyer_id'].toString();
        otherIds.add(uid == s ? b : s);
      }

      final productsRes = await sb
          .from('products')
          .select(
        'id, owner_id, title, category_id, category_title, city, price, images, description, phone, status, admin_note, approved_at, created_at, condition',
      )
          .inFilter('id', productIds);

      final products = (productsRes as List).cast<Map<String, dynamic>>();
      final productById = {for (final p in products) p['id'].toString(): p};

      final profRes = otherIds.isEmpty
          ? []
          : await sb
          .from('profiles')
          .select('id, full_name')
          .inFilter('id', otherIds.toList());

      final profs = (profRes as List).cast<Map<String, dynamic>>();
      final nameById = {
        for (final p in profs)
          p['id'].toString(): (p['full_name'] ?? '').toString().trim()
      };

      final out = <_ThreadRow>[];

      for (final t in tlist) {
        final pid = t['product_id'].toString();
        final sellerId = t['seller_id'].toString();
        final buyerId = t['buyer_id'].toString();
        final otherId = (uid == sellerId) ? buyerId : sellerId;

        final otherName =
        (nameById[otherId] ?? '').isEmpty ? "Kullanıcı" : nameById[otherId]!;

        final prodMap = productById[pid];

        final product = prodMap == null
            ? ProductModel(
          id: pid,
          ownerId: sellerId,
          title: "Ürün",
          categoryId: "",
          categoryTitle: "",
          price: 0,
          city: "",
          images: const [],
          description: "",
          phone: null,
          sellerName: otherName,
          status: "active",
          createdAt: DateTime.now(),
        )
            : ProductModel.fromMap({
          ...prodMap,
          'profiles': {'full_name': otherName},
        });

        out.add(
          _ThreadRow(
            threadId: t['id'].toString(),
            product: product,
            otherName: otherName,
            lastMessage: (t['last_message'] ?? '').toString(),
            updatedAt: DateTime.tryParse((t['updated_at'] ?? '').toString()),
          ),
        );
      }

      if (!mounted) return;
      setState(() {
        items = out;
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

  String _fmtTime(DateTime? dt) {
    if (dt == null) return "";
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return "şimdi";
    if (diff.inMinutes < 60) return "${diff.inMinutes} dk";
    if (diff.inHours < 24) return "${diff.inHours} sa";

    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    return "$d.$m";
  }

  String _fmtPrice(int price) {
    if (price <= 0) return "Fiyat yok";
    final s = price.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      b.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) b.write('.');
    }
    return "${b.toString()} ₺";
  }

  Widget _smartImage(String path) {
    final p = path.trim();
    final isNetwork = p.startsWith('http://') || p.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        p,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _imageFallback(),
      );
    }

    return Image.asset(
      p,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _imageFallback(),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFE8EEEE),
      alignment: Alignment.center,
      child: const Icon(Icons.inventory_2_outlined, color: Colors.black45),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = q.trim().toLowerCase();

    final filtered = items.where((x) {
      if (query.isEmpty) return true;
      return x.otherName.toLowerCase().contains(query) ||
          x.product.title.toLowerCase().contains(query) ||
          x.lastMessage.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kDark,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Ürün Mesajları",
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
              child: ListView.separated(
                padding: const EdgeInsets.all(14),
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final it = filtered[i];
                  final img = it.product.images.isNotEmpty
                      ? it.product.images.first
                      : null;

                  return InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProductChatPage(
                            product: it.product,
                            threadId: it.threadId,
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
                          ClipRRect(
                            borderRadius:
                            BorderRadius.circular(16),
                            child: SizedBox(
                              width: 66,
                              height: 66,
                              child: img == null
                                  ? _imageFallback()
                                  : _smartImage(img),
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
                                        it.otherName,
                                        maxLines: 1,
                                        overflow:
                                        TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight:
                                          FontWeight.w900,
                                          fontSize: 15,
                                          color: kDark,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _fmtTime(it.updatedAt),
                                      style: const TextStyle(
                                        color: Colors.black45,
                                        fontSize: 12,
                                        fontWeight:
                                        FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  it.product.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black54,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  it.lastMessage.isEmpty
                                      ? "Yeni sohbet"
                                      : it.lastMessage,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.black45,
                                    fontWeight: FontWeight.w600,
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
                                  child: Text(
                                    _fmtPrice(it.product.price),
                                    style: const TextStyle(
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
          "Henüz ürün sohbeti yok.\nBir ürün ilanından mesaj başlatabilirsin.",
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

class _ThreadRow {
  final String threadId;
  final ProductModel product;
  final String otherName;
  final String lastMessage;
  final DateTime? updatedAt;

  _ThreadRow({
    required this.threadId,
    required this.product,
    required this.otherName,
    required this.lastMessage,
    required this.updatedAt,
  });
}