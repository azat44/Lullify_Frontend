class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://lullify.up.railway.app/api/v1',
  );
  // flutter run --dart-define=API_BASE_URL=https://lullifybackend-dev.up.railway.app/api/v1
  // flutter run (uses Railway prod API by default)
  static const Duration apiTimeout = Duration(seconds: 15);
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const int defaultPageSize = 20;
}
