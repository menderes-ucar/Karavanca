enum ModuleType { camp, caravan, product }

class CategoryModel {
  final String id;
  final ModuleType module;
  final String title;
  final String? parentId; // alt kategori için
  final String iconKey;   // ui'da icon map edeceğiz

  const CategoryModel({
    required this.id,
    required this.module,
    required this.title,
    required this.iconKey,
    this.parentId,
  });
}
