import 'package:flutter/material.dart';
import 'package:karavanis/screens/camps/suggest_camp_page.dart';

import '../../models/category_model.dart';
import '../../models/filter_models.dart';
import '../../widgets/widgets/filter_sheet.dart';
import 'camp_home_page.dart';
import 'bookings_page.dart';
import 'favorites_page.dart';

class CampShell extends StatefulWidget {
  const CampShell({super.key});

  @override
  State<CampShell> createState() => _CampShellState();
}

class _CampShellState extends State<CampShell> {
  int _index = 0;

  ListingFilter _filter = const ListingFilter();

  Future<void> _openFilter() async {
    final res = await showModalBottomSheet<ListingFilter>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => FilterSheet(
        module: ModuleType.camp,
        initial: _filter,
      ),
    );

    if (res != null && mounted) {
      setState(() => _filter = res);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CampHomePage(filter: _filter),
      const FavoritesPage(),
    ];

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(
              index: _index,
              children: pages,
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF2E7D32),
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
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
        ],
      ),
    );
  }
}
