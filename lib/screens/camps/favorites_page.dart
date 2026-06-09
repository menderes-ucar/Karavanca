import 'package:flutter/material.dart';

import '../../models/camp_model.dart';
import '../../services/camp_service.dart';
import '../../services/camp_favorites_service.dart';
import '../../widgets/camp_list_card.dart';
import 'camp_detail_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final _service = CampService();
  final _fav = CampFavoritesService.I;

  List<CampModel> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
    CampFavoritesService.I.load();
  }

  Future<void> _loadAll() async {
    setState(() => _loading = true);
    final data = await _service.getPopularCamps(); // seed'in tamamını döndürüyorsun zaten
    if (!mounted) return;
    setState(() {
      _all = data;
      _loading = false;
    });
  }

  List<CampModel> _onlyFavorites(Set<String> favIds) {
    // sadece favori id’leri olanları seç
    final map = {for (final c in _all) c.id: c};
    final list = <CampModel>[];

    for (final id in favIds) {
      final c = map[id];
      if (c != null) list.add(c);
    }

    // istersen isim/rating’e göre sırala
    list.sort((a, b) => b.rating.compareTo(a.rating));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favoriler')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder<Set<String>>(
        valueListenable: _fav.favoriteIds,
        builder: (_, favIds, __) {
          final items = _onlyFavorites(favIds);

          if (items.isEmpty) {
            return const Center(child: Text('Henüz favori yok.'));
          }

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, i) {
              final camp = items[i];
              return CampListCard(
                camp: camp,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => CampDetailPage(camp: camp)),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
