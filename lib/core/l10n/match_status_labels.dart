class MatchStatusLabels {
  MatchStatusLabels._();

  static const _ru = <String, String>{
    'OPEN': 'Открыт набор',
    'CLOSED': 'Закрыт',
    'FULL': 'Мест нет',
    'SCHEDULED': 'Запланирован',
    'UPCOMING': 'Скоро',
    'LIVE': 'Идёт сейчас',
    'IN_PROGRESS': 'В процессе',
    'ONGOING': 'В процессе',
    'FINISHED': 'Завершён',
    'COMPLETED': 'Завершён',
    'CANCELLED': 'Отменён',
    'CANCELED': 'Отменён',
    'POSTPONED': 'Перенесён',
    'DRAFT': 'Черновик',
    'PUBLISHED': 'Опубликован',
    'ACTIVE': 'Активен',
    'PENDING': 'Ожидает',
    'REGISTRATION_OPEN': 'Регистрация открыта',
    'REGISTRATION_CLOSED': 'Регистрация закрыта',
    'WAITING': 'Ожидание',
    'CONFIRMED': 'Подтверждён',
  };

  static const _en = <String, String>{
    'OPEN': 'Open for registration',
    'CLOSED': 'Closed',
    'FULL': 'Full',
    'SCHEDULED': 'Scheduled',
    'UPCOMING': 'Upcoming',
    'LIVE': 'Live',
    'IN_PROGRESS': 'In progress',
    'ONGOING': 'In progress',
    'FINISHED': 'Finished',
    'COMPLETED': 'Completed',
    'CANCELLED': 'Cancelled',
    'CANCELED': 'Canceled',
    'POSTPONED': 'Postponed',
    'DRAFT': 'Draft',
    'PUBLISHED': 'Published',
    'ACTIVE': 'Active',
    'PENDING': 'Pending',
    'REGISTRATION_OPEN': 'Registration open',
    'REGISTRATION_CLOSED': 'Registration closed',
    'WAITING': 'Waiting',
    'CONFIRMED': 'Confirmed',
  };

  static String readable(String raw, String languageCode) {
    final t = raw.trim();
    if (t.isEmpty) return '—';
    final key = t.toUpperCase().replaceAll(RegExp(r'[\s\-]+'), '_');
    final map = languageCode == 'ru' ? _ru : _en;
    if (map.containsKey(key)) return map[key]!;
    if (key.contains('_')) {
      return key
          .split('_')
          .where((w) => w.isNotEmpty)
          .map(
            (w) =>
                '${w[0].toUpperCase()}${w.length > 1 ? w.substring(1).toLowerCase() : ''}',
          )
          .join(' ');
    }
    return t[0].toUpperCase() + (t.length > 1 ? t.substring(1).toLowerCase() : '');
  }
}
