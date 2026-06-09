import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/push_notification_service.dart';
import '../main_shell.dart'; // GEREKİRSE yolu düzelt
import 'login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        // ilk açılışta kısa loading
        if (!snapshot.hasData && session == null) {
          return const _SplashLoading();
        }

        if (session != null) {
          Future.microtask(() async {
            await PushNotificationService.init();
          });

          return const MainShell();
        }

        return const LoginPage();
      },
    );
  }
}

class _SplashLoading extends StatelessWidget {
  const _SplashLoading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
