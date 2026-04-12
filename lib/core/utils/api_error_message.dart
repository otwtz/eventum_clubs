import '../api/play_go_api_client.dart';
import '../l10n/app_localizations.dart';

/// Сообщение для пользователя из любой ошибки API/сети.
String friendlyApiError(Object error, AppLocalizations l10n) {
  if (error is PlayGoApiException) {
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

  // Карточка игрока (англ. сообщения с API)
  if (lower.contains('favoriteformat') && lower.contains('invalid')) {
    return l10n.errorFavoriteFormatInvalid;
  }
  if (lower.contains('preferredfoot') && lower.contains('invalid')) {
    return l10n.errorPreferredFootInvalid;
  }
  if (lower.contains('skilltag') &&
      (lower.contains('invalid') ||
          lower.contains('at least') ||
          lower.contains('required'))) {
    return l10n.errorStrongSidesRequired;
  }
  if (lower.contains('strong side') ||
      lower.contains('strongside') ||
      (lower.contains('strong') && lower.contains('at least'))) {
    return l10n.errorStrongSidesRequired;
  }
  if (lower.contains('status') &&
      (lower.contains('at least') || lower.contains('choose'))) {
    return l10n.errorStatusesRequired;
  }
  if (lower.contains('captain role cannot be changed')) {
    return l10n.errorCaptainRolePatch;
  }
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
