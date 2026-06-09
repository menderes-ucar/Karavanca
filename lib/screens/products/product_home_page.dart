import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/product_model.dart';
import '../../services/product_service.dart';
import '../../services/product_favorites_service.dart';
import 'product_detail_page.dart';
import 'product_create_page.dart';
import 'product_chat_page.dart';

enum ProductSortType { recommended, priceLow, priceHigh, newest }
enum TimeFilter { all, h48, w1, m1 }

class ProductHomePage extends StatefulWidget {
  final ProductFavoritesService favoritesService;
  const ProductHomePage({super.key, required this.favoritesService});

  @override
  State<ProductHomePage> createState() => _ProductHomePageState();
}

class _ProductHomePageState extends State<ProductHomePage> {
  final _service = ProductService();

  bool loading = true;
  List<ProductModel> all = [];
  String q = "";

  // ✅ Aktif filtreler
  bool urgentOnly = false;
  bool priceDroppedOnly = false;
  String? selectedCategoryId; // null = tümü
  String? selectedCity; // null = tümü
  TimeFilter timeFilter = TimeFilter.all;
  ProductSortType sort = ProductSortType.recommended;
  RangeValues priceRange = const RangeValues(0, 3000000);
  RealtimeChannel? _productsChannel;
  // ✅ Drawer geçici filtreler
  bool tempUrgentOnly = false;
  bool tempPriceDroppedOnly = false;
  String? tempCategoryId;
  String? tempCity;
  TimeFilter tempTimeFilter = TimeFilter.all;
  ProductSortType tempSort = ProductSortType.recommended;
  RangeValues tempPriceRange = const RangeValues(0, 3000000);

  String citySearch = "";

  final List<_Cat> cats = const [
    _Cat("Çadır ve gereçleri", "tent", Icons.house_siding_outlined),
    _Cat("Uyku & Konfor", "sleep", Icons.bed_outlined),
    _Cat("Kamp Mutfak", "kitchen", Icons.outdoor_grill_outlined),
    _Cat("Kamp Masası", "furniture", Icons.chair_outlined),
    _Cat("Elektronik", "electronics", Icons.battery_charging_full_outlined),
    _Cat("Aydınlatma", "light", Icons.flashlight_on_outlined),
    _Cat("Giyim & Ayakkabı", "wear", Icons.hiking_outlined),
    _Cat("Aksesuar", "accessory", Icons.shopping_bag_outlined),
  ];

