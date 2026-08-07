import 'dart:convert';
import 'camp_place.dart';

extension _TagRead on Map<String, dynamic> {
  String? s(String key) => this[key]?.toString();
  bool? b(String key) {
    final v = this[key];
    if (v == null) return null;
    if (v is bool) return v;
    final t = v.toString().toLowerCase();
    if (t == 'true' || t == '1' || t == 'yes') return true;
    if (t == 'false' || t == '0' || t == 'no') return false;
    return null;
  }

  int? i(String key) {
    final v = this[key];
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  List<String> sl(String key) {
    final v = this[key];
    if (v is List) return v.map((e) => e.toString()).toList();
    return <String>[];
  }
}

class CampAmenity {
  final String name;
  final String icon; // string id (ui tarafında map edeceğiz)
  final bool available;

  CampAmenity({
    required this.name,
    required this.icon,
    required this.available,
  });

  factory CampAmenity.fromJson(Map<String, dynamic> j) {
    return CampAmenity(
      name: (j['name'] ?? '').toString(),
      icon: (j['icon'] ?? 'info').toString(),
      available: (j['available'] == true),
    );
  }
}

class CampModel {
  final String id;
  final String name;
  final String city;
  final String region; // district
  final String description;
  final double rating;
  final int reviews;
  final int pricePerNight;
  final List<String> images;
  final String categoryId;
  final String? mapsQuery;
  final List<String> tags;
  final List<CampAmenity> amenities;
  final String? checkIn;
  final String? checkOut;
  final bool? petsAllowed;
  final bool? freeCancellation;

  // ✅ OSM / dış kaynak alanları
  final String? phone;
  final String? website;
  final String? fee;
  final String? openingHours;

  CampModel({
    required this.id,
    required this.name,
    required this.city,
    required this.region,
    required this.description,
    required this.rating,
    required this.reviews,
    required this.pricePerNight,
    required this.images,
    required this.categoryId,
    required this.tags,
    required this.amenities,
    this.checkIn,
    this.checkOut,
    this.petsAllowed,
    this.freeCancellation,
    this.phone,
    this.website,
    this.fee,
    this.openingHours,
    this.mapsQuery,
  });

  // 🌲 GÜVENLİ RESİM LİSTESİ: Liste boşsa veya geçersizse lokal orman.png döndürür
  List<String> get safeImages {
    if (images.isEmpty) {
      return ["assets/images/camps/orman.png"];
    }
    return images;
  }

  /// ✅ SUPABASE DB -> CampModel (snake_case kolonlar)
  factory CampModel.fromDb(Map<String, dynamic> j) {
    // CSV import sonrası bazen array alanları List gelir, bazen string gelir.
    List<String> _asListString(dynamic v) {
      if (v == null) return [];
      if (v is List) return v.map((e) => e.toString()).toList();

      // string ise JSON list olabilir: '["a","b"]'
      if (v is String) {
        final s = v.trim();
        if (s.startsWith('[') && s.endsWith(']')) {
          try {
            final x = jsonDecode(s) as List;
            return x.map((e) => e.toString()).toList();
          } catch (_) {}
        }
      }
      return [];
    }

    List<CampAmenity> _asAmenityList(dynamic v) {
      if (v == null) return [];
      if (v is List) {
        return v
            .whereType<Map>()
            .map((m) => CampAmenity.fromJson(m.cast<String, dynamic>()))
            .toList();
      }
      if (v is String) {
        final s = v.trim();
        if (s.startsWith('[') && s.endsWith(']')) {
          try {
            final x = jsonDecode(s) as List;
            return x
                .whereType<Map>()
                .map((m) => CampAmenity.fromJson(m.cast<String, dynamic>()))
                .toList();
          } catch (_) {}
        }
      }
      return [];
    }

    final images = _asListString(j['images']);
    final tags = _asListString(j['tags']);
    final amenities = _asAmenityList(j['amenities']);

    return CampModel(
      id: (j['id'] ?? '').toString(),
      name: (j['name'] ?? 'Bilinmeyen Kamp').toString(),
      city: (j['city'] ?? '').toString(),
      region: (j['region'] ?? '').toString(),
      description: (j['description'] ?? '').toString(),
      rating: (j['rating'] is num) ? (j['rating'] as num).toDouble() : 0.0,
      reviews: (j['reviews'] is num) ? (j['reviews'] as num).toInt() : 0,
      pricePerNight: (j['price_per_night'] is num)
          ? (j['price_per_night'] as num).toInt()
          : int.tryParse((j['price_per_night'] ?? '0').toString()) ?? 0,
      images: images.isEmpty ? ["assets/images/camps/orman.png"] : images,
      categoryId: (j['category_id'] ?? 'camping').toString(),
      tags: tags,
      amenities: amenities,
      checkIn: j['check_in']?.toString(),
      checkOut: j['check_out']?.toString(),
      petsAllowed: j['pets_allowed'] as bool?,
      freeCancellation: j['free_cancellation'] as bool?,
      phone: j['phone']?.toString(),
      website: j['website']?.toString(),
      fee: j['fee']?.toString(),
      openingHours: j['opening_hours']?.toString(),
      mapsQuery: j['maps_query']?.toString(),
    );
  }

