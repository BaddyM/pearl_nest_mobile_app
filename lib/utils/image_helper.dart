import 'package:pearlnest/apis/app_config.dart';

class ImageHelper {
  static String getFullImageUrl(String url) {
    // Handle comma-separated URLs and filter out invalid ones
    if (url.contains(',')) {
      final urls = url.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty && e != 'undefined').toList();
      if (urls.isNotEmpty) {
        url = urls.first;
      }
    }
    
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    final String baseUrl = AppConfig.getCurrentBaseUrl();
    String cleanUrl = url.replaceFirst(RegExp(r'^(\/|\./)'), '');
    return '$baseUrl/$cleanUrl';
  }
}
