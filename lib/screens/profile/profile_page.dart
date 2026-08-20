import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../constants/app_config.dart';
import '../credits/credit_history_page.dart';
import '../auth/login_page.dart';
import '../auth/register_page.dart';
import '../credits/credit_packages_page.dart';
import 'admin_hub_page.dart';
import 'legal_pages.dart';
import 'my_caravans_page.dart';
import '../products/product_my_listings_page.dart';
import '../../services/credit_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  static const Color turquoise = Color(0xFF00B8C8);
  static const Color deepTurquoise = Color(0xFF007C89);
  static const Color dark = Color(0xFF06343A);
  static const Color bg = Color(0xFFEFFBFC);
  static const Color sand = Color(0xFFFFC66B);

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool loadingProfile = true;

  String fullName = "-";
  String memberSinceText = "-";
  bool isAdmin = false;

  // ✅ YENİ: gerçek kredi bilgisi
  int credits = 0;
  final _creditService = CreditService();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => loadingProfile = true);

    try {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;

      if (uid == null) {
        setState(() {
          fullName = "-";
          memberSinceText = "-";
          isAdmin = false;
          credits = 0;
          loadingProfile = false;
        });
        return;
      }

      final row = await sb
          .from('profiles')
          .select('full_name, created_at')
          .eq('id', uid)
          .maybeSingle();

      final name = (row?['full_name'] ?? '').toString().trim();
      final createdAt = row?['created_at']?.toString();

      bool adminFlag = false;
      try {
        final r = await sb.rpc('is_admin');
        adminFlag = r == true;
      } catch (e) {
        adminFlag = false;
        debugPrint("❌ is_admin rpc error: $e");
      }

      // ✅ YENİ: gerçek kredi çekiliyor
      int creditsValue = 0;
      try {
        creditsValue = await _creditService.getMyCredits();
      } catch (e) {
        debugPrint("❌ credits fetch error: $e");
      }

      if (!mounted) return;
      setState(() {
        fullName = name.isEmpty ? "Kullanıcı" : name;
        memberSinceText = _fmtTrDate(createdAt) ?? "-";
        isAdmin = adminFlag;
        credits = creditsValue;
        loadingProfile = false;
      });
    } catch (e, st) {
      debugPrint("❌ _loadProfile ERROR: $e");
      debugPrint("$st");

      if (!mounted) return;
      setState(() => loadingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Profil bilgileri alınamadı: $e")),
      );
    }
  }

  String? _fmtTrDate(String? iso) {
    if (iso == null || iso.isEmpty) return null;
    final dt = DateTime.tryParse(iso);
    if (dt == null) return null;

    const months = [
      "Ocak",
      "Şubat",
      "Mart",
      "Nisan",
      "Mayıs",
      "Haziran",
      "Temmuz",
      "Ağustos",
      "Eylül",
      "Ekim",
      "Kasım",
      "Aralık",
    ];

    return "${dt.day} ${months[dt.month - 1]} ${dt.year}";
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
  }

  // 🗑️ HESAP SİLME FONKSİYONU
  Future<void> _deleteAccount() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
            SizedBox(width: 10),
            Text("Hesabımı Sil", style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          "Hesabınızı ve buna bağlı verilerinizi silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.",
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Vazgeç", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Evet, Hesabımı Sil", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;

      if (uid == null) return;

      // 1. Profil tablosundan veriyi sil
      await sb.from('profiles').delete().eq('id', uid);

      // 2. RPC veya yetkili delete işlemi varsa (Opsiyonel RPC)
      try {
        await sb.rpc('delete_user');
      } catch (_) {}

      // 3. Oturumu Kapat
      await sb.auth.signOut();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Hesabınız başarıyla silindi.")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hesap silinirken hata oluştu: $e")),
      );
    }
  }

  void _soon(String text) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text)),
    );
  }

  void _openAdmin() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminHubPage()),
    );
  }

  void _openCaravans() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MyCaravansPage()),
    );
  }

  void _openProducts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProductMyListingsPage()),
    );
  }

  void _openProfileInfo() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileInfoPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (Supabase.instance.client.auth.currentSession == null) {
      return _buildGuestProfile(context);
    }

    return Scaffold(
      backgroundColor: ProfilePage.bg,
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 245,
              backgroundColor: ProfilePage.deepTurquoise,
              foregroundColor: Colors.white,
              title: const Text(
                "Profil",
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
              actions: [
                if (isAdmin)
                  IconButton(
                    tooltip: "Admin Panel",
                    onPressed: _openAdmin,
                    icon: const Icon(Icons.admin_panel_settings),
                  ),
                IconButton(
                  tooltip: "Çıkış",
                  onPressed: _signOut,
                  icon: const Icon(Icons.logout),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: _hero(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 28),
                child: Column(
                  children: [
                    _quickStats(),
                    const SizedBox(height: 18),
                    _sectionTitle("Hesabım", "Karavanis üyelik ve profil işlemleri"),
                    const SizedBox(height: 10),
                    _menuCard([
                      _MenuAction(
                        icon: Icons.badge_outlined,
                        title: "Profil Bilgilerim",
                        subtitle: "Ad, üyelik ve hesap detayların",
                        color: ProfilePage.turquoise,
                        onTap: _openProfileInfo,
                      ),
                      _MenuAction(
                        icon: Icons.notifications_none,
                        title: "Bildirimler",
                        subtitle: "Mesaj ve ilan bildirim tercihleri",
                        color: Colors.orange,
                        onTap: () => _soon("Bildirim ayarları yakında aktif olacak."),
                      ),
                      _MenuAction(
                        icon: Icons.workspace_premium_outlined,
                        title: "Paket Satın Al",
                        subtitle: "İlan hakkı ve görünürlük paketleri",
                        color: Colors.purple,
                        onTap: () {
                          if (!AppConfig.isCreditSystemActive) {
                            _soon("Kredi paket sistemi yakında aktif olacaktır.");
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreditPackagesPage()),
                          );
                        },
                      ),
                      _MenuAction(
                        icon: Icons.receipt_long_outlined,
                        title: "Kredi Hareketlerim",
                        subtitle: "Kredi kazanma ve harcama geçmişin",
                        color: ProfilePage.turquoise,
                        onTap: () {
                          if (!AppConfig.isCreditSystemActive) {
                            _soon("Kredi hareketleri yakında aktif olacaktır.");
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CreditHistoryPage()),
                          );
                        },
                      ),
                      _MenuAction(
                        icon: Icons.info_outline,
                        title: "Karavanis Hakkında",
                        subtitle: "Vizyonumuz, platform mimarimiz ve ekosistemimiz",
                        color: Colors.blueGrey,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AboutPage()),
                        ),
                      ),
                      _MenuAction(
                        icon: Icons.privacy_tip_outlined,
                        title: "Gizlilik ve Veri Güvenliği",
                        subtitle: "KVKK uyumluluğu, veri işleme ve güvenlik politikaları",
                        color: Colors.indigo,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PrivacyPage()),
                        ),
                      ),
                      _MenuAction(
                        icon: Icons.article_outlined,
                        title: "Hizmet ve Kullanım Şartları",
                        subtitle: "Platform standartları, kullanıcı hakları ve taahhütler",
                        color: Colors.brown,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TermsPage()),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 18),
                    _sectionTitle("İlanlarım", "Karavan ve kamp ürünlerini yönet"),
                    const SizedBox(height: 10),
                    _menuCard([
                      _MenuAction(
                        icon: Icons.rv_hookup,
                        title: "Karavan İlanlarım",
                        subtitle: "Karavan ilanlarını görüntüle ve düzenle",
                        color: ProfilePage.deepTurquoise,
                        onTap: _openCaravans,
                      ),
                      _MenuAction(
                        icon: Icons.inventory_2_outlined,
                        title: "Ürün İlanlarım",
                        subtitle: "Kamp ürünlerini yönet",
                        color: Colors.green,
                        onTap: _openProducts,
                      ),
                    ]),
                    if (isAdmin) ...[
                      const SizedBox(height: 18),
                      _sectionTitle("Yönetim", "Admin işlemleri"),
                      const SizedBox(height: 10),
                      _adminCard(),
                    ],
                    const SizedBox(height: 18),
                    _logoutCard(),
                    const SizedBox(height: 12),
                    _deleteAccountCard(), // 🗑️ ÇIKIŞ YAPIN ALTINA EKLENEN HESAP SİLME BUTONU
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestProfile(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfilePage.bg,
      appBar: AppBar(
        title: const Text(
          'Profil',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: ProfilePage.deepTurquoise,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: Column(
              children: [
                Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    color: ProfilePage.deepTurquoise.withOpacity(.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline,
                    size: 52,
                    color: ProfilePage.deepTurquoise,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Misafir olarak devam ediyorsun',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: ProfilePage.dark,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Kamp alanlarını, karavan ilanlarını ve ürünleri giriş yapmadan inceleyebilirsin. Favori, mesaj ve ilan verme gibi hesap gerektiren işlemler için giriş yapmalısın.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.45,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                      );
                      if (mounted) setState(() {});
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ProfilePage.deepTurquoise,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Giriş Yap',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                      );
                      if (mounted) setState(() {});
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ProfilePage.deepTurquoise,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Kayıt Ol',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _hero() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ProfilePage.dark,
            ProfilePage.deepTurquoise,
            ProfilePage.turquoise,
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -42,
            top: 44,
            child: Icon(
              Icons.terrain,
              size: 170,
              color: Colors.white.withOpacity(.08),
            ),
          ),
          Positioned(
            left: -28,
            bottom: -22,
            child: Icon(
              Icons.forest,
              size: 150,
              color: Colors.white.withOpacity(.10),
            ),
          ),
          Positioned(
            right: 22,
            bottom: 22,
            child: Icon(
              Icons.rv_hookup,
              size: 78,
              color: Colors.white.withOpacity(.18),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 72, 18, 18),
              child: Row(
                children: [
                  Container(
                    width: 92,
                    height: 92,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.18),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(.35)),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 52,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: loadingProfile
                        ? const Text(
                      "Profil yükleniyor...",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 22,
                      ),
                    )
                        : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _miniPill(
                              isAdmin ? "ADMIN" : "BİREYSEL ÜYE",
                              isAdmin
                                  ? Colors.black.withOpacity(.45)
                                  : ProfilePage.sand,
                              isAdmin ? Colors.white : Colors.black,
                            ),
                            _miniPill(
                              "STANDART",
                              Colors.white.withOpacity(.18),
                              Colors.white,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_month,
                              size: 16,
                              color: Colors.white70,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "Üyelik: $memberSinceText",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniPill(String text, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withOpacity(.15)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w900,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _quickStats() {
    final items = [
      _StatItem(
        icon: Icons.credit_score,
        title: "İlan Kredisi",
        value: AppConfig.isCreditSystemActive ? credits.toString() : "Sınırsız",
        color: ProfilePage.turquoise,
      ),

      _StatItem(
        icon: Icons.verified_outlined,
        title: "Onay",
        value: "Manuel",
        color: Colors.orange,
      ),
      _StatItem(
        icon: Icons.calendar_month,
        title: "Üyelik",
        value: memberSinceText == "-" ? "-" : "Aktif",
        color: Colors.green,
      ),
    ];

    return LayoutBuilder(
      builder: (context, c) {
        final cross = c.maxWidth > 760 ? 4 : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cross,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 112,
          ),
          itemBuilder: (_, i) {
            final item = items[i];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: item.color.withOpacity(.14)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 18,
                    offset: Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: item.color.withOpacity(.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(item.icon, color: item.color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          item.value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: ProfilePage.dark,
                            fontWeight: FontWeight.w900,
                            fontSize: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionTitle(String title, String subtitle) {
    return Row(
      children: [
        Container(
          width: 5,
          height: 34,
          decoration: BoxDecoration(
            color: ProfilePage.turquoise,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: ProfilePage.dark,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 2),
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
    );
  }

  Widget _menuCard(List<_MenuAction> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _menuTile(items[i]),
            if (i != items.length - 1)
              Divider(
                height: 1,
                color: Colors.black.withOpacity(.06),
                indent: 74,
              ),
          ],
        ],
      ),
    );
  }

  Widget _menuTile(_MenuAction item) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          color: item.color.withOpacity(.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(item.icon, color: item.color),
      ),
      title: Text(
        item.title,
        style: const TextStyle(
          color: ProfilePage.dark,
          fontWeight: FontWeight.w900,
        ),
      ),
      subtitle: Text(
        item.subtitle,
        style: const TextStyle(
          color: Colors.black54,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: item.onTap,
    );
  }

  Widget _adminCard() {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: _openAdmin,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              Color(0xFF06343A),
              Color(0xFF00B8C8),
            ],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2200B8C8),
              blurRadius: 24,
              offset: Offset(0, 12),
            ),
          ],
        ),
        child: const Row(
          children: [
            Icon(Icons.admin_panel_settings, color: Colors.white, size: 34),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Admin Panel",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "İlan, kamp önerisi ve yönetim işlemleri",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _logoutCard() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: BorderSide(color: Colors.red.withOpacity(.25)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        onPressed: _signOut,
        icon: const Icon(Icons.logout),
        label: const Text(
          "Çıkış Yap",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }

  // 🗑️ HESAP SİLME BUTONU WIDGET'I
  Widget _deleteAccountCard() {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        style: TextButton.styleFrom(
          foregroundColor: Colors.red.shade700,
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        onPressed: _deleteAccount,
        icon: const Icon(Icons.delete_forever_outlined, size: 20),
        label: const Text(
          "Hesabımı Sil",
          style: TextStyle(
            fontWeight: FontWeight.w700,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

class _StatItem {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });
}

class _MenuAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MenuAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
}

class ProfileInfoPage extends StatelessWidget {
  const ProfileInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ProfilePage.bg,
      appBar: AppBar(
        backgroundColor: ProfilePage.deepTurquoise,
        foregroundColor: Colors.white,
        title: const Text("Profil Bilgilerim"),
      ),
      body: const Center(
        child: Text(
          "Burayı sonra dolduracağız 👌",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}