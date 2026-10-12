import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:udyogasethu/core/services/thumbnail_library.dart';
import 'package:udyogasethu/core/theme/app_colors.dart';
import 'package:udyogasethu/core/theme/app_typography.dart';
import 'package:udyogasethu/features/marketplace/domain/produce_marketplace_item.dart';
import 'package:udyogasethu/features/provider/domain/provider_job.dart';
import 'package:udyogasethu/features/seeker/domain/job_detail.dart';
import 'package:udyogasethu/features/seeker/domain/job_recommendation.dart';

enum ThumbnailSize {
  card,
  header,
  small,
}

/// Dynamic, illustrated Job Thumbnail with bold playful outlined title lettering
class JobThumbnail extends StatelessWidget {
  final String? title;
  final String? categorySlug;
  final String? jobId;
  final String? thumbnailPath;
  final String? sitePhotoUrl;
  final String? description;
  final ThumbnailSize size;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool showTitle;
  final BoxFit fit;

  const JobThumbnail({
    super.key,
    this.title,
    this.categorySlug,
    this.jobId,
    this.thumbnailPath,
    this.sitePhotoUrl,
    this.description,
    this.size = ThumbnailSize.card,
    this.width,
    this.height,
    this.borderRadius,
    this.showTitle = true,
    this.fit = BoxFit.cover,
  });

  /// Factory for JobRecommendation
  factory JobThumbnail.fromRecommendation(
    JobRecommendation job, {
    ThumbnailSize size = ThumbnailSize.card,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    bool showTitle = true,
  }) {
    return JobThumbnail(
      title: job.title,
      categorySlug: job.categorySlug,
      jobId: job.id,
      thumbnailPath: job.sitePhotoUrl,
      sitePhotoUrl: job.sitePhotoUrl,
      description: job.description,
      size: size,
      width: width,
      height: height,
      borderRadius: borderRadius,
      showTitle: showTitle,
    );
  }

  /// Factory for JobDetail
  factory JobThumbnail.fromDetail(
    JobDetail job, {
    ThumbnailSize size = ThumbnailSize.header,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    bool showTitle = true,
  }) {
    return JobThumbnail(
      title: job.title,
      categorySlug: job.categorySlug,
      jobId: job.id,
      thumbnailPath: job.sitePhotoUrl,
      sitePhotoUrl: job.sitePhotoUrl,
      description: job.description,
      size: size,
      width: width,
      height: height,
      borderRadius: borderRadius,
      showTitle: showTitle,
    );
  }

  /// Factory for ProviderJob
  factory JobThumbnail.fromProviderJob(
    ProviderJob job, {
    ThumbnailSize size = ThumbnailSize.card,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    bool showTitle = true,
  }) {
    return JobThumbnail(
      title: job.title,
      categorySlug: job.categoryName,
      jobId: job.id,
      thumbnailPath: job.thumbnailPath ?? job.sitePhotoUrl,
      sitePhotoUrl: job.sitePhotoUrl,
      description: job.description,
      size: size,
      width: width,
      height: height,
      borderRadius: borderRadius,
      showTitle: showTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolution = ThumbnailLibrary.resolveJob(
      thumbnailPath: thumbnailPath,
      sitePhotoUrl: sitePhotoUrl,
      title: title,
      categorySlug: categorySlug,
      description: description,
    );

    return _ThumbnailRenderer(
      resolution: resolution,
      title: title,
      size: size,
      width: width,
      height: height,
      borderRadius: borderRadius,
      showTitle: showTitle,
      fit: fit,
      semanticLabel: title != null ? 'Thumbnail for $title' : 'Job thumbnail',
    );
  }
}

/// Dynamic, illustrated Produce Thumbnail for fruits, vegetables, grains, crops
class ProduceThumbnail extends StatelessWidget {
  final String name;
  final String? category;
  final String? imageUrl;
  final List<String>? images;
  final ThumbnailSize size;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool showTitle;
  final BoxFit fit;

  const ProduceThumbnail({
    super.key,
    required this.name,
    this.category,
    this.imageUrl,
    this.images,
    this.size = ThumbnailSize.card,
    this.width,
    this.height,
    this.borderRadius,
    this.showTitle = true,
    this.fit = BoxFit.cover,
  });

  factory ProduceThumbnail.fromMarketplaceItem(
    ProduceMarketplaceItem item, {
    ThumbnailSize size = ThumbnailSize.card,
    double? width,
    double? height,
    BorderRadius? borderRadius,
    bool showTitle = true,
  }) {
    return ProduceThumbnail(
      name: item.name,
      category: item.category,
      images: item.images,
      imageUrl: item.images.isNotEmpty ? item.images.first : null,
      size: size,
      width: width,
      height: height,
      borderRadius: borderRadius,
      showTitle: showTitle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolution = ThumbnailLibrary.resolveProduce(
      imageUrl: imageUrl,
      images: images,
      name: name,
      category: category,
    );

    return _ThumbnailRenderer(
      resolution: resolution,
      title: name,
      size: size,
      width: width,
      height: height,
      borderRadius: borderRadius,
      showTitle: showTitle,
      fit: fit,
      semanticLabel: 'Farm produce thumbnail for $name',
    );
  }
}

/// Dynamic, illustrated Resource & Equipment Thumbnail
class ResourceThumbnail extends StatelessWidget {
  final String title;
  final String? resourceType;
  final String? imageUrl;
  final ThumbnailSize size;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool showTitle;
  final BoxFit fit;

