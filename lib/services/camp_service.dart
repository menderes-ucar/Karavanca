import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/camp_model.dart';

class CampService {
  static const String _seedPath = 'assets/camps_seed.json';

  List<CampModel>? _cache;
  final _db = Supabase.instance.client;

  String _norm(String s) {
    var x = s.trim().toLowerCase();

    x = x
        .replaceAll('İ', 'i')
        .replaceAll('I', 'i')
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');

    x = x.replaceAll('i̇', 'i');
    return x;
  }

  // =========================
  // ✅ SUPABASE LOAD
  // =========================
  Future<List<CampModel>> _loadFromSupabase({String? city}) async {
    try {
      dynamic res;

      if (city == null || city.trim().isEmpty) {
        res = await _db
            .from('camps')
            .select()
            .order('rating', ascending: false);
      } else {
        res = await _db
            .from('camps')
            .select()
            .eq('city', city)
            .order('rating', ascending: false);
      }

      if (res is! List) {
        debugPrint('❌ Supabase camps select LIST değil -> ${res.runtimeType}');
        return <CampModel>[];
      }

      const fallbackImage =
          'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=1600&q=80';

      final out = <CampModel>[];
      for (var i = 0; i < res.length; i++) {
        final e = res[i];
        try {
          if (e is! Map) continue;
          final m = CampModel.fromDb(e.cast<String, dynamic>());

          final safeImages = (m.images.isEmpty) ? [fallbackImage] : m.images;

          out.add(CampModel(
            id: m.id,
            name: m.name,
            city: m.city,
            region: m.region,
            description: m.description,
            rating: m.rating,
            reviews: m.reviews,
            pricePerNight: m.pricePerNight,
            images: safeImages,
            categoryId: m.categoryId,
            tags: m.tags,
            amenities: m.amenities,
            checkIn: m.checkIn,
            checkOut: m.checkOut,
            petsAllowed: m.petsAllowed,
            freeCancellation: m.freeCancellation,
            phone: m.phone,
            website: m.website,
            fee: m.fee,
            openingHours: m.openingHours,
          ));
        } catch (err, st) {
          debugPrint('❌ CampModel.fromDb FAIL index=$i item=$e');
          debugPrint('❌ error=$err');
          debugPrint('$st');
        }
      }

      debugPrint('✅ SUPABASE PARSED COUNT=${out.length} (city=${city ?? "ALL"})');
      return out;
    } catch (e, st) {
      debugPrint('❌ _loadFromSupabase ERROR: $e');
      debugPrint('$st');
      return <CampModel>[];
    }
  }

  // =========================
  // ✅ SEED LOAD (fallback)
  // =========================
  Future<List<CampModel>> _loadSeed() async {
    if (_cache != null) return _cache!;

    final raw = await rootBundle.loadString(_seedPath);
    final decoded = jsonDecode(raw);

    if (decoded is! List) {
      debugPrint('❌ camps_seed.json LIST değil -> type=${decoded.runtimeType}');
      _cache = <CampModel>[];
      return _cache!;
    }

    final data = decoded;
    debugPrint('✅ JSON COUNT=${data.length}');

    const fallbackImage =
        'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=1600&q=80';

    final List<CampModel> list = [];

    for (var i = 0; i < data.length; i++) {
      final e = data[i];

      try {
        if (e is! Map<String, dynamic>) {
          debugPrint('❌ fromSeedJson SKIP index=$i (Map değil) itemType=${e.runtimeType}');
          continue;
        }

        final m = CampModel.fromSeedJson(e);

        final safeImages = (m.images.isEmpty) ? [fallbackImage] : m.images;

        list.add(CampModel(
          id: m.id,
          name: m.name,
          city: m.city,
          region: m.region,
          description: m.description,
          rating: m.rating,
          reviews: m.reviews,
          pricePerNight: m.pricePerNight,
          images: safeImages,
          categoryId: m.categoryId,
          tags: m.tags,
          amenities: m.amenities,
          checkIn: m.checkIn,
          checkOut: m.checkOut,
          petsAllowed: m.petsAllowed,
          freeCancellation: m.freeCancellation,
          phone: m.phone,
          website: m.website,
          fee: m.fee,
          openingHours: m.openingHours,
        ));
      } catch (err, st) {
        debugPrint('❌ fromSeedJson FAIL index=$i item=$e');
        debugPrint('❌ error=$err');
        debugPrint('$st');
      }
    }

    debugPrint('✅ SEED PARSED COUNT=${list.length}');
    _cache = list;
    return list;
  }

  // =========================
  // ✅ PUBLIC API (AYNI)
  // =========================
  Future<List<CampModel>> getAllCamps() async {
    final supa = await _loadFromSupabase();
    if (supa.isNotEmpty) return supa;
    return _loadSeed();
  }
  Future<CampModel?> getById(String id) async {
    try {
      final res = await _db
          .from('camps')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (res != null) {
        final m = CampModel.fromDb(Map<String, dynamic>.from(res));

        const fallbackImage =
            'https://images.unsplash.com/photo-1501785888041-af3ef285b470?auto=format&fit=crop&w=1600&q=80';

        return CampModel(
          id: m.id,
          name: m.name,
          city: m.city,
          region: m.region,
          description: m.description,
          rating: m.rating,
          reviews: m.reviews,
          pricePerNight: m.pricePerNight,
          images: m.images.isEmpty ? [fallbackImage] : m.images,
          categoryId: m.categoryId,
          tags: m.tags,
          amenities: m.amenities,
          checkIn: m.checkIn,
          checkOut: m.checkOut,
          petsAllowed: m.petsAllowed,
          freeCancellation: m.freeCancellation,
          phone: m.phone,
          website: m.website,
          fee: m.fee,
          openingHours: m.openingHours,
          mapsQuery: m.mapsQuery,
        );
      }

      final seed = await _loadSeed();
      for (final c in seed) {
        if (c.id == id) {
          return c;
        }
      }

      return null;
    } catch (e) {
      debugPrint('❌ Camp getById error: $e');
      return null;
    }
  }
  Future<List<CampModel>> getPopularCamps() async {
    final supa = await _loadFromSupabase();
    if (supa.isNotEmpty) return supa;

    final list = await _loadSeed();
    final sorted = List<CampModel>.from(list)
      ..sort((a, b) {
        final r = b.rating.compareTo(a.rating);
        if (r != 0) return r;
        return b.reviews.compareTo(a.reviews);
      });
    return sorted;
  }

  Future<List<CampModel>> getCampsByCity(String cityName) async {
    final q = _norm(cityName);

    if (q.isEmpty || q == _norm('Hepsi')) {
      final supa = await _loadFromSupabase();
      if (supa.isNotEmpty) return supa;
      return _loadSeed();
    }

    final supaCity = await _loadFromSupabase(city: cityName);
    if (supaCity.isNotEmpty) return supaCity;

    final list = await _loadSeed();
    return list.where((c) => _norm(c.city) == q).toList();
  }

  Future<List<CampModel>> searchCamps() async {
    return getPopularCamps();
  }
}
