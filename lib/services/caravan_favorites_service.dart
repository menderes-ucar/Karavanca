import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CaravanFavoritesService {
  final SupabaseClient _sb = Supabase.instance.client;

  final ValueNotifier<Set<String>> favoriteIds =
  ValueNotifier<Set<String>>(<String>{});

  bool _loadedOnce = false;

  Future<void> load() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) {
      favoriteIds.value = <String>{};
      _loadedOnce = true;
      return;
    }

    final data = await _sb
        .from('caravan_favorites')
        .select('caravan_id')
        .eq('user_id', uid);

    final rows = (data as List).cast<Map<String, dynamic>>();
    final ids = rows
        .map((r) => (r['caravan_id'] ?? '').toString())
        .where((x) => x.isNotEmpty)
        .toSet();

    favoriteIds.value = ids;
    _loadedOnce = true;
  }

  Future<void> toggleFavorite(String caravanId) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;

    if (!_loadedOnce) {
      await load();
    }

    final current = Set<String>.from(favoriteIds.value);
    final isFav = current.contains(caravanId);

    // ✅ UI hemen güncellensin (optimistic)
    if (isFav) {
      current.remove(caravanId);
    } else {
      current.add(caravanId);
    }
    favoriteIds.value = current;

    try {
      if (isFav) {
        await _sb
            .from('caravan_favorites')
            .delete()
            .eq('user_id', uid)
            .eq('caravan_id', caravanId);
      } else {
        await _sb.from('caravan_favorites').insert({
          'user_id': uid,
          'caravan_id': caravanId,
        });
      }
    } catch (e) {
      // ❌ DB hata verirse UI rollback
      final rollback = Set<String>.from(favoriteIds.value);
      if (isFav) {
        rollback.add(caravanId);
      } else {
        rollback.remove(caravanId);
      }
      favoriteIds.value = rollback;
      rethrow;
    }
  }

  void dispose() {
    favoriteIds.dispose();
  }
}
