import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/main_shell.dart';
import '../screens/camps/camp_detail_page.dart';
import '../screens/caravans/caravan_chat_detail_page.dart';
import '../screens/caravans/caravan_detail_page.dart';
import '../screens/products/product_chat_page.dart';
import '../screens/products/product_detail_page.dart';

import '../services/camp_service.dart';
import '../services/caravan_service.dart';
import '../services/product_service.dart';

import '../services/caravan_favorites_service.dart';
import '../services/product_favorites_service.dart';

import 'app_nav_service.dart';

class PushNotificationService {
  PushNotificationService._();

  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final SupabaseClient _sb = Supabase.instance.client;

  static final FlutterLocalNotificationsPlugin _local =
  FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'karavanis_default',
    'Karavanis Bildirimleri',
    description: 'Karavanis uygulama bildirimleri',
    importance: Importance.high,
  );

  static bool _handlersReady = false;

  static Future<void> initialize() async {
    await init();
  }

  static Future<void> init() async {
    if (kIsWeb) return;

    try {
      await _initLocalNotifications();
      await _requestPermission();
      await saveCurrentToken();
      setupNotificationTapHandlers();

      FirebaseMessaging.instance.onTokenRefresh.listen((token) async {
        try {
          await _saveToken(token);
        } catch (e) {
          debugPrint('❌ FCM token refresh save error: $e');
        }
      });
    } catch (e) {
      debugPrint('❌ PushNotificationService init error: $e');
    }
  }

  static Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');

    const initSettings = InitializationSettings(android: androidInit);

    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) async {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;

        try {
          final decoded = jsonDecode(payload);
          if (decoded is! Map) return;

          final fakeMessage = RemoteMessage(
            data: decoded.map((k, v) => MapEntry(k.toString(), v.toString())),
          );

          await _handleNotificationTap(fakeMessage);
        } catch (e) {
          debugPrint('❌ Local notification payload parse error: $e');
        }
      },
    );

    await _local
        .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  static Future<void> _requestPermission() async {
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final settings = await _messaging.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        debugPrint(
          '🔔 Notification permission status: ${settings.authorizationStatus}',
        );
      }
    } catch (e) {
      debugPrint('❌ FCM permission error: $e');
    }
  }

  static Future<void> saveCurrentToken() async {
    try {
      final user = _sb.auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ FCM token alınmadı: kullanıcı login değil.');
        return;
      }

      final token = await _messaging.getToken();
      debugPrint('✅ FCM TOKEN = $token');

      if (token == null || token.trim().isEmpty) return;

      await _saveToken(token);
    } catch (e) {
      debugPrint('❌ FCM getToken error: $e');
    }
  }

  static void setupNotificationTapHandlers() {
    if (_handlersReady) return;
    _handlersReady = true;

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message);
    });

    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        _handleNotificationTap(message);
      }
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = message.notification?.title ?? 'Karavanis';
      final body = message.notification?.body ?? 'Yeni bildirimin var.';

      await _local.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            _channel.id,
            _channel.name,
            channelDescription: _channel.description,
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: jsonEncode(message.data),
      );
    });
  }

  static Future<void> _handleNotificationTap(RemoteMessage message) async {
    final type = message.data['type']?.toString();
    final id = message.data['id']?.toString();

    debugPrint('🔔 Notification tap: type=$type id=$id data=${message.data}');

    if (type == null || type.trim().isEmpty) {
      _openTab(null);
      return;
    }

    final nav = appNavigatorKey.currentState;
    if (nav == null) return;

    try {
      if (type == 'camp') {
        if (id == null || id.trim().isEmpty) {
          _openTab('camp');
          return;
        }

        final camp = await CampService().getById(id);
        if (camp == null) {
          _openTab('camp');
          return;
        }

        nav.push(MaterialPageRoute(builder: (_) => CampDetailPage(camp: camp)));
        return;
      }

      if (type == 'caravan') {
        if (id == null || id.trim().isEmpty) {
          _openTab('caravan');
          return;
        }

        final caravan = await CaravanService().getById(id);
        if (caravan == null) {
          _openTab('caravan');
          return;
        }

        nav.push(
          MaterialPageRoute(
            builder: (_) => CaravanDetailPage(
              listing: caravan,
              favoritesService: CaravanFavoritesService(),
            ),
          ),
        );
        return;
      }

      if (type == 'product') {
        if (id == null || id.trim().isEmpty) {
          _openTab('product');
          return;
        }

        final product = await ProductService().getById(id);
        if (product == null) {
          _openTab('product');
          return;
        }

        nav.push(
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(
              product: product,
              favoritesService: ProductFavoritesService(),
            ),
          ),
        );
        return;
      }

      if (type == 'caravan_chat') {
        final threadId = message.data['threadId']?.toString();
        final caravanId = message.data['itemId']?.toString();

        if (threadId == null ||
            threadId.trim().isEmpty ||
            caravanId == null ||
            caravanId.trim().isEmpty) {
          _openTab('caravan');
          return;
        }

        final caravan = await CaravanService().getById(caravanId);
        if (caravan == null) {
          _openTab('caravan');
          return;
        }

        nav.push(
          MaterialPageRoute(
            builder: (_) => CaravanChatDetailPage(
              caravanId: caravan.id,
              caravanTitle: caravan.title,
              sellerId: caravan.ownerId,
              sellerName: caravan.sellerName ?? 'Satıcı',
              threadId: threadId,
            ),
          ),
        );
        return;
      }

      if (type == 'product_chat') {
        final threadId = message.data['threadId']?.toString();
        final productId = message.data['itemId']?.toString();

        if (threadId == null ||
            threadId.trim().isEmpty ||
            productId == null ||
            productId.trim().isEmpty) {
          _openTab('product');
          return;
        }

        final product = await ProductService().getById(productId);
        if (product == null) {
          _openTab('product');
          return;
        }

        nav.push(
          MaterialPageRoute(
            builder: (_) => ProductChatPage(
              product: product,
              threadId: threadId,
            ),
          ),
        );
        return;
      }

      _openTab(type);
    } catch (e) {
      debugPrint('❌ Notification detail open error: $e');
      _openTab(type);
    }
  }

  static void _openTab(String? type) {
    int tabIndex = 0;

    if (type == 'camp') {
      tabIndex = 0;
    } else if (type == 'caravan' || type == 'caravan_chat') {
      tabIndex = 1;
    } else if (type == 'product' || type == 'product_chat') {
      tabIndex = 2;
    }

    final nav = appNavigatorKey.currentState;
    if (nav == null) return;

    nav.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => MainShell(initialIndex: tabIndex)),
          (route) => false,
    );
  }

  static Future<void> _saveToken(String token) async {
    final user = _sb.auth.currentUser;
    if (user == null) return;

    await _sb.from('user_push_tokens').upsert({
      'user_id': user.id,
      'fcm_token': token,
      'platform': Platform.isAndroid
          ? 'android'
          : Platform.isIOS
          ? 'ios'
          : 'other',
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'fcm_token');

    debugPrint('✅ FCM token Supabase kaydedildi.');
  }

  static Future<void> deleteCurrentTokenFromSupabase() async {
    try {
      final token = await _messaging.getToken();
      if (token == null) return;

      await _sb.from('user_push_tokens').delete().eq('fcm_token', token);
    } catch (e) {
      debugPrint('❌ FCM token delete error: $e');
    }
  }
}