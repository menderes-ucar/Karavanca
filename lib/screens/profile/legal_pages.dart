import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const Color turquoise = Color(0xFF00B8C8);
  static const Color deepTurquoise = Color(0xFF007C89);
  static const Color dark = Color(0xFF06343A);
  static const Color bg = Color(0xFFEFFBFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: deepTurquoise,
        foregroundColor: Colors.white,
        title: const Text(
          "Karavanis Hakkında",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(
              title: "Doğayla Bağlantıda Ekosistem Mimarisi",
              subtitle: "Mobilite, Kamp ve Özgür Yaşam Platformu",
              icon: Icons.forest_outlined,
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: "Platform Vizyonu",
              content:
              "Karavanis; karavan tutkunlarını, kamp severleri, çekme karavan üreticilerini ve outdoor ekipman tedarikçilerini tek bir dijital çatıda buluşturan uçtan uca bir mobil ekosistemdir. Mimarimiz, topluluk odaklı bilgi paylaşımını yüksek güvenlikli pazar yeri standartlarıyla harmanlayarak sürdürülebilir bir mobilite deneyimi sunar.",
            ),
            _buildSection(
              title: "Teknoloji ve Güvenlik Altyapısı",
              content:
              "Platformumuz; veri doğrulama, dinamik pazar yeri algoritmaları ve yüksek performanslı bulut veritabanı mimarisi (Supabase / AWS) ile desteklenmektedir. Kullanıcılarımızın ilan güvenliği ve veri gizliliği kurumsal düzeyde korunmaktadır.",
            ),
            _buildSection(
              title: "Sürekli Gelişim ve Topluluk",
              content:
              "Sadece bir pazar yeri değil; doğada yaşam kültürünü yaygınlaştıran, rota önerileri ve onaylı kamp alanları ile doğaseverlerin seyahat planlamalarını optimize eden dinamik bir teknoloji sağlayıcısıyız.",
            ),
            const SizedBox(height: 24),
            _buildFooterInfo("Karavanis SaaS Platform Mimarisi v1.0.0"),
          ],
        ),
      ),
    );
  }
}

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  static const Color deepTurquoise = Color(0xFF007C89);
  static const Color bg = Color(0xFFEFFBFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: deepTurquoise,
        foregroundColor: Colors.white,
        title: const Text(
          "Gizlilik ve Veri Güvenliği",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(
              title: "Veri Koruma Politikası & KVKK",
              subtitle: "Kişisel Verilerin İşlenmesi ve Aydınlatma Metni",
              icon: Icons.privacy_tip_outlined,
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: "1. Toplanan Veriler ve Veri Sorumlusu",
              content:
              "Karavanis platformuna kaydolurken veya hizmetlerimizi kullanırken; ad-soyad, e-posta, telefon numarası, konum bilgileri ve ilan detayları 6698 sayılı KVKK standartlarına uygun olarak işlenmektedir. Veri sorumlusu sıfatıyla şirketimiz, verilerinizi izinsiz erişimlere karşı korumayı taahhüt eder.",
            ),
            _buildSection(
              title: "2. Verilerin İşlenme Amaçları",
              content:
              "Toplanan kişisel verileriniz; hesabınızın doğrulanması, ilan yayınlama süreçlerinin yürütülmesi, platform içi güvenlik denetimlerinin sağlanması ve kullanıcı deneyiminin kişiselleştirilmesi amaçlarıyla işlenir.",
            ),
            _buildSection(
              title: "3. Veri Güvenliği ve Üçüncü Taraflar",
              content:
              "Verileriniz, yasal zorunluluklar hariç olmak üzere kesinlikle üçüncü şahıs veya kurumlarla ticari amaçla paylaşılmaz. Tüm veri iletimleri SSL/TLS şifreleme protokolleri ile güvence altına alınır.",
            ),
            _buildSection(
              title: "4. Kullanıcı Hakları",
              content:
              "KVKK'nın 11. maddesi uyarınca dilediğiniz zaman hesabınızı silme, işlenen verileriniz hakkında bilgi talep etme ve hatalı verilerin düzeltilmesini isteme hakkına sahipsiniz.",
            ),
            const SizedBox(height: 24),
            _buildFooterInfo("Son Güncelleme: Ağustos 2026"),
          ],
        ),
      ),
    );
  }
}

class TermsPage extends StatelessWidget {
  const TermsPage({super.key});

