import 'package:flutter/material.dart';
import '../constants/legal_texts.dart';

class LegalDisclaimerSheet extends StatelessWidget {
  final String contentText;
  final Color themeColor;
  final IconData icon;

  const LegalDisclaimerSheet({
    super.key,
    required this.contentText,
    required this.themeColor,
    this.icon = Icons.gavel_rounded,
  });

  /// Sayfalardan bu popup'ı kolayca tetiklemek için statik bir fonksiyon
  static Future<bool?> show(
      BuildContext context, {
        required String contentText,
        required Color themeColor,
        IconData icon = Icons.gavel_rounded,
      }) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => LegalDisclaimerSheet(
        contentText: contentText,
        themeColor: themeColor,
        icon: icon,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üstteki küçük modern çizgi (bardan aşina olduğumuz yapı)
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Icon(icon, color: themeColor),
                const SizedBox(width: 10),
                const Text(
                  LegalTexts.title,
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16.5),
                ),
              ],
            ),
            const Divider(height: 24),
            Text(
              contentText,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 13.5,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  LegalTexts.buttonText,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}