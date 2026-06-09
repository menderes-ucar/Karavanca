import 'package:flutter/material.dart';
import '../../services/caravan_favorites_service.dart';
import 'caravan_list_page.dart';
import 'caravan_favorites_page.dart';
import 'caravan_chats_page.dart';

class CaravanShellPage extends StatefulWidget {
  const CaravanShellPage({super.key});

  @override
  State<CaravanShellPage> createState() => _CaravanShellPageState();
}

class _CaravanShellPageState extends State<CaravanShellPage> {
  int index = 0;

  final CaravanFavoritesService favoritesService = CaravanFavoritesService();

  @override
  void initState() {
    super.initState();
    favoritesService.load();
  }

  @override
  void dispose() {
    favoritesService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CaravanListPage(favoritesService: favoritesService),
      CaravanFavoritesPage(favoritesService: favoritesService),
      const CaravanChatsPage(),
      const _CaravanProfilePlaceholder(),
    ];

    return Scaffold(
      body: IndexedStack(index: index, children: pages),

      // ✅ CampShell ile aynı sistem
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF2E7D32),
        selectedIndex: index,
        onDestinationSelected: (i) => setState(() => index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Ana',
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
    );
  }
}

class _CaravanProfilePlaceholder extends StatelessWidget {
  const _CaravanProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil")),
      body: const Center(child: Text("Profil sayfası sonra bağlanacak.")),
    );
  }
}
