import 'package:flutter/material.dart';

import 'camps/camp_shell.dart';
import 'caravans/caravan_shell_page.dart';
import 'products/product_shell.dart';
import 'profile/profile_page.dart';

class MainShell extends StatelessWidget {
  final int initialIndex;

  const MainShell({
    super.key,
    this.initialIndex = 0,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      initialIndex: initialIndex,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(76),
          child: AppBar(
            toolbarHeight: 0,
            automaticallyImplyLeading: false,
            titleSpacing: 0,
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Kamp', icon: Icon(Icons.park)),
                Tab(text: 'Karavan', icon: Icon(Icons.rv_hookup)),
                Tab(text: 'Ürün', icon: Icon(Icons.shopping_bag)),
                Tab(text: 'Profil', icon: Icon(Icons.person)),
              ],
            ),
          ),
        ),
        body: const TabBarView(
          physics: NeverScrollableScrollPhysics(),
          children: [
            CampShell(),
            CaravanShellPage(),
            ProductShell(),
            ProfilePage(),
          ],
        ),
      ),
    );
  }
}