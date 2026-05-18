import '../api/play_go_api_client.dart';
import '../l10n/app_localizations.dart';

/// Сообщение для пользователя из любой ошибки API/сети.
String friendlyApiError(Object error, AppLocalizations l10n) {
  if (error is PlayGoApiException) {
    if (error.statusCode == 403) {
      final m = error.message.trim();
      if (m.isNotEmpty && RegExp(r'[а-яА-ЯёЁ]').hasMatch(m)) return m;
      return l10n.errorAccountBlocked;
    }
    return userFriendlyServerMessage(error.message, l10n);
  }
  final s = error.toString().toLowerCase();
  if (s.contains('connection refused') ||
      s.contains('socketexception') ||
      s.contains('failed host lookup') ||
      s.contains('network is unreachable') ||
      s.contains('timed out') ||
      s.contains('timeout')) {
    return l10n.apiConnectionFailed;
  }
  return l10n.genericNetworkError;
}

/// Текст ошибки с бэкенда → понятный пользователю (с учётом языка приложения).
String userFriendlyServerMessage(String? raw, AppLocalizations l10n) {
  final t = raw?.trim() ?? '';
  if (t.isEmpty) return l10n.errorServerTryAgain;

  // Сообщение уже на русском — показываем как есть
  if (RegExp(r'[а-яА-ЯёЁ]').hasMatch(t)) return t;

  final lower = t.toLowerCase();

  if (lower.contains('validation') || lower.contains('bad request')) {
    return l10n.errorValidation;
  }

  // Авторизация
  if (lower.contains('unauthorized') ||
      lower == '401' ||
      lower.contains('invalid token') ||
      lower.contains('jwt')) {
    return l10n.errorUnauthorized;
  }
  if (lower.contains('auth required')) {
    return l10n.subscriptionAdminEndpointDenied;
  }
  if (lower.contains('forbidden') ||
      lower == '403' ||
      lower.contains('blocked') ||
      lower.contains('banned')) {
    return l10n.errorAccountBlocked;
  }
  if (lower.contains('invalid credentials') ||
      lower.contains('wrong password') ||
      lower.contains('invalid password')) {
    return l10n.errorInvalidCredentials;
  }
  if (lower.contains('email') && (lower.contains('taken') || lower.contains('exists'))) {
    return l10n.errorEmailTaken;
  }
  if (lower.contains('username') && (lower.contains('taken') || lower.contains('exists'))) {
    return l10n.errorUsernameTaken;
  }
  if (lower.contains('conflict') || lower.contains('409')) {
    return l10n.errorConflict;
  }

  // Короткое англ. сообщение — не дублируем длинный технический текст
  if (t.length <= 120 && !t.contains('{') && !t.contains('stack')) {
    return t;
  }

  return l10n.errorServerTryAgain;
}
