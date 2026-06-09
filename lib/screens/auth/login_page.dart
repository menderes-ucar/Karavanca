import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/push_notification_service.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  SupabaseClient get supa => Supabase.instance.client;

  Future<void> _login() async {
    final email = _email.text.trim();
    final pass = _pass.text;

    if (email.isEmpty || pass.isEmpty) {
      _toast('Email ve şifre boş olamaz');
      return;
    }

    setState(() => _loading = true);
    try {
      await supa.auth.signInWithPassword(
        email: email,
        password: pass,
      );
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (_) {
      _toast('Bir hata oldu. Tekrar dene.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ✅ ARKAPLAN RESMİ (asset)
          Image.asset(
            'assets/images/lgn.png',
            fit: BoxFit.cover,
          ),

          // ✅ Okunabilirlik için overlay
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.20),
                  Colors.black.withOpacity(0.55),
                ],
              ),
            ),
          ),

          // ✅ İçerik
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 40,
                      maxWidth: 420,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const _Header(
                              title: 'Hoş geldin',
                              subtitle: 'Kamp • Karavan • Ürün',
                              icon: Icons.terrain,
                            ),
                            const SizedBox(height: 18),
                            _CardShell(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Giriş Yap',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  _Input(
                                    controller: _email,
                                    label: 'Email',
                                    hint: 'ornek@mail.com',
                                    keyboardType: TextInputType.emailAddress,
                                    prefixIcon: Icons.mail_outline,
                                  ),
                                  const SizedBox(height: 12),
                                  _Input(
                                    controller: _pass,
                                    label: 'Şifre',
                                    hint: '••••••••',
                                    prefixIcon: Icons.lock_outline,
                                    obscure: _obscure,
                                    suffix: IconButton(
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: _loading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                    ),
                                    child: _loading
                                        ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                        : const Text('Giriş Yap'),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: _loading
                                        ? null
                                        : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => const RegisterPage(),
                                        ),
                                      );
                                    },
                                    child: const Text(
                                      'Hesabın yok mu? Kayıt ol',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          height: 54,
          width: 54,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: Colors.white),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        // ✅ Kartı da transparan yaptık
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            color: Color(0x14000000),
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final TextInputType? keyboardType;
  final IconData? prefixIcon;
  final bool obscure;
  final Widget? suffix;

  const _Input({
    required this.controller,
    required this.label,
    required this.hint,
    this.keyboardType,
    this.prefixIcon,
    this.obscure = false,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        labelStyle: TextStyle(color: Colors.white.withOpacity(0.85)),
        hintStyle: TextStyle(color: Colors.white.withOpacity(0.55)),

        prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
        prefixIconColor: Colors.white.withOpacity(0.85),

        suffixIcon: suffix,
        suffixIconColor: Colors.white.withOpacity(0.85),

        filled: true,
        fillColor: Colors.white.withOpacity(0.12), // ✅ transparan

        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
          BorderSide(color: Colors.white.withOpacity(0.70), width: 1.4),
        ),
      ),
    );
  }
}
