import 'package:flutter/material.dart';
import '../services/ugc_moderation_service.dart';

class UgcActionSheet {
  static Future<bool> report({
    required BuildContext context,
    required String contentType,
    required String contentId,
    String? reportedUserId,
    String title = 'İçeriği Şikayet Et',
  }) async {
    const reasons = <String>[
      'Taciz veya tehdit',
      'Dolandırıcılık',
      'Uygunsuz içerik',
      'Spam',
      'Telif / hak ihlali',
      'Diğer',
    ];
    String selected = reasons.first;
    final details = TextEditingController();

    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Neden şikayet ediyorsun?'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selected,
                    items: reasons.map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
                    onChanged: (value) => setState(() => selected = value ?? reasons.first),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: details,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Ek açıklama (isteğe bağlı)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Şikayet Et')),
            ],
          ),
        ),
      );
      if (submitted != true) return false;
      await UgcModerationService.instance.reportContent(
        contentType: contentType,
        contentId: contentId,
        reportedUserId: reportedUserId,
        reason: selected,
        details: details.text,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Şikayetiniz alındı. İncelenecek.')));
      }
      return true;
    } finally {
      details.dispose();
    }
  }

  static Future<bool> block({
    required BuildContext context,
    required String userId,
    String userLabel = 'Bu kullanıcı',
  }) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Text('Kullanıcıyı Engelle'),
            content: Text('$userLabel engellenecek. Bu kullanıcıyla ilgili içerikler ve iletişim feedinden çıkarılacak. Aynı zamanda moderasyon ekibine bildirim oluşturulacak. Devam edilsin mi?'),
            actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Engelle')),
    ],
    ),
    );
    if (confirmed != true) return false;
    await UgcModerationService.instance.blockUser(userId);
    if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kullanıcı engellendi.')));
    }
    return true;
  }
}