  static const Color deepTurquoise = Color(0xFF007C89);
  static const Color bg = Color(0xFFEFFBFC);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: deepTurquoise,
        foregroundColor: Colors.white,
        title: const Text(
          "Hizmet ve Kullanım Şartları",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderCard(
              title: "Kullanım Sözleşmesi",
              subtitle: "Platform Hak ve Yükümlülükleri",
              icon: Icons.article_outlined,
            ),
            const SizedBox(height: 20),
            _buildSection(
              title: "1. Genel Hükümler ve Hizmet Kapsamı",
              content:
              "Karavanis uygulamasını indirerek ve üye olarak bu şartları kabul etmiş sayılırsınız. Karavanis, kullanıcılar arasında ilan ve bilgi paylaşımı sağlayan bir aracı hizmet sağlayıcı platformdur.",
            ),
            _buildSection(
              title: "2. İlan Yayınlama ve İçerik Sorumluluğu",
              content:
              "Yayınlanan karavan, ürün veya kamp ilanlarının doğruluğu, mülkiyet hakları ve yasal sorumluluğu tamamen ilanı oluşturan kullanıcıya aittir. Yanıltıcı, telif hakkını ihlal eden veya yasadışı içerikler tespiti halinde derhal kaldırılır ve hesap askıya alınır.",
            ),
            _buildSection(
              title: "3. Topluluk Kuralları ve UGC Güvenliği",
              content:
              "Karavanis; taciz, tehdit, nefret söylemi, cinsel içerik, dolandırıcılık, spam, yasa dışı faaliyetleri teşvik eden veya başka kişilerin haklarını ihlal eden içeriklere tolerans göstermez. Kullanıcılar uygunsuz içerikleri ve kötüye kullanan hesapları bildirebilir ve engelleyebilir. Bildirilen içerikler moderasyon sürecine alınır; gerekli durumlarda içerik kaldırılır ve hesap askıya alınabilir veya kapatılabilir.",
            ),
            _buildSection(
              title: "4. İçerik Filtreleme ve Moderasyon",
              content:
              "Platform, mesajlar ve kullanıcı tarafından oluşturulan içerikler için otomatik ve manuel güvenlik kontrolleri kullanabilir. Kullanıcılar tarafından yapılan bildirimler makul şekilde ve gecikmeden incelenir. Objectionable veya abusive içerik tespit edildiğinde kaldırma, erişimi kısıtlama ve hesap kapatma dahil gerekli işlemler uygulanır.",
            ),
            _buildSection(
              title: "5. Kullanıcı Engelleme ve Bildirme",
              content:
              "Kullanıcılar başka bir kullanıcıyı engelleyebilir. Engellenen kullanıcıyla ilgili içerik ve iletişim, engelleyen kullanıcının deneyiminden çıkarılır. Engelleme aynı zamanda moderasyon ekibine kötüye kullanım sinyali sağlar. Kullanıcılar belirli bir içerik veya mesajı neden belirterek bildirebilir.",
            ),
            _buildSection(
              title: "6. Fikri Mülkiyet Hakları",
              content:
              "Platform bünyesinde yer alan tüm yazılım, tasarım, marka, logo ve veritabanı hakları Karavanis'e aittir. İzinsiz kopyalanamaz, çoğaltılamaz ve tersine mühendislik işlemlerine tabi tutulamaz.",
            ),
            _buildSection(
              title: "7. Hizmet Değişiklikleri ve Fesih",
              content:
              "Karavanis, platformun işleyişini, modüllerini veya kullanım şartlarını önceden bildirmek kaydıyla güncelleme hakkını saklı tutar. Kullanım şartlarına aykırı davranan hesaplar tek taraflı olarak kapatılabilir.",
            ),
            const SizedBox(height: 24),
            _buildFooterInfo("Yürürlük Tarihi: Ağustos 2026"),
          ],
        ),
      ),
    );
  }
}

// 📌 Ortak UI Bileşenleri
Widget _buildHeaderCard({
  required String title,
  required String subtitle,
  required IconData icon,
}) {
  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F000000),
          blurRadius: 15,
          offset: Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFF00B8C8).withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: const Color(0xFF007C89), size: 28),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFF06343A),
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildSection({required String title, required String content}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 18),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF06343A),
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              color: Colors.black,
              height: 1.5,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}

Widget _buildFooterInfo(String text) {
  return Center(
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.black38,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}