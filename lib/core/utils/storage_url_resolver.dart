import 'package:firebase_storage/firebase_storage.dart';

import 'logger.dart';

/// Utility service to resolve Firebase Storage URLs into authenticated download URLs.
/// Parses raw Google Cloud Storage direct bucket links (`https://storage.googleapis.com/<bucket>/<path>`)
/// and `gs://` links to query the correct Firebase Storage bucket reference, avoiding object-not-found 404 errors.
abstract class StorageUrlResolver {
  static final Map<String, String> _urlCache = {};
  static final Set<String> _missingUrls = {};

  /// Checks if a URL is already resolved or marked as missing in local memory cache.
  static bool isCached(String rawUrl) =>
      _urlCache.containsKey(rawUrl) || _missingUrls.contains(rawUrl);

  /// Checks if a URL has been confirmed as missing (HTTP 404 / object-not-found).
  static bool isMissing(String rawUrl) => _missingUrls.contains(rawUrl);

  /// Resolves any Firebase Storage URL into a valid, authenticated download URL with `?alt=media`.
  /// Returns empty string `''` if the object does not exist on the server.
  static Future<String> resolveUrl(String rawUrl) async {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) return '';

    // 1. If previously confirmed as missing, return empty string immediately
    if (_missingUrls.contains(trimmed)) {
      return '';
    }

    // 2. Return cached resolved URL if available
    if (_urlCache.containsKey(trimmed)) {
      return _urlCache[trimmed]!;
    }

    // 3. Already formatted Firebase Storage download URL containing active signed token
    if (trimmed.contains('firebasestorage.googleapis.com') &&
        trimmed.contains('token=')) {
      _urlCache[trimmed] = trimmed;
      return trimmed;
    }

    // 4. Parse URI into precise Firebase Storage Reference (handles https://storage.googleapis.com/, firebasestorage.googleapis.com, & gs://)
    final ref = parseStorageReference(trimmed);
    if (ref != null) {
      try {
        final downloadUrl = await ref.getDownloadURL();
        _urlCache[trimmed] = downloadUrl;
        return downloadUrl;
      } on FirebaseException catch (e) {
        if (e.code == 'object-not-found' || e.message?.contains('404') == true) {
          Logger.w('Storage object not found on server (HTTP 404): $trimmed');
          _missingUrls.add(trimmed);
          return '';
        }
        Logger.w('FirebaseStorage Exception [${e.code}]: ${e.message}');
      } catch (e) {
        Logger.w('StorageUrlResolver: Error fetching getDownloadURL for $trimmed: $e');
      }
    }

    // 5. Fallback URL transformation for storage.googleapis.com direct URLs if SDK lookup failed non-fatally
    if (trimmed.startsWith('https://storage.googleapis.com/')) {
      final uri = Uri.parse(trimmed);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2) {
        final bucket = pathSegments.first;
        final objectPath = pathSegments.sublist(1).join('/');
        final encodedPath = Uri.encodeComponent(objectPath);
        final fallbackUrl =
            'https://firebasestorage.googleapis.com/v0/b/$bucket/o/$encodedPath?alt=media';
        _urlCache[trimmed] = fallbackUrl;
        return fallbackUrl;
      }
    }

    return trimmed;
  }

  /// Parses raw storage URLs (`gs://bucket/path`, `https://storage.googleapis.com/bucket/path`,
  /// or `https://firebasestorage.googleapis.com/v0/b/bucket/o/path`)
  /// into a targeted [Reference] bound to the specific Firebase Storage bucket.
  static Reference? parseStorageReference(String rawUrl) {
    try {
      // Handle gs://bucket/path
      if (rawUrl.startsWith('gs://')) {
        final uri = Uri.parse(rawUrl);
        final bucket = uri.host;
        final path = uri.path.startsWith('/') ? uri.path.substring(1) : uri.path;
        return FirebaseStorage.instanceFor(bucket: bucket).ref(path);
      }

      // Handle https://storage.googleapis.com/bucket/path
      if (rawUrl.startsWith('https://storage.googleapis.com/')) {
        final uri = Uri.parse(rawUrl);
        final pathSegments = uri.pathSegments;
        if (pathSegments.length >= 2) {
          final bucket = pathSegments.first;
          final objectPath = pathSegments.sublist(1).join('/');
          return FirebaseStorage.instanceFor(bucket: bucket).ref(objectPath);
        }
      }

      // Handle https://firebasestorage.googleapis.com/v0/b/bucket/o/path
      if (rawUrl.contains('firebasestorage.googleapis.com/v0/b/')) {
        final uri = Uri.parse(rawUrl);
        final pathSegments = uri.pathSegments;
        final bIndex = pathSegments.indexOf('b');
        final oIndex = pathSegments.indexOf('o');
        if (bIndex != -1 && oIndex != -1 && pathSegments.length > oIndex + 1) {
          final bucket = pathSegments[bIndex + 1];
          final rawObjectPath = pathSegments.sublist(oIndex + 1).join('/');
          final objectPath = Uri.decodeComponent(rawObjectPath);
          return FirebaseStorage.instanceFor(bucket: bucket).ref(objectPath);
        }
      }

      // Default fallback using standard FirebaseStorage instance refFromURL
      return FirebaseStorage.instance.refFromURL(rawUrl);
    } catch (e) {
      Logger.w('Failed to parse storage reference for $rawUrl: $e');
      return null;
    }
  }
}
