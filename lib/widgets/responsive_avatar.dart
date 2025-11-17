import 'package:flutter/material.dart';

/// A small responsive avatar that scales up on wider screens (especially web).
///
/// Use `imageUrl` for a network avatar, or `backgroundImage` for any ImageProvider.
/// If neither is provided, `initials` will be shown as text. You can also
/// provide a fixed `size` (radius) to override the responsive calculation.
class ResponsiveAvatar extends StatelessWidget {
  final String? imageUrl;
  final ImageProvider? backgroundImage;
  final String? initials;
  final double? size; // radius
  final Color? backgroundColor;
  final Widget? fallbackIcon;

  const ResponsiveAvatar({
    Key? key,
    this.imageUrl,
    this.backgroundImage,
    this.initials,
    this.size,
    this.backgroundColor,
    this.fallbackIcon,
  }) : super(key: key);

  Size preferredSize(BuildContext context) {
    return Size.square(_computedRadius(context));
  }

  double _computedRadius(BuildContext context) {
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
    final radius = _computedRadius(context);

    final ImageProvider? provider = backgroundImage ??
        (imageUrl != null && imageUrl!.isNotEmpty
            ? NetworkImage(imageUrl!)
            : null);

    return CircleAvatar(
      radius: radius,
      // Use the newer surfaceContainerHighest as surfaceVariant is deprecated
      backgroundColor: backgroundColor ??
          Theme.of(context).colorScheme.surfaceContainerHighest,
      backgroundImage: provider,
      child: provider == null
          ? (initials != null
              ? Text(
                  initials!,
                  style: TextStyle(
                    fontSize: radius * 0.7,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                )
              : (fallbackIcon ?? const Icon(Icons.person)))
          : null,
    );
  }
}
