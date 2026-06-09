import 'package:flutter/material.dart';
import '../../models/camp_model.dart';
import '../../services/camp_service.dart';
import '../../widgets/camp_list_card.dart';
import '../../widgets/widgets/filter_sheet.dart';
import 'camp_detail_page.dart';
import '../../models/filter_models.dart';
import '../../models/category_model.dart';

class SearchResultsPage extends StatefulWidget {
  final String query;
  final DateTimeRange? range;
  final int guests;

  const SearchResultsPage({
    super.key,
    required this.query,
    required this.range,
    required this.guests,
  });

  @override
  State<SearchResultsPage> createState() => _SearchResultsPageState();
}

class _SearchResultsPageState extends State<SearchResultsPage> {
  final _service = CampService();

  List<CampModel> _items = [];
  bool _loading = true;

  // ✅ filtre state
  ListingFilter _filter = const ListingFilter();

  @override
  void initState() {
    super.initState();

    // CampHome’dan gelen ilk arama değerleri (tarih/kişi)
    _filter = ListingFilter(
      dateRange: widget.range,
      guests: widget.guests,
      sort: SortType.recommended,
    );

    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final data = await _service.searchCamps();
    if (!mounted) return;
    setState(() {
      _items = data;
      _loading = false;
    });
  }

  // ✅ filtre uygula
  List<CampModel> _applyFilter(List<CampModel> list) {
    var x = List<CampModel>.from(list);

    // kategori
    if (_filter.categoryId != null) {
      x = x.where((c) => c.categoryId == _filter.categoryId).toList();
    }

    // fiyat
    if (_filter.minPrice != null) {
      x = x.where((c) => c.pricePerNight >= _filter.minPrice!).toList();
    }
    if (_filter.maxPrice != null) {
      x = x.where((c) => c.pricePerNight <= _filter.maxPrice!).toList();
    }

    // puan
    if (_filter.minRating != null) {
      x = x.where((c) => c.rating >= _filter.minRating!).toList();
    }

    // sıralama
    switch (_filter.sort) {
      case SortType.priceLow:
        x.sort((a, b) => a.pricePerNight.compareTo(b.pricePerNight));
        break;
      case SortType.priceHigh:
        x.sort((a, b) => b.pricePerNight.compareTo(a.pricePerNight));
        break;
      case SortType.ratingHigh:
        x.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      case SortType.newest:
      // mock datada tarih alanı yoksa dokunma
        break;
      case SortType.recommended:
        break;
    }

    return x;
  }

  Future<void> _openFilter() async {
    final res = await showModalBottomSheet<ListingFilter>(
      context: context,
      isScrollControlled: true, // ✅ şart (taşma yok)
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => FilterSheet(
        module: ModuleType.camp,
        initial: _filter,
      ),
    );

    if (res != null && mounted) {
      setState(() => _filter = res); // ✅ listeyi etkiler
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _applyFilter(_items);

    return Scaffold(
      appBar: AppBar(
        title: Text('${_loading ? "" : "${filtered.length}+"} Kamp Alanı Bulundu'),
        actions: [
          TextButton.icon(
            onPressed: _openFilter,
            icon: const Icon(Icons.tune),
            label: const Text('Filtrele'),
          ),
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.map_outlined),
            label: const Text('Harita'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : filtered.isEmpty
          ? const Center(child: Text('Sonuç bulunamadı'))
          : ListView.builder(
        itemCount: filtered.length,
        itemBuilder: (context, i) {
          final camp = filtered[i];
          return CampListCard(
            camp: camp,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CampDetailPage(camp: camp),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
