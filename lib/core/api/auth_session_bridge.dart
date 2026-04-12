/// Мост между `AuthNotifier` и HTTP-слоем: при 401 вызывается обновление токена.
///
/// Регистрация выполняется в конструкторе `AuthNotifier` (`auth_provider.dart`).
class AuthSessionBridge {
  AuthSessionBridge._();

  static String? Function()? _accessToken;
  static Future<bool> Function()? _refresh;

  static void register({
    required String? Function() accessToken,
    required Future<bool> Function() refreshAccessToken,
  }) {
    _accessToken = accessToken;
    _refresh = refreshAccessToken;
  }

  static String? get accessToken => _accessToken?.call();

  /// Параллельные 401 сходятся в один refresh (см. `AuthNotifier.tryRefreshTokens`).
  static Future<bool> runRefresh() async {
    final f = _refresh;
    if (f == null) return false;
    return f();
  }
}
