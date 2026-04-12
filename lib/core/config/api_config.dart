/// Базовый URL EVENTUM API (см. docs/EVENTUM_IMPLEMENTATION_PHASES.md).
/// Локально по умолчанию порт `4000`. На устройстве: IP хоста с бэкендом.
/// Пример: `flutter run --dart-define=API_BASE_URL=http://192.168.1.5:4000`
class ApiConfig {
  ApiConfig._();

  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:4000',
  );
}
