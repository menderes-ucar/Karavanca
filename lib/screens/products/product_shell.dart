import 'package:flutter/material.dart';
import '../../services/auth_guard.dart';
import 'package:karavanis/screens/products/product_chats_page.dart';
import '../../services/product_favorites_service.dart';
import 'product_home_page.dart';
import 'product_favorites_page.dart';

class ProductShell extends StatefulWidget {
  const ProductShell({super.key});

  @override
  State<ProductShell> createState() => _ProductShellState();
}

class _ProductShellState extends State<ProductShell> {
  int _index = 0;
  final favService = ProductFavoritesService();

  // ✅ AppBar rengiyle aynı
  static const Color _primary = Color(0xFF2E7D32);

  @override
  void initState() {
    super.initState();
    favService.loadFromDb();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ProductHomePage(favoritesService: favService),
      ProductFavoritesPage(favoritesService: favService),
      const ProductChatsPage(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),

      // ✅ NavigationBar rengi burada verilir
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          backgroundColor: _primary,
          indicatorColor: Colors.white.withOpacity(0.18),
          labelTextStyle: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              );
            }
            return const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            );
          }),
          iconTheme: MaterialStateProperty.resolveWith((states) {
            if (states.contains(MaterialState.selected)) {
              return const IconThemeData(color: Colors.white);
            }
            return const IconThemeData(color: Colors.white70);
          }),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) async {
            if ((i == 1 || i == 2) && !await AuthGuard.requireAuth(context)) return;
            if (mounted) setState(() => _index = i);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.storefront_outlined),
              selectedIcon: Icon(Icons.storefront),
              label: 'Ürünler',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border),
              selectedIcon: Icon(Icons.favorite),
              label: 'Favori',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Mesaj',
            ),
          ],
        ),
      ),
    );
  }
}
