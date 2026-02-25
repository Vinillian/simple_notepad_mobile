class ApiConstants {
  // Базовый URL API.
  // По умолчанию используется адрес для эмулятора (10.0.2.2).
  // Для реального устройства задайте IP при сборке:
  // flutter run --dart-define=API_URL=http://192.168.1.135:3000/api
  // или при сборке APK:
  // flutter build apk --release --dart-define=API_URL=http://192.168.1.135:3000/api
  static const String baseUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'http://10.0.2.2:3000/api',
  );
}
