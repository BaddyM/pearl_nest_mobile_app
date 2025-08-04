import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CacheHelper {
  /// Clear all cached images
  static Future<void> clearAllImageCache() async {
    await DefaultCacheManager().emptyCache();
  }
  
  /// Clear specific image from cache
  static Future<void> clearSpecificImageCache(String imageUrl) async {
    await DefaultCacheManager().removeFile(imageUrl);
  }
  
  /// Clear profile image cache specifically
  static Future<void> clearProfileImageCache(String? profileImageUrl) async {
    if (profileImageUrl != null && profileImageUrl.isNotEmpty) {
      await DefaultCacheManager().removeFile(profileImageUrl);
    }
  }
  
  /// Preload profile image (useful after login)
  static Future<void> preloadProfileImage(String imageUrl) async {
    await DefaultCacheManager().downloadFile(imageUrl);
  }
}