import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/camp_model.dart';
import '../../services/auth_guard.dart';
import '../../widgets/image_slider.dart';
import '../../widgets/amenity_tile.dart';

import '../../services/camp_favorites_service.dart';
import '../../widgets/representative_image_badge.dart';
import '../../widgets/ugc_action_sheet.dart';


class CampDetailPage extends StatelessWidget {
  final CampModel camp;
  const CampDetailPage({super.key, required this.camp});

  Future<void> _openWebsite(BuildContext context) async {
    final website = camp.website?.trim();

    if (website == null || website.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Website bilgisi yok.')),
      );
      return;
    }

    final uri = Uri.tryParse(
      website.startsWith('http') ? website : 'https://$website',
    );

    if (uri == null) return;

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _openMap(BuildContext context) async {
    final query = (camp.mapsQuery?.trim().isNotEmpty == true)
        ? camp.mapsQuery!.trim()
        : '${camp.name} ${camp.region} ${camp.city}';

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}',
    );

    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _report(BuildContext context) async {
    if (!await AuthGuard.requireAuth(context)) return;
    await UgcActionSheet.report(
      context: context,
      contentType: 'camp',
      contentId: camp.id,
      title: 'Kamp Alanını Şikayet Et',
    );
  }

  @override
  Widget build(BuildContext context) {
    final fav = CampFavoritesService.I; // ✅ EKLE

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 280,
                backgroundColor: Colors.white,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),

                // ✅ SAĞ ÜST FAVORİ BUTONU
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: ValueListenableBuilder<Set<String>>(
                      valueListenable: fav.favoriteIds,
                      builder: (_, favIds, __) {
                        final isFav = favIds.contains(camp.id);

                        return InkWell(
                          borderRadius: BorderRadius.circular(999),
                          onTap: () async {
                            if (!await AuthGuard.requireAuth(context)) return;
                            await fav.toggle(camp.id);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.30),
                              ),
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.white,
                              size: 22,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                flexibleSpace: FlexibleSpaceBar(
                  background: ImageSlider(images: camp.images),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        camp.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.place_outlined,
                              size: 18, color: Colors.black54),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              camp.region,
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children:
                        camp.tags.map((t) => Chip(label: Text(t))).toList(),
                      ),

                      const SizedBox(height: 16),

                      // ✅ TEMSİLÎ GÖRSEL BİLGİLENDİRME KARTI (Tıklanabilir)
                      const RepresentativeImageBadge(
                        isMini: false,
                        themeColor: Color(0xFF06343A),
                      ),

                      const SizedBox(height: 16),

                      if (camp.description.trim().isNotEmpty) ...[
                        const Text(
                          'Açıklama',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(camp.description, style: const TextStyle(height: 1.35)),
                        const SizedBox(height: 18),
                      ],

                      const SizedBox(height: 18),

                      const Text(
                        'İmkanlar',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              ...camp.amenities.map(
                                    (a) => Padding(
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                                  child: AmenityTile(amenity: a),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 18),

                      const Text(
                        'Kurallar & Bilgiler',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              const Text(
                                'Bilgiler doğrulanmaktadır.',
                                style: TextStyle(
                                  color: Colors.black54,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),

                      const Text(
                        'İletişim & Yönlendirme',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  onPressed: () => _openMap(context),
                                  icon: const Icon(Icons.map_outlined),
                                  label: const Text('Haritada Aç'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _openWebsite(context),
                                  icon: const Icon(Icons.language),
                                  label: const Text('Websiteye Git'),
                                ),
                              ),
                              const SizedBox(height: 10),
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: () => _report(context),
                                  icon: const Icon(Icons.flag_outlined),
                                  label: const Text('Bilgi Hatalı / Şikayet Et'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _infoRow(String k, String v) {
    return Row(
      children: [
        Expanded(child: Text(k, style: const TextStyle(color: Colors.black54))),
        Text(v, style: const TextStyle(fontWeight: FontWeight.w900)),
      ],
    );
  }
}