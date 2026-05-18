/// План абонемента для клуба / вида спорта (`priceCents`, `durationDays`, опционально `clubId` / `sportId`).
class ClubPassOption {
  const ClubPassOption({
    required this.id,
    required this.title,
    this.priceCents = 0,
    this.durationDays = 0,
    this.clubId,
    this.sportId,
  });

  final String id;
  final String title;
  /// Цена в копейках.
  final int priceCents;
  /// Срок действия в днях.
  final int durationDays;
  /// Если задан — абонемент привязан к залу; иначе может быть общий на [sportId].
  final String? clubId;
  final String? sportId;
}

/// Одна строка расписания клуба (см. API `schedules`).
class ClubScheduleEntry {
  const ClubScheduleEntry({
    required this.title,
    this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.ageGroup = '',
    this.coachName = '',
    this.note = '',
  });

  final String title;
  /// 1 = понедельник … 7 = воскресенье (как в типичном backend ISO).
  final int? dayOfWeek;
  final String startTime;
  final String endTime;
  final String ageGroup;
  final String coachName;
  final String note;
}

class ClubDetails {
  const ClubDetails({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.sport,
    required this.description,
    required this.minAge,
    required this.maxAge,
    required this.latitude,
    required this.longitude,
    this.imageUrl,
    this.yandexMapsUrl,
    this.kind,
    this.coaches = const [],
    this.schedules = const [],
    this.passes = const [],
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final String sport;
  final String description;
  final int minAge;
  final int maxAge;
  final double latitude;
  final double longitude;
  final String? imageUrl;
  final String? yandexMapsUrl;
  final String? kind;
  final List<String> coaches;
  final List<ClubScheduleEntry> schedules;
  final List<ClubPassOption> passes;
}
