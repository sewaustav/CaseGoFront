class AppConfig {
  static const authUrl = String.fromEnvironment(
    'AUTH_URL',
    defaultValue: 'http://localhost:8000/api/v1/auth',
  );
  static const profileUrl = String.fromEnvironment(
    'PROFILE_URL',
    defaultValue: 'http://localhost:8080/profile/api/v1',
  );
  static const caseGoUrl = String.fromEnvironment(
    'CASE_GO_URL',
    defaultValue: 'http://localhost:8081/api/v1/case_go',
  );
  static const caseProfileUrl = String.fromEnvironment(
    'CASE_PROFILE_URL',
    defaultValue: 'http://localhost:8082/api/v1/case_go',
  );
}
