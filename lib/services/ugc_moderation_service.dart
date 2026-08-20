import 'package:supabase_flutter/supabase_flutter.dart';

class UgcModerationService {
  UgcModerationService._();
  static final UgcModerationService instance = UgcModerationService._();

  final SupabaseClient _sb = Supabase.instance.client;

  static const List<String> _blockedTerms = <String>[
    'orospu', 'sikik', 'siktir', 'amk', 'yarrak', 'pic', 'piç',
    'pezevenk', 'serefsiz', 'şerefsiz', 'gerizekali', 'gerizekalı',
    'fuck', 'bitch', 'asshole', 'motherfucker',
  ];

  bool containsObjectionableContent(String text) {
    final normalized = text.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9çğıöşü]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return _blockedTerms.any((term) =>
        RegExp(r'(^|\s)' + RegExp.escape(term.toLowerCase()) + r'(\s|$)')
            .hasMatch(normalized));
  }

  Future<void> reportContent({
    required String contentType,
    required String contentId,
    String? reportedUserId,
    required String reason,
    String? details,
  }) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) throw StateError('Giriş yapmalısın.');
    await _sb.from('content_reports').insert({
      'reporter_id': uid,
      'reported_user_id': reportedUserId,
      'content_type': contentType,
      'content_id': contentId,
      'reason': reason.trim(),
      'details': details?.trim().isEmpty == true ? null : details?.trim(),
    });
  }

  Future<void> blockUser(String userId) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) throw StateError('Giriş yapmalısın.');
    if (uid == userId) throw StateError('Kendini engelleyemezsin.');
    await _sb.from('user_blocks').upsert({
      'blocker_id': uid, 'blocked_id': userId,
    }, onConflict: 'blocker_id,blocked_id');
    await _sb.from('content_reports').insert({
      'reporter_id': uid,
      'reported_user_id': userId,
      'content_type': 'user',
      'content_id': userId,
      'reason': 'Kullanıcı engellendi / kötüye kullanım sinyali',
      'details': 'Kullanıcı engelleme işlemi moderasyon ekibine bildirim olarak kaydedildi.',
    });
  }

  Future<bool> isBlocked(String userId) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null || userId.isEmpty) return false;
    final row = await _sb.from('user_blocks')
        .select('blocker_id')
        .or('and(blocker_id.eq.$uid,blocked_id.eq.$userId),and(blocker_id.eq.$userId,blocked_id.eq.$uid)')
        .limit(1).maybeSingle();
    return row != null;
  }
}
