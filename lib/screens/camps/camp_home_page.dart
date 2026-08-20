import 'package:flutter/material.dart';
import '../../services/auth_guard.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/filter_models.dart';
import '../../models/camp_model.dart';
import '../../services/camp_service.dart';
import '../../widgets/camp_card_small.dart';
import 'camp_detail_page.dart';
import 'suggest_camp_page.dart'; // ✅ EKLE (dosya yolunu kendi projene göre düzelt)

class CampHomePage extends StatefulWidget {
  final ListingFilter filter;

  const CampHomePage({
    super.key,
    required this.filter,
  });

  @override
  State<CampHomePage> createState() => _CampHomePageState();
}

class _CampHomePageState extends State<CampHomePage> {
  final _whereCtrl = TextEditingController();
  DateTimeRange? _range;
  int _guests = 2;

  final List<String> _cities = const [
    'Hepsi','Adana','Adıyaman','Afyonkarahisar','Ağrı','Aksaray','Amasya','Ankara','Antalya','Ardahan','Artvin',
    'Aydın','Balıkesir','Bartın','Batman','Bayburt','Bilecik','Bingöl','Bitlis','Bolu','Burdur',
    'Bursa','Çanakkale','Çankırı','Çorum','Denizli','Diyarbakır','Düzce','Edirne','Elazığ','Erzincan',
    'Erzurum','Eskişehir','Gaziantep','Giresun','Gümüşhane','Hakkâri','Hatay','Iğdır','Isparta','İstanbul',
    'İzmir','Kahramanmaraş','Karabük','Karaman','Kars','Kastamonu','Kayseri','Kilis','Kırıkkale','Kırklareli',
    'Kırşehir','Kocaeli','Konya','Kütahya','Malatya','Manisa','Mardin','Mersin','Muğla','Muş',
    'Nevşehir','Niğde','Ordu','Osmaniye','Rize','Sakarya','Samsun','Siirt','Sinop','Sivas',
    'Şanlıurfa','Şırnak','Tekirdağ','Tokat','Trabzon','Tunceli','Uşak','Van','Yalova','Yozgat','Zonguldak'
  ];
  RealtimeChannel? _campChannel;
  String _selectedCity = 'Hepsi';

  final _service = CampService();

