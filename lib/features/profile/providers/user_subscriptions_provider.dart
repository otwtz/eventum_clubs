import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/play_go_api_client.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../models/user_subscription.dart';

/// Абонементы текущего пользователя (GET `/api/me/subscriptions`).
final mySubscriptionsProvider =
    FutureProvider.autoDispose<List<UserSubscription>>((ref) async {
  final auth = ref.watch(authProvider);
  if (!auth.isAuthenticated) return const [];
  final token = auth.accessToken;
  final userId = auth.user?.id;
  if (token == null || token.isEmpty || userId == null || userId.isEmpty) {
    return const [];
  }
  return PlayGoApiClient().getMySubscriptions(token);
});
