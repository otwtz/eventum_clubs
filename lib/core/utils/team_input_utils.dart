// Валидация ввода для команд и приглашений.

abstract final class TeamInputUtils {
  /// Простая проверка email (для выбора поля `email` vs `login` в API).
  static bool looksLikeEmail(String s) {
    final t = s.trim();
    if (t.length < 5) return false;
    final at = t.indexOf('@');
    if (at <= 0 || at == t.length - 1) return false;
    final dot = t.lastIndexOf('.');
    return dot > at + 1 && dot < t.length - 1;
  }

  static bool isValidTeamName(String name) {
    final t = name.trim();
    return t.length >= 2 && t.length <= 120;
  }

  static bool isValidLoginOrInvite(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return false;
    if (looksLikeEmail(t)) return true;
    // никнейм: без пробелов, длина как у логина на сервере (сервер довалидирует)
    if (t.contains(RegExp(r'\s'))) return false;
    return t.length >= 2 && t.length <= 64;
  }

  /// Никнейм (не email) — для профиля и регистрации.
  static bool isValidUsername(String raw) {
    final t = raw.trim();
    if (t.isEmpty) return false;
    if (looksLikeEmail(t)) return false;
    return isValidLoginOrInvite(t);
  }
}
