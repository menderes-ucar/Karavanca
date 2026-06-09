import 'package:flutter/material.dart';
import '../../models/caravan_model.dart';
import '../../services/caravan_favorites_service.dart';
import '../../services/caravan_service.dart';
import 'caravan_create_page.dart';
import 'caravan_detail_page.dart';

enum CaravanSortType { recommended, priceLow, priceHigh, newest }

class CaravanListPage extends StatefulWidget {
  final CaravanFavoritesService favoritesService;

  const CaravanListPage({
    super.key,
    required this.favoritesService,
  });

  @override
  State<CaravanListPage> createState() => _CaravanListPageState();
}

class _CaravanListPageState extends State<CaravanListPage> {
  final CaravanService service = CaravanService();

  bool loading = true;
  List<CaravanModel> listings = [];

  String searchText = "";

  // Aktif filtre
  String? selectedCategoryId;
  RangeValues priceRange = const RangeValues(0, 3000000);

  // Yeni aktif filtreler
  bool isUrgent = false;
  bool isPriceDropped = false;
  String? timeFilter; // "48h" | "1w" | "1m"

  // Şehir (aktif)
  String? selectedCity;

  // ✅ Şehir arama text'i (drawer)
  String citySearch = "";

  // ✅ 81 il (sabit)
  static const List<String> trCities = [
    "Adana","Adıyaman","Afyonkarahisar","Ağrı","Amasya","Ankara","Antalya","Artvin","Aydın","Balıkesir",
    "Bilecik","Bingöl","Bitlis","Bolu","Burdur","Bursa","Çanakkale","Çankırı","Çorum","Denizli",
    "Diyarbakır","Edirne","Elazığ","Erzincan","Erzurum","Eskişehir","Gaziantep","Giresun","Gümüşhane","Hakkari",
    "Hatay","Isparta","Mersin","İstanbul","İzmir","Kars","Kastamonu","Kayseri","Kırklareli","Kırşehir",
    "Kocaeli","Konya","Kütahya","Malatya","Manisa","Kahramanmaraş","Mardin","Muğla","Muş","Nevşehir",
    "Niğde","Ordu","Rize","Sakarya","Samsun","Siirt","Sinop","Sivas","Tekirdağ","Tokat",
    "Trabzon","Tunceli","Şanlıurfa","Uşak","Van","Yozgat","Zonguldak","Aksaray","Bayburt","Karaman",
    "Kırıkkale","Batman","Şırnak","Bartın","Ardahan","Iğdır","Yalova","Karabük","Kilis","Osmaniye",
    "Düzce"
  ];

  // SIRALA (aktif)
  CaravanSortType sort = CaravanSortType.recommended;

  // Drawer geçici filtre
  String? tempCategoryId;
  RangeValues tempPriceRange = const RangeValues(0, 3000000);

  // Drawer geçici filtreler
  bool tempUrgent = false;
  bool tempPriceDropped = false;
  String? tempTimeFilter;

  // Şehir (drawer)
  String? tempCity;

  // SIRALA (drawer)
  CaravanSortType tempSort = CaravanSortType.recommended;

  final List<_CategoryItem> categories = const [
    _CategoryItem(title: "Moto Karavan", id: "car_motor"),
    _CategoryItem(title: "Çekme Karavan", id: "car_tow"),
    _CategoryItem(title: "Offroad Karavan", id: "car_offroad"),
    _CategoryItem(title: "Alkoven Karavan", id: "car_alkoven"),
    _CategoryItem(title: "Mini Camper Karavan", id: "car_mini"),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);

    // ✅ sadece active ilanlar
    final data = await service.getActiveCaravans();

