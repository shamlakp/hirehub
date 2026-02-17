import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart';

class UrlHelper {
  static const String _baseUrl = 'http://127.0.0.1:8000';
  static const String _androidEmulatorUrl = 'http://10.0.2.2:8000';

  static String getBaseUrl() {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return _androidEmulatorUrl;
    }
    return _baseUrl;
  }

  static Future<void> launchBackendUrl(String path) async {
    final String fullUrl = '${getBaseUrl()}$path';
    final Uri uri = Uri.parse(fullUrl);
    
    try {
      debugPrint('Attempting to launch: $fullUrl');
      final bool success = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!success) {
        // Fallback for some platforms/browsers
        await launchUrl(uri);
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
      // Final fallback
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e2) {
        debugPrint('Final attempt failed: $e2');
      }
    }
  }
}
