import 'package:flutter/material.dart';

class CaravanSideMenu extends StatelessWidget {
  final void Function(String? categoryId) onSelectCategory;
  final VoidCallback onClear;

  const CaravanSideMenu({
    super.key,
    required this.onSelectCategory,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    void select(String? id) {
      onSelectCategory(id);
      Navigator.pop(context);
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Color(0xfff2b233)),
            child: Text(
              "KARAVANİS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.clear),
            title: const Text("Tüm Kategoriler"),
            onTap: () {
              onClear();
              Navigator.pop(context);
            },
          ),
          const Divider(),

          ExpansionTile(
            title: const Text("Karavan"),
            childrenPadding: const EdgeInsets.only(left: 16),
            children: [
              ListTile(
                title: const Text("Moto Karavan"),
                onTap: () => select("car_motor"),
              ),
              ListTile(
                title: const Text("Çekme Karavan"),
                onTap: () => select("car_tow"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
