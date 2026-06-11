import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/product_service.dart';
// ✅ Paket yollarına göre burayı kontrol et knk
import '../../constants/legal_texts.dart';
import '../../widgets/legal_disclaimer_sheet.dart';

class ProductCreatePage extends StatefulWidget {
  const ProductCreatePage({super.key});

  @override
  State<ProductCreatePage> createState() => _ProductCreatePageState();
}

class _ProductCreatePageState extends State<ProductCreatePage> {
  // ✅ TEK RENK YEŞİL
  static const Color kGreen = Color(0xFF16A34A);

  final _service = ProductService();
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'İstanbul');
  final _priceCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  bool _loading = false;
  bool _acceptedLegal = false; // Yasal onay durumu

  // ✅ Storage
  static const _bucket = 'product-images';
  final ImagePicker _picker = ImagePicker();
  bool uploading = false;
  final List<String> images = [];

  // ✅ KATEGORİ (Tür)
  static const List<Map<String, String>> kProductCategories = [
    {'id': 'tent', 'title': 'Çadır ve gereçleri'},
    {'id': 'sleep', 'title': 'Uyku ekipmanları'},
    {'id': 'kitchen', 'title': 'Kamp mutfak'},
    {'id': 'furniture', 'title': 'Kamp masa / sandalye'},
    {'id': 'electronics', 'title': 'Elektronik'},
    {'id': 'bag', 'title': 'Çanta / sırt çantası'},
    {'id': 'other', 'title': 'Diğer'},
  ];

  String _selectedCategoryId = 'tent';
  Map<String, String> get _selectedCategory =>
      kProductCategories.firstWhere((c) => c['id'] == _selectedCategoryId);

  // ✅ DURUM
  static const List<Map<String, String>> kConditions = [
    {'id': 'new', 'title': 'Yeni'},
    {'id': 'like_new', 'title': 'Sıfır Ayarında'},
    {'id': 'used', 'title': 'Kullanılmış'},
    {'id': 'damaged', 'title': 'Hasarlı'},
  ];

  String _selectedConditionId = 'used';
  Map<String, String> get _selectedCondition =>
      kConditions.firstWhere((c) => c['id'] == _selectedConditionId);

  @override
  void dispose() {
    _titleCtrl.dispose();
    _cityCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  int? _parsePrice(String s) {
    final x = s.trim().replaceAll('.', '').replaceAll(',', '');
    return int.tryParse(x);
  }

  String _publicUrl(String path) {
    final sb = Supabase.instance.client;
    final base = sb.storage.from(_bucket).getPublicUrl(path);
    return "$base?t=${DateTime.now().millisecondsSinceEpoch}";
  }

  Future<Uint8List> _compressImage(XFile file) async {
    final dir = await getTemporaryDirectory();

    final targetPath =
        '${dir.path}/product_${DateTime.now().millisecondsSinceEpoch}.jpg';

    final result = await FlutterImageCompress.compressWithFile(
      file.path,
      quality: 70,
      minWidth: 1280,
      minHeight: 1280,
      format: CompressFormat.jpeg,
    );

    if (result == null) {
      return await file.readAsBytes();
    }

    return result;
  }

  Future<void> _pickAndUploadImage() async {
    if (uploading || _loading) return;
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
        _toast("Oturum yok. Tekrar giriş yap.");
        return;
      }

      final Uint8List bytes = await _compressImage(file);

      const ext = 'jpg';
      const contentType = 'image/jpeg';

      final path = 'products/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg';

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
      _toast("Foto yükleme hatası: $e");
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _removeImage(String imgPath) async {
    if (uploading || _loading) return;
    setState(() => uploading = true);

    try {
      final sb = Supabase.instance.client;
      await sb.storage.from(_bucket).remove([imgPath]);
      if (!mounted) return;
      setState(() => images.remove(imgPath));
    } catch (e) {
      if (!mounted) return;
      _toast("Foto silme hatası: $e");
    } finally {
      if (mounted) setState(() => uploading = false);
    }
  }

  Future<void> _openLegalSheet() async {
    final accepted = await LegalDisclaimerSheet.show(
      context,
      contentText: LegalTexts.productDisclaimer,
      themeColor: kGreen,
      icon: Icons.gavel_rounded,
    );

    if (accepted == true) {
      setState(() => _acceptedLegal = true);
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedLegal) {
      _toast('Lütfen fotoğraf ve ilan yasal sorumluluk metnini onaylayın.');
      return;
    }

    final price = _parsePrice(_priceCtrl.text);
    if (price == null || price <= 0) {
      _toast('Fiyat geçersiz');
      return;
    }

    final categoryId = _selectedCategory['id']!;
    final categoryTitle = _selectedCategory['title']!;
    final conditionId = _selectedCondition['id']!;

    setState(() => _loading = true);
    try {
      await _service.create(
        title: _titleCtrl.text.trim(),
        categoryId: categoryId,
        categoryTitle: categoryTitle,
        city: _cityCtrl.text.trim(),
        price: price,
        description: _descCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        images: images,
        condition: conditionId,
      );

      if (!mounted) return;
      _toast('Ürün ilanı gönderildi (pending).');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _toast('Hata: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _sectionTitle(String s, IconData ic) => Row(
    children: [
      Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.55),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black.withOpacity(0.06)),
        ),
        child: Icon(ic, size: 18, color: Colors.black87),
      ),
      const SizedBox(width: 10),
      Text(
        s,
        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final busy = uploading || _loading;

    return Scaffold(
      backgroundColor: kGreen,
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
            child: _SolidGreenButton(
              onPressed: busy ? null : _submit,
              loading: _loading,
              text: _loading ? "Gönderiliyor..." : "İlanı Gönder",
              color: kGreen,
              icon: Icons.publish,
            ),
          ),
        ),
      ),
      body: Container(
        color: kGreen,
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                pinned: true,
                title: const Text(
                  "Ürün İlanı Ekle",
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            color: Colors.white.withOpacity(0.72),
                            border: Border.all(color: Colors.white.withOpacity(0.45)),
                          ),
                          // ✅ Listenin başındaki const kaldırıldı, hata çözüldü
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              const _Pill(text: "15 Foto", icon: Icons.photo_outlined),
                              const _Pill(text: "Durum", icon: Icons.fact_check_outlined),
                              const _Pill(text: "Tür", icon: Icons.category_outlined),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        _PremiumCard(
                          header: _sectionTitle("Temel Bilgiler", Icons.edit_outlined),
                          child: Column(
                            children: [
                              _FormFieldElite(
                                controller: _titleCtrl,
                                label: "Başlık",
                                hint: "Örn: 2 Kişilik Çadır",
                                validator: (v) {
                                  final x = (v ?? '').trim();
                                  if (x.isEmpty) return 'Başlık zorunlu';
                                  if (x.length < 3) return 'En az 3 karakter';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _DropElite(
                                label: "Tür",
                                value: _selectedCategoryId,
                                items: kProductCategories
                                    .map((c) => DropdownMenuItem(
                                  value: c['id'],
                                  child: Text(c['title']!),
                                ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _selectedCategoryId = v);
                                },
                              ),
                              const SizedBox(height: 12),
                              _DropElite(
                                label: "Durum",
                                value: _selectedConditionId,
                                items: kConditions
                                    .map((c) => DropdownMenuItem(
                                  value: c['id'],
                                  child: Text(c['title']!),
                                ))
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() => _selectedConditionId = v);
                                },
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: _FormFieldElite(
                                      controller: _cityCtrl,
                                      label: "Şehir",
                                      hint: "İstanbul",
                                      validator: (v) {
                                        final x = (v ?? '').trim();
                                        if (x.isEmpty) return 'Şehir zorunlu';
                                        return null;
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _FormFieldElite(
                                      controller: _priceCtrl,
                                      label: "Fiyat (₺)",
                                      hint: "1500",
                                      keyboardType: TextInputType.number,
                                      validator: (v) {
                                        final x = (v ?? '').trim();
                                        if (x.isEmpty) return 'Fiyat zorunlu';
                                        if (_parsePrice(x) == null) return 'Sayı gir';
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _FormFieldElite(
                                controller: _phoneCtrl,
                                label: "Telefon (opsiyonel)",
                                hint: "05xx xxx xx xx",
                                keyboardType: TextInputType.phone,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PremiumCard(
                          header: _sectionTitle("Açıklama", Icons.notes_outlined),
                          child: _FormFieldElite(
                            controller: _descCtrl,
                            label: "Açıklama",
                            hint: "Ürün durumu, pazarlık, kullanım süresi vb.",
                            maxLines: 6,
                            validator: (v) {
                              final x = (v ?? '').trim();
                              if (x.isEmpty) return 'Açıklama zorunlu';
                              if (x.length < 10) return 'En az 10 karakter';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PremiumCard(
                          header: _sectionTitle("Fotoğraflar", Icons.photo_camera_back_outlined),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      "Fotoğraf ekleyin • ${images.length}/15",
                                      style: const TextStyle(fontWeight: FontWeight.w800),
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
                                            url: _publicUrl(img),
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
                                "• İlk foto kapak olur. Net foto ekle.",
                                style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        _PremiumCard(
                          header: _sectionTitle("Yasal Beyan", Icons.gavel_outlined),
                          child: CheckboxListTile(
                            value: _acceptedLegal,
                            onChanged: (v) {
                              if (v == true) {
                                _openLegalSheet();
                              } else {
                                setState(() => _acceptedLegal = false);
                              }
                            },
                            title: const Text(
                              "Yüklediğim fotoğrafların telif hakları ve ürünün hukuki sorumluluğu şahsıma aittir. *",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12.5,
                              ),
                            ),
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                            activeColor: kGreen,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
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

// ================= TANGIBLE UI CLASSES (Eksiksiz Sınıflar) =================

class _PremiumCard extends StatelessWidget {
  final Widget header;
  final Widget child;
  const _PremiumCard({required this.header, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.90),
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
          header,
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData icon;
  const _Pill({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.black87),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _FormFieldElite extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final String? Function(String?)? validator;
  final int maxLines;
  final TextInputType? keyboardType;

  const _FormFieldElite({
    required this.controller,
    required this.label,
    required this.hint,
    this.validator,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
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
      validator: validator,
    );
  }
}

class _DropElite extends StatelessWidget {
  final String label;
  final String value;
  final List<DropdownMenuItem<String>> items;
  final ValueChanged<String?> onChanged;

  const _DropElite({
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
      items: items,
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

class _SolidGreenButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool loading;
  final String text;
  final Color color;
  final IconData icon;

  const _SolidGreenButton({
    required this.onPressed,
    required this.loading,
    required this.text,
    required this.color,
    required this.icon,
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
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}