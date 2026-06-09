import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/filter_models.dart';
import '../../services/category_service.dart';

class FilterSheet extends StatefulWidget {
  final ModuleType module;
  final ListingFilter initial;

  const FilterSheet({
    super.key,
    required this.module,
    required this.initial,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  final _catService = CategoryService();

  List<CategoryModel> _cats = [];
  String? _categoryId;

  RangeValues _price = const RangeValues(0, 5000);
  double _minRating = 0;
  SortType _sort = SortType.recommended;

  // CAMP
  DateTimeRange? _range;
  int _guests = 2;

  // CARAVAN
  RangeValues _year = const RangeValues(2005, 2026);

  // PRODUCT
  bool? _onlyNew; // null=hepsi, true=sıfır, false=2.el

  @override
  void initState() {
    super.initState();

    // ORTAK
    _categoryId = widget.initial.categoryId;
    _minRating = widget.initial.minRating ?? 0;
    _sort = widget.initial.sort;

    final minP = (widget.initial.minPrice ?? 0).toDouble();
    final maxP = (widget.initial.maxPrice ?? 5000).toDouble();
    _price = RangeValues(minP, maxP);

    // CAMP
    _range = widget.initial.dateRange;
    _guests = widget.initial.guests ?? 2;

    // CARAVAN
    final minY = (widget.initial.minYear ?? 2005).toDouble();
    final maxY = (widget.initial.maxYear ?? DateTime.now().year).toDouble();
    _year = RangeValues(minY, maxY);

    // PRODUCT
    _onlyNew = widget.initial.onlyNew;

    _loadCats();
  }

  Future<void> _loadCats() async {
    final data = await _catService.getCategories(widget.module);
    if (!mounted) return;
    setState(() => _cats = data);
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

  void _reset() {
    setState(() {
      _categoryId = null;
      _price = const RangeValues(0, 5000);
      _minRating = 0;
      _sort = SortType.recommended;

      _range = null;
      _guests = 2;

      _year = RangeValues(2005, DateTime.now().year.toDouble());

      _onlyNew = null;
    });
  }

  void _apply() {
    final isCamp = widget.module == ModuleType.camp;
    final isCaravan = widget.module == ModuleType.caravan;
    final isProduct = widget.module == ModuleType.product;

    Navigator.pop(
      context,
      ListingFilter(
        // ortak
        categoryId: _categoryId,
        minPrice: _price.start.toInt(),
        maxPrice: _price.end.toInt(),
        minRating: _minRating <= 0 ? null : _minRating,
        sort: _sort,

        // camp
        dateRange: isCamp ? _range : null,
        guests: isCamp ? _guests : null,

        // caravan
        minYear: isCaravan ? _year.start.toInt() : null,
        maxYear: isCaravan ? _year.end.toInt() : null,

        // product
        onlyNew: isProduct ? _onlyNew : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCamp = widget.module == ModuleType.camp;
    final isCaravan = widget.module == ModuleType.caravan;
    final isProduct = widget.module == ModuleType.product;

    final rangeText = _range == null
        ? 'Seçilmedi'
        : '${_range!.start.day}.${_range!.start.month} - ${_range!.end.day}.${_range!.end.month}';

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 10,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // başlık + kapat
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Filtrele',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Kategori
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Kategori',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (_cats.isEmpty)
                const LinearProgressIndicator()
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Tümü'),
                      selected: _categoryId == null,
                      onSelected: (_) => setState(() => _categoryId = null),
                    ),
                    ..._cats.map(
                          (c) => ChoiceChip(
                        label: Text(c.title),
                        selected: _categoryId == c.id,
                        onSelected: (_) => setState(() => _categoryId = c.id),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 16),

              // CAMP: tarih + kişi
              if (isCamp) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Tarih',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.date_range_outlined),
                  title: Text(rangeText),
                  trailing: TextButton(
                    onPressed: _pickRange,
                    child: const Text('Seç'),
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.people_outline),
                  title: const Text('Kişi'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => setState(() => _guests = (_guests - 1).clamp(1, 20)),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text(
                        '$_guests',
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      IconButton(
                        onPressed: () => setState(() => _guests = (_guests + 1).clamp(1, 20)),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
              ],

              // CARAVAN: araç yılı
              if (isCaravan) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Araç Yılı',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                RangeSlider(
                  values: _year,
                  min: 1990,
                  max: DateTime.now().year.toDouble(),
                  divisions: (DateTime.now().year - 1990),
                  labels: RangeLabels('${_year.start.toInt()}', '${_year.end.toInt()}'),
                  onChanged: (v) => setState(() => _year = v),
                ),
                Row(
                  children: [
                    Text('Min: ${_year.start.toInt()}'),
                    const Spacer(),
                    Text('Max: ${_year.end.toInt()}'),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // PRODUCT: durum
              if (isProduct) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Durum',
                    style: TextStyle(
                      color: Colors.black.withOpacity(0.7),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Hepsi'),
                      selected: _onlyNew == null,
                      onSelected: (_) => setState(() => _onlyNew = null),
                    ),
                    ChoiceChip(
                      label: const Text('Sıfır'),
                      selected: _onlyNew == true,
                      onSelected: (_) => setState(() => _onlyNew = true),
                    ),
                    ChoiceChip(
                      label: const Text('2. El'),
                      selected: _onlyNew == false,
                      onSelected: (_) => setState(() => _onlyNew = false),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],

              // Fiyat aralığı
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Fiyat',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              RangeSlider(
                values: _price,
                min: 0,
                max: 20000,
                divisions: 200,
                labels: RangeLabels('${_price.start.toInt()}₺', '${_price.end.toInt()}₺'),
                onChanged: (v) => setState(() => _price = v),
              ),
              Row(
                children: [
                  Text('Min: ${_price.start.toInt()}₺'),
                  const Spacer(),
                  Text('Max: ${_price.end.toInt()}₺'),
                ],
              ),

              const SizedBox(height: 12),

              // Puan
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Minimum Puan',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Slider(
                value: _minRating,
                min: 0,
                max: 5,
                divisions: 10,
                label: _minRating.toStringAsFixed(1),
                onChanged: (v) => setState(() => _minRating = v),
              ),

              const SizedBox(height: 12),

              // Sıralama
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Sırala',
                  style: TextStyle(
                    color: Colors.black.withOpacity(0.7),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              DropdownButtonFormField<SortType>(
                value: _sort,
                items: const [
                  DropdownMenuItem(value: SortType.recommended, child: Text('Önerilen')),
                  DropdownMenuItem(value: SortType.priceLow, child: Text('Fiyat: düşük → yüksek')),
                  DropdownMenuItem(value: SortType.priceHigh, child: Text('Fiyat: yüksek → düşük')),
                  DropdownMenuItem(value: SortType.ratingHigh, child: Text('Puan: yüksek → düşük')),
                  DropdownMenuItem(value: SortType.newest, child: Text('En yeni')),
                ],
                onChanged: (v) => setState(() => _sort = v ?? SortType.recommended),
              ),

              const SizedBox(height: 16),

              // Alt butonlar
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _reset,
                      child: const Text('Sıfırla'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _apply,
                      child: const Text('Uygula'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
