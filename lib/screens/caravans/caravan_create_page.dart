import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/app_config.dart';
import '../../services/admin_push_service.dart';
import '../../services/credit_service.dart';
import '../../services/ugc_moderation_service.dart';
import '../../constants/legal_texts.dart';
import '../../widgets/legal_disclaimer_sheet.dart';

class CaravanCreatePage extends StatefulWidget {
  const CaravanCreatePage({super.key});

  @override
  State<CaravanCreatePage> createState() => _CaravanCreatePageState();
}

class _CaravanCreatePageState extends State<CaravanCreatePage> {
  // ✅ TEK RENK
  static const Color kMain = Color(0xfff2b233);

  final titleCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final priceCtrl = TextEditingController();
  final noteCtrl = TextEditingController();

  final _creditService = CreditService();

  bool acceptedRules = false;

  String? region;
  String? fromWho;
  String? barter;
  String? status;
  String? warranty;
  String? city;

  // ✅ FOTO
  static const _bucket = 'caravan-images';
  final ImagePicker _picker = ImagePicker();
  bool uploading = false;
  bool publishing = false;

  final List<String> images = [];

  static const List<String> regions = [
    "Marmara",
    "Ege",
    "Akdeniz",
    "İç Anadolu",
    "Karadeniz",
    "Doğu Anadolu",
    "Güneydoğu Anadolu"
  ];
  static const List<String> fromList = ["Sahibinden", "Galeriden"];
  static const List<String> yesNo = ["Evet", "Hayır"];
  static const List<String> statusList = ["İkinci El", "Sıfır"];
  static const List<String> warrantyList = ["Var", "Yok"];

  static const List<String> trCities = [
    "Adana","Adıyaman","Afyonkarahisar","Ağrı","Amasya","Ankara","Antalya","Artvin","Aydın","Balıkesir",
    "Bilecik","Bingöl","Bitlis","Bolu","Burdur","Bursa","Çanakkale","Çankırı","Çorum","Denizli",
    "Diyarbakır","Edirne","Elazığ","Erzincan","Erzurum","Eskişehir","Gaziantep","Giresun","Gümüşhane","Hakkari",
    "Hatay","Isparta","Mersin","İstanbul","İzmir","Kars","Kastamonu","Kayseri","Kırklareli","Kırşehir",
    "Kocaeli","Konya","Kütahya","Malatya","Manisa","Kahramanmaraş","Mardin","Muğla","Muş","Nevşehir",
    "Niğde","Ordu","Rize","Sakarya","Samsun","Siirt","Sinop","Sivas","Tekirdağ","Tokat",
    "Trabzon","Tunceli","Şanlıurfa","Uşak","Van","Yozgat","Zonguldak","Aksaray","Bayburt","Karaman",
    "Kırıkkale","Batman","Şırnak","Bartın","Ardahan","Iğdır","Yalova","Karabük","Kilis","Osmaniye","Düzce"
  ];

  @override
  void dispose() {
    titleCtrl.dispose();
    descCtrl.dispose();
    priceCtrl.dispose();
    noteCtrl.dispose();
    super.dispose();
  }

  Future<Uint8List> _compressImage(XFile file) async {
    final dir = await getTemporaryDirectory();

    final targetPath =
        '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 70,
      minWidth: 1280,
      minHeight: 1280,
    );

