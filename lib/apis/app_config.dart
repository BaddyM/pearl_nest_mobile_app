import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://admin.pearlnestestates.com';

  static String get devBaseUrl => dotenv.env['DEV_API_BASE_URL'] ?? 'http://localhost:3000';

  static String get androidEmulatorUrl => dotenv.env['ANDROID_EMULATOR_URL'] ?? 'http://10.0.2.2:3000/api';

  static String get iosSimulatorUrl => dotenv.env['IOS_SIMULATOR_URL'] ?? 'http://localhost:3000/api';

  static const String loginEndpoint = '/user/login';
  static const String registerEndpoint = '/user/register';
  static const String profileEndpoint = '/user/userProfile/fetch';
  static const String updateProfileEndpoint = '/user/userProfile/update';
  static const String propertiesEndpoint = '/property/list';
  static const String propertySearchEndpoint = '/property/search';
  static const String favoritesEndpoint = '/favorites';

  static const int requestTimeout = 30;
  static const int maxRetries = 3;

  static String getCurrentBaseUrl() {
    // You can add logic here to determine which URL to use based on environment
    // For now, using the production URL from environment variables
    return baseUrl;
  }
}
