import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductFavoritesService {
  final SupabaseClient _sb = Supabase.instance.client;

  /// UI bunu dinliyor (sen zaten kullanıyorsun)
  final ValueNotifier<Set<String>> favoriteIds = ValueNotifier<Set<String>>({});

  /// DB’den favorileri çek
  Future<void> loadFromDb() async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) {
      favoriteIds.value = {};
      return;
    }

    final rows = await _sb
        .from('product_favorites')
        .select('product_id')
        .eq('user_id', uid);

    final ids = <String>{};
    for (final r in rows as List) {
      final pid = r['product_id'];
      if (pid != null) ids.add(pid.toString());
    }

    favoriteIds.value = ids;
  }

  /// Favori toggle: varsa sil, yoksa ekle (DB + local)
  Future<void> toggleFavorite(String productId) async {
    final uid = _sb.auth.currentUser?.id;
    if (uid == null) return;

    final current = Set<String>.from(favoriteIds.value);
    final isFav = current.contains(productId);

    // ✅ Optimistic UI (anında değişsin)
    if (isFav) {
      current.remove(productId);
    } else {
      current.add(productId);
    }
    favoriteIds.value = current;

    try {
      if (isFav) {
        await _sb
            .from('product_favorites')
            .delete()
            .eq('user_id', uid)
            .eq('product_id', productId);
      } else {
        await _sb.from('product_favorites').insert({
          'user_id': uid,
          'product_id': productId,
        });
      }
    } catch (e) {
      // ❌ DB hata verirse geri al
      final rollback = Set<String>.from(favoriteIds.value);
      if (isFav) {
        rollback.add(productId);
      } else {
        rollback.remove(productId);
      }
      favoriteIds.value = rollback;

      if (kDebugMode) {
        debugPrint("❌ toggleFavorite DB ERROR: $e");
      }
    }
  }

  /// (Opsiyonel) çıkış yapınca temizle
  void clearLocal() {
    favoriteIds.value = {};
  }
}
