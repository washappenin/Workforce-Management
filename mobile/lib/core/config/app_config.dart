class AppConfig {
  const AppConfig._();

  static const defaultApiBaseUrl =
      'https://workforce-management-production.up.railway.app';

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: defaultApiBaseUrl,
  );

  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'staging',
  );

  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';
}
