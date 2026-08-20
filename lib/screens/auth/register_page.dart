import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../profile/legal_pages.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();

  final _email = TextEditingController();
  final _pass = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  bool _termsAccepted = false;

  SupabaseClient get supa => Supabase.instance.client;

  Future<void> _register() async {
    final firstName = _firstName.text.trim();
    final lastName = _lastName.text.trim();
    final email = _email.text.trim();
    final pass = _pass.text;

    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || pass.isEmpty) {
      _toast('Ad, soyad, email ve şifre zorunlu');
      return;
    }

    if (pass.length < 6) {
      _toast('Şifre en az 6 karakter olsun');
      return;
    }

    if (!_termsAccepted) {
      _toast('Kullanım Koşulları ve Topluluk Kuralları kabul edilmelidir.');
      return;
    }

    setState(() => _loading = true);

    try {
      await supa.auth.signUp(
        email: email,
        password: pass,
        data: {
          'first_name': firstName,
          'last_name': lastName,
          'full_name': '$firstName $lastName',
          'terms_accepted_at': DateTime.now().toUtc().toIso8601String(),
          'terms_version': '2026-08',
        },
      );

      _toast('Kayıt tamam. Giriş ekranına yönlendiriyorum.');
      if (mounted) Navigator.pop(context);
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
    _firstName.dispose();
    _lastName.dispose();
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Kayıt Ol'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/rgstr.png',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.20),
                  Colors.black.withOpacity(0.60),
                ],
              ),
            ),
          ),
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
                            Text(
                              'Yeni Hesap',
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _CardShell(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _Input(
                                    controller: _firstName,
                                    label: 'Ad',
                                    hint: '',
                                    prefixIcon: Icons.person_outline,
                                  ),
                                  const SizedBox(height: 12),
                                  _Input(
                                    controller: _lastName,
                                    label: 'Soyad',
                                    hint: '',
                                    prefixIcon: Icons.badge_outlined,
                                  ),
                                  const SizedBox(height: 12),
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
                                    hint: 'en az 6 karakter',
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
                                  const SizedBox(height: 12),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: _termsAccepted,
                                        onChanged: _loading
                                            ? null
                                            : (value) => setState(() => _termsAccepted = value ?? false),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(top: 11),
                                          child: Wrap(
                                            children: [
                                              const Text(
                                                'Kullanım Koşulları ve Topluluk Kuralları’nı okudum ve kabul ediyorum.',
                                                style: TextStyle(color: Colors.white, height: 1.35),
                                              ),
                                              TextButton(
                                                onPressed: _loading
                                                    ? null
                                                    : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsPage())),
                                                child: const Text('Koşulları Gör'),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ElevatedButton(
                                    onPressed: _loading ? null : _register,
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
                                        : const Text('Kayıt Ol'),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Kayıt olunca profiles otomatik oluşacak (trigger).',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
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

class _CardShell extends StatelessWidget {
  final Widget child;
  const _CardShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
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
        fillColor: Colors.white.withOpacity(0.12),
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
