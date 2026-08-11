import '../services/api_service.dart';

/// Helper utility for normalizing media URLs and providing ngrok bypass headers.
abstract class UrlHelper {
  /// Custom HTTP headers to bypass ngrok's free-tier browser warning page
  /// and ensure media/images load directly as binary content.
  static const Map<String, String> ngrokHeaders = {
    'ngrok-skip-browser-warning': '69420',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  /// Normalizes relative or incomplete image/mesh URLs:
  /// - Prepends [ApiService.baseUrl] if starting with '/'
  /// - Upgrades `http://` to `https://` for ngrok/cloud-run URLs
  /// - Trims whitespace
  static String normalizeUrl(String? url) {
    if (url == null) return '';
    var trimmed = url.trim();
    if (trimmed.isEmpty) return '';

    if (trimmed.startsWith('/')) {
      final base = ApiService.baseUrl.endsWith('/')
          ? ApiService.baseUrl.substring(0, ApiService.baseUrl.length - 1)
          : ApiService.baseUrl;
      trimmed = '$base$trimmed';
    }

    if (trimmed.startsWith('http://') &&
        (trimmed.contains('ngrok') || trimmed.contains('.run.app'))) {
      trimmed = trimmed.replaceFirst('http://', 'https://');
    }

    return trimmed;
  }
}
