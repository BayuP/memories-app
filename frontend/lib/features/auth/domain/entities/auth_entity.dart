class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;

  @override
  String toString() =>
      'AuthTokens(accessToken: [redacted], refreshToken: [redacted])';
}
