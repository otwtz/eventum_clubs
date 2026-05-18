import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sports_clubs_repository.dart';
import '../models/club_details.dart';
import '../models/sports_club.dart';

final sportsClubsRepositoryProvider = Provider<SportsClubsRepository>((ref) {
  return SportsClubsRepository();
});

final sportsClubsFeedProvider = FutureProvider<List<SportsClub>>((ref) {
  final repository = ref.read(sportsClubsRepositoryProvider);
  return repository.fetchAvailableClubs();
});

final clubDetailProvider =
    FutureProvider.family<ClubDetails, String>((ref, id) {
  return ref.read(sportsClubsRepositoryProvider).fetchClubById(id);
});
