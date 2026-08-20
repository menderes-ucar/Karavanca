import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminPushService {
  static const _functionUrl =
      'https://xfgusdjbyxhloytifcdj.supabase.co/functions/v1/send-push';

  // ✅ TEK KULLANICI
  Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    final accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Admin oturumu gerekli.');
    }
    final res = await http.post(
      Uri.parse(_functionUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'userId': userId,
        'title': title,
        'body': body,
        'data': data,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Push gönderilemedi: ${res.statusCode} ${res.body}',
      );
    }
  }

  // ✅ TÜM ADMİNLER
  Future<void> sendToAdmins({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    final sb = Supabase.instance.client;

    final admins = await sb
        .from('profiles')
        .select('id')
        .eq('is_admin', true);

    final list = (admins as List).cast<Map<String, dynamic>>();

    for (final admin in list) {
      final adminId = admin['id']?.toString();

      if (adminId == null || adminId.isEmpty) continue;

      await sendToUser(
        userId: adminId,
        title: title,
        body: body,
        data: data,
      );
    }
  }

  // ✅ HERKESE
  Future<void> sendToAll({
    required String title,
    required String body,
    Map<String, dynamic> data = const {},
  }) async {
    final accessToken = Supabase.instance.client.auth.currentSession?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Admin oturumu gerekli.');
    }
    final res = await http.post(
      Uri.parse(_functionUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode({
        'title': title,
        'body': body,
        'data': data,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception(
        'Push gönderilemedi: ${res.statusCode} ${res.body}',
      );
    }
  }
}