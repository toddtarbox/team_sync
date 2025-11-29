import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

/// A common component that wraps images and makes them tappable to show full-screen view
///
/// Usage:
/// ```dart
/// TappableImage.network(
///   imageUrl: 'https://example.com/image.jpg',
///   width: 100,
///   height: 100,
///   fit: BoxFit.cover,
/// )
/// ```
class TappableImage extends StatelessWidget {
  final ImageProvider imageProvider;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;
  final Widget? placeholder;
  final Widget? errorWidget;
  final String? heroTag;

  const TappableImage({
    super.key,
    required this.imageProvider,
    this.width,
    this.height,
    this.fit,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
    this.heroTag,
  });

  /// Create a TappableImage from a network URL
  factory TappableImage.network({
    required String imageUrl,
    double? width,
    double? height,
    BoxFit? fit,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
    String? heroTag,
  }) {
    return TappableImage(
      imageProvider: NetworkImage(imageUrl),
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      placeholder: placeholder,
      errorWidget: errorWidget,
      heroTag: heroTag,
    );
  }

  /// Create a TappableImage from an AssetImage
  factory TappableImage.asset({
    required String assetPath,
    double? width,
    double? height,
    BoxFit? fit,
    BorderRadius? borderRadius,
    Widget? placeholder,
    Widget? errorWidget,
    String? heroTag,
  }) {
    return TappableImage(
      imageProvider: AssetImage(assetPath),
      width: width,
      height: height,
      fit: fit,
      borderRadius: borderRadius,
      placeholder: placeholder,
      errorWidget: errorWidget,
      heroTag: heroTag,
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Image(
      image: imageProvider,
      width: width,
      height: height,
      fit: fit ?? BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return errorWidget ??
            Container(
              width: width,
              height: height,
              color: Theme.of(context).colorScheme.errorContainer,
              child: Icon(
                Icons.broken_image,
                color: Theme.of(context).colorScheme.onErrorContainer,
                size: (width != null && height != null)
                    ? (width! < height! ? width! * 0.5 : height! * 0.5)
                    : 32,
              ),
            );
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return placeholder ??
            Container(
              width: width,
              height: height,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              ),
            );
      },
    );

    // Apply border radius if provided
    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    // Wrap with Hero if heroTag provided
    if (heroTag != null) {
      imageWidget = Hero(
        tag: heroTag!,
        child: imageWidget,
      );
    }

    return GestureDetector(
      onTap: () => _showFullScreenImage(context),
      child: imageWidget,
    );
  }

  void _showFullScreenImage(BuildContext context) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // Full screen photo view
            Center(
              child: heroTag != null
                  ? Hero(
                      tag: heroTag!,
                      child: PhotoView(
                        imageProvider: imageProvider,
                        backgroundDecoration: const BoxDecoration(
                          color: Colors.transparent,
                        ),
                        minScale: PhotoViewComputedScale.contained,
                        maxScale: PhotoViewComputedScale.covered * 3,
                        initialScale: PhotoViewComputedScale.contained,
                      ),
                    )
                  : PhotoView(
                      imageProvider: imageProvider,
                      backgroundDecoration: const BoxDecoration(
                        color: Colors.transparent,
                      ),
                      minScale: PhotoViewComputedScale.contained,
                      maxScale: PhotoViewComputedScale.covered * 3,
                      initialScale: PhotoViewComputedScale.contained,
                    ),
            ),
            // Close button
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 32,
                ),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black54,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A widget that displays multiple images in a horizontal scrollable view
/// Each image is tappable to show full screen
class TappableImageGallery extends StatelessWidget {
  final List<String> imageUrls;
  final double imageHeight;
  final double imageWidth;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const TappableImageGallery({
    super.key,
    required this.imageUrls,
    this.imageHeight = 120,
    this.imageWidth = 120,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: imageHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: imageUrls.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return TappableImage.network(
            imageUrl: imageUrls[index],
            width: imageWidth,
            height: imageHeight,
            fit: fit,
            borderRadius: borderRadius ?? BorderRadius.circular(8),
            heroTag: 'gallery_image_$index',
          );
        },
      ),
    );
  }
}
