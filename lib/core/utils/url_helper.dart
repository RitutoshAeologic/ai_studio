import '../services/api_service.dart';
import 'storage_url_resolver.dart';

/// Helper utility for normalizing media URLs, resolving Firebase Storage 403 issues,
/// and providing ngrok bypass headers.
abstract class UrlHelper {
  /// Custom HTTP headers to bypass ngrok's free-tier browser warning page
  /// and ensure media/images load directly as binary content.
  static const Map<String, String> ngrokHeaders = {
    'ngrok-skip-browser-warning': '69420',
    'User-Agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
  };

  /// Normalizes relative or incomplete image/mesh URLs and resolves Firebase Storage 403s:
  /// - Converts `https://storage.googleapis.com/<bucket>/<path>` to `https://firebasestorage.googleapis.com/v0/b/<bucket>/o/<path>?alt=media`
  /// - Prepends [ApiService.baseUrl] if starting with '/'
  /// - Upgrades `http://` to `https://` for ngrok/cloud-run URLs
  /// - Trims whitespace
  static String normalizeUrl(String? url) {
    if (url == null) return '';
    var trimmed = url.trim();
    if (trimmed.isEmpty) return '';

    // Convert raw GCS bucket URLs to Firebase Storage download endpoint format
    if (trimmed.startsWith('https://storage.googleapis.com/')) {
      final uri = Uri.parse(trimmed);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        final bucket = pathSegments.first;
        final objectPath = pathSegments.sublist(1).join('/');
        final encodedPath = Uri.encodeComponent(objectPath);
        trimmed =
            'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedPath?alt=media';
      }
    }

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

  /// Async URL resolver that uses Firebase Storage SDK token resolution if available.
  static Future<String> resolveStorageUrl(String? url) async {
    final normalized = normalizeUrl(url);
    if (normalized.isEmpty) return '';
    return StorageUrlResolver.resolveUrl(normalized);
  }
}
