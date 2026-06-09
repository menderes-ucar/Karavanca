class CampPlace {
  final int id;
  final String name;
  final double lat;
  final double lng;

  // ✅ yeni alanlar (backend'den gelecek)
  final String? city;
  final String? district;
  final String? address;

  final Map<String, dynamic> tags;

  CampPlace({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.tags,
    this.city,
    this.district,
    this.address,
  });

  String get tourism => (tags['tourism'] ?? '').toString();

  String get typeLabel {
    switch (tourism) {
      case 'camp_site':
        return 'Kamp Alanı';
      case 'caravan_site':
        return 'Karavan Alanı';
      case 'camp_pitch':
        return 'Kamp Noktası';
      default:
        return 'Kamp';
    }
  }

  String? get phone => tags['phone']?.toString();
  String? get website => tags['website']?.toString();
  String? get fee => tags['fee']?.toString();
  String? get openingHours => tags['opening_hours']?.toString();

  bool get wifi => (tags['internet_access']?.toString() == 'wlan');
  bool get toilets => (tags['toilets']?.toString() == 'yes');
  bool get shower => (tags['shower']?.toString() == 'yes');
  bool get power => (tags['power_supply']?.toString() == 'yes');

  factory CampPlace.fromJson(Map<String, dynamic> j) {
    return CampPlace(
      id: (j['id'] as num).toInt(),
      name: (j['name'] ?? 'Kamp Alanı').toString(),
      lat: (j['lat'] as num).toDouble(),
      lng: (j['lng'] as num).toDouble(),

      // ✅ yeni alanlar
      city: j['city']?.toString(),
      district: j['district']?.toString(),
      address: j['address']?.toString(),

      tags: (j['tags'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }
}
