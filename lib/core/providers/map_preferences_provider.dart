import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_provider.dart';

/// Сохранённая позиция карты (центр + зум) для "часто посещаемых" областей.
class SavedMapPosition {
  final double lat;
  final double lon;
  final double zoom;

  const SavedMapPosition({required this.lat, required this.lon, required this.zoom});

  Map<String, dynamic> toJson() => {'lat': lat, 'lon': lon, 'zoom': zoom};

  factory SavedMapPosition.fromJson(Map<String, dynamic> json) {
    return SavedMapPosition(
      lat: (json['lat'] as num?)?.toDouble() ?? 55.7558,
      lon: (json['lon'] as num?)?.toDouble() ?? 37.6173,
      zoom: (json['zoom'] as num?)?.toDouble() ?? 10.0,
    );
  }
}

/// Локальное хранилище настроек карты: последняя позиция, область проживания (город пользователя), частые области.
class MapPreferencesNotifier extends StateNotifier<SavedMapPosition?> {
  MapPreferencesNotifier() : super(null) {
    _load();
  }

  SharedPreferences get _prefs => GetIt.instance<SharedPreferences>();

  static const _keyLastPosition = 'map_last_position';
  static const _keyFrequentRegions = 'map_frequent_regions';
  static const _maxFrequentRegions = 20;

  Future<void> _load() async {
    final json = _prefs.getString(_keyLastPosition);
    if (json != null) {
      try {
        state = SavedMapPosition.fromJson(Map<String, dynamic>.from(jsonDecode(json)));
      } catch (_) {}
    }
  }

  Future<void> savePosition(double lat, double lon, double zoom) async {
    state = SavedMapPosition(lat: lat, lon: lon, zoom: zoom);
    await _prefs.setString(_keyLastPosition, jsonEncode(state!.toJson()));
  }

  Future<void> addFrequentRegion(double lat, double lon, double zoom) async {
    final list = getFrequentRegions();
    list.removeWhere((e) => (e.lat - lat).abs() < 0.01 && (e.lon - lon).abs() < 0.01);
    list.insert(0, SavedMapPosition(lat: lat, lon: lon, zoom: zoom));
    if (list.length > _maxFrequentRegions) list.length = _maxFrequentRegions;
    await _prefs.setString(_keyFrequentRegions, jsonEncode(list.map((e) => e.toJson()).toList()));
  }

  List<SavedMapPosition> getFrequentRegions() {
    final json = _prefs.getString(_keyFrequentRegions);
    if (json == null) return [];
    try {
      final list = jsonDecode(json) as List<dynamic>;
      return list.map((e) => SavedMapPosition.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (_) {
      return [];
    }
  }
}

final mapPreferencesProvider = StateNotifierProvider<MapPreferencesNotifier, SavedMapPosition?>((ref) {
  return MapPreferencesNotifier();
});

/// Область проживания пользователя (город) — из профиля; центр карты по умолчанию берём отсюда.
final userResidenceCityProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).user?.city;
});