  const ResourceThumbnail({
    super.key,
    required this.title,
    this.resourceType,
    this.imageUrl,
    this.size = ThumbnailSize.card,
    this.width,
    this.height,
    this.borderRadius,
    this.showTitle = true,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    final resolution = ThumbnailLibrary.resolveResource(
      imageUrl: imageUrl,
      title: title,
      resourceType: resourceType,
    );

    return _ThumbnailRenderer(
      resolution: resolution,
      title: title,
      size: size,
      width: width,
      height: height,
      borderRadius: borderRadius,
      showTitle: showTitle,
      fit: fit,
      semanticLabel: 'Farm resource thumbnail for $title',
    );
  }
}

/// Common rendering engine for thumbnails with 16:9 ratio, cached image, and comic lettering
class _ThumbnailRenderer extends StatelessWidget {
  final ThumbnailResolution resolution;
  final String? title;
  final ThumbnailSize size;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool showTitle;
  final BoxFit fit;
  final String semanticLabel;

  const _ThumbnailRenderer({
    required this.resolution,
    this.title,
    required this.size,
    this.width,
    this.height,
    this.borderRadius,
    required this.showTitle,
    required this.fit,
    required this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final dims = _calculateDimensions(size, width, height);
    final radius = borderRadius ?? _defaultRadius(size);

    Widget imageWidget;
    if (resolution.isNetwork && resolution.networkUrl != null) {
      imageWidget = CachedNetworkImage(
        imageUrl: resolution.networkUrl!,
        fit: fit,
        width: dims.width,
        height: dims.height,
        placeholder: (context, url) => Container(
          color: const Color(0xFFF1F5F9),
          child: const Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primaryTeal,
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Image.asset(
          ThumbnailLibrary.fallbackAsset,
          fit: fit,
          width: dims.width,
          height: dims.height,
        ),
      );
    } else {
      imageWidget = Image.asset(
        resolution.assetPath ?? ThumbnailLibrary.fallbackAsset,
        fit: fit,
        width: dims.width,
        height: dims.height,
        errorBuilder: (context, error, stackTrace) => Image.asset(
          ThumbnailLibrary.fallbackAsset,
          fit: fit,
          width: dims.width,
          height: dims.height,
        ),
      );
    }

    final shouldDrawTitle = showTitle &&
        !resolution.hasBakedInTitle &&
        title != null &&
        title!.trim().isNotEmpty &&
        size != ThumbnailSize.small;

    return Semantics(
      label: semanticLabel,
      image: true,
      child: ClipRRect(
        borderRadius: radius,
        child: SizedBox(
          width: dims.width,
          height: dims.height,
          child: Stack(
            fit: StackFit.expand,
            children: [
              imageWidget,
              if (shouldDrawTitle)
                ThumbnailTitleOverlay(
                  title: title!,
                  size: size,
                ),
            ],
          ),
        ),
      ),
    );
  }

  _Dimensions _calculateDimensions(ThumbnailSize size, double? w, double? h) {
    if (w != null && h != null) {
      return _Dimensions(width: w, height: h);
    }

    switch (size) {
      case ThumbnailSize.header:
        final targetW = w ?? double.infinity;
        final targetH = h ?? 200.0;
        return _Dimensions(width: targetW, height: targetH);
      case ThumbnailSize.card:
        final targetW = w ?? double.infinity;
        // 16:9 ratio default for card height if not specified
        final targetH = h ?? (w != null ? (w * 9 / 16) : 130.0);
        return _Dimensions(width: targetW, height: targetH);
      case ThumbnailSize.small:
        final targetW = w ?? 56.0;
        final targetH = h ?? 56.0;
        return _Dimensions(width: targetW, height: targetH);
    }
  }

  BorderRadius _defaultRadius(ThumbnailSize size) {
    switch (size) {
      case ThumbnailSize.header:
        return BorderRadius.circular(16);
      case ThumbnailSize.card:
        return BorderRadius.circular(14);
      case ThumbnailSize.small:
        return BorderRadius.circular(10);
    }
  }
}

class _Dimensions {
  final double width;
  final double height;
  const _Dimensions({required this.width, required this.height});
}

/// Outlined playful comic lettering with Google Fonts and Indic fallbacks
class ThumbnailTitleOverlay extends StatelessWidget {
  final String title;
  final ThumbnailSize size;

  const ThumbnailTitleOverlay({
    super.key,
    required this.title,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final isHeader = size == ThumbnailSize.header;
    final fontSize = isHeader ? 22.0 : 13.5;
    final outlineWidth = isHeader ? 4.5 : 3.0;

    // Bold comic font with Indic fallbacks
    final baseStyle = GoogleFonts.lilitaOne(
      fontSize: fontSize,
      fontWeight: FontWeight.w900,
      letterSpacing: 0.8,
      height: 1.15,
    ).copyWith(
      fontFamilyFallback: AppTypography.fontFallbacks,
    );

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(
          isHeader ? 14 : 8,
          isHeader ? 20 : 12,
          isHeader ? 14 : 8,
          isHeader ? 10 : 6,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.black.withValues(alpha: 0.85),
              Colors.black.withValues(alpha: 0.45),
              Colors.transparent,
            ],
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.bottomLeft,
          child: Stack(
            children: [
              // 1. Black stroke outline layer
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: baseStyle.copyWith(
                  foreground: Paint()
                    ..style = PaintingStyle.stroke
                    ..strokeWidth = outlineWidth
                    ..strokeCap = StrokeCap.round
                    ..strokeJoin = StrokeJoin.round
                    ..color = const Color(0xFF0F172A),
                ),
              ),
              // 2. Vibrant golden pop fill with drop shadow
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: baseStyle.copyWith(
                  color: const Color(0xFFFDE047), // Vibrant yellow
                  shadows: const [
                    Shadow(
                      color: Color(0xAA000000),
                      offset: Offset(0, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
