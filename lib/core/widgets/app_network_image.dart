import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import '../constants/app_colors.dart';
import '../constants/app_strings.dart';
import '../constants/app_text_styles.dart';
import '../utils/storage_url_resolver.dart';
import 'aperture_indicator.dart';

/// Robust network image widget that automatically resolves Firebase Storage / GCS URLs,
/// gracefully handling missing objects (HTTP 404 / object-not-found) with a clean UI fallback.
class AppNetworkImage extends StatefulWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget Function(BuildContext, String)? placeholder;
  final Widget Function(BuildContext, String, dynamic)? errorWidget;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<AppNetworkImage> createState() => _AppNetworkImageState();
}

class _AppNetworkImageState extends State<AppNetworkImage> {
  late Future<String> _resolvedUrlFuture;

  @override
  void initState() {
    super.initState();
    _resolvedUrlFuture = StorageUrlResolver.resolveUrl(widget.imageUrl);
  }

  @override
  void didUpdateWidget(AppNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _resolvedUrlFuture = StorageUrlResolver.resolveUrl(widget.imageUrl);
    }
  }

  Widget _buildFallbackUI(BuildContext context, dynamic error) {
    if (widget.errorWidget != null) {
      return widget.errorWidget!(context, widget.imageUrl, error);
    }
    return Container(
      color: AppColors.surfaceInput,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_not_supported_rounded,
              color: AppColors.slate,
              size: 32.r,
            ),
            SizedBox(height: 4.h),
            Text(
              AppStrings.imageUnavailable,
              style: AppTextStyles.caption(color: AppColors.slate),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrl.isEmpty) {
      return _buildFallbackUI(context, 'Empty URL');
    }

    return FutureBuilder<String>(
      future: _resolvedUrlFuture,
      builder: (context, snapshot) {
        final resolvedUrl = snapshot.data ?? widget.imageUrl;

        // If resolution returned empty string, the file was confirmed as missing (HTTP 404)
        if (resolvedUrl.isEmpty && snapshot.connectionState != ConnectionState.waiting) {
          return _buildFallbackUI(context, 'Object Not Found (404)');
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            !StorageUrlResolver.isCached(widget.imageUrl)) {
          return widget.placeholder?.call(context, widget.imageUrl) ??
              Center(
                child: ApertureIndicator(
                  size: 28.r,
                  color: AppColors.ember,
                ),
              );
        }

        return CachedNetworkImage(
          imageUrl: resolvedUrl,
          width: widget.width,
          height: widget.height,
          fit: widget.fit,
          placeholder: widget.placeholder ??
              (context, url) => Center(
                    child: ApertureIndicator(
                      size: 28.r,
                      color: AppColors.ember,
                    ),
                  ),
          errorWidget: (context, url, error) => _buildFallbackUI(context, error),
        );
      },
    );
  }
}
