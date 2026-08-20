import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/admin_push_service.dart';
import '../../services/ugc_moderation_service.dart';
import 'map_picker_osm_page.dart';

// ✅ CLEAN CODE IMPORTLARI (Kendi klasör yapına göre yolları kontrol et knk)
import '../../constants/legal_texts.dart';
import '../../widgets/legal_disclaimer_sheet.dart';

class SuggestCampPage extends StatefulWidget {
  const SuggestCampPage({super.key});

  @override
  State<SuggestCampPage> createState() => _SuggestCampPageState();
}

class _SuggestCampPageState extends State<SuggestCampPage> {
  final _name = TextEditingController();
  final _city = TextEditingController();
  final _district = TextEditingController();
  final _desc = TextEditingController();
  final _phone = TextEditingController();
  final _website = TextEditingController();
  final _maps = TextEditingController();
  final _checkIn = TextEditingController();
  final _checkOut = TextEditingController();
  final _price = TextEditingController();

  bool _petsAllowed = false;
  bool _freeCancellation = false;

  // ✅ 1. EKLEME: Yasal onay durumunu tutacak state değişkeni
  bool _suggestLegalAccepted = false;

  final Set<String> _selectedAmenities = {};
  final Set<String> _selectedTags = {};

  final List<String> _amenityOptions = [
    'WC',
    'Duş',
    'Elektrik',
    'Su',
    'Wi-Fi',
    'Otopark',
    'Market',
    'Restoran',
    'Mangal Alanı',
    'Çamaşır',
    'Karavan Elektrik Bağlantısı',
  ];

  final List<String> _tagOptions = [
    'Doğa',
    'Göl Kenarı',
    'Deniz Kenarı',
    'Aile Dostu',
    'Sessiz',
    'Karavan Uygun',
    'Çadır Uygun',
  ];
  bool loading = false;

  // ✅ Home "yeşil hissi" (soft)
  static const _bg = Color(0xff4CAF50);
  static const _cardBg = Colors.white;
  static const _fieldBg = Color(0xFFF6F7FB);

