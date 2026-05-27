import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../../models/user_model.dart';
import '../../models/user_subscription.dart';
import '../../models/coach_profile.dart';

/// Клиент EVENTUM API: auth (`/api/auth/*`), профиль (`/api/me`), пароль.
class PlayGoApiClient {
  PlayGoApiClient() : _baseUrl = ApiConfig.baseUrl;

  final String _baseUrl;
  final _client = http.Client();

  Map<String, String> _jsonHeaders({String? token}) {
    final h = {'Content-Type': 'application/json', 'Accept': 'application/json'};
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  void _throwFromResponse(http.Response response) {
    final code = response.statusCode;
    String message = 'Ошибка $code';
    try {
      final body = jsonDecode(response.body);
      if (body is Map) {
        message = body['message']?.toString() ??
            body['error']?.toString() ??
            body['msg']?.toString() ??
            message;
      }
    } catch (_) {}
    throw PlayGoApiException(code, message);
  }

  /// Тело `{ "coachProfile": { ... } }` от `/api/me/coach-profile`.
  Map<String, dynamic>? _unwrapCoachProfileMap(Map<String, dynamic> decoded) {
    if (!decoded.containsKey('coachProfile')) return null;
    final inner = decoded['coachProfile'];
    if (inner == null) return null;
    if (inner is Map<String, dynamic>) return Map<String, dynamic>.from(inner);
    if (inner is Map) return Map<String, dynamic>.from(inner);
    return null;
  }

  /// GET /api/health
  Future<bool> health() async {
    try {
      final r = await _client
          .get(Uri.parse('$_baseUrl/api/health'))
          .timeout(const Duration(seconds: 5));
      return r.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// POST /api/auth/register
  /// 201: { accessToken, user: { id, email, username, firstName, lastName, city } }
  Future<AuthResult> register({
    required String email,
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String city,
  }) async {
    final r = await _client.post(
      Uri.parse('$_baseUrl/api/auth/register'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'email': email,
        'username': username,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'city': city,
      }),
    ).timeout(const Duration(seconds: 15));

    if (r.statusCode != 201) _throwFromResponse(r);

    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final token = data['accessToken']?.toString() ?? '';
    final userMap = _extractUserMap(data);
    if (userMap == null) throw PlayGoApiException(r.statusCode, 'Нет user в ответе');
    return AuthResult(
      accessToken: token,
      user: _userFromMap(userMap),
    );
  }

  /// POST /api/auth/login
  /// Body: { "identifier": "email|username", "password": "..." }
  /// 200: { accessToken, user }
  Future<AuthResult> login({
    required String identifier,
    required String password,
  }) async {
    final r = await _client.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: _jsonHeaders(),
      body: jsonEncode({
        'identifier': identifier,
        'password': password,
      }),
    ).timeout(const Duration(seconds: 15));

    if (r.statusCode != 200) _throwFromResponse(r);

    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final token = data['accessToken']?.toString() ?? '';
    final userMap = _extractUserMap(data);
    if (userMap == null) throw PlayGoApiException(r.statusCode, 'Нет user в ответе');
    return AuthResult(
      accessToken: token,
      user: _userFromMap(userMap),
    );
  }

  /// GET /api/me — профиль текущего пользователя.
  Future<UserModel> getMe(String token) async {
    final r = await _client
        .get(
          Uri.parse('$_baseUrl/api/me'),
          headers: _jsonHeaders(token: token),
        )
        .timeout(const Duration(seconds: 10));

    if (r.statusCode != 200) _throwFromResponse(r);

    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final userMap = _extractUserMap(data);
    if (userMap == null) throw PlayGoApiException(r.statusCode, 'Нет user в ответе');
    return _userFromMap(userMap);
  }

  /// PATCH /api/me — обновить профиль (поля регистрации + email).
  Future<UserModel> updateMe(
    String token, {
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    required String city,
  }) async {
    final body = <String, dynamic>{
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'city': city,
    };
    final u = username.trim();
    if (u.isNotEmpty) {
      body['username'] = u;
    }

    final r = await _client
        .patch(
          Uri.parse('$_baseUrl/api/me'),
          headers: _jsonHeaders(token: token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    if (r.statusCode != 200) _throwFromResponse(r);

    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final userMap = _extractUserMap(data);
    if (userMap == null) throw PlayGoApiException(r.statusCode, 'Нет user в ответе');
    return _userFromMap(userMap);
  }

  /// POST /api/me/password/check — проверка текущего пароля. 204 при успехе.
  Future<void> checkPassword(String token, String password) async {
    final r = await _client
        .post(
          Uri.parse('$_baseUrl/api/me/password/check'),
          headers: _jsonHeaders(token: token),
          body: jsonEncode({'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    if (r.statusCode != 204) _throwFromResponse(r);
  }

  /// POST /api/me/password — смена пароля.
  Future<void> changePassword(
    String token, {
    required String oldPassword,
    required String newPassword,
  }) async {
    final r = await _client
        .post(
          Uri.parse('$_baseUrl/api/me/password'),
          headers: _jsonHeaders(token: token),
          body: jsonEncode({
            'oldPassword': oldPassword,
            'newPassword': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 10));

    if (r.statusCode != 200) _throwFromResponse(r);
  }

  /// DELETE /api/me — удаление аккаунта пользователя (безвозвратно, каскады на сервере).
  ///
  /// Некоторые развёртывания требуют подтверждение пароля: [password].
  Future<void> deleteMe(
    String token, {
    String? password,
  }) async {
    final uri = Uri.parse('$_baseUrl/api/me');
    final headers = Map<String, String>.from(_jsonHeaders(token: token));
    Object? body;
    if (password != null && password.isNotEmpty) {
      body = jsonEncode({'password': password.trim()});
      headers.putIfAbsent('Content-Type', () => 'application/json');
    }

    final r = await _client
        .delete(uri, headers: headers, body: body)
        .timeout(const Duration(seconds: 45));

    if (r.statusCode != 200 && r.statusCode != 204) {
      _throwFromResponse(r);
    }
  }

  /// GET `/api/me/coach-profile` — анкета в поле `coachProfile` или отсутствует.
  Future<CoachProfile?> getMyCoachProfile(String token) async {
    final r = await _client
        .get(
          Uri.parse('$_baseUrl/api/me/coach-profile'),
          headers: _jsonHeaders(token: token),
        )
        .timeout(const Duration(seconds: 15));

    if (r.statusCode == 404) return null;
    if (r.statusCode != 200) _throwFromResponse(r);

    dynamic decoded;
    try {
      decoded = jsonDecode(r.body);
    } catch (_) {
      throw PlayGoApiException(r.statusCode, 'Некорректный JSON coach profile');
    }
    if (decoded is! Map) {
      throw PlayGoApiException(r.statusCode, 'Ожидался объект coach profile');
    }
    final map = Map<String, dynamic>.from(decoded);
    final unwrapped = _unwrapCoachProfileMap(map);
    if (unwrapped != null) return CoachProfile.fromJson(unwrapped);
    if (map['id'] != null || map['userId'] != null) {
      return CoachProfile.fromJson(map);
    }
    return null;
  }

  /// PUT `/api/me/coach-profile` — создать/обновить анкету.
  Future<CoachProfile> upsertMyCoachProfile(
    String token,
    Map<String, dynamic> body,
  ) async {
    final r = await _client
        .put(
          Uri.parse('$_baseUrl/api/me/coach-profile'),
          headers: _jsonHeaders(token: token),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 20));

    if (r.statusCode != 200 && r.statusCode != 201 && r.statusCode != 204) {
      _throwFromResponse(r);
    }

    if ((r.body).trim().isEmpty || r.body.trim() == 'null') {
      final again = await getMyCoachProfile(token);
      return again ??
          CoachProfile(
            id: '',
            userId: '',
            bio: '',
            clubId: body['clubId']?.toString(),
          );
    }

    final decoded = jsonDecode(r.body);
    final extracted = decoded is Map
        ? _unwrapCoachProfileMap(Map<String, dynamic>.from(decoded))
        : null;
    if (extracted != null) {
      return CoachProfile.fromJson(extracted);
    }
    if (decoded is Map<String, dynamic>) {
      return CoachProfile.fromJson(Map<String, dynamic>.from(decoded));
    }
    final again = await getMyCoachProfile(token);
    return again ??
        CoachProfile(id: '', userId: '', bio: '');
  }

  /// POST multipart `/api/me/coach-profile/photo` — имя файлового поля на сервере: `file`.
  ///
  /// Возвращает относительный путь загрузки (например `/uploads/coaches/...`), если есть в теле ответа.
  Future<String?> uploadCoachProfilePhoto(
    String token,
    List<int> imageBytes,
    String filename,
  ) async {
    final uri = Uri.parse('$_baseUrl/api/me/coach-profile/photo');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.headers['Accept'] = 'application/json';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename,
      ),
    );

    final streamed = await request.send().timeout(const Duration(seconds: 60));
    final r = await http.Response.fromStream(streamed);

    if (r.statusCode != 200 && r.statusCode != 201) _throwFromResponse(r);

    if (r.body.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(r.body);
      if (decoded is Map) {
        final m = Map<String, dynamic>.from(decoded);
        return m['photoUrl']?.toString() ??
            m['url']?.toString() ??
            m['path']?.toString();
      }
    } catch (_) {}
    return null;
  }

  /// Публичный спортивный справочник: `GET /api/sports`.
  Future<List<({String code, String name})>> fetchSports() async {
    final r = await _client
        .get(Uri.parse('$_baseUrl/api/sports'), headers: _jsonHeaders())
        .timeout(const Duration(seconds: 15));
    if (r.statusCode != 200) _throwFromResponse(r);
    dynamic decoded;
    try {
      decoded = jsonDecode(r.body);
    } catch (_) {
      return const [];
    }
    if (decoded is! List) return const [];
    final out = <({String code, String name})>[];
    for (final e in decoded) {
      if (e is! Map) continue;
      final m = Map<String, dynamic>.from(e);
      final code = m['code']?.toString() ?? '';
      final name = m['name']?.toString() ?? '';
      if (code.isEmpty && name.isEmpty) continue;
      out.add((code: code, name: name.isEmpty ? code : name));
    }
    return out;
  }

  /// Карточки тренеров по городу клуба: `GET /api/coach-profiles/search`.
  Future<List<CoachProfile>> searchCoachProfilesPublic({
    String? cityName,
    String? cityId,
    String? sportCode,
    int limit = 24,
  }) async {
    final q = <String, String>{
      if (cityName != null && cityName.trim().isNotEmpty)
        'city': cityName.trim(),
      if (cityId != null && cityId.trim().isNotEmpty)
        'cityId': cityId.trim(),
      if (sportCode != null && sportCode.trim().isNotEmpty)
        'sportCode': sportCode.trim(),
      'limit': '${limit.clamp(1, 50)}',
    };
    final uri =
        Uri.parse('$_baseUrl/api/coach-profiles/search').replace(
      queryParameters: q.isEmpty ? null : q,
    );
    final r = await _client
        .get(uri, headers: _jsonHeaders())
        .timeout(const Duration(seconds: 20));
    if (r.statusCode != 200) _throwFromResponse(r);
    dynamic decoded;
    try {
      decoded = jsonDecode(r.body);
    } catch (_) {
      throw PlayGoApiException(
        r.statusCode,
        'Некорректный JSON поиска тренеров',
      );
    }
    if (decoded is! Map) return const [];
    final raw = decoded['coaches'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => CoachProfile.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  /// GET `/api/ecosystem` — агрегат экосистемы (структура задаётся сервером).
  ///
  /// Требует Bearer там, где бэкенд закрывает маршрут.
  Future<Map<String, dynamic>> getEcosystem(String token) async {
    final r = await _client
        .get(
          Uri.parse('$_baseUrl/api/ecosystem'),
          headers: _jsonHeaders(token: token),
        )
        .timeout(const Duration(seconds: 15));

    if (r.statusCode == 404) return {};
    if (r.statusCode != 200) _throwFromResponse(r);

    dynamic decoded;
    try {
      decoded = jsonDecode(r.body);
    } catch (_) {
      return {};
    }
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
    return {};
  }

  /// GET /api/me/subscriptions — абонементы текущего пользователя (не админ).
  Future<List<UserSubscription>> getMySubscriptions(String token) async {
    final r = await _client
        .get(
          Uri.parse('$_baseUrl/api/me/subscriptions'),
          headers: _jsonHeaders(token: token),
        )
        .timeout(const Duration(seconds: 20));

    if (r.statusCode != 200) _throwFromResponse(r);

    return _subscriptionsFromResponseBody(r.statusCode, r.body);
  }

  /// GET /api/admin/subscriptions — список абонементов (фильтры в query).
  Future<List<UserSubscription>> getAdminSubscriptions(
    String token, {
    String? sportId,
    String? clubId,
    String? userId,
    UserSubscriptionStatus? status,
  }) async {
    final q = <String, String>{};
    if (sportId != null && sportId.isNotEmpty) q['sportId'] = sportId;
    if (clubId != null && clubId.isNotEmpty) q['clubId'] = clubId;
    if (userId != null && userId.isNotEmpty) q['userId'] = userId;
    if (status != null) q['status'] = status.toApi();

    final uri = Uri.parse('$_baseUrl/api/admin/subscriptions')
        .replace(queryParameters: q.isEmpty ? null : q);

    final r = await _client
        .get(uri, headers: _jsonHeaders(token: token))
        .timeout(const Duration(seconds: 20));

    if (r.statusCode != 200) _throwFromResponse(r);

    return _subscriptionsFromResponseBody(r.statusCode, r.body);
  }

  List<UserSubscription> _subscriptionsFromResponseBody(
    int statusCode,
    String body,
  ) {
    dynamic decoded;
    try {
      decoded = jsonDecode(body);
    } catch (_) {
      throw PlayGoApiException(
        statusCode,
        'Некорректный JSON ответа subscriptions',
      );
    }
    final rawList = _decodeSubscriptionList(decoded);
    return rawList.map((e) {
      if (e is! Map) {
        throw PlayGoApiException(500, 'Ожидался объект абонемента в списке');
      }
      return UserSubscription.fromJson(Map<String, dynamic>.from(e));
    }).toList();
  }

  /// PATCH /api/admin/subscriptions/:id/status — смена статуса (ACTIVE, EXPIRED, CANCELLED).
  Future<void> patchAdminSubscriptionStatus(
    String token,
    String subscriptionId, {
    required UserSubscriptionStatus status,
  }) async {
    final encoded = Uri.encodeComponent(subscriptionId);
    final r = await _client
        .patch(
          Uri.parse('$_baseUrl/api/admin/subscriptions/$encoded/status'),
          headers: _jsonHeaders(token: token),
          body: jsonEncode({'status': status.toApi()}),
        )
        .timeout(const Duration(seconds: 15));

    if (r.statusCode != 200 && r.statusCode != 204) _throwFromResponse(r);
  }

  List<dynamic> _decodeSubscriptionList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      for (final key in ['data', 'items', 'subscriptions', 'results']) {
        final v = decoded[key];
        if (v is List) return v;
      }
    }
    return const [];
  }

  bool _parseBlocked(Map<String, dynamic> map) {
    final v = map['isBlocked'] ?? map['blocked'] ?? map['is_blocked'];
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    final rest = map['restrictions'];
    if (rest is Map) {
      final b = rest['isBlocked'] ?? rest['blocked'];
      if (b is bool) return b;
    }
    return false;
  }

  /// Ответ может быть `{ user: {...} }` или плоский объект пользователя.
  Map<String, dynamic>? _extractUserMap(Map<String, dynamic> data) {
    final nested = data['user'];
    if (nested is Map<String, dynamic>) return nested;
    if (data.containsKey('email') || data.containsKey('username')) {
      return data;
    }
    return null;
  }

  UserModel _userFromMap(Map<String, dynamic> map) {
    final cityVal = map['city'];
    String cityStr;
    if (cityVal is Map) {
      cityStr = cityVal['name']?.toString() ?? cityVal['title']?.toString() ?? '';
    } else {
      cityStr = cityVal?.toString() ?? '';
    }
    return UserModel(
      id: map['id']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      firstName: map['firstName']?.toString() ?? '',
      lastName: map['lastName']?.toString() ?? '',
      city: cityStr,
      photoPath: null,
      isBlocked: _parseBlocked(map),
    );
  }
}

class PlayGoApiException implements Exception {
  final int statusCode;
  final String message;
  PlayGoApiException(this.statusCode, this.message);
  @override
  String toString() => message;
}

class AuthResult {
  final String accessToken;
  final UserModel user;

  AuthResult({
    required this.accessToken,
    required this.user,
  });
}
