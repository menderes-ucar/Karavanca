import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/auth/login_page.dart';

/// Account-based actions için ortak giriş kontrolü.
/// Misafir kullanıcılar içerikleri görüntüleyebilir; favori, mesaj,
/// ilan verme gibi hesap gerektiren işlemlerde giriş istenir.
class AuthGuard {
  const AuthGuard._();

  static bool get isAuthenticated =>
      Supabase.instance.client.auth.currentSession != null;

  static Future<bool> requireAuth(BuildContext context) async {
    if (isAuthenticated) return true;

    final shouldLogin = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Giriş gerekli'),
        content: const Text(
          'Bu işlemi kullanmak için Karavanca hesabınızla giriş yapmalısınız.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Giriş Yap'),
          ),
        ],
      ),
    );

    if (shouldLogin != true || !context.mounted) return false;

    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );

    return isAuthenticated;
  }
}
