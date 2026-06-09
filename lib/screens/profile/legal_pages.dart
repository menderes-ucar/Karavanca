import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hakkında')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Karavanis, kamp alanlarını keşfetmek, karavan ilanlarını incelemek '
              've kamp topluluğunu bir araya getirmek amacıyla geliştirilmiş bir platformdur.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
      ),
    );
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gizlilik Politikası')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Karavanis kullanıcı verilerini üçüncü taraflara satmaz. '
              'Uygulama içerisinde kullanıcı tarafından eklenen içerikler '
              'kullanıcının sorumluluğundadır.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
      ),
    );
  }
}

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kullanım Koşulları')),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          'Karavanis içerisindeki ilan ve kamp bilgileri kullanıcılar '
              'tarafından eklenebilir. Yanlış, eksik veya güncel olmayan '
              'bilgilerden platform sorumlu tutulamaz.',
          style: TextStyle(fontSize: 15, height: 1.5),
        ),
      ),
    );
  }
}