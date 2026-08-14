import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import 'logger.dart';
import 'url_helper.dart';

/// Helper service to download remote 3D .glb mesh models natively via Dart's HTTP client.
/// Bypasses mobile browser / WebView CORS restrictions (`Access-Control-Allow-Origin`) completely
/// by caching the binary .glb file locally on the device disk before passing it to the 3D renderer.
abstract class GlbLoaderHelper {
  static final Map<String, String> _memoryCache = {};

  /// Resolves the remote .glb URL, downloads the binary payload via Dart native http,
  /// saves it to the app's local temporary directory, and returns a local file:// path or data URI.
  static Future<String> loadGlb(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';

    if (_memoryCache.containsKey(trimmed)) {
      final cachedPath = _memoryCache[trimmed]!;
      if (await File(cachedPath.replaceFirst('file://', '')).exists()) {
        return cachedPath;
      }
    }

    try {
      final resolvedUrl = await UrlHelper.resolveStorageUrl(trimmed);
      if (resolvedUrl.isEmpty) return '';

      // Generate deterministic filename using hashCode of rawUrl
      final dir = await getTemporaryDirectory();
      final hash = trimmed.hashCode.abs().toString();
      final filePath = '${dir.path}/mesh_$hash.glb';
      final file = File(filePath);

      // Return cached file if already downloaded and valid
      if (await file.exists() && (await file.length()) > 0) {
        Logger.d('GlbLoaderHelper: Found cached .glb file at $filePath');
        final localUri = 'file://$filePath';
        _memoryCache[trimmed] = localUri;
        return localUri;
      }

      Logger.d('GlbLoaderHelper: Downloading .glb natively via Dart HTTP (bypassing CORS) from $resolvedUrl');
      final response = await http.get(
        Uri.parse(resolvedUrl),
        headers: UrlHelper.ngrokHeaders,
      );

      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        await file.writeAsBytes(response.bodyBytes);
        Logger.d('GlbLoaderHelper: Successfully cached ${response.bodyBytes.length} bytes to $filePath');
        final localUri = 'file://$filePath';
        _memoryCache[trimmed] = localUri;
        return localUri;
      } else {
        Logger.w('GlbLoaderHelper: Native HTTP download failed with status ${response.statusCode}');
      }
    } catch (e) {
      Logger.w('GlbLoaderHelper: Exception during native .glb download: $e');
    }

    // Fallback to resolved storage URL if native download fails
    return UrlHelper.resolveStorageUrl(trimmed);
  }
}
