class AppConfig {
  static const String baseUrl = 'backend_url';

  static const String devBaseUrl = 'http://localhost:3000/api';

  static const String androidEmulatorUrl = 'http://10.0.2.2:3000/api';

  static const String iosSimulatorUrl = 'http://localhost:3000/api';

  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String profileEndpoint = '/auth/profile';
  static const String propertiesEndpoint = '/properties';
  static const String favoritesEndpoint = '/favorites';

  static const int requestTimeout = 30; 
  static const int maxRetries = 3;

  static String getCurrentBaseUrl() {
    return devBaseUrl;
  }
}
