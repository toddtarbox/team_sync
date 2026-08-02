import 'package:flutter/material.dart';

/// A reusable component for displaying an image/avatar with an optional badge overlay
///
/// This component is commonly used in award/accomplishment cards to show:
/// - Profile images with count badges
/// - Award images with multiple image indicators
/// - Custom badge content
///
/// Features:
/// - Circular avatar display
/// - Network image support
/// - Fallback icon/widget
/// - Count badge (e.g., "3" for 3 images)
/// - Custom badge widget
/// - Configurable size and colors
///
/// Usage:
/// ```dart
/// // With count badge
/// ImageWithBadge(
///   imageUrl: player.profileImage,
///   badgeCount: 5,
///   radius: 24,
/// )
///
/// // With custom badge
/// ImageWithBadge(
///   imageUrl: award.imageUrl,
///   badgeWidget: Icon(Icons.star, size: 16),
///   radius: 30,
/// )
///
/// // Fallback icon
/// ImageWithBadge(
///   imageUrl: null,
///   fallbackIcon: Icon(Icons.emoji_events),
///   radius: 24,
/// )
/// ```
class ImageWithBadge extends StatelessWidget {
  /// Image URL to display (null for fallback)
  final String? imageUrl;

  /// Count to display in badge (e.g., number of images)
  final int? badgeCount;

  /// Custom badge widget (overrides badgeCount)
  final Widget? badgeWidget;

  /// Radius of the circular avatar
  final double radius;

  /// Fallback widget to display when imageUrl is null
  final Widget fallbackIcon;

  /// Background color for avatar (when using fallback)
  final Color? backgroundColor;

  /// Hero tag for animations
  final String? heroTag;

  /// Badge background color
  final Color? badgeBackgroundColor;

  /// Badge text/icon color
  final Color? badgeColor;

  /// Badge position offset
  final double badgeOffset;

  /// Badge size
  final double badgeSize;

  const ImageWithBadge({
    super.key,
    this.imageUrl,
    this.badgeCount,
    this.badgeWidget,
    this.radius = 24.0,
    this.fallbackIcon = const Icon(Icons.person, color: Colors.white),
    this.backgroundColor,
    this.heroTag,
    this.badgeBackgroundColor,
    this.badgeColor,
    this.badgeOffset = -4.0,
    this.badgeSize = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final avatar = _buildAvatar(context);
    final badge = _buildBadge(context);

    // If no badge, return avatar only
    if (badge == null) {
      return avatar;
    }

    // Return avatar with badge
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: badgeOffset,
          bottom: badgeOffset,
          child: badge,
        ),
      ],
    );
  }

  /// Build the circular avatar
  Widget _buildAvatar(BuildContext context) {
    final avatarWidget = CircleAvatar(
      radius: radius,
      backgroundColor:
          backgroundColor ?? Theme.of(context).colorScheme.primaryContainer,
      backgroundImage: imageUrl != null && imageUrl!.isNotEmpty
          ? NetworkImage(imageUrl!)
          : null,
      onBackgroundImageError: (error, stackTrace) {
        debugPrint('Error loading image in ImageWithBadge: $error');
      },
      child: imageUrl == null || imageUrl!.isEmpty ? fallbackIcon : null,
    );

    // Wrap with Hero if heroTag provided
    if (heroTag != null) {
      return Hero(
        tag: heroTag!,
        child: avatarWidget,
      );
    }

    return avatarWidget;
  }

  /// Build the badge widget
  Widget? _buildBadge(BuildContext context) {
    // Custom badge widget takes priority
    if (badgeWidget != null) {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: badgeBackgroundColor ?? Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: badgeWidget,
      );
    }

    // Count badge
    if (badgeCount != null && badgeCount! > 0) {
      return Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          color: badgeBackgroundColor ?? Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            badgeCount.toString(),
            style: TextStyle(
              color: badgeColor ?? Theme.of(context).colorScheme.onPrimary,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    }

    // No badge
    return null;
  }
}

/// A variant of ImageWithBadge specifically for square/rounded images
class SquareImageWithBadge extends StatelessWidget {
  /// Image URL to display
  final String? imageUrl;

  /// Count to display in badge
  final int? badgeCount;

  /// Custom badge widget
  final Widget? badgeWidget;

  /// Size (width and height)
  final double size;

  /// Fallback widget
  final Widget fallbackWidget;

  /// Border radius
  final BorderRadius? borderRadius;

  /// Hero tag
  final String? heroTag;

  /// Badge configuration
  final Color? badgeBackgroundColor;
  final Color? badgeColor;
  final double badgeOffset;

  const SquareImageWithBadge({
    super.key,
    this.imageUrl,
    this.badgeCount,
    this.badgeWidget,
    this.size = 100.0,
    this.fallbackWidget = const Icon(Icons.image, size: 40, color: Colors.grey),
    this.borderRadius,
    this.heroTag,
    this.badgeBackgroundColor,
    this.badgeColor,
    this.badgeOffset = -8.0,
  });

  @override
  Widget build(BuildContext context) {
    final imageWidget = _buildImage(context);
    final badge = _buildBadge(context);

    if (badge == null) {
      return imageWidget;
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        imageWidget,
        Positioned(
          right: badgeOffset,
          top: badgeOffset,
          child: badge,
        ),
      ],
    );
  }

  Widget _buildImage(BuildContext context) {
    Widget image;

    if (imageUrl != null && imageUrl!.isNotEmpty) {
      image = Image.network(
        imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: size,
            height: size,
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            child: Center(child: fallbackWidget),
          );
        },
      );
    } else {
      image = Container(
        width: size,
        height: size,
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(child: fallbackWidget),
      );
    }

    if (borderRadius != null) {
      image = ClipRRect(
        borderRadius: borderRadius!,
        child: image,
      );
    }

    if (heroTag != null) {
      image = Hero(tag: heroTag!, child: image);
    }

    return image;
  }

  Widget? _buildBadge(BuildContext context) {
    if (badgeWidget != null) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: badgeBackgroundColor ?? Theme.of(context).colorScheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: badgeWidget,
      );
    }

    if (badgeCount != null && badgeCount! > 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: badgeBackgroundColor ?? Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          badgeCount.toString(),
          style: TextStyle(
            color: badgeColor ?? Theme.of(context).colorScheme.onPrimary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return null;
  }
}