    if (!mounted) return;
    setState(() {
      listings = data;
      loading = false;
    });
  }

  void _syncTempWithActive() {
    tempCategoryId = selectedCategoryId;
    tempPriceRange = priceRange;

    tempUrgent = isUrgent;
    tempPriceDropped = isPriceDropped;
    tempTimeFilter = timeFilter;

    tempCity = selectedCity;

    tempSort = sort;

    citySearch = ""; // ✅ drawer açılınca aramayı temizle
  }

  void _applyFilters() {
    setState(() {
      selectedCategoryId = tempCategoryId;
      priceRange = tempPriceRange;

      isUrgent = tempUrgent;
      isPriceDropped = tempPriceDropped;
      timeFilter = tempTimeFilter;

      selectedCity = tempCity;

      sort = tempSort;
    });
    Navigator.pop(context);
  }

  void _clearFilters() {
    setState(() {
      selectedCategoryId = null;
      priceRange = const RangeValues(0, 3000000);
      tempCategoryId = null;
      tempPriceRange = const RangeValues(0, 3000000);

      isUrgent = false;
      isPriceDropped = false;
      timeFilter = null;

      selectedCity = null;
      tempCity = null;

      tempUrgent = false;
      tempPriceDropped = false;
      tempTimeFilter = null;

      sort = CaravanSortType.recommended;
      tempSort = CaravanSortType.recommended;

      citySearch = "";
    });
    Navigator.pop(context);
  }

  String _timeLabel(String? v) {
    switch (v) {
      case "48h":
        return "Son 48 saat";
      case "1w":
        return "1 hafta";
      case "1m":
        return "1 ay";
      default:
        return "Tümü";
    }
  }

  String _sortLabel(CaravanSortType s) {
    switch (s) {
      case CaravanSortType.priceLow:
        return "Fiyat (Artan)";
      case CaravanSortType.priceHigh:
        return "Fiyat (Azalan)";
      case CaravanSortType.newest:
        return "En Yeni";
      case CaravanSortType.recommended:
      default:
        return "Önerilen";
    }
  }

  List<CaravanModel> get filtered {
    final q = searchText.trim().toLowerCase();
    final now = DateTime.now();

    Duration? timeWindow;
    if (timeFilter == "48h") timeWindow = const Duration(hours: 48);
    if (timeFilter == "1w") timeWindow = const Duration(days: 7);
    if (timeFilter == "1m") timeWindow = const Duration(days: 30);

    var x = listings.where((item) {
      final okSearch = q.isEmpty
          ? true
          : item.title.toLowerCase().contains(q) ||
          item.city.toLowerCase().contains(q);

      final okCategory =
      selectedCategoryId == null ? true : item.categoryId == selectedCategoryId;

      final okCity = selectedCity == null ? true : item.city == selectedCity;

      final okPrice = item.price >= priceRange.start && item.price <= priceRange.end;

      final okUrgent = !isUrgent ? true : item.isUrgent;
      final okDropped = !isPriceDropped ? true : item.isPriceDropped;

      final okTime =
      timeWindow == null ? true : now.difference(item.createdAt) <= timeWindow;

      return okSearch &&
          okCategory &&
          okCity &&
          okPrice &&
          okUrgent &&
          okDropped &&
          okTime;
    }).toList();

    switch (sort) {
      case CaravanSortType.priceLow:
        x.sort((a, b) => a.price.compareTo(b.price));
        break;
      case CaravanSortType.priceHigh:
        x.sort((a, b) => b.price.compareTo(a.price));
        break;
      case CaravanSortType.newest:
        x.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case CaravanSortType.recommended:
        break;
    }

    return x;
  }

  String formatPrice(int price) {
    final s = price.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buffer.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buffer.write('.');
    }
    return "${buffer.toString()} ₺";
  }

  @override
  Widget build(BuildContext context) {
    final activeChips = <Widget>[];

    if (isUrgent) {
      activeChips.add(_Chip(
        text: "Acil Acil",
        onClear: () => setState(() => isUrgent = false),
      ));
    }
    if (isPriceDropped) {
      activeChips.add(_Chip(
        text: "Fiyatı Düşenler",
        onClear: () => setState(() => isPriceDropped = false),
      ));
    }
    if (timeFilter != null) {
      activeChips.add(_Chip(
        text: _timeLabel(timeFilter),
        onClear: () => setState(() => timeFilter = null),
      ));
    }
    if (selectedCity != null) {
      activeChips.add(_Chip(
        text: selectedCity!,
        onClear: () => setState(() => selectedCity = null),
      ));
    }
    if (sort != CaravanSortType.recommended) {
      activeChips.add(_Chip(
        text: _sortLabel(sort),
        onClear: () => setState(() => sort = CaravanSortType.recommended),
      ));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      drawer: Drawer(
        child: SafeArea(
          child: StatefulBuilder(
            builder: (context, setDrawerState) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: ListView(
                  children: [
                    const Text("Filtreler",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    const Text("Karavan Çeşitleri",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),

                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        border: Border.all(color: Colors.white.withOpacity(0.18)),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String?>(
                            value: null,
                            groupValue: tempCategoryId,
                            title: const Text("Tümü"),
                            onChanged: (v) => setDrawerState(() => tempCategoryId = v),
                          ),
                          const Divider(height: 1),
                          ...categories.map((c) {
                            return RadioListTile<String?>(
                              value: c.id,
                              groupValue: tempCategoryId,
                              title: Text(c.title),
                              onChanged: (v) => setDrawerState(() => tempCategoryId = v),
                            );
                          }).toList(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Text("Hızlı Filtreler",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xffe6e6e6)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          SwitchListTile(
                            value: tempUrgent,
                            title: const Text("Acil Acil"),
                            onChanged: (v) => setDrawerState(() => tempUrgent = v),
                          ),
                          const Divider(height: 1),
                          SwitchListTile(
                            value: tempPriceDropped,
                            title: const Text("Fiyatı Düşenler"),
                            onChanged: (v) =>
                                setDrawerState(() => tempPriceDropped = v),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Text("Zaman", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xffe6e6e6)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<String?>(
                            value: null,
                            groupValue: tempTimeFilter,
                            title: const Text("Tümü"),
                            onChanged: (v) => setDrawerState(() => tempTimeFilter = v),
                          ),
                          const Divider(height: 1),
                          RadioListTile<String?>(
                            value: "48h",
                            groupValue: tempTimeFilter,
                            title: const Text("Son 48 saat"),
                            onChanged: (v) => setDrawerState(() => tempTimeFilter = v),
                          ),
                          const Divider(height: 1),
                          RadioListTile<String?>(
                            value: "1w",
                            groupValue: tempTimeFilter,
                            title: const Text("1 hafta"),
                            onChanged: (v) => setDrawerState(() => tempTimeFilter = v),
                          ),
                          const Divider(height: 1),
                          RadioListTile<String?>(
                            value: "1m",
                            groupValue: tempTimeFilter,
                            title: const Text("1 ay"),
                            onChanged: (v) => setDrawerState(() => tempTimeFilter = v),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Text("Şehir", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xffe6e6e6)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            onChanged: (v) => setDrawerState(() => citySearch = v),
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
                          Builder(builder: (_) {
                            final q = citySearch.trim().toLowerCase();
                            final list = q.isEmpty
                                ? trCities
                                : trCities
                                .where((c) => c.toLowerCase().contains(q))
                                .toList();

                            return DropdownButtonFormField<String?>(
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
                                ...list.map(
                                      (c) => DropdownMenuItem<String?>(
                                    value: c,
                                    child: Text(c),
                                  ),
                                ),
                              ],
                              onChanged: (v) => setDrawerState(() => tempCity = v),
                            );
                          }),
                          if (tempCity != null) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Seçili: $tempCity",
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => setDrawerState(() => tempCity = null),
                                  child: const Text("Temizle"),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Text("Sırala", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xffe6e6e6)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<CaravanSortType>(
                            value: CaravanSortType.recommended,
                            groupValue: tempSort,
                            title: const Text("Önerilen"),
                            onChanged: (v) => setDrawerState(() => tempSort = v!),
                          ),
                          const Divider(height: 1),
                          RadioListTile<CaravanSortType>(
                            value: CaravanSortType.priceLow,
                            groupValue: tempSort,
                            title: const Text("Fiyat (Artan)"),
                            onChanged: (v) => setDrawerState(() => tempSort = v!),
                          ),
                          const Divider(height: 1),
                          RadioListTile<CaravanSortType>(
                            value: CaravanSortType.priceHigh,
                            groupValue: tempSort,
                            title: const Text("Fiyat (Azalan)"),
                            onChanged: (v) => setDrawerState(() => tempSort = v!),
                          ),
                          const Divider(height: 1),
                          RadioListTile<CaravanSortType>(
                            value: CaravanSortType.newest,
                            groupValue: tempSort,
                            title: const Text("En Yeni"),
                            onChanged: (v) => setDrawerState(() => tempSort = v!),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),
                    const Text("Fiyat Aralığı",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xffe6e6e6)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${formatPrice(tempPriceRange.start.round())} - ${formatPrice(tempPriceRange.end.round())}",
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          RangeSlider(
                            values: tempPriceRange,
                            min: 0,
                            max: 3000000,
                            divisions: 60,
                            labels: RangeLabels(
                              formatPrice(tempPriceRange.start.round()),
                              formatPrice(tempPriceRange.end.round()),
                            ),
                            onChanged: (v) => setDrawerState(() => tempPriceRange = v),
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
        backgroundColor: const  Color(0xFF2E7D32),
        elevation: 0,
        titleSpacing: 12,
        title: Container(
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: const Color(0xff3b4b63),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            onChanged: (v) => setState(() => searchText = v),
            decoration: const InputDecoration(
              hintText: "Kelime, ilan no veya mağaza adı ile ara",
              hintStyle: TextStyle(color: Colors.white70, fontSize: 13),
              border: InputBorder.none,
              suffixIcon: Icon(Icons.search, color: Colors.white),
            ),
          ),
        ),
        actions: [
          IconButton(onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Builder(
        builder: (context) {
          final mainList = filtered;

          return ListView(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
            children: [
              const Text(
                "Son İlanlar",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              if (activeChips.isNotEmpty) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: activeChips,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black12),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 18,
                      color: Color(0x14000000),
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: mainList.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      "İlan bulunamadı",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
                    : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mainList.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (context, index) {
                    final item = mainList[index];
                    return _ListingTile(
                      item: item,
                      favoritesService: widget.favoritesService,
                      formatPrice: formatPrice,
                    );
                  },
                ),
              ),

              const SizedBox(height: 18),

              const Text(
                "İlanlar",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black12),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 18,
                      color: Color(0x14000000),
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: mainList.isEmpty
                    ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 28),
                  child: Center(
                    child: Text(
                      "İlan bulunamadı",
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                )
                    : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: mainList.length,
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (context, index) {
                    final item = mainList[index];
                    return _ListingTile(
                      item: item,
                      favoritesService: widget.favoritesService,
                      formatPrice: formatPrice,
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final res = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const CaravanCreatePage()),
          );
          if (res == true) {
            await _load();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text("İlan Ver"),
      ),
    );
  }
}

class _CategoryItem {
  final String title;
  final String id;
  const _CategoryItem({required this.title, required this.id});
}

class _Chip extends StatelessWidget {
  final String text;
  final VoidCallback onClear;

  const _Chip({required this.text, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: onClear,
            child: const Icon(Icons.close, size: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _ListingTile extends StatelessWidget {
  final CaravanModel item;
  final CaravanFavoritesService favoritesService;
  final String Function(int) formatPrice;

  const _ListingTile({
    required this.item,
    required this.favoritesService,
    required this.formatPrice,
  });

  bool _isHttp(String s) => s.startsWith('http://') || s.startsWith('https://');

  @override
  Widget build(BuildContext context) {
    final image = item.images.isNotEmpty ? item.images.first.trim() : null;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CaravanDetailPage(
              listing: item,
              favoritesService: favoritesService,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
          boxShadow: const [
            BoxShadow(
              blurRadius: 14,
              color: Color(0x12000000),
              offset: Offset(0, 8),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: (image == null || image.isEmpty)
                        ? Container(
                      color: Colors.grey.shade200,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_outlined),
                    )
                        : (_isHttp(image)
                        ? Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        "assets/images/placeholder.png",
                        fit: BoxFit.cover,
                      ),
                    )
                        : Image.asset(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        "assets/images/placeholder.png",
                        fit: BoxFit.cover,
                      ),
                    )),
                  ),

                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        formatPrice(item.price),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    top: 8,
                    left: 8,
                    child: ValueListenableBuilder<Set<String>>(
                      valueListenable: favoritesService.favoriteIds,
                      builder: (_, favs, __) {
                        final isFav = favs.contains(item.id);
                        return InkWell(
                          onTap: () => favoritesService.toggleFavorite(item.id),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.95),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: Colors.black12),
                            ),
                            child: Icon(
                              isFav ? Icons.favorite : Icons.favorite_border,
                              color: isFav ? Colors.red : Colors.black87,
                              size: 18,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  if (item.isUrgent)
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          "ACİL",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: _StatusBadge(status: item.status),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.city,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();

    String text;
    Color bg;

    if (s == 'active') {
      text = "YAYINDA";
      bg = Colors.green.withOpacity(0.85);
    } else if (s == 'passive') {
      text = "PASİF";
      bg = Colors.grey.withOpacity(0.85);
    } else {
      text = "ONAY BEKLİYOR";
      bg = Colors.orange.withOpacity(0.90);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}