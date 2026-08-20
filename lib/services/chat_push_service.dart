import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatPushService {
  static const _functionUrl =
      'https://xfgusdjbyxhloytifcdj.supabase.co/functions/v1/send-push';

  Future<void> sendMessagePush({
    required String receiverUserId,
    required String title,
    required String body,
    required String threadId,
    required String itemId,
    required String type,
  }) async {
    final payload = {
      'userId': receiverUserId,
      'title': title,
      'body': body,
      'threadId': threadId,
      'data': {
        'type': type,
        'threadId': threadId,
        'itemId': itemId,
      },
    };

    debugPrint('📨 CHAT PUSH PAYLOAD = ${jsonEncode(payload)}');

    final session = Supabase.instance.client.auth.currentSession;
    final accessToken = session?.accessToken;
    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Push göndermek için oturum gerekli.');
    }

    final res = await http.post(
      Uri.parse(_functionUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $accessToken',
      },
      body: jsonEncode(payload),
    );

    debugPrint('📨 CHAT PUSH STATUS = ${res.statusCode}');
    debugPrint('📨 CHAT PUSH BODY = ${res.body}');

    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw Exception('Chat push gönderilemedi: ${res.statusCode} ${res.body}');
    }
  }
}