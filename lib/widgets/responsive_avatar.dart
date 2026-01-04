import 'package:flutter/material.dart';

/// A small responsive avatar that scales up on wider screens (especially web).
///
/// Use `imageUrl` for a network avatar, or `backgroundImage` for any ImageProvider.
/// If neither is provided, `initials` will be shown as text. You can also
/// provide a fixed `size` (radius) to override the responsive calculation.
/// Set `isSquare` to true for a square avatar, false (default) for circular.
class ResponsiveAvatar extends StatelessWidget {
  final String? imageUrl;
  final ImageProvider? backgroundImage;
  final String? initials;
  final double? size; // radius
  final Color? backgroundColor;
  final Widget? fallbackIcon;
  final bool isSquare; // true for square, false for circle

  const ResponsiveAvatar({
    super.key,
    this.imageUrl,
    this.backgroundImage,
    this.initials,
    this.size,
    this.backgroundColor,
    this.fallbackIcon,
    this.isSquare = false,
  });

  Size preferredSize(BuildContext context) {
    return Size.square(computedRadius(context));
  }

  /// Compute the avatar radius based on the provided `size` or the
  /// current screen width. Public so subclasses can call it.
  double computedRadius(BuildContext context) {
    if (size != null) return size!;
    final w = MediaQuery.of(context).size.width;

    // Scale more aggressively for very large screens (desktop / web)
    if (w >= 1400) return 56;
    if (w >= 1100) return 48;
    if (w >= 900) return 44;
    if (w >= 600) return 40;
    return 32;
  }

  @override
  Widget build(BuildContext context) {
    final radius = computedRadius(context);

    final ImageProvider? provider = backgroundImage ??
        (imageUrl != null && imageUrl!.isNotEmpty
            ? NetworkImage(imageUrl!)
            : null);

    final String? displayInitials = initials;

    // Create child widget (initials or fallback icon)
    // This will show when there's no image OR when image loading fails
    Widget? childWidget = displayInitials != null && displayInitials.isNotEmpty
        ? Text(
            displayInitials,
            style: TextStyle(
              fontSize: radius * 0.5,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          )
        : (fallbackIcon ?? const Icon(Icons.person));

    if (isSquare) {
      // Square avatar with optional image
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: BoxDecoration(
          color: backgroundColor ??
              Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          image: provider != null
              ? DecorationImage(
                  image: provider,
                  fit: BoxFit.contain, // Fit entire image inside the area
                )
              : null,
        ),
        child: provider == null ? Center(child: childWidget) : null,
      );
    } else {
      // Circular avatar (default)
      // For circle, we need to wrap in a container to control fit
      if (provider != null) {
        return Container(
          width: radius * 2,
          height: radius * 2,
          decoration: BoxDecoration(
            color: backgroundColor ??
                Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: BoxShape.circle,
          ),
          child: ClipOval(
            child: Image(
              image: provider,
              fit: BoxFit.contain, // Fit entire image inside the circle
              errorBuilder: (context, error, stackTrace) {
                return Center(child: childWidget);
              },
            ),
          ),
        );
      } else {
        // No image provider, use CircleAvatar with child
        return CircleAvatar(
          radius: radius,
          backgroundColor: backgroundColor ??
              Theme.of(context).colorScheme.surfaceContainerHighest,
          child: childWidget,
        );
      }
    }
  }
}
