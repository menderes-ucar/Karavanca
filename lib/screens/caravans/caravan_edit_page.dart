import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CaravanEditPage extends StatefulWidget {
  final String id;
  final String initialTitle;
  final String initialCity;
  final dynamic initialPrice;
  final String? initialDesc;
  final List<String>? initialImages;

  const CaravanEditPage({
    super.key,
    required this.id,
    required this.initialTitle,
    required this.initialCity,
    required this.initialPrice,
    this.initialDesc,
    this.initialImages,
  });

  @override
  State<CaravanEditPage> createState() => _CaravanEditPageState();
}

class _CaravanEditPageState extends State<CaravanEditPage> {
  late final TextEditingController _title;
  late final TextEditingController _city;
  late final TextEditingController _price;
  late final TextEditingController _desc;

  final ImagePicker picker = ImagePicker();

  static const _bucket = 'caravan-images';

  List<String> images = [];
  bool saving = false;
  bool uploading = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle);
    _city = TextEditingController(text: widget.initialCity);
    _price = TextEditingController(text: widget.initialPrice.toString());
    _desc = TextEditingController(text: widget.initialDesc ?? '');
    images = List<String>.from(widget.initialImages ?? []);
  }

  @override
  void dispose() {
    _title.dispose();
    _city.dispose();
    _price.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (uploading || saving) return;

    final XFile? file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;

    setState(() => uploading = true);

    try {
      final sb = Supabase.instance.client;
      final bytes = await file.readAsBytes();

      // ✅ extension'ı koru (jpg/png/webp vs)
      final ext = (file.path.split('.').last).toLowerCase();
      final safeExt = (ext.isEmpty) ? 'jpg' : ext;

      final path =
          'caravans/${widget.id}/${DateTime.now().millisecondsSinceEpoch}.$safeExt';

      await sb.storage.from(_bucket).uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(
          upsert: true,
          // basit content-type (iş görür)
          contentType: safeExt == 'png' ? 'image/png' : 'image/jpeg',
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
    if (uploading || saving) return;

    setState(() => uploading = true);

    try {
      final sb = Supabase.instance.client;

      // ✅ storage’dan sil
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

  Future<void> _save() async {
    final title = _title.text.trim();
    final city = _city.text.trim();
    final price = int.tryParse(
      _price.text.replaceAll('.', '').replaceAll(',', '').trim(),
    );
    final desc = _desc.text.trim();

    if (title.isEmpty || city.isEmpty || price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Başlık/şehir/fiyat alanlarını doğru doldur."),
        ),
      );
      return;
    }

    setState(() => saving = true);

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

      await sb.from('caravans').update({
        'title': title,
        'city': city,
        'price': price,
        'description': desc.isEmpty ? null : desc,
        'images': images,

        // ✅ edit edilince tekrar admin onayına düşsün
        'status': 'pending',
        'approved_at': null,
        'approved_by': null,

        // ✅ Admin tarafında “son düzenleme” göstermek için
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', widget.id).eq('owner_id', uid);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Güncelleme hatası: $e")),
      );
    } finally {
      if (!mounted) return;
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sb = Supabase.instance.client;

    return Scaffold(
      appBar: AppBar(
        title: const Text("İlanı Düzenle"),
        actions: [
          TextButton(
            onPressed: (saving || uploading) ? null : _save,
            child: saving
                ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Text("Kaydet"),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ✅ Profesyonel uyarı
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE0B2)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFF9A3412)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "İlanı güncellediğinde tekrar admin onayına düşer.",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF9A3412),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: "Başlık"),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _desc,
            minLines: 4,
            maxLines: 8,
            decoration: const InputDecoration(labelText: "Açıklama"),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _city,
            decoration: const InputDecoration(labelText: "Şehir"),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _price,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Fiyat"),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              const Expanded(
                child: Text(
                  "Fotoğraflar",
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              if (uploading) const SizedBox(width: 8),
              if (uploading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final img in images)
                Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(
                            sb.storage.from(_bucket).getPublicUrl(img),
                          ),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 4,
                      top: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(img),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black,
                          child: Icon(Icons.close, size: 14, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              InkWell(
                onTap: (uploading || saving) ? null : _pickImage,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: Icon(uploading ? Icons.hourglass_top : Icons.add),
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          ElevatedButton.icon(
            onPressed: (saving || uploading) ? null : _save,
            icon: const Icon(Icons.save),
            label: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }
}