  Future<void> _pickFromMap() async {
    final res = await Navigator.push<MapPickResult?>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerOsmPage()),
    );
    if (res == null) return;

    setState(() {
      _maps.text =
      "${res.latLng.latitude.toStringAsFixed(6)},${res.latLng.longitude.toStringAsFixed(6)}";
    });
  }

  // ✅ 2. EKLEME: Ortak Bottom Sheet'i tetikleyen fonksiyon
  Future<void> _openLegalSheet() async {
    final accepted = await LegalDisclaimerSheet.show(
      context,
      contentText: LegalTexts.campDisclaimer,
      themeColor: _bg,
      icon: Icons.map_rounded,
    );

    if (accepted == true) {
      setState(() => _suggestLegalAccepted = true);
    }
  }

  Future<void> _send() async {
    // ✅ 3. EKLEME: Yasal beyan onaylanmadıysa işlemi kesen kontrol
    if (!_suggestLegalAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen yasal sorumluluk beyanını onaylayın.")),
      );
      return;
    }

    final sb = Supabase.instance.client;

    final name = _name.text.trim();
    final city = _city.text.trim();
    final district = _district.text.trim();
    final desc = _desc.text.trim();

    if (UgcModerationService.instance.containsObjectionableContent('$name $desc')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kamp önerisi topluluk kurallarına aykırı içerik içeriyor.')));
      return;
    }

    if (name.isEmpty || city.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kamp adı + şehir zorunlu knk")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      await sb.from('camp_suggestions').insert({
        'created_by': sb.auth.currentUser!.id,
        'name': name,
        'city': city,
        'district': district.isEmpty ? null : district,
        'description': desc.isEmpty ? null : desc,
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'website': _website.text.trim().isEmpty ? null : _website.text.trim(),
        'check_in':
        _checkIn.text.trim().isEmpty ? null : _checkIn.text.trim(),

        'check_out':
        _checkOut.text.trim().isEmpty ? null : _checkOut.text.trim(),
        'pets_allowed': _petsAllowed,
        'free_cancellation': _freeCancellation,
        'amenities': _selectedAmenities.map((e) {
          String icon = 'info';

          final k = e.toLowerCase();

          if (k.contains('wc')) {
            icon = 'wc';
          } else if (k.contains('duş')) {
            icon = 'shower';
          } else if (k.contains('elektrik')) {
            icon = 'bolt';
          } else if (k.contains('market')) {
            icon = 'store';
          } else if (k.contains('restoran')) {
            icon = 'restaurant';
          } else if (k.contains('wifi')) {
            icon = 'wifi';
          } else if (k.contains('karavan')) {
            icon = 'rv';
          }

          return {
            'name': e,
            'icon': icon,
            'available': true,
          };
        }).toList(),
        'tags': _selectedTags.toList(),
        'price_per_night': int.tryParse(_price.text.trim()) ?? 0,
        'maps_query': _maps.text.trim().isEmpty ? null : _maps.text.trim(),

        'images': [],
        'status': 'pending',
        'admin_note': null,
        'approved_at': null,
        'approved_by': null,
      });
      await AdminPushService().sendToAdmins(
        title: 'Yeni kamp önerisi var 🏕️',
        body: '$name • $city onay bekliyor',
        data: {
          'type': 'admin_camp_suggestion',
          'id': name,
        },
      );
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Öneri gönderildi ✅ Admin onayı bekliyor")),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _city.dispose();
    _district.dispose();
    _desc.dispose();
    _phone.dispose();
    _website.dispose();
    _maps.dispose();
    super.dispose();
    _checkIn.dispose();
    _checkOut.dispose();
    _price.dispose();
  }

  InputDecoration _dec(String label, {IconData? icon, Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      isDense: true,
      prefixIcon: icon == null ? null : Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: _fieldBg,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.10)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.black.withOpacity(0.25), width: 1.2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text("Kamp Öner"),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.black.withOpacity(0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                TextField(
                  controller: _name,
                  decoration: _dec("Kamp Adı *", icon: Icons.terrain),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _city,
                  decoration: _dec("Şehir *", icon: Icons.location_city),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _district,
                  decoration: _dec("İlçe", icon: Icons.place_outlined),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _desc,
                  decoration: _dec("Açıklama", icon: Icons.notes_outlined),
                  minLines: 3,
                  maxLines: 6,
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _phone,
                  decoration: _dec("Telefon", icon: Icons.phone_outlined),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _website,
                  decoration: _dec("Website", icon: Icons.language),
                ),
                const SizedBox(height: 10),

                TextField(
                  controller: _maps,
                  readOnly: true,
                  decoration: _dec(
                    "Konum (lat,lng)",
                    icon: Icons.map_outlined,
                    suffix: TextButton(
                      onPressed: _pickFromMap,
                      child: const Text("Haritadan Seç"),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _checkIn,
                        decoration: _dec(
                          "Giriş Saati",
                          icon: Icons.login,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _checkOut,
                        decoration: _dec(
                          "Çıkış Saati",
                          icon: Icons.logout,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                TextField(
                  controller: _price,
                  keyboardType: TextInputType.number,
                  decoration: _dec(
                    "Gecelik Fiyat (₺)",
                    icon: Icons.payments_outlined,
                  ),
                ),

                const SizedBox(height: 14),

                SwitchListTile(
                  value: _petsAllowed,
                  onChanged: (v) => setState(() => _petsAllowed = v),
                  title: const Text("Evcil hayvan kabul ediliyor"),
                  secondary: const Icon(Icons.pets),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  tileColor: _fieldBg,
                ),

                const SizedBox(height: 10),

                SwitchListTile(
                  value: _freeCancellation,
                  onChanged: (v) => setState(() => _freeCancellation = v),
                  title: const Text("Ücretsiz iptal var"),
                  secondary: const Icon(Icons.event_available),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  tileColor: _fieldBg,
                ),

                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "İmkanlar",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _amenityOptions.map((a) {
                    final selected = _selectedAmenities.contains(a);

                    return FilterChip(
                      label: Text(a),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selectedAmenities.add(a);
                          } else {
                            _selectedAmenities.remove(a);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                const SizedBox(height: 18),

                Align(
                  alignment: Alignment.centerLeft,
                  child: const Text(
                    "Etiketler",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _tagOptions.map((a) {
                    final selected = _selectedTags.contains(a);

                    return FilterChip(
                      label: Text(a),
                      selected: selected,
                      onSelected: (v) {
                        setState(() {
                          if (v) {
                            _selectedTags.add(a);
                          } else {
                            _selectedTags.remove(a);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),

                // ✅ 4. GÜNCELLEME: Gönder Butonunun Hemen Üstüne Temiz Yasal Checkbox Alanı Eklendi
                const SizedBox(height: 20),
                CheckboxListTile(
                  value: _suggestLegalAccepted,
                  onChanged: (v) {
                    if (v == true) {
                      _openLegalSheet();
                    } else {
                      setState(() => _suggestLegalAccepted = false);
                    }
                  },
                  title: const Text(
                    "Önerilen kamp alanına dair paylaşılan bilgi ve içeriklerin yasal sorumluluğunu onaylıyorum. *",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  activeColor: _bg,
                ),

                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: loading ? null : _send,
                    icon: loading
                        ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                        : const Icon(Icons.send),
                    label: const Text("Gönder"),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}