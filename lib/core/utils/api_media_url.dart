import '../config/api_config.dart';

/// Полный URL для путей вида `/uploads/...` с того же хоста, что и API.
String? absoluteBackendMediaUrl(String? raw) {
  final s = raw?.trim() ?? '';
  if (s.isEmpty) return null;
  if (s.startsWith('http://') || s.startsWith('https://')) return s;
  if (s.startsWith('//')) return 'https:$s';
  final base = ApiConfig.baseUrl.replaceAll(RegExp(r'/+$'), '');
  final path = s.startsWith('/') ? s : '/$s';
  return '$base$path';
}
