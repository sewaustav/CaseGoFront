class AppConfig {
  static const authUrl = String.fromEnvironment(
    'AUTH_URL',
    defaultValue: '/api/v1/auth',
  );
  static const profileUrl = String.fromEnvironment(
    'PROFILE_URL',
    defaultValue: '/profile/api/v1',
  );
  static const caseGoUrl = String.fromEnvironment(
    'CASE_GO_URL',
    defaultValue: '/api/v1/case_go',
  );
  static const caseProfileUrl = String.fromEnvironment(
    'CASE_PROFILE_URL',
    defaultValue: '/api/v1/case_profile',
  );
}
