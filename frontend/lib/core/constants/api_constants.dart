abstract final class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String authSignUp = '/api/v1/auth/signup';
  static const String authSignIn = '/api/v1/auth/signin';
  static const String authRefresh = '/api/v1/auth/refresh';
}
