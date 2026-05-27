import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../home/models/sports_club.dart';

/// Одна строка истории клубов из ответов AI (без полной модели [SportsClub]).
class AiMatchedClubHistoryEntry {
  const AiMatchedClubHistoryEntry({
    required this.id,
    required this.name,
    required this.city,
    this.imageUrl,
  });

  final String id;
  final String name;
  final String city;
  final String? imageUrl;

  factory AiMatchedClubHistoryEntry.fromSportsClub(SportsClub c) {
    return AiMatchedClubHistoryEntry(
      id: c.id,
      name: c.name,
      city: c.city,
      imageUrl: c.imageUrls.isNotEmpty ? c.imageUrls.first : null,
    );
  }

  factory AiMatchedClubHistoryEntry.fromPrefsJson(String raw) {
    final m = jsonDecode(raw) as Map<String, dynamic>;
    return AiMatchedClubHistoryEntry(
      id: m['id'] as String,
      name: m['name'] as String,
      city: (m['city'] as String?) ?? '',
      imageUrl: m['img'] as String?,
    );
  }

  String toPrefsJson() =>
      jsonEncode({'id': id, 'name': name, 'city': city, 'img': imageUrl});
}

final aiMatchedClubsHistoryProvider =
    StateNotifierProvider<
      AiMatchedClubsHistoryNotifier,
      List<AiMatchedClubHistoryEntry>
    >((ref) {
      return AiMatchedClubsHistoryNotifier();
    });

/// До 10 последних уникальных клубов из результатов подбора (persist в prefs).
class AiMatchedClubsHistoryNotifier
    extends StateNotifier<List<AiMatchedClubHistoryEntry>> {
  AiMatchedClubsHistoryNotifier() : super(const []) {
    Future.microtask(_load);
  }

  SharedPreferences get _prefs => GetIt.instance<SharedPreferences>();

  static const _key = 'ai_matched_clubs_history_v1';

  Future<void> _load() async {
    try {
      final strings = _prefs.getStringList(_key);
      if (strings == null || strings.isEmpty) {
        return;
      }
      state = strings
          .map(AiMatchedClubHistoryEntry.fromPrefsJson)
          .toList(growable: false);
    } catch (_) {}
  }

  Future<void> prependFromSearch(List<SportsClub> clubs) async {
    if (clubs.isEmpty) {
      return;
    }
    final additions = clubs
        .map(AiMatchedClubHistoryEntry.fromSportsClub)
        .toList();
    final seen = <String>{};
    final merged = <AiMatchedClubHistoryEntry>[];
    for (final e in [...additions, ...state]) {
      if (!(seen.add(e.id))) continue;
      merged.add(e);
      if (merged.length >= 10) break;
    }
    state = merged;
    try {
      await _prefs.setStringList(
        _key,
        merged.map((e) => e.toPrefsJson()).toList(),
      );
    } catch (_) {}
  }
}
