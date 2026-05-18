import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/play_go_api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../models/coach_profile.dart';

/// Анкета тренера: `GET /api/coach-profiles/me`.
final myCoachProfileProvider =
    FutureProvider.autoDispose<CoachProfile?>((ref) async {
  final auth = ref.watch(authProvider);
  final token = auth.accessToken;
  if (!auth.isAuthenticated || token == null || token.isEmpty) {
    return null;
  }
  return PlayGoApiClient().getMyCoachProfile(token);
});
