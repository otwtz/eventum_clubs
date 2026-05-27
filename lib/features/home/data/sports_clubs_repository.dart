import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/api/play_go_api_client.dart';
import '../../../core/config/api_config.dart';
import '../../../core/utils/api_media_url.dart';
import '../models/club_details.dart';
import '../models/sports_club.dart';

class SportsClubsRepository {
  SportsClubsRepository({http.Client? httpClient})
      : _client = httpClient ?? http.Client();

  final http.Client _client;

  Future<List<SportsClub>> fetchAvailableClubs() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/clubs');
    final r = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    if (r.statusCode != 200) {
      String message = 'Ошибка ${r.statusCode}';
      try {
        final body = jsonDecode(r.body);
        if (body is Map) {
          message = body['message']?.toString() ??
              body['error']?.toString() ??
              body['msg']?.toString() ??
              message;
        }
      } catch (_) {}
      throw PlayGoApiException(r.statusCode, message);
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(r.body);
    } catch (_) {
      throw PlayGoApiException(r.statusCode, 'Некорректный JSON ответа /api/clubs');
    }

    final rawList = _decodeClubList(decoded);
    return rawList.map((e) {
      if (e is! Map) {
        throw PlayGoApiException(500, 'Ожидался объект клуба в списке');
      }
      return _parseClub(Map<String, dynamic>.from(e));
    }).toList();
  }

  /// `GET /api/clubs` с фильтрами (город, вид спорта, возраст) — как в ecosystem.
  Future<List<SportsClub>> fetchClubsFiltered({
    String? city,
    String? sportCode,
    int? age,
  }) async {
    final q = <String, String>{};
    final c = city?.trim() ?? '';
    if (c.isNotEmpty) q['city'] = c;
    final sc = sportCode?.trim() ?? '';
    if (sc.isNotEmpty) q['sportCode'] = sc;
    if (age != null && age > 0) q['age'] = '$age';

    final uri = Uri.parse('${ApiConfig.baseUrl}/api/clubs')
        .replace(queryParameters: q.isEmpty ? null : q);
    final r = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    if (r.statusCode != 200) {
      String message = 'Ошибка ${r.statusCode}';
      try {
        final body = jsonDecode(r.body);
        if (body is Map) {
          message = body['message']?.toString() ??
              body['error']?.toString() ??
              body['msg']?.toString() ??
              message;
        }
      } catch (_) {}
      throw PlayGoApiException(r.statusCode, message);
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(r.body);
    } catch (_) {
      throw PlayGoApiException(r.statusCode, 'Некорректный JSON ответа /api/clubs');
    }

    final rawList = _decodeClubList(decoded);
    return rawList.map((e) {
      if (e is! Map) {
        throw PlayGoApiException(500, 'Ожидался объект клуба в списке');
      }
      return _parseClub(Map<String, dynamic>.from(e));
    }).toList();
  }

  Future<ClubDetails> fetchClubById(String id) async {
    final encoded = Uri.encodeComponent(id);
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/clubs/$encoded');
    final r = await _client
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 20));

    if (r.statusCode != 200) {
      String message = 'Ошибка ${r.statusCode}';
      try {
        final body = jsonDecode(r.body);
        if (body is Map) {
          message = body['message']?.toString() ??
              body['error']?.toString() ??
              body['msg']?.toString() ??
              message;
        }
      } catch (_) {}
      throw PlayGoApiException(r.statusCode, message);
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(r.body);
    } catch (_) {
      throw PlayGoApiException(r.statusCode, 'Некорректный JSON ответа /api/clubs/:id');
    }
    if (decoded is! Map) {
      throw PlayGoApiException(r.statusCode, 'Ожидался объект клуба');
    }
    return _parseClubDetails(Map<String, dynamic>.from(decoded));
  }

  ClubDetails _parseClubDetails(Map<String, dynamic> m) {
    final id = m['id']?.toString() ?? '';
    final name = m['name']?.toString() ?? '';
    final address = m['address']?.toString() ?? '';
    final description = m['description']?.toString() ?? '';

    final city = _parseCity(m);
    final sport = _parseSport(m);

    final minAge = _parseInt(m['minAge']) ?? 0;
    final maxAge = _parseInt(m['maxAge']) ?? 99;

    final lat = _parseDouble(m['latitude']);
    final lon = _parseDouble(m['longitude']);

    final coachesRaw = m['coaches'];
    final coaches = <String>[];
    if (coachesRaw is List) {
      for (final c in coachesRaw) {
        final s = _parseCoachDisplayName(c);
        if (s.isNotEmpty) coaches.add(s);
      }
    }

    final schedulesRaw = m['schedules'];
    final schedules = <ClubScheduleEntry>[];
    if (schedulesRaw is List) {
      for (final s in schedulesRaw) {
        if (s is! Map) continue;
        final sm = Map<String, dynamic>.from(s);
        schedules.add(
          ClubScheduleEntry(
            title: sm['title']?.toString() ?? '',
            dayOfWeek: _parseInt(sm['dayOfWeek']),
            startTime: sm['startTime']?.toString() ?? '',
            endTime: sm['endTime']?.toString() ?? '',
            ageGroup: sm['ageGroup']?.toString() ?? '',
            coachName: sm['coachName']?.toString() ?? '',
            note: sm['note']?.toString() ?? '',
          ),
        );
      }
    }

    final passes = _parseClubPasses(m);

    return ClubDetails(
      id: id.isEmpty ? name : id,
      name: name.isEmpty ? address : name,
      address: address,
      city: city,
      sport: sport.isEmpty ? '—' : sport,
      description: description,
      minAge: minAge,
      maxAge: maxAge,
      latitude: lat,
      longitude: lon,
      imageUrl: m['imageUrl']?.toString(),
      yandexMapsUrl: m['yandexMapsUrl']?.toString(),
      kind: m['kind']?.toString(),
      coaches: coaches,
      schedules: schedules,
      passes: passes,
    );
  }

  List<ClubPassOption> _parseClubPasses(Map<String, dynamic> m) {
    dynamic raw = m['subscriptions'] ??
        m['passes'] ??
        m['membershipPlans'] ??
        m['memberships'];
    if (raw is! List) return const [];

    final out = <ClubPassOption>[];
    for (var i = 0; i < raw.length; i++) {
      final item = raw[i];
      if (item is! Map) continue;
      final pm = Map<String, dynamic>.from(item);

      String title = pm['title']?.toString() ??
          pm['name']?.toString() ??
          pm['label']?.toString() ??
          '';

      int priceCents = _parseInt(pm['priceCents']) ?? 0;
      int durationDays = _parseInt(pm['durationDays']) ?? 0;
      String? clubId = pm['clubId']?.toString();
      if (clubId != null && clubId.isEmpty) clubId = null;
      String? sportId = pm['sportId']?.toString();
      if (sportId != null && sportId.isEmpty) sportId = null;

      final nested = pm['subscription'] ?? pm['plan'] ?? pm['template'];
      if (nested is Map) {
        final nm = Map<String, dynamic>.from(nested);
        if (title.isEmpty) {
          title = nm['title']?.toString() ??
              nm['name']?.toString() ??
              nm['label']?.toString() ??
              '';
        }
        final pc = _parseInt(nm['priceCents']);
        if (pc != null && pc > 0) priceCents = pc;
        final dd = _parseInt(nm['durationDays']);
        if (dd != null && dd > 0) durationDays = dd;
        if (clubId == null) {
          final c = nm['clubId']?.toString();
          clubId = (c != null && c.isNotEmpty) ? c : null;
          if (clubId == null && nm['club'] is Map) {
            clubId = (nm['club'] as Map)['id']?.toString();
          }
        }
        if (sportId == null) {
          final s = nm['sportId']?.toString();
          sportId = (s != null && s.isNotEmpty) ? s : null;
          if (sportId == null && nm['sport'] is Map) {
            sportId = (nm['sport'] as Map)['id']?.toString();
          }
        }
      }

      if (clubId == null && pm['club'] is Map) {
        clubId = (pm['club'] as Map)['id']?.toString();
      }
      if (sportId == null && pm['sport'] is Map) {
        sportId = (pm['sport'] as Map)['id']?.toString();
      }

      var id = pm['id']?.toString() ?? '';
      if (id.isEmpty) id = 'pass_$i';

      if (title.isEmpty) continue;

      out.add(
        ClubPassOption(
          id: id,
          title: title,
          priceCents: priceCents,
          durationDays: durationDays,
          clubId: clubId,
          sportId: sportId,
        ),
      );
    }
    return out;
  }

  List<dynamic> _decodeClubList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      for (final key in ['data', 'items', 'clubs', 'results']) {
        final v = decoded[key];
        if (v is List) return v;
      }
    }
    return const [];
  }

  SportsClub _parseClub(Map<String, dynamic> m) {
    final id = m['id']?.toString() ?? '';
    final name = m['name']?.toString() ?? '';
    final address = m['address']?.toString() ?? '';
    final description = m['description']?.toString() ?? '';
    final district = m['district']?.toString() ?? '';

    final city = _parseCity(m);
    final sport = _parseSport(m);

    final minAge = _parseInt(m['minAge']) ?? 0;
    final maxAge = _parseInt(m['maxAge']) ?? 99;

    final lat = _parseDouble(m['latitude']);
    final lon = _parseDouble(m['longitude']);

    return SportsClub(
      id: id.isEmpty ? name : id,
      name: name.isEmpty ? address : name,
      city: city,
      district: district,
      sport: sport.isEmpty ? '—' : sport,
      minAge: minAge,
      maxAge: maxAge,
      address: address,
      description: description,
      latitude: lat,
      longitude: lon,
      imageUrls: _parseClubImageUrls(m),
    );
  }

  /// URL фото клуба из разных схем API (список, объекты, одиночное поле).
  List<String> _parseClubImageUrls(Map<String, dynamic> m) {
    final ordered = <String>[];
    final seen = <String>{};

    void addRaw(String? raw) {
      final u = absoluteBackendMediaUrl(raw);
      if (u == null || u.isEmpty || seen.contains(u)) return;
      seen.add(u);
      ordered.add(u);
    }

    addRaw(m['imageUrl']?.toString());
    addRaw(m['photoUrl']?.toString());
    addRaw(m['coverUrl']?.toString());

    const listKeys = <String>[
      'images',
      'photos',
      'gallery',
      'attachments',
      'imageUrls',
      'photoUrls',
    ];
    for (final key in listKeys) {
      final rawList = m[key];
      if (rawList is! List) continue;
      for (final item in rawList) {
        if (item is String) {
          addRaw(item);
        } else if (item is Map) {
          final im = Map<String, dynamic>.from(item);
          addRaw(im['url']?.toString() ?? im['src']?.toString() ?? im['path']?.toString());
        }
      }
    }

    return ordered;
  }

  String _parseCity(Map<String, dynamic> m) {
    final c = m['city'];
    if (c is Map) {
      return c['name']?.toString() ?? c['title']?.toString() ?? '';
    }
    return c?.toString() ?? '';
  }

  String _parseSport(Map<String, dynamic> m) {
    final s = m['sport'];
    if (s is Map) {
      return s['name']?.toString() ?? s['code']?.toString() ?? '';
    }
    return m['sportCode']?.toString() ??
        m['sportName']?.toString() ??
        '';
  }

  int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  double _parseDouble(dynamic v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0;
  }

  /// Строка тренера: имя или объект (CoachProfile, user, …).
  String _parseCoachDisplayName(dynamic c) {
    if (c == null) return '';
    if (c is String) return c.trim();
    if (c is Map) {
      final cm = Map<String, dynamic>.from(c);
      final name = cm['name']?.toString().trim();
      if (name != null && name.isNotEmpty) return name;
      final fullName = '${cm['firstName'] ?? ''} ${cm['lastName'] ?? ''}'.trim();
      if (fullName.isNotEmpty) return fullName;
      final uRaw = cm['user'];
      if (uRaw is Map) {
        final u = Map<String, dynamic>.from(uRaw);
        final uName = '${u['firstName'] ?? ''} ${u['lastName'] ?? ''}'.trim();
        if (uName.isNotEmpty) return uName;
        final un = u['username']?.toString().trim();
        if (un != null && un.isNotEmpty) return un;
      }
      final spec = cm['specialization']?.toString().trim();
      if (spec != null && spec.isNotEmpty) return spec;
    }
    return c.toString().trim();
  }
}
