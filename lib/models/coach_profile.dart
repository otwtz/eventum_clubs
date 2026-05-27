/// Анкета тренера (`GET/PATCH /api/me/coach-profile`, поиск: `GET /api/coach-profiles/search`).
class CoachProfile {
  const CoachProfile({
    required this.id,
    required this.userId,
    this.bio = '',
    this.clubId,
    this.clubName,
    this.photoUrl,
    this.specialization,
    this.experienceYears,
    this.coachFirstName = '',
    this.coachLastName = '',
    this.clubCityDisplay = '',
    this.clubSportName = '',
  });

  final String id;
  final String userId;
  final String bio;
  final String? clubId;
  final String? clubName;
  /// Относительный путь вида `/uploads/coaches/...` или полный URL.
  final String? photoUrl;
  final String? specialization;
  final int? experienceYears;
  final String coachFirstName;
  final String coachLastName;
  /// Город клуба из вложенного объекта `club` (список `/api/coach-profiles/search`).
  final String clubCityDisplay;
  final String clubSportName;

  /// Отображаемое имя тренера (анкета или вложенный `user`).
  String get trainerDisplayName {
    final direct = '$coachFirstName $coachLastName'.trim();
    if (direct.isNotEmpty) return direct;
    return '';
  }

  factory CoachProfile.fromJson(Map<String, dynamic> m) {
    String readId() =>
        m['id']?.toString() ??
        m['coachProfileId']?.toString() ??
        m['profileId']?.toString() ??
        '';

    String readUserId() {
      final u = m['user'];
      if (u is Map) {
        return Map<String, dynamic>.from(u)['id']?.toString() ?? '';
      }
      return m['userId']?.toString() ?? '';
    }

    final clubRaw = m['club'];
    String? cid = m['clubId']?.toString();
    String? cname = m['clubName']?.toString();
    String clubCity = '';
    String clubSport = '';
    if (clubRaw is Map) {
      final cm = Map<String, dynamic>.from(clubRaw);
      cid ??= cm['id']?.toString();
      cname ??= cm['name']?.toString();
      clubCity = cm['city']?.toString() ?? '';
      final sp = cm['sport'];
      if (sp is Map) {
        clubSport = Map<String, dynamic>.from(sp)['name']?.toString() ?? '';
      }
    }

    String fn = m['firstName']?.toString() ?? '';
    String ln = m['lastName']?.toString() ?? '';
    if (fn.isEmpty && ln.isEmpty) {
      final u = m['user'];
      if (u is Map) {
        final um = Map<String, dynamic>.from(u);
        fn = um['firstName']?.toString() ?? '';
        ln = um['lastName']?.toString() ?? '';
      }
    }

    int? exp;
    final e = m['experienceYears'] ?? m['yearsExperience'];
    if (e is int) exp = e;
    if (e is num) exp = e.toInt();
    exp ??= int.tryParse(e?.toString() ?? '');

    return CoachProfile(
      id: readId(),
      userId: readUserId(),
      bio: m['bio']?.toString() ??
          m['achievements']?.toString() ??
          m['about']?.toString() ??
          m['description']?.toString() ??
          '',
      clubId: (cid != null && cid.isNotEmpty) ? cid : null,
      clubName: (cname != null && cname.isNotEmpty) ? cname : null,
      photoUrl: _readPhotoUrl(m),
      specialization: m['specialization']?.toString(),
      experienceYears: exp,
      coachFirstName: fn.trim(),
      coachLastName: ln.trim(),
      clubCityDisplay: clubCity.trim(),
      clubSportName: clubSport.trim(),
    );
  }

  Map<String, dynamic> toUpsertBody() {
    final b = <String, dynamic>{
      'bio': bio,
    };
    if (clubId != null && clubId!.trim().isNotEmpty) {
      b['clubId'] = clubId!.trim();
    } else {
      b['clubId'] = null;
    }
    if (specialization != null && specialization!.trim().isNotEmpty) {
      b['specialization'] = specialization!.trim();
    }
    if (experienceYears != null) {
      b['experienceYears'] = experienceYears;
    }
    return b;
  }
}

String? _readPhotoUrl(Map<String, dynamic> m) {
  final v = m['photoUrl'] ??
      m['photo'] ??
      m['imageUrl'] ??
      m['avatarUrl'] ??
      m['portrait'];
  final s = v?.toString().trim();
  return (s == null || s.isEmpty) ? null : s;
}
