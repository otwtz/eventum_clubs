import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteClubIdsNotifier extends StateNotifier<Set<String>> {
  FavoriteClubIdsNotifier() : super(<String>{}) {
    Future.microtask(_loadFromPrefs);
  }

  SharedPreferences get _prefs => GetIt.instance<SharedPreferences>();

  static const _key = 'favorite_club_ids';

  Future<void> _loadFromPrefs() async {
    try {
      final list = _prefs.getStringList(_key);
      if (list != null && list.isNotEmpty) {
        state = {...list};
      }
    } catch (_) {}
  }

  bool containsId(String clubId) => state.contains(clubId);

  Future<void> toggle(String clubId) async {
    if (clubId.trim().isEmpty) return;
    final next = Set<String>.from(state);
    if (next.contains(clubId)) {
      next.remove(clubId);
    } else {
      next.add(clubId);
    }
    state = next;
    final sorted = next.toList()..sort();
    await _prefs.setStringList(_key, sorted);
  }
}

final favoriteClubIdsProvider =
    StateNotifierProvider<FavoriteClubIdsNotifier, Set<String>>((ref) {
  return FavoriteClubIdsNotifier();
});
