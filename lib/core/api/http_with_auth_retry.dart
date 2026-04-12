import 'package:http/http.dart' as http;

import 'auth_session_bridge.dart';

Future<http.Response> sendWithAuthRetry(
  String token,
  Future<http.Response> Function(String accessToken) send,
) async {
  var response = await send(token);
  if (response.statusCode != 401) return response;
  final refreshed = await AuthSessionBridge.runRefresh();
  if (!refreshed) return response;
  final next = AuthSessionBridge.accessToken;
  if (next == null || next.isEmpty || next == token) return response;
  return send(next);
}
