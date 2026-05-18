/// Оплаченный абонемент пользователя (см. GET `/api/admin/subscriptions`).
enum UserSubscriptionStatus {
  active,
  expired,
  cancelled;

  static UserSubscriptionStatus? tryParse(String? raw) {
    switch (raw?.trim().toUpperCase()) {
      case 'ACTIVE':
        return UserSubscriptionStatus.active;
      case 'EXPIRED':
        return UserSubscriptionStatus.expired;
      case 'CANCELLED':
        return UserSubscriptionStatus.cancelled;
      default:
        return null;
    }
  }

  String toApi() => switch (this) {
        UserSubscriptionStatus.active => 'ACTIVE',
        UserSubscriptionStatus.expired => 'EXPIRED',
        UserSubscriptionStatus.cancelled => 'CANCELLED',
      };
}

class UserSubscription {
  const UserSubscription({
    required this.id,
    required this.status,
    this.clubId,
    this.sportId,
    this.clubName = '',
    this.sportName = '',
    this.title = '',
    this.priceCents = 0,
    this.durationDays = 0,
  });

  final String id;
  final UserSubscriptionStatus status;
  final String? clubId;
  final String? sportId;
  final String clubName;
  final String sportName;
  final String title;
  final int priceCents;
  final int durationDays;

  bool get isClubScoped =>
      clubId != null && clubId!.trim().isNotEmpty;

  factory UserSubscription.fromJson(Map<String, dynamic> m) {
    final id = m['id']?.toString() ?? '';
    final status = UserSubscriptionStatus.tryParse(m['status']?.toString()) ??
        UserSubscriptionStatus.active;

    String? clubId = m['clubId']?.toString();
    String clubName = '';
    final clubRaw = m['club'];
    if (clubRaw is Map) {
      final cm = Map<String, dynamic>.from(clubRaw);
      clubId ??= cm['id']?.toString();
      clubName = cm['name']?.toString() ?? '';
    }

    String? sportId = m['sportId']?.toString();
    String sportName = '';
    final sportRaw = m['sport'];
    if (sportRaw is Map) {
      final sm = Map<String, dynamic>.from(sportRaw);
      sportId ??= sm['id']?.toString();
      sportName = sm['name']?.toString() ?? sm['code']?.toString() ?? '';
    }

    String title = m['title']?.toString() ?? '';
    int priceCents = _readInt(m['priceCents']);
    int durationDays = _readInt(m['durationDays']);

    final plan = m['subscription'] ?? m['plan'] ?? m['template'];
    if (plan is Map) {
      final pm = Map<String, dynamic>.from(plan);
      if (title.isEmpty) {
        title = pm['title']?.toString() ??
            pm['name']?.toString() ??
            pm['label']?.toString() ??
            '';
      }
      final pc = _readInt(pm['priceCents']);
      if (pc > 0) priceCents = pc;
      final dd = _readInt(pm['durationDays']);
      if (dd > 0) durationDays = dd;

      final pClub = pm['club'];
      if (pClub is Map && clubId == null) {
        final c = Map<String, dynamic>.from(pClub);
        clubId = c['id']?.toString();
        if (clubName.isEmpty) clubName = c['name']?.toString() ?? '';
      }
      final pSport = pm['sport'];
      if (pSport is Map && sportId == null) {
        final s = Map<String, dynamic>.from(pSport);
        sportId = s['id']?.toString();
        if (sportName.isEmpty) {
          sportName = s['name']?.toString() ?? s['code']?.toString() ?? '';
        }
      }
    }

    return UserSubscription(
      id: id,
      status: status,
      clubId: clubId,
      sportId: sportId,
      clubName: clubName,
      sportName: sportName,
      title: title,
      priceCents: priceCents,
      durationDays: durationDays,
    );
  }
}

int _readInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}
