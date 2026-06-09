import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CampFavoritesService {
  static final CampFavoritesService I = CampFavoritesService._();

  CampFavoritesService._();

  final sb = Supabase.instance.client;

  final ValueNotifier<Set<String>> favoriteIds = ValueNotifier(<String>{});

  String get me => sb.auth.currentUser!.id;

  bool isFav(String id) => favoriteIds.value.contains(id);

  /// ✅ Sayfa açılınca çağır:
  /// await CampFavoritesService.I.load();
  Future<void> load() async {
    final uid = sb.auth.currentUser?.id;
    if (uid == null) {
      favoriteIds.value = <String>{};
      return;
    }

    final data = await sb
        .from('camp_favorites')
        .select('camp_id')
        .eq('user_id', uid);

    final list = (data as List).cast<Map<String, dynamic>>();
    favoriteIds.value = list.map((r) => r['camp_id'].toString()).toSet();
  }

  /// ✅ UI anında değişir, DB’ye de kaydeder.
  /// (Realtime şart değil, yenileyince silinmez.)


  Future<void> toggle(String id) async {
    final uid = sb.auth.currentUser?.id;
    if (uid == null) return;

    final s = Set<String>.from(favoriteIds.value);
    final wasFav = s.contains(id);

    // 1) UI anında güncelle
    if (wasFav) {
      s.remove(id);
    } else {
      s.add(id);
    }
    favoriteIds.value = s;

    // 2) DB yaz
    try {
      debugPrint(
          "⭐️ CAMP_FAV toggle start: uid=$uid camp_id=$id wasFav=$wasFav");

      if (wasFav) {
        final res = await sb
            .from('camp_favorites')
            .delete()
            .eq('user_id', uid)
            .eq('camp_id', id)
            .select();

        debugPrint("✅ CAMP_FAV delete OK: $res");
      } else {
        final res = await sb
            .from('camp_favorites')
            .insert({'user_id': uid, 'camp_id': id})
            .select();

        debugPrint("✅ CAMP_FAV insert OK: $res");
      }
    } catch (e) {
      debugPrint("❌ CAMP_FAV DB FAIL: $e");

      // rollback
      final rollback = Set<String>.from(favoriteIds.value);
      if (wasFav) {
        rollback.add(id);
      } else {
        rollback.remove(id);
      }
      favoriteIds.value = rollback;
    }
  }
}