import '../models/category_model.dart';

class CategoryService {
  Future<List<CategoryModel>> getCategories(ModuleType module) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _all.where((c) => c.module == module && c.parentId == null).toList();
  }

  Future<List<CategoryModel>> getSubCategories(String parentId) async {
    await Future.delayed(const Duration(milliseconds: 250));
    return _all.where((c) => c.parentId == parentId).toList();
  }

  static const List<CategoryModel> _all = [
    // CAMP
    CategoryModel(id: 'camp_sea', module: ModuleType.camp, title: 'Deniz Kenarı', iconKey: 'sea'),
    CategoryModel(id: 'camp_mountain', module: ModuleType.camp, title: 'Dağ Kampı', iconKey: 'mountain'),
    CategoryModel(id: 'camp_forest', module: ModuleType.camp, title: 'Orman', iconKey: 'forest'),
    CategoryModel(id: 'camp_lake', module: ModuleType.camp, title: 'Göl Kenarı', iconKey: 'lake'),

    // CARAVAN
    CategoryModel(id: 'caravan_motor', module: ModuleType.caravan, title: 'Motokaravan', iconKey: 'rv'),
    CategoryModel(id: 'caravan_tow', module: ModuleType.caravan, title: 'Çekme Karavan', iconKey: 'tow'),
    CategoryModel(id: 'caravan_panelvan', module: ModuleType.caravan, title: 'Panelvan Dönüşüm', iconKey: 'van'),

    // PRODUCT
    CategoryModel(id: 'prod_tent', module: ModuleType.product, title: 'Çadır', iconKey: 'tent'),
    CategoryModel(id: 'prod_sleep', module: ModuleType.product, title: 'Uyku Tulumu', iconKey: 'sleep'),
    CategoryModel(id: 'prod_cook', module: ModuleType.product, title: 'Ocak', iconKey: 'cook'),
    CategoryModel(id: 'prod_chair', module: ModuleType.product, title: 'Sandalye', iconKey: 'chair'),
  ];
}