  List<CampModel> _all = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _range = widget.filter.dateRange;
    _guests = widget.filter.guests ?? 2;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadByCity();
    });
  }
  void _listenRealtime() {
    _campChannel = Supabase.instance.client
        .channel('camps-realtime')
        .onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'camps',
      callback: (payload) async {
        debugPrint('🔄 camps realtime tetiklendi');
        await _loadByCity();
        _listenRealtime();
      },
    )
        .subscribe();
  }
  Future<void> _loadByCity() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final data = (_selectedCity == 'Hepsi')
          ? await _service.getPopularCamps()
          : await _service.getCampsByCity(_selectedCity);

      if (!mounted) return;
      setState(() => _all = data);

      debugPrint('✅ load($_selectedCity) -> ${data.length} sonuç');
    } catch (e, st) {
      debugPrint('❌ load ERROR: $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() => _all = []);
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  void didUpdateWidget(covariant CampHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filter != widget.filter) {
      setState(() {
        _range = widget.filter.dateRange;
        _guests = widget.filter.guests ?? 2;
      });
    }
  }

  List<CampModel> get _filtered {
    var x = List<CampModel>.from(_all);
    final f = widget.filter;

    if (f.categoryId != null) {
      x = x.where((c) => c.categoryId == f.categoryId).toList();
    }


    if (f.minRating != null) {
      x = x.where((c) => c.rating >= f.minRating!).toList();
    }

    switch (f.sort) {
      case SortType.priceLow:
        x.sort((a, b) => a.pricePerNight.compareTo(b.pricePerNight));
        break;
      case SortType.priceHigh:
        x.sort((a, b) => b.pricePerNight.compareTo(a.pricePerNight));
        break;
      case SortType.ratingHigh:
        x.sort((a, b) => b.rating.compareTo(a.rating));
        break;
      default:
        break;
    }

    return x;
  }

  List<CampModel> get _popular {
    final x = List<CampModel>.from(_filtered);
    x.sort((a, b) => b.rating.compareTo(a.rating));
    return x.take(8).toList();
  }

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) setState(() => _range = picked);
  }

  @override
  void dispose() {
    _whereCtrl.dispose();
    _campChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rangeText = _range == null
        ? 'Tarih seç'
        : '${_range!.start.day}.${_range!.start.month} - ${_range!.end.day}.${_range!.end.month}';

    final allList = _filtered;
    final popList = _popular;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F5),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (!await AuthGuard.requireAuth(context)) return;
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SuggestCampPage()),
          );
          // await _loadByCity();
        },
        icon: const Icon(Icons.add_location_alt_outlined),
        label: const Text("Kamp Öner"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _heroHeader(),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: _elevatedPanel(
                child: Column(
                  children: [
                    DropdownButtonFormField<String>(
                      value: _selectedCity,
                      decoration: InputDecoration(
                        labelText: 'Şehir',
                        prefixIcon: const Icon(Icons.location_city),
                        filled: true,
                        fillColor: const Color(0xfff6f7fb),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      items: _cities
                          .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) async {
                        if (v == null) return;
                        setState(() => _selectedCity = v);
                        await _loadByCity();
                      },
                    ),
                    const SizedBox(height: 10),

                    // ✅ SADECE "Nereye?" KALDI (Tarih kaldırıldı)
                    TextField(
                      controller: _whereCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nereye?',
                        hintText: 'Şehir / bölge / kamp adı',
                        prefixIcon: const Icon(Icons.place_outlined),
                        filled: true,
                        fillColor: const Color(0xfff6f7fb),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),

                    const SizedBox(height: 10),

                    // ✅ KİŞİ SEÇME KALDIRILDI (sadece Ara butonu bırakıldı)
                    _elevatedPanel(
                      padding: const EdgeInsets.all(12),
                      radius: 14,
                      bg: const Color(0xfff6f7fb),
                      child: Row(
                        children: [
                          const Icon(Icons.search, color: Colors.black54),
                          const SizedBox(width: 10),
                          const Text("Ara", style: TextStyle(fontWeight: FontWeight.w800)),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: () {},
                            icon: const Icon(Icons.search, size: 18),
                            label: const Text('Ara'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(
                    title: 'Popüler Kamp Alanları',
                    subtitle: _loading ? 'yükleniyor…' : '${popList.length} öneri',
                  ),
                  const SizedBox(height: 10),

                  SizedBox(
                    height: 176,
                    child: _loading
                        ? const Center(child: CircularProgressIndicator())
                        : (popList.isEmpty
                        ? const Center(child: Text('Bu şehirde popüler kamp yok.'))
                        : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: popList.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (_, i) {
                        final camp = popList[i];
                        return SizedBox(
                          width: 180,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => CampDetailPage(camp: camp)),
                            ),
                            child: _elevatedPanel(
                              radius: 14,
                              padding: EdgeInsets.zero,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: CampCardSmall(camp: camp),
                              ),
                            ),
                          ),
                        );
                      },
                    )),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle(
                    title: 'Tüm Kamp Alanları',
                    subtitle: _loading ? 'yükleniyor…' : '${allList.length} sonuç',
                  ),
                  const SizedBox(height: 10),

                  if (_loading)
                    const Center(child: CircularProgressIndicator())
                  else if (allList.isEmpty)
                    const Center(child: Text('Bu şehir için kamp yok.'))
                  else
                    LayoutBuilder(
                      builder: (context, c) {
                        final w = c.maxWidth;
                        final cross = w >= 1100 ? 4 : (w >= 760 ? 3 : 2);

                        return GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: allList.length,
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cross,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: cross >= 3 ? 0.82 : 0.78,
                          ),
                          itemBuilder: (_, i) {
                            final camp = allList[i];
                            return InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => CampDetailPage(camp: camp)),
                              ),
                              child: _elevatedPanel(
                                radius: 14,
                                padding: EdgeInsets.zero,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: CampCardSmall(camp: camp),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroHeader() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=1600&q=80',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(color: Colors.black12),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.10),
                  Colors.black.withOpacity(0.55),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Kamp Alanları",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  "Şehre göre keşfet, filtrele ve favorine ekle.",
                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle({required String title, required String subtitle}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(color: Colors.black54, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _elevatedPanel({
    required Widget child,
    EdgeInsets padding = const EdgeInsets.all(14),
    double radius = 18,
    Color bg = Colors.white,
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: Colors.black.withOpacity(.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