  // ✅ TEMA 1 (Forest + Amber)
  static const Color _bg = Color(0xFFF6F7FB);
  static const Color _primary = Color(0xFF2E7D32); // forest/teal
  static const Color _accent = Color(0xFFF59E0B); // amber
  static const Color _card = Colors.white;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _load();
    _listenRealtime();
  }
  void _listenRealtime() {
    _productsChannel = Supabase.instance.client
        .channel('products-realtime')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'products',
      callback: (payload) async {
        debugPrint('🔄 products realtime tetiklendi');
        await _load();
      },
    )
        .subscribe();
  }
  Future<void> _load() async {
    setState(() => loading = true);

    try {
      final data = await _service.getAll();
      if (!mounted) return;
      setState(() => all = data);
    } catch (e, st) {
      debugPrint("❌ ProductHomePage _load ERROR: $e");
      debugPrint("$st");
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ürünler yüklenemedi: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() => loading = false);
    }
  }

  void _syncTempWithActive() {
    tempUrgentOnly = urgentOnly;
    tempPriceDroppedOnly = priceDroppedOnly;
    tempCategoryId = selectedCategoryId;
    tempCity = selectedCity;
    tempTimeFilter = timeFilter;
    tempSort = sort;
    tempPriceRange = priceRange;
    citySearch = "";
  }
  @override
  void dispose() {
    _productsChannel?.unsubscribe();
    super.dispose();
  }
  void _applyFilters() {
    setState(() {
      urgentOnly = tempUrgentOnly;
      priceDroppedOnly = tempPriceDroppedOnly;
      selectedCategoryId = tempCategoryId;
      selectedCity = tempCity;
      timeFilter = tempTimeFilter;
      sort = tempSort;
      priceRange = tempPriceRange;
    });
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      urgentOnly = false;
      priceDroppedOnly = false;
      selectedCategoryId = null;
      selectedCity = null;
      timeFilter = TimeFilter.all;
      sort = ProductSortType.recommended;
      priceRange = const RangeValues(0, 3000000);

      // drawer temp
      tempUrgentOnly = false;
      tempPriceDroppedOnly = false;
      tempCategoryId = null;
      tempCity = null;
      tempTimeFilter = TimeFilter.all;
      tempSort = ProductSortType.recommended;
      tempPriceRange = const RangeValues(0, 3000000);
      citySearch = "";
    });
    Navigator.pop(context);
  }

  String _formatPrice(int price) {
    final s = price.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      b.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) b.write('.');
    }
    return "${b.toString()} ₺";
  }

  String _timeLabel(TimeFilter t) {
    switch (t) {
      case TimeFilter.h48:
        return "Son 48 saat";
      case TimeFilter.w1:
        return "1 hafta";
      case TimeFilter.m1:
        return "1 ay";
      case TimeFilter.all:
      default:
        return "Tümü";
    }
  }

  String _sortLabel(ProductSortType s) {
    switch (s) {
      case ProductSortType.priceLow:
        return "Fiyat (Artan)";
      case ProductSortType.priceHigh:
        return "Fiyat (Azalan)";
      case ProductSortType.newest:
        return "En Yeni";
      case ProductSortType.recommended:
      default:
        return "Önerilen";
    }
  }

  Duration? _timeWindow(TimeFilter t) {
    switch (t) {
      case TimeFilter.h48:
        return const Duration(hours: 48);
      case TimeFilter.w1:
        return const Duration(days: 7);
      case TimeFilter.m1:
        return const Duration(days: 30);
      case TimeFilter.all:
      default:
        return null;
    }
  }

  List<ProductModel> _applyCommon(List<ProductModel> list) {
    final query = q.trim().toLowerCase();
    final now = DateTime.now();
    final tw = _timeWindow(timeFilter);

    var out = list.where((p) {
      final okQ = query.isEmpty
          ? true
          : p.title.toLowerCase().contains(query) ||
          p.city.toLowerCase().contains(query);

      final okUrgent = !urgentOnly ? true : p.isUrgent;
      final okDrop = !priceDroppedOnly ? true : p.isPriceDropped;

      final okCat =
      selectedCategoryId == null ? true : p.categoryId == selectedCategoryId;

      final okCity = selectedCity == null ? true : p.city == selectedCity;

      final okPrice =
          p.price >= priceRange.start && p.price <= priceRange.end;

      final created = p.createdAt;
      final okTime = tw == null ? true : now.difference(created) <= tw;

      return okQ && okUrgent && okDrop && okCat && okCity && okPrice && okTime;
    }).toList();

    switch (sort) {
      case ProductSortType.priceLow:
        out.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSortType.priceHigh:
        out.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSortType.newest:
        out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ProductSortType.recommended:
        break;
    }

    return out;
  }

  List<String> get _cities {
    final set = <String>{};
    for (final p in all) {
      final c = p.city.trim();
      if (c.isNotEmpty) set.add(c);
    }
    final list = set.toList()..sort((a, b) => a.compareTo(b));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final activeChips = <Widget>[];

    if (urgentOnly) {
      activeChips.add(_ChipPill(
        text: "Acil",
        onClear: () => setState(() => urgentOnly = false),
        color: _primary,
      ));
    }
    if (priceDroppedOnly) {
      activeChips.add(_ChipPill(
        text: "Fiyatı Düşen",
        onClear: () => setState(() => priceDroppedOnly = false),
        color: _primary,
      ));
    }
    if (selectedCategoryId != null) {
      final name = cats.firstWhere((c) => c.id == selectedCategoryId,
          orElse: () => const _Cat("Kategori", "", Icons.category))
          .title;
      activeChips.add(_ChipPill(
        text: name,
        onClear: () => setState(() => selectedCategoryId = null),
        color: _primary,
      ));
    }
    if (selectedCity != null) {
      activeChips.add(_ChipPill(
        text: selectedCity!,
        onClear: () => setState(() => selectedCity = null),
        color: _primary,
      ));
    }
    if (timeFilter != TimeFilter.all) {
      activeChips.add(_ChipPill(
        text: _timeLabel(timeFilter),
        onClear: () => setState(() => timeFilter = TimeFilter.all),
        color: _primary,
      ));
    }
    if (sort != ProductSortType.recommended) {
      activeChips.add(_ChipPill(
        text: _sortLabel(sort),
        onClear: () => setState(() => sort = ProductSortType.recommended),
        color: _primary,
      ));
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,

      // ✅ Drawer filtreler
      drawer: Drawer(
        child: SafeArea(
          child: StatefulBuilder(
            builder: (context, setDrawerState) {
              final cityQ = citySearch.trim().toLowerCase();
              final cityList = cityQ.isEmpty
                  ? _cities
                  : _cities.where((c) => c.toLowerCase().contains(cityQ)).toList();

              return Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    const Text(
                      "Filtreler",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 14),

                    // ✅ Kategoriler
                    const Text("Kategoriler",
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xffe6e6e6)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String?>(
                            value: null,
                            groupValue: tempCategoryId,
                            title: const Text("Tümü"),
                            onChanged: (v) =>
                                setDrawerState(() => tempCategoryId = v),
                          ),
                          const Divider(height: 1),
                          ...cats.map((c) {
                            return RadioListTile<String?>(
                              value: c.id,
                              groupValue: tempCategoryId,
                              title: Text(c.title),
                              onChanged: (v) =>
                                  setDrawerState(() => tempCategoryId = v),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ✅ Hızlı filtreler
                    const Text("Hızlı Filtreler",
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xffe6e6e6)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: tempUrgentOnly,
                            title: const Text("Acil"),
                            onChanged: (v) =>
                                setDrawerState(() => tempUrgentOnly = v),
                            activeColor: _primary,
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            value: tempPriceDroppedOnly,
                            title: const Text("Fiyatı Düşenler"),
                            onChanged: (v) =>
                                setDrawerState(() => tempPriceDroppedOnly = v),
                            activeColor: _primary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ✅ Zaman
                    const Text("Zaman",
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xffe6e6e6)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<TimeFilter>(
                            value: TimeFilter.all,
                            groupValue: tempTimeFilter,
                            title: const Text("Tümü"),
                            onChanged: (v) =>
                                setDrawerState(() => tempTimeFilter = v!),
                            activeColor: _primary,
                          ),
                          const Divider(height: 1),
                          RadioListTile<TimeFilter>(
                            value: TimeFilter.h48,
                            groupValue: tempTimeFilter,
                            title: const Text("Son 48 saat"),
                            onChanged: (v) =>
                                setDrawerState(() => tempTimeFilter = v!),
                            activeColor: _primary,
                          ),
                          const Divider(height: 1),
                          RadioListTile<TimeFilter>(
                            value: TimeFilter.w1,
                            groupValue: tempTimeFilter,
                            title: const Text("1 hafta"),
                            onChanged: (v) =>
                                setDrawerState(() => tempTimeFilter = v!),
                            activeColor: _primary,
                          ),
                          const Divider(height: 1),
                          RadioListTile<TimeFilter>(
                            value: TimeFilter.m1,
                            groupValue: tempTimeFilter,
                            title: const Text("1 ay"),
                            onChanged: (v) =>
                                setDrawerState(() => tempTimeFilter = v!),
                            activeColor: _primary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ✅ Şehir
                    const Text("Şehir",
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xffe6e6e6)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          TextField(
                            onChanged: (v) =>
                                setDrawerState(() => citySearch = v),
                            decoration: InputDecoration(
                              hintText: "Şehir ara (örn. İstanbul)",
                              prefixIcon: const Icon(Icons.search),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          DropdownButtonFormField<String?>(
                            value: tempCity,
                            isExpanded: true,
                            decoration: InputDecoration(
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            hint: const Text("Şehir seç"),
                            items: [
                              const DropdownMenuItem<String?>(
                                value: null,
                                child: Text("Tümü"),
                              ),
                              ...cityList.map(
                                    (c) => DropdownMenuItem<String?>(
                                  value: c,
                                  child: Text(c),
                                ),
                              ),
                            ],
                            onChanged: (v) => setDrawerState(() => tempCity = v),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ✅ Sırala
                    const Text("Sırala",
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xffe6e6e6)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<ProductSortType>(
                            value: ProductSortType.recommended,
                            groupValue: tempSort,
                            title: const Text("Önerilen"),
                            onChanged: (v) =>
                                setDrawerState(() => tempSort = v!),
                            activeColor: _primary,
                          ),
                          const Divider(height: 1),
                          RadioListTile<ProductSortType>(
                            value: ProductSortType.priceLow,
                            groupValue: tempSort,
                            title: const Text("Fiyat (Artan)"),
                            onChanged: (v) =>
                                setDrawerState(() => tempSort = v!),
                            activeColor: _primary,
                          ),
                          const Divider(height: 1),
                          RadioListTile<ProductSortType>(
                            value: ProductSortType.priceHigh,
                            groupValue: tempSort,
                            title: const Text("Fiyat (Azalan)"),
                            onChanged: (v) =>
                                setDrawerState(() => tempSort = v!),
                            activeColor: _primary,
                          ),
                          const Divider(height: 1),
                          RadioListTile<ProductSortType>(
                            value: ProductSortType.newest,
                            groupValue: tempSort,
                            title: const Text("En Yeni"),
                            onChanged: (v) =>
                                setDrawerState(() => tempSort = v!),
                            activeColor: _primary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ✅ Fiyat aralığı
                    const Text("Fiyat Aralığı",
                        style: TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xffe6e6e6)),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${_formatPrice(tempPriceRange.start.round())} - ${_formatPrice(tempPriceRange.end.round())}",
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          RangeSlider(
                            values: tempPriceRange,
                            min: 0,
                            max: 3000000,
                            divisions: 60,
                            activeColor: _primary,
                            labels: RangeLabels(
                              _formatPrice(tempPriceRange.start.round()),
                              _formatPrice(tempPriceRange.end.round()),
                            ),
                            onChanged: (v) =>
                                setDrawerState(() => tempPriceRange = v),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _clearFilters,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _primary,
                              side: BorderSide(color: _primary.withOpacity(.35)),
                            ),
                            child: const Text("Temizle"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _applyFilters,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xff2e74ff),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Uygula"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),

      onDrawerChanged: (isOpened) {
        if (isOpened) setState(_syncTempWithActive);
      },

      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        titleSpacing: 8,

        // ✅ Arama kutusunun SOLUNA 3 nokta
        title: Row(
          children: [
            IconButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(Icons.more_vert),
              tooltip: "Filtreler",
            ),
            Expanded(
              child: Container(
                height: 42,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: TextField(
                  onChanged: (v) => setState(() => q = v),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: "Ürün ara (çadır, tulum, ocak...)",
                    hintStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.search, color: Colors.white),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: "Yenile",
          ),
          const SizedBox(width: 6),
        ],
      ),

      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: _accent,
        foregroundColor: Colors.black,
        onPressed: () async {
          final refreshed = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const ProductCreatePage()),
          );
          if (refreshed == true) _load();
        },
        icon: const Icon(Icons.add),
        label: const Text("İlan Ver", style: TextStyle(fontWeight: FontWeight.w800)),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(12),
        children: [
          // ✅ aktif filtre chipleri (premium görünür)
          if (activeChips.isNotEmpty) ...[
            Wrap(spacing: 10, runSpacing: 10, children: activeChips),
            const SizedBox(height: 12),
          ],

          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: cats.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final c = cats[i];
                final active = selectedCategoryId == c.id;
                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    setState(() {
                      selectedCategoryId =
                      (selectedCategoryId == c.id) ? null : c.id;
                    });
                  },
                  child: Opacity(
                    opacity: (selectedCategoryId == null || active) ? 1 : 0.55,
                    child: _CategoryPill(
                      title: c.title,
                      icon: c.icon,
                      primary: _primary,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // ✅ kategori bölümleri (mevcut yapın bozulmadan)
          ...cats.map((cat) {
            // kategori filtresi seçildiyse diğerlerini gösterme
            if (selectedCategoryId != null && selectedCategoryId != cat.id) {
              return const SizedBox.shrink();
            }

            final inCat = all.where((p) => p.categoryId == cat.id).toList();
            final list = _applyCommon(inCat);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      cat.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const Spacer(),
                    Text("${list.length} ilan",
                        style: const TextStyle(color: Colors.grey)),
                  ],
                ),
                const SizedBox(height: 10),

                if (list.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xffe6e6e6)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Bu kategoride şu an ilan yok.",
                            style: TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    height: 245,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, i) {
                        final p = list[i];
                        final img = p.images.isNotEmpty ? p.images.first : null;

                        return SizedBox(
                          width: 185,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailPage(
                                    product: p,
                                    favoritesService: widget.favoritesService,
                                  ),
                                ),
                              );
                            },
                            child: Card(
                              elevation: 1,
                              color: _card,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              clipBehavior: Clip.antiAlias,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Stack(
                                      children: [
                                        Positioned.fill(
                                          child: img == null
                                              ? Container(
                                            color: Colors.grey.shade200,
                                            alignment: Alignment.center,
                                            child: const Icon(Icons.image_outlined),
                                          )
                                              : _smartImage(img),
                                        ),
                                        Positioned(
                                          top: 10,
                                          right: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.black54,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              _formatPrice(p.price),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (p.isUrgent)
                                          Positioned(
                                            bottom: 10,
                                            left: 10,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.red.withOpacity(0.85),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Text(
                                                "ACİL",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ),
                                        if (p.isPriceDropped)
                                          Positioned(
                                            bottom: 10,
                                            right: 10,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.green.withOpacity(0.85),
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: const Text(
                                                "DÜŞTÜ",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ),
                                          ),
                                        Positioned(
                                          top: 10,
                                          left: 10,
                                          child: ValueListenableBuilder<Set<String>>(
                                            valueListenable: widget.favoritesService.favoriteIds,
                                            builder: (_, favs, __) {
                                              final isFav = favs.contains(p.id);
                                              return InkWell(
                                                onTap: () => widget.favoritesService
                                                    .toggleFavorite(p.id),
                                                child: Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: Colors.white.withOpacity(0.95),
                                                    shape: BoxShape.circle,
                                                  ),
                                                  child: Icon(
                                                    isFav
                                                        ? Icons.favorite
                                                        : Icons.favorite_border,
                                                    color: isFav ? Colors.red : Colors.black87,
                                                    size: 18,
                                                  ),
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          p.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          p.city,
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        SizedBox(
                                          width: double.infinity,
                                          child: OutlinedButton.icon(
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: _primary,
                                              side: BorderSide(
                                                color: _primary.withOpacity(0.45),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                            onPressed: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (_) => ProductChatPage(product: p),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.chat_bubble_outline, size: 18),
                                            label: const Text(
                                              "Mesaj At",
                                              style: TextStyle(fontWeight: FontWeight.w800),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 4),
              ],
            );
          }).toList(),

          const SizedBox(height: 18),
        ],
      ),
    );
  }

  // ✅ URL ise network, değilse asset
  Widget _smartImage(String path) {
    final p = path.trim();
    final isNetwork = p.startsWith('http://') || p.startsWith('https://');

    if (isNetwork) {
      return Image.network(
        p,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Image.asset(
          "assets/images/placeholder.png",
          fit: BoxFit.cover,
        ),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Container(
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        },
      );
    }

    return Image.asset(
      p,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        "assets/images/placeholder.png",
        fit: BoxFit.cover,
      ),
    );
  }
}

class _Cat {
  final String title;
  final String id;
  final IconData icon;
  const _Cat(this.title, this.id, this.icon);
}

class _ChipPill extends StatelessWidget {
  final String text;
  final VoidCallback onClear;
  final Color color;

  const _ChipPill({
    required this.text,
    required this.onClear,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onClear,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withOpacity(.20)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.close, size: 16, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color primary;

  const _CategoryPill({
    required this.title,
    required this.icon,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xffe6e6e6)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}