  /// ✅ Seed JSON -> CampModel
  factory CampModel.fromSeedJson(Map<String, dynamic> j) {
    final id = (j.s("id") ?? "").trim();
    final name = (j.s("name") ?? "Bilinmeyen Kamp").trim();
    final city = (j.s("city") ?? "").trim();
    final district = (j.s("district") ?? "").trim();

    // basit tag mantığı: amenities listeni tag olarak da kullanabilirsin
    final amenitiesStrings = j.sl("amenities");

    // amenities -> CampAmenity listesine dönüştürelim
    final amenityModels = amenitiesStrings.map((a) {
      final key = a.toLowerCase();
      // icon id’leri: ui tarafında map edersin
      String icon = "info";
      if (key.contains("duş")) icon = "shower";
      else if (key.contains("wc") || key.contains("tuvalet")) icon = "wc";
      else if (key.contains("elektrik")) icon = "bolt";
      else if (key.contains("karavan")) icon = "rv";
      else if (key.contains("market")) icon = "store";
      else if (key.contains("restoran") || key.contains("kafe")) icon = "restaurant";
      else if (key.contains("wifi")) icon = "wifi";

      return CampAmenity(name: a, icon: icon, available: true);
    }).toList();

    // ✅ DÜZELTME: Eskiden "placeholder.jpg" olan yer orman.png olarak değiştirildi
    final images = <String>[
      "assets/images/camps/orman.png",
    ];

    // price: seed’de yok -> 0 ver (UI’da “—” gösterebilirsin)
    final price = j.i("pricePerNight") ?? 0;

    return CampModel(
      id: id.isEmpty ? "seed_${name.hashCode}" : id,
      name: name,
      city: city,
      region: district, // district -> region
      description: (j.s("description") ?? "").trim(),
      rating: (double.tryParse((j.s("rating") ?? "").toString()) ?? 4.4),
      reviews: j.i("reviews") ?? 0,
      pricePerNight: price,
      images: (j["images"] is List && (j["images"] as List).isNotEmpty)
          ? (j["images"] as List).map((e) => e.toString()).toList()
          : images,
      categoryId: (j.s("categoryId") ?? "camping"),
      tags: (j["tags"] is List && (j["tags"] as List).isNotEmpty)
          ? (j["tags"] as List).map((e) => e.toString()).toList()
          : amenitiesStrings, // yoksa amenities'i tag gibi kullan
      amenities: amenityModels,
      checkIn: j.s("checkIn"),
      checkOut: j.s("checkOut"),
      petsAllowed: j.b("petsAllowed"),
      freeCancellation: j.b("freeCancellation"),
      phone: j.s("phone"),
      website: j.s("website"),
      fee: j.s("fee"),
      openingHours: j.s("openingHours"),
      mapsQuery: j.s("mapsQuery"),
    );
  }
}