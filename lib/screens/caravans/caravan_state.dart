import 'package:flutter/foundation.dart';

class CaravanState {
  /// Kategori filtresi
  final ValueNotifier<String?> selectedCategory = ValueNotifier<String?>(null);
  final ValueNotifier<String?> selectedSubCategory = ValueNotifier<String?>(null);

  /// Favoriler
  final ValueNotifier<Set<String>> favoriteIds = ValueNotifier<Set<String>>(<String>{});

  void setCategory(String? category, {String? subCategory}) {
    selectedCategory.value = category;
    selectedSubCategory.value = subCategory;
  }

  bool isFavorite(String id) => favoriteIds.value.contains(id);

  void toggleFavorite(String id) {
    final set = Set<String>.from(favoriteIds.value);
    if (set.contains(id)) {
      set.remove(id);
    } else {
      set.add(id);
    }
    favoriteIds.value = set;
  }

  void dispose() {
    selectedCategory.dispose();
    selectedSubCategory.dispose();
    favoriteIds.dispose();
  }
}
