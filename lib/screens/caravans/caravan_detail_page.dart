import 'package:flutter/material.dart';
import '../../services/auth_guard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/caravan_model.dart';
import '../../services/caravan_favorites_service.dart';
import '../../widgets/ugc_action_sheet.dart';
import '../../services/ugc_moderation_service.dart';
import 'caravan_chat_detail_page.dart';

class CaravanDetailPage extends StatefulWidget {
  final CaravanModel listing;
  final CaravanFavoritesService favoritesService;

  const CaravanDetailPage({
    super.key,
    required this.listing,
    required this.favoritesService,
  });

  @override
  State<CaravanDetailPage> createState() => _CaravanDetailPageState();
}

class _CaravanDetailPageState extends State<CaravanDetailPage> {
  int _activeImage = 0;

  String _fmtPrice(int p) {
    final s = p.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      b.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) b.write('.');
    }
    return "${b.toString()} ₺";
  }

  // ✅ URL / eski path -> asset path'e çevir
  // ✅ network / storage path / asset destekli (caravan-images bucket)
  Widget _smartImage(String path) {
    final p = path.trim();

    // 1) Direkt URL ise
    final isNetwork = p.startsWith('http://') || p.startsWith('https://');
    if (isNetwork) {
      return Image.network(
        p,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          color: Colors.black12,
          alignment: Alignment.center,
          child: const Icon(Icons.image_not_supported),
        ),
      );
    }

    // 2) Storage path ise public url üret
    final sb = Supabase.instance.client;
    final url = sb.storage.from('caravan-images').getPublicUrl(p);

    return Image.network(
      url,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.image_not_supported),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final images = l.images.isEmpty ? <String>[] : l.images;

    // ✅ satıcı adı boş gelirse fallback
    final sellerDisplayName = (l.sellerName != null && l.sellerName!.trim().isNotEmpty)
        ? l.sellerName!.trim()
        : "İlan Sahibi";

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F7FB),
        appBar: AppBar(
          title: Text(l.title),
          actions: [
            ValueListenableBuilder<Set<String>>(
              valueListenable: widget.favoritesService.favoriteIds,
              builder: (_, favs, __) {
                final isFav = favs.contains(l.id);
                return IconButton(
                  onPressed: () async {
                    if (!await AuthGuard.requireAuth(context)) return;
                    await widget.favoritesService.toggleFavorite(l.id);
                  },
                  icon: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : null,
                  ),
                );
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: "İlan Detayları"),
              Tab(text: "Benzer İlanlar"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // -------- TAB 1: İlan Detayları
            ListView(
              children: [
                // ✅ HERO
                SizedBox(
                  height: 280,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (images.isEmpty)
                        Container(
                          color: Colors.grey.shade200,
                          alignment: Alignment.center,
                          child: const Icon(Icons.image_outlined, size: 40),
                        )
                      else
                        _smartImage(images[_activeImage.clamp(0, images.length - 1)]),
                      // gradient
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.05),
                              Colors.black.withOpacity(0.65),
                            ],
                          ),
                        ),
                      ),

                      // fiyat badge
                      Positioned(
                        right: 14,
                        bottom: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.70),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.15)),
                          ),
                          child: Text(
                            _fmtPrice(l.price),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),

                      // şehir chip
                      Positioned(
                        left: 14,
                        bottom: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.place_outlined, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                l.city,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // thumbnails
                if (images.length > 1)
                  SizedBox(
                    height: 92,
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                      scrollDirection: Axis.horizontal,
                      itemCount: images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (_, i) {
                        final selected = i == _activeImage;
                        return InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () => setState(() => _activeImage = i),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 110,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: selected
                                    ? Colors.black
                                    : Colors.black.withOpacity(0.10),
                                width: selected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 6),
                                )
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: _smartImage(images[i]),
                          ),
                        );
                      },
                    ),
                  ),

                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _InfoCard(
                        rows: [
                          _RowItem("İlan No", l.id),
                          _RowItem("İlan Tarihi", _dateText(l.createdAt)),
                          _RowItem("Tip", _categoryText(l.categoryId)),
                          _RowItem("Durum", "İkinci El"),
                          _RowItem("Takas", "Evet"),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // ✅ SATICI (sadece mesaj)
                      _SellerCard(
                        name: sellerDisplayName,
                        onMessage: () async {
                          if (!await AuthGuard.requireAuth(context)) return;
                          if (!mounted) return;
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CaravanChatDetailPage(
                                caravanId: l.id,
                                caravanTitle: l.title,
                                sellerId: l.ownerId,
                                sellerName: sellerDisplayName,
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 12),
                      const _SafetyCard(),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: "Açıklama",
                        child: Text(
                          l.description ?? "Açıklama yok.",
                          style: const TextStyle(height: 1.4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SectionCard(
                        title: "Teknik Özellikler",
                        child: Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: (l.features.isEmpty
                              ? const ["Özellik belirtilmedi"]
                              : l.features)
                              .map(
                                (f) => _FeatureChip(
                              text: f,
                              checked: l.features.isNotEmpty,
                            ),
                          )
                              .toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),

            // -------- TAB 2: Benzer ilanlar
            const Center(
              child: Text("Benzer ilanlar daha sonra bağlanacak."),
            ),
          ],
        ),
      ),
    );
  }

  static String _dateText(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";
  }

  static String _categoryText(String id) {
    switch (id) {
      case "car_motor":
        return "Moto Karavan";
      case "car_tow":
        return "Çekme Karavan";
      case "car_offroad":
        return "Offroad Karavan";
      case "car_alkoven":
        return "Alkoven Karavan";
      case "car_mini":
        return "Mini Camper";
      default:
        return id;
    }
  }
}

class _RowItem {
  final String label;
  final String value;
  const _RowItem(this.label, this.value);
}

class _InfoCard extends StatelessWidget {
  final List<_RowItem> rows;
  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "İlan Bilgileri",
      child: Column(
        children: rows
            .map(
              (r) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(r.label,
                      style: const TextStyle(color: Colors.black54)),
                ),
                Expanded(
                  flex: 6,
                  child: Text(
                    r.value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            ),
          ),
        )
            .toList(),
      ),
    );
  }
}

class _SellerCard extends StatelessWidget {
  final String name;
  final VoidCallback onMessage;

  const _SellerCard({
    required this.name,
    required this.onMessage,
  });

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "Satıcı",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 18,
                child: Icon(Icons.person, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: onMessage,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text(
                "Mesaj Gönder",
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  const _SafetyCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: "Güvenlik İpuçları",
      child: const Text(
        "• Satıcıyla yüz yüze görüşmeden kesinlikle para göndermeyin.\n"
            "• Aracı görmeden kapora için para göndermeyi kabul etmeyin.\n"
            "• Tanımadığınız kişilere kimlik/telefon bilgileriyle yapılan transferlere dikkat edin.\n"
            "• Para ödemesi ile ürün teslimini (devir işlemini) aynı anda yapın.",
        style: TextStyle(color: Colors.black87, height: 1.35),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String text;
  final bool checked;

  const _FeatureChip({required this.text, required this.checked});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: checked ? const Color(0xfff4fbf6) : const Color(0xfff7f7f7),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            checked ? Icons.check_circle : Icons.check_box_outline_blank,
            size: 18,
            color: checked ? Colors.green : Colors.black26,
          ),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
