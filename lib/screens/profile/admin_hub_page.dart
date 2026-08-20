import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'admin_camps_page.dart';
import 'admin_report_page.dart';
import 'admin_suggestions_page.dart';
import 'admin_caravans_page.dart';
import 'admin_products_page.dart';
import 'admin_credits_page.dart';

class AdminHubPage extends StatefulWidget {
  const AdminHubPage({super.key});

  @override
  State<AdminHubPage> createState() => _AdminHubPageState();
}

class _AdminHubPageState extends State<AdminHubPage> {
  bool loading = true;
  bool allowed = false;

  @override
  void initState() {
    super.initState();
    _guard();
  }

  Future<void> _guard() async {
    try {
      final sb = Supabase.instance.client;
      final uid = sb.auth.currentUser?.id;

      if (uid == null) {
        allowed = false;
      } else {
        final r = await sb.rpc('is_admin'); // ✅ en sağlam kontrol
        allowed = (r == true);
      }
    } catch (_) {
      allowed = false;
    }

    if (!mounted) return;

    if (!allowed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erişim yok.")),
      );
      Navigator.pop(context);
      return;
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Admin Panel")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.park),
            title: const Text("Kamp Önerileri"),
            subtitle: const Text("Pending önerileri gör ve approve et"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminSuggestionsPage()),
              );
            },

          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.cabin),
            title: const Text("Kamp Alanları"),
            subtitle: const Text("Yayındaki kamp alanlarını aktif/pasif yap veya sil"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminCampsPage()),
              );
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.rv_hookup),
            title: const Text("Karavan İlanları"),
            subtitle: const Text("Pending ilanları gör ve approve et"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminCaravansPage()),
              );
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.shopping_bag_outlined),
            title: const Text("Ürün İlanları"),
            subtitle: const Text("Pending ürünleri gör, approve et, aktif/pasif yap"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminProductsPage()),
              );
            },
          ),
          const SizedBox(height: 10),
          // ✅ YENİ: Kredi Yönetimi
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('UGC Moderasyon'),
            subtitle: const Text('Kullanıcı raporları, içerik bildirimleri ve moderasyon'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminReportsPage()));
            },
          ),
          const SizedBox(height: 10),
          ListTile(
            leading: const Icon(Icons.credit_score),
            title: const Text("Kredi Yönetimi"),
            subtitle: const Text("Kullanıcılara manuel kredi yükle / düş"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminCreditsPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}