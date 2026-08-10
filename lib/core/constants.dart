class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080/api/v1',
  );
  // use this command to start the flutter with the online API based on the develop branch
  // flutter run --dart-define=API_BASE_URL=https://lullifybackend-dev.up.railway.app/api/v1
  static const Duration apiTimeout = Duration(seconds: 15);
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const int defaultPageSize = 20;
}
