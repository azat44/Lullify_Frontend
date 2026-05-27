class AppConstants {
  AppConstants._();

  static const String apiBaseUrl = 'http://localhost:8080/api/v1';
  static const Duration apiTimeout = Duration(seconds: 15);
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const int defaultPageSize = 20;
}
