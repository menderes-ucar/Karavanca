import 'package:flutter/material.dart';
import '../models/category_model.dart';

class CategoryChips extends StatelessWidget {
  final List<CategoryModel> items;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  const CategoryChips({
    super.key,
    required this.items,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          if (i == 0) {
            return ChoiceChip(
              label: const Text('Tümü'),
              selected: selectedId == null,
              onSelected: (_) => onChanged(null),
            );
          }

          final cat = items[i - 1];
          return ChoiceChip(
            label: Text(cat.title),
            selected: selectedId == cat.id,
            onSelected: (_) => onChanged(cat.id),
          );
        },
      ),
    );
  }
}
