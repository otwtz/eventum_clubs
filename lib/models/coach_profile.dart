/// Анкета тренера (`GET/PATCH /api/coach-profiles/me`, фото в `/uploads/coaches`).
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
    if (clubRaw is Map) {
      final cm = Map<String, dynamic>.from(clubRaw);
      cid ??= cm['id']?.toString();
      cname ??= cm['name']?.toString();
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
          m['about']?.toString() ??
          m['description']?.toString() ??
          '',
      clubId: (cid != null && cid.isNotEmpty) ? cid : null,
      clubName: (cname != null && cname.isNotEmpty) ? cname : null,
      photoUrl: _readPhotoUrl(m),
      specialization: m['specialization']?.toString(),
      experienceYears: exp,
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
