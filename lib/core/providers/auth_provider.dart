import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/auth_session_bridge.dart';
import '../api/play_go_api_client.dart';
import '../../models/user_model.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(PlayGoApiClient());
});

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._api) : super(const AuthState.unauthenticated()) {
    AuthSessionBridge.register(
      accessToken: () => state.accessToken,
      refreshAccessToken: tryRefreshTokens,
    );
    _restoreSession();
  }

  final PlayGoApiClient _api;
  SharedPreferences get _prefs => GetIt.instance<SharedPreferences>();

  Future<bool>? _tokenRefreshFuture;

  static const _keyAccessToken = 'playgo_access_token';
  static const _keyRefreshToken = 'playgo_refresh_token';
  static const _keyUserId = 'playgo_user_id';
  static const _keyUserEmail = 'playgo_user_email';
  static const _keyUserUsername = 'playgo_user_username';
  static const _keyUserFirstName = 'playgo_user_first_name';
  static const _keyUserLastName = 'playgo_user_last_name';
  static const _keyUserCity = 'playgo_user_city';
  static const _keyUserPhotoPath = 'playgo_user_photo_path';

  /// Восстанавливает сессию: сначала из локального хранилища (чтобы не вылетать из профиля),
  /// затем в фоне обновляет данные с сервера при наличии сети.
  Future<void> _restoreSession() async {
    final token = _prefs.getString(_keyAccessToken);
    if (token == null || token.isEmpty) return;

    final cachedUser = _loadCachedUser();
    if (cachedUser != null) {
      state = AuthState.authenticated(accessToken: token, user: cachedUser);
    }

    try {
      final user = await _api.getMe(token);
      final photoPath = _prefs.getString(_keyUserPhotoPath);
      final updatedUser = UserModel(
        id: user.id,
        email: user.email,
        username: user.username,
        firstName: user.firstName,
        lastName: user.lastName,
        city: user.city,
        photoPath: photoPath,
      );
      final access = state.accessToken ?? token;
      state = AuthState.authenticated(accessToken: access, user: updatedUser);
      await _saveSession(access, updatedUser);
    } on PlayGoApiException catch (e) {
      // После неудачного refresh внутри [getMe] или без refresh-токена.
      if (e.statusCode == 401) {
        await _clearStorage();
        state = const AuthState.unauthenticated();
        return;
      }
      if (cachedUser == null) {
        await _clearStorage();
        state = const AuthState.unauthenticated();
      }
    } catch (_) {
      if (cachedUser == null) {
        await _clearStorage();
        state = const AuthState.unauthenticated();
      }
    }
  }

  UserModel? _loadCachedUser() {
    final id = _prefs.getString(_keyUserId);
    final email = _prefs.getString(_keyUserEmail);
    final username = _prefs.getString(_keyUserUsername);
    final firstName = _prefs.getString(_keyUserFirstName);
    final lastName = _prefs.getString(_keyUserLastName);
    final city = _prefs.getString(_keyUserCity);
    final photoPath = _prefs.getString(_keyUserPhotoPath);
    if (email == null || username == null) return null;
    return UserModel(
      id: id ?? '',
      email: email,
      username: username,
      firstName: firstName ?? '',
      lastName: lastName ?? '',
      city: city ?? '',
      photoPath: photoPath,
    );
  }

  /// [refreshToken]: при [replaceStoredRefresh] == false — `null` не трогает prefs;
  /// непустая строка — записать; `''` — удалить.
  /// При [replaceStoredRefresh] == true (логин/регистрация): `null` или пусто — удалить refresh.
  Future<void> _saveSession(
    String token,
    UserModel user, {
    String? photoPath,
    String? refreshToken,
    bool replaceStoredRefresh = false,
  }) async {
    await _prefs.setString(_keyAccessToken, token);
    await _prefs.setString(_keyUserId, user.id);
    await _prefs.setString(_keyUserEmail, user.email);
    await _prefs.setString(_keyUserUsername, user.username);
    await _prefs.setString(_keyUserFirstName, user.firstName);
    await _prefs.setString(_keyUserLastName, user.lastName);
    await _prefs.setString(_keyUserCity, user.city);
    if (photoPath != null) {
      await _prefs.setString(_keyUserPhotoPath, photoPath);
    }
    if (replaceStoredRefresh) {
      final r = refreshToken?.trim();
      if (r != null && r.isNotEmpty) {
        await _prefs.setString(_keyRefreshToken, r);
      } else {
        await _prefs.remove(_keyRefreshToken);
      }
    } else if (refreshToken != null) {
      if (refreshToken.isEmpty) {
        await _prefs.remove(_keyRefreshToken);
      } else {
        await _prefs.setString(_keyRefreshToken, refreshToken);
      }
    }
  }

  Future<void> _clearStorage() async {
    await _prefs.remove(_keyAccessToken);
    await _prefs.remove(_keyRefreshToken);
    await _prefs.remove(_keyUserId);
    await _prefs.remove(_keyUserEmail);
    await _prefs.remove(_keyUserUsername);
    await _prefs.remove(_keyUserFirstName);
    await _prefs.remove(_keyUserLastName);
    await _prefs.remove(_keyUserCity);
    await _prefs.remove(_keyUserPhotoPath);
  }

  /// Обновление access (и при необходимости refresh) по [POST /api/auth/refresh].
  /// Параллельные вызовы сходятся в один запрос.
  Future<bool> tryRefreshTokens() {
    if (_tokenRefreshFuture != null) return _tokenRefreshFuture!;
    final future = _performTokenRefresh();
    _tokenRefreshFuture = future;
    future.whenComplete(() => _tokenRefreshFuture = null);
    return future;
  }

  Future<bool> _performTokenRefresh() async {
    final refresh = _prefs.getString(_keyRefreshToken);
    if (refresh == null || refresh.isEmpty) return false;
    try {
      final tr = await _api.refreshWithRefreshToken(refresh);
      final photoPath =
          state.user?.photoPath ?? _prefs.getString(_keyUserPhotoPath);
      UserModel user;
      try {
        user = await _api.getMe(tr.accessToken, withAuthRetry: false);
      } catch (_) {
        final cached = state.user ?? _loadCachedUser();
        if (cached == null) return false;
        user = cached;
      }
      final updatedUser = UserModel(
        id: user.id,
        email: user.email,
        username: user.username,
        firstName: user.firstName,
        lastName: user.lastName,
        city: user.city,
        photoPath: photoPath,
      );
      await _saveSession(
        tr.accessToken,
        updatedUser,
        refreshToken: tr.refreshToken,
      );
      state = AuthState.authenticated(
        accessToken: tr.accessToken,
        user: updatedUser,
      );
      return true;
    } on PlayGoApiException catch (e) {
      if (e.statusCode == 401) {
        await _prefs.remove(_keyRefreshToken);
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> register({
    required String email,
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String city,
    String? photoPath,
  }) async {
    final result = await _api.register(
      email: email,
      username: username,
      password: password,
      firstName: firstName,
      lastName: lastName,
      city: city,
    );
    final u = UserModel(
      id: result.user.id,
      email: result.user.email,
      username: result.user.username,
      firstName: result.user.firstName,
      lastName: result.user.lastName,
      city: result.user.city,
      photoPath: photoPath,
    );
    await _saveSession(
      result.accessToken,
      u,
      photoPath: photoPath,
      refreshToken: result.refreshToken,
      replaceStoredRefresh: true,
    );
    state = AuthState.authenticated(
      accessToken: result.accessToken,
      user: u,
    );
  }

  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    final result = await _api.login(identifier: identifier, password: password);
    final photoPath = _prefs.getString(_keyUserPhotoPath);
    final u = UserModel(
      id: result.user.id,
      email: result.user.email,
      username: result.user.username,
      firstName: result.user.firstName,
      lastName: result.user.lastName,
      city: result.user.city,
      photoPath: photoPath,
    );
    await _saveSession(
      result.accessToken,
      u,
      photoPath: photoPath,
      refreshToken: result.refreshToken,
      replaceStoredRefresh: true,
    );
    state = AuthState.authenticated(
      accessToken: result.accessToken,
      user: u,
    );
  }

  Future<void> logout() async {
    await _clearStorage();
    state = const AuthState.unauthenticated();
  }

  /// GET /api/me — для pull-to-refresh (главная, профиль).
  Future<void> refreshSessionUser() async {
    final token = state.accessToken;
    if (token == null || token.isEmpty) return;
    final photoPath =
        state.user?.photoPath ?? _prefs.getString(_keyUserPhotoPath);
    try {
      final user = await _api.getMe(token);
      final updatedUser = UserModel(
        id: user.id,
        email: user.email,
        username: user.username,
        firstName: user.firstName,
        lastName: user.lastName,
        city: user.city,
        photoPath: photoPath,
      );
      final access = state.accessToken ?? token;
      state = AuthState.authenticated(accessToken: access, user: updatedUser);
      await _saveSession(access, updatedUser);
    } on PlayGoApiException catch (e) {
      if (e.statusCode == 401) {
        await _clearStorage();
        state = const AuthState.unauthenticated();
      }
    } catch (_) {}
  }

  /// Обновить профиль (PATCH /api/me).
  Future<void> updateProfile({
    required String email,
    required String username,
    required String firstName,
    required String lastName,
    required String city,
  }) async {
    final token = state.accessToken;
    if (token == null || token.isEmpty) return;

    final user = await _api.updateMe(
      token,
      email: email,
      username: username,
      firstName: firstName,
      lastName: lastName,
      city: city,
    );
    final access = state.accessToken ?? token;
    state = AuthState.authenticated(
      accessToken: access,
      user: UserModel(
        id: user.id,
        email: user.email,
        username: user.username,
        firstName: user.firstName,
        lastName: user.lastName,
        city: user.city,
        photoPath: state.user?.photoPath,
      ),
    );
    await _saveSession(access, state.user!);
  }

  /// Проверка текущего пароля (POST /api/me/password/check).
  Future<void> checkPassword(String password) async {
    final token = state.accessToken;
    if (token == null || token.isEmpty) return;
    await _api.checkPassword(token, password);
  }

  /// Смена пароля (POST /api/me/password).
  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    final token = state.accessToken;
    if (token == null || token.isEmpty) return;
    await _api.changePassword(token, oldPassword: oldPassword, newPassword: newPassword);
  }
}

class AuthState {
  final bool isAuthenticated;
  final String? accessToken;
  final UserModel? user;

  const AuthState.unauthenticated()
      : isAuthenticated = false,
        accessToken = null,
        user = null;

  const AuthState.authenticated({required this.accessToken, required this.user})
      : isAuthenticated = true;
}