    return await result!.readAsBytes();
  }

  Future<void> _pickAndUploadImage() async {
    if (uploading || publishing) return;
    if (images.length >= 15) return;

    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (file == null) return;

    setState(() => uploading = true);

    try {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;

      if (uid == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Oturum yok. Tekrar giriş yap.")),
        );
        return;
      }

      final Uint8List bytes = await _compressImage(file);
      final extRaw = file.path.split('.').last.toLowerCase();
      final ext = extRaw.isEmpty ? 'jpg' : extRaw;

      String contentType;
      if (ext == 'png') {
        contentType = 'image/png';
      } else if (ext == 'webp') {
        contentType = 'image/webp';
      } else {
        contentType = 'image/jpeg';
      }

      final path = 'caravans/$uid/${DateTime.now().millisecondsSinceEpoch}.$ext';

      await sb.storage.from(_bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          upsert: false,
          contentType: contentType,
        ),
      );

      if (!mounted) return;
      setState(() => images.add(path));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Foto yükleme hatası: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() => uploading = false);
    }
  }

  Future<void> _removeImage(String imgPath) async {
    if (uploading || publishing) return;
    setState(() => uploading = true);

    try {
      final sb = Supabase.instance.client;
      await sb.storage.from(_bucket).remove([imgPath]);

      if (!mounted) return;
      setState(() => images.remove(imgPath));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Foto silme hatası: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() => uploading = false);
    }
  }

  Future<void> _openLegalSheet() async {
    final accepted = await LegalDisclaimerSheet.show(
      context,
      contentText: LegalTexts.caravanDisclaimer,
      themeColor: kMain,
      icon: Icons.rv_hookup_rounded,
    );

    if (accepted == true) {
      setState(() => acceptedRules = true);
    }
  }

  // ✅ Kredi yetersizse gösterilecek dialog
  Future<void> _showInsufficientCreditsDialog() async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Yetersiz Kredi"),
        content: Text(
          "Karavan ilanı yayınlamak için ${CreditService.caravanListingCost} kredi gerekiyor. "
              "Mevcut kredin yetersiz görünüyor. Profil sayfandan kredi yükleyebilirsin.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Tamam"),
          ),
        ],
      ),
    );
  }

  Future<void> _publish() async {
    if (uploading || publishing) return;

    if (!acceptedRules) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lütfen ilan verme kurallarını onaylayın.")),
      );
      return;
    }

    final sb = Supabase.instance.client;
    final uid = sb.auth.currentUser?.id;

    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Oturum yok. Tekrar giriş yap.")),
      );
      return;
    }

    final title = titleCtrl.text.trim();
    final desc = descCtrl.text.trim();
    final priceText = priceCtrl.text.trim();

    if (UgcModerationService.instance.containsObjectionableContent('$title $desc')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('İlan metni topluluk kurallarına aykırı içerik içeriyor.')));
      return;
    }

    if (title.isEmpty || priceText.isEmpty || city == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Başlık + fiyat + il zorunlu")),
      );
      return;
    }

    final price = int.tryParse(priceText.replaceAll('.', '').replaceAll(',', ''));
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Fiyat sayı olmalı")),
      );
      return;
    }

    final features = <String>[
      if (region != null) "Bölge: $region",
      if (fromWho != null) "Kimden: $fromWho",
      if (barter != null) "Takas: $barter",
      if (status != null) "Durum: $status",
      if (warranty != null) "Garanti: $warranty",
    ];

    setState(() => publishing = true);

    try {
      // ✅ Kredi kontrolü — Sistem pasifse atlanır
      if (AppConfig.isCreditSystemActive) {
        final hasCredits = await _creditService.hasEnoughCredits(CreditService.caravanListingCost);
        if (!hasCredits) {
          if (!mounted) return;
          setState(() => publishing = false);
          _showInsufficientCreditsDialog();
          return;
        }
      }

      final row = await sb
          .from('caravans')
          .insert({
        'owner_id': uid,
        'title': title,
        'city': city,
        'price': price,
        'description': desc.isEmpty ? null : desc,
        'phone': null,
        'features': features,
        'images': images,
        'status': 'pending',
        'admin_note': noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
        'approved_at': null,
        'approved_by': null,
      })
          .select('id')
          .single();
      final caravanId = row['id'] as String;

      // ✅ İlan oluşturulduktan sonra kredi düş — Sistem pasifse atlanır
      if (AppConfig.isCreditSystemActive) {
        try {
          await _creditService.deductForListing(
            amount: CreditService.caravanListingCost,
            listingType: 'caravan',
            referenceId: caravanId,
          );
        } catch (e) {
          await sb.from('caravans').delete().eq('id', caravanId);
          rethrow;
        }
      }

      await AdminPushService().sendToAdmins(
        title: 'Yeni karavan ilanı var 🚐',
        body: '$title • $city onay bekliyor',
        data: {
          'type': 'admin_caravan',
          'id': caravanId,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("İlan gönderildi ✅ Admin onayı bekliyor")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      if (e is InsufficientCreditsException) {
        _showInsufficientCreditsDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Yayınlama hatası: $e")),
        );
      }
    } finally {
      if (!mounted) return;
      setState(() => publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sb = Supabase.instance.client;

    String publicUrl(String path) {
      final base = sb.storage.from(_bucket).getPublicUrl(path);
      return "$base?t=${DateTime.now().millisecondsSinceEpoch}";
    }

    final busy = uploading || publishing;

    return Scaffold(
      backgroundColor: kMain,
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                blurRadius: 14,
                offset: const Offset(0, -6),
                color: Colors.black.withOpacity(0.12),
              )
            ],
          ),
          child: SizedBox(
            height: 56,
            child: _SolidPublishButton(
              onPressed: busy ? null : _publish,
              loading: publishing,
              text: publishing ? "Gönderiliyor..." : "İlanı Yayınla",
              color: kMain,
            ),
          ),
        ),
      ),
      body: Container(
        color: kMain,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                title: const Text(
                  "İlan Ver",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
                centerTitle: false,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _GlassCard(
                        title: "İlan Bilgileri",
                        icon: Icons.assignment_outlined,
                        child: Column(
                          children: [
                            _EliteTextField(
                              controller: titleCtrl,
                              label: "İlan Başlığı *",
                              hint: "Örn: 2020 Model Çekme Karavan",
                            ),
                            const SizedBox(height: 12),
                            _EliteTextField(
                              controller: descCtrl,
                              label: "İlan Açıklaması",
                              hint: "Detayları yaz (donanım, km, kullanım, ekstra...)",
                              minLines: 6,
                              maxLines: 10,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: _EliteTextField(
                                    controller: priceCtrl,
                                    label: "Fiyat *",
                                    hint: "1200000",
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 110,
                                  child: _EliteDropdown(
                                    label: "Para",
                                    value: "TL",
                                    items: const ["TL", "USD", "EUR"],
                                    onChanged: (_) {},
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _EliteDropdown(
                                    label: "Bölge *",
                                    value: region,
                                    items: regions,
                                    onChanged: (v) => setState(() => region = v),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _EliteDropdown(
                                    label: "Kimden *",
                                    value: fromWho,
                                    items: fromList,
                                    onChanged: (v) => setState(() => fromWho = v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _EliteDropdown(
                                    label: "Takas *",
                                    value: barter,
                                    items: yesNo,
                                    onChanged: (v) => setState(() => barter = v),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _EliteDropdown(
                                    label: "Durum *",
                                    value: status,
                                    items: statusList,
                                    onChanged: (v) => setState(() => status = v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            _EliteDropdown(
                              label: "Garanti *",
                              value: warranty,
                              items: warrantyList,
                              onChanged: (v) => setState(() => warranty = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassCard(
                        title: "İlan Fotoğrafları",
                        icon: Icons.photo_camera_back_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Fotoğraf ekleyin • ${images.length}/15",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                if (uploading)
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            LayoutBuilder(
                              builder: (ctx, c) {
                                final w = c.maxWidth;
                                final itemW = (w - 16) / 3;
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final img in images)
                                      SizedBox(
                                        width: itemW,
                                        height: itemW,
                                        child: _ImageTile(
                                          url: publicUrl(img),
                                          onRemove: () => _removeImage(img),
                                        ),
                                      ),
                                    if (images.length < 15)
                                      SizedBox(
                                        width: itemW,
                                        height: itemW,
                                        child: _AddTile(
                                          disabled: busy,
                                          onTap: busy ? () {} : _pickAndUploadImage,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              "• Net, ışıklı foto ekle. İlk foto kapak gibi görünür.",
                              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassCard(
                        title: "İlan Notu",
                        icon: Icons.sticky_note_2_outlined,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _EliteTextField(
                              controller: noteCtrl,
                              label: "Not (sadece sen görürsün)",
                              hint: "Örn: pazarlık payı var / acil / hafta sonu gösterilebilir",
                              minLines: 4,
                              maxLines: 7,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Bu notu sadece sen görürsün.",
                              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassCard(
                        title: "Adres Bilgileri",
                        icon: Icons.place_outlined,
                        child: _EliteDropdown(
                          label: "İl *",
                          value: city,
                          items: trCities,
                          onChanged: (v) => setState(() => city = v),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _GlassCard(
                        title: "Kurallar ve Yasal Sorumluluk",
                        icon: Icons.security_outlined,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.55),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.black.withOpacity(0.06)),
                          ),
                          child: CheckboxListTile(
                            value: acceptedRules,
                            onChanged: (v) {
                              if (v == true) {
                                _openLegalSheet();
                              } else {
                                setState(() => acceptedRules = false);
                              }
                            },
                            title: const Text(
                              "İlan ve fotoğraf yükleme yasal sorumluluk metnini okudum, onaylıyorum. *",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 12.5,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                            activeColor: kMain,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================== TANGIBLE UI PIECES (Eksiksiz Sınıflar) ==================

class _GlassCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _GlassCard({required this.title, required this.icon, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            blurRadius: 22,
            offset: const Offset(0, 14),
            color: Colors.black.withOpacity(0.06),
          ),
          BoxShadow(
            blurRadius: 8,
            offset: const Offset(0, 3),
            color: Colors.black.withOpacity(0.04),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 18, color: Colors.black87),
              ),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _EliteTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final int minLines;
  final int maxLines;
  final TextInputType? keyboardType;

  const _EliteTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7F8FB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.black, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _EliteDropdown extends StatelessWidget {
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _EliteDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF7F8FB),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}

class _ImageTile extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;

  const _ImageTile({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(url, fit: BoxFit.cover, errorBuilder: (_, __, ___) {
            return Container(
              color: Colors.black12,
              alignment: Alignment.center,
              child: const Icon(Icons.image_not_supported_outlined),
            );
          }),
          Positioned(
            top: 8,
            right: 8,
            child: InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.62),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;
  final bool disabled;

  const _AddTile({required this.onTap, required this.disabled});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black.withOpacity(0.10)),
          color: disabled ? Colors.black.withOpacity(0.04) : const Color(0xFFF7F8FB),
        ),
        child: Center(
          child: Icon(
            disabled ? Icons.hourglass_top : Icons.add,
            size: 34,
            color: Colors.black.withOpacity(0.55),
          ),
        ),
      ),
    );
  }
}

class _SolidPublishButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final String text;
  final Color color;

  const _SolidPublishButton({
    required this.onPressed,
    required this.loading,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;

    return Opacity(
      opacity: disabled ? 0.60 : 1,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: color,
              boxShadow: [
                BoxShadow(
                  blurRadius: 16,
                  offset: const Offset(0, 10),
                  color: Colors.black.withOpacity(0.18),
                )
              ],
            ),
            child: Center(
              child: loading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
                  : Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}