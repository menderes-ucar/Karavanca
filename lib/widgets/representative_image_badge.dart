import 'package:flutter/material.dart';
import '../constants/legal_texts.dart';
import 'legal_disclaimer_sheet.dart';

class RepresentativeImageBadge extends StatelessWidget {
  final bool isMini; // Liste kartı için küçük, detay sayfası için geniş kart
  final Color themeColor;

  const RepresentativeImageBadge({
    super.key,
    this.isMini = false,
    this.themeColor = const Color(0xFF0F766E), // Varsayılan accent renk
  });

  void _showInfoSheet(BuildContext context) {
    LegalDisclaimerSheet.show(
      context,
      contentText: LegalTexts.campDisclaimer, // ✅ Mevcut kamp metnin kullanıldı
      themeColor: themeColor,
      icon: Icons.photo_library_outlined,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isMini) {
      // 🏷️ KÜÇÜK ROZET (Listelerdeki Görsellerin Üzerine Stack İle Koymak İçin)
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showInfoSheet(context),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.65),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.info_outline, size: 12, color: Colors.amber),
                SizedBox(width: 4),
                Text(
                  "Temsilî Görsel",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 💳 GENİŞ SAAS KARTI (Her Kamp Detay Sayfasında Kullanmak İçin)
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showInfoSheet(context),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: themeColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: themeColor.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_camera_back_outlined, color: themeColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          "Temsilî Görsel Kullanımı",
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: themeColor,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.open_in_new, size: 12, color: themeColor),
                      ],
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      "Fotoğraflar telif hakları nedeniyle temsili olarak kullanılmıştır ve gerçek kamp alanını yansıtmamaktadır.",
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}