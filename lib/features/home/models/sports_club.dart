class SportsClub {
  const SportsClub({
    required this.id,
    required this.name,
    required this.city,
    required this.district,
    required this.sport,
    required this.minAge,
    required this.maxAge,
    required this.address,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.imageUrls = const [],
  });

  final String id;
  final String name;
  final String city;
  final String district;
  final String sport;
  final int minAge;
  final int maxAge;
  final String address;
  final String description;
  final double latitude;
  final double longitude;
  /// Абсолютные URL фото клуба с ленты/API.
  final List<String> imageUrls;

  /// Подпись для фильтра «город / район».
  String get cityAreaLabel {
    final d = district.trim();
    if (d.isEmpty) return city;
    return '$city / $d';
  }
}
