import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../../models/user_model.dart';
import 'auth_session_bridge.dart';

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

  Future<http.Response> _sendWithAuthRetry(
    String token,
    Future<http.Response> Function(String accessToken) send,
  ) async {
    var response = await send(token);
    if (response.statusCode != 401) return response;
    final refreshed = await AuthSessionBridge.runRefresh();
    if (!refreshed) return response;
    final next = AuthSessionBridge.accessToken;
    if (next == null || next.isEmpty || next == token) return response;
    return send(next);
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
      refreshToken: _parseOptionalRefreshToken(data),
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
      refreshToken: _parseOptionalRefreshToken(data),
    );
  }

  /// POST /api/auth/refresh — новая пара токенов по refresh (EVENTUM).
  ///
  /// Тело: `{ "refreshToken": "..." }`. Ответ: `{ "accessToken", "refreshToken"? }`.
  Future<TokenRefreshResult> refreshWithRefreshToken(String refreshToken) async {
    final r = await _client
        .post(
          Uri.parse('$_baseUrl/api/auth/refresh'),
          headers: _jsonHeaders(),
          body: jsonEncode({'refreshToken': refreshToken}),
        )
        .timeout(const Duration(seconds: 15));

    if (r.statusCode != 200) _throwFromResponse(r);

    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final access = data['accessToken']?.toString() ?? '';
    if (access.isEmpty) {
      throw PlayGoApiException(r.statusCode, 'Нет accessToken в ответе refresh');
    }
    return TokenRefreshResult(
      accessToken: access,
      refreshToken: _parseOptionalRefreshToken(data),
    );
  }

  /// GET /api/me — профиль текущего пользователя.
  ///
  /// [withAuthRetry]: при `false` не повторять запрос после refresh (избегает рекурсии из [AuthNotifier]).
  Future<UserModel> getMe(String token, {bool withAuthRetry = true}) async {
    Future<http.Response> send(String t) => _client
        .get(
          Uri.parse('$_baseUrl/api/me'),
          headers: _jsonHeaders(token: t),
        )
        .timeout(const Duration(seconds: 10));

    final r = withAuthRetry ? await _sendWithAuthRetry(token, send) : await send(token);

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

    Future<http.Response> send(String t) => _client
        .patch(
          Uri.parse('$_baseUrl/api/me'),
          headers: _jsonHeaders(token: t),
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 10));

    final r = await _sendWithAuthRetry(token, send);

    if (r.statusCode != 200) _throwFromResponse(r);

    final data = jsonDecode(r.body) as Map<String, dynamic>;
    final userMap = _extractUserMap(data);
    if (userMap == null) throw PlayGoApiException(r.statusCode, 'Нет user в ответе');
    return _userFromMap(userMap);
  }

  /// POST /api/me/password/check — проверка текущего пароля. 204 при успехе.
  Future<void> checkPassword(String token, String password) async {
    Future<http.Response> send(String t) => _client
        .post(
          Uri.parse('$_baseUrl/api/me/password/check'),
          headers: _jsonHeaders(token: t),
          body: jsonEncode({'password': password}),
        )
        .timeout(const Duration(seconds: 10));

    final r = await _sendWithAuthRetry(token, send);

    if (r.statusCode != 204) _throwFromResponse(r);
  }

  /// POST /api/me/password — смена пароля.
  Future<void> changePassword(
    String token, {
    required String oldPassword,
    required String newPassword,
  }) async {
    Future<http.Response> send(String t) => _client
        .post(
          Uri.parse('$_baseUrl/api/me/password'),
          headers: _jsonHeaders(token: t),
          body: jsonEncode({
            'oldPassword': oldPassword,
            'newPassword': newPassword,
          }),
        )
        .timeout(const Duration(seconds: 10));

    final r = await _sendWithAuthRetry(token, send);

    if (r.statusCode != 200) _throwFromResponse(r);
  }

  String? _parseOptionalRefreshToken(Map<String, dynamic> data) {
    final direct = data['refreshToken'] ?? data['refresh_token'];
    final s1 = direct?.toString();
    if (s1 != null && s1.isNotEmpty) return s1;
    final tokens = data['tokens'];
    if (tokens is Map) {
      final t = tokens['refreshToken'] ?? tokens['refresh_token'];
      final s2 = t?.toString();
      if (s2 != null && s2.isNotEmpty) return s2;
    }
    return null;
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
  final String? refreshToken;

  AuthResult({
    required this.accessToken,
    required this.user,
    this.refreshToken,
  });
}

class TokenRefreshResult {
  final String accessToken;
  final String? refreshToken;

  TokenRefreshResult({required this.accessToken, this.refreshToken});
}
