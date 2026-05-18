import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/play_go_api_client.dart';
import '../../../core/providers/auth_provider.dart';

/// Ответ GET `/api/ecosystem` (структура на стороне сервера).
final ecosystemSnapshotProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final auth = ref.watch(authProvider);
  final token = auth.accessToken;
  if (!auth.isAuthenticated || token == null || token.isEmpty) {
    return {};
  }
  try {
    return await PlayGoApiClient().getEcosystem(token);
  } catch (_) {
    return {};
  }
});
