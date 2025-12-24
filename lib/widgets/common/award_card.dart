import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/widgets/common/tappable_image.dart';

/// Variant determines the visual layout of the award card
enum AwardCardVariant {
  /// Grid layout - image on top, text below
  grid,

  /// List layout - image/avatar on left, text on right
  list,

  /// Carousel layout - optimized for horizontal scrolling
  carousel,
}

/// A universal card component for displaying awards, achievements, and accomplishments
///
/// This component provides consistent styling and behavior across all award types:
/// - Team Awards
/// - Player Awards
/// - Team Accomplishments
///
/// Features:
/// - Multiple layout variants (grid, list, carousel)
/// - Optional image with TappableImage support
/// - Badge display (year, count, custom)
/// - Action buttons (edit, delete, promote)
/// - Reorder handle support
/// - Consistent error handling
///
/// Usage:
/// ```dart
/// AwardCard(
///   title: 'State Champions',
///   description: 'Won the state championship',
///   imageUrl: 'https://...',
///   year: 2024,
///   variant: AwardCardVariant.grid,
///   onTap: () => _showDetails(),
///   onEdit: () => _editAward(),
/// )
/// ```
class AwardCard extends StatelessWidget {
  /// The title of the award/accomplishment
  final String title;

  /// Optional description text
  final String? description;

  /// Single image URL (for awards with one image)
  final String? imageUrl;

  /// Multiple image URLs (for accomplishments with multiple images)
  final List<String>? imageUrls;

  /// Year to display as a badge (e.g., 2024)
  final int? year;

  /// Custom badge text (e.g., player name, category)
  final String? badgeText;

  /// Number badge (e.g., image count)
  final int? badgeCount;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Callback for edit action
  final VoidCallback? onEdit;

  /// Callback for delete action
  final VoidCallback? onDelete;

  /// Callback for promote action (awards to accomplishments)
  final VoidCallback? onPromote;

  /// Custom icon to use instead of default trophy
  final IconData? customIcon;

  /// Color for the icon/avatar background
  final Color? iconColor;

  /// Whether to show reorder handle (for drag-to-reorder lists)
  final bool showReorderHandle;

  /// Layout variant to use
  final AwardCardVariant variant;

  /// Hero tag for image animations
  final String? heroTag;

  /// Whether this is for web (affects some behaviors)
  final bool isWeb;

  /// Whether this award has been promoted (affects promote button icon)
  final bool isPromoted;

  const AwardCard({
    super.key,
    required this.title,
    this.description,
    this.imageUrl,
    this.imageUrls,
    this.year,
    this.badgeText,
    this.badgeCount,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onPromote,
    this.customIcon,
    this.iconColor,
    this.showReorderHandle = false,
    this.variant = AwardCardVariant.list,
    this.heroTag,
    this.isWeb = false,
    this.isPromoted = false,
  });

  /// Get the primary image URL (first from imageUrls or single imageUrl)
  String? get _primaryImageUrl {
    if (imageUrls != null && imageUrls!.isNotEmpty) {
      return imageUrls!.first;
    }
    return imageUrl;
  }

  /// Check if there are multiple images
  bool get _hasMultipleImages => imageUrls != null && imageUrls!.length > 1;

  @override
  Widget build(BuildContext context) {
    switch (variant) {
      case AwardCardVariant.grid:
        return _buildGridCard(context);
      case AwardCardVariant.list:
        return _buildListCard(context);
      case AwardCardVariant.carousel:
        return _buildCarouselCard(context);
    }
  }

  /// Build grid layout card (image on top, text below)
  Widget _buildGridCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image section
          Expanded(
            flex: 5,
            child: _buildImageSection(context, fit: BoxFit.cover),
          ),
          // Text section
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AutoSizeText(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Expanded(
                        child: Text(
                          description!,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Build list layout card (avatar on left, text on right)
  Widget _buildListCard(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        // Leading: avatar with optional badge
        leading: _buildAvatarWithBadge(context),

        // Title with year badge
        title: _buildTitleWithBadge(context),

        // Subtitle (description)
        subtitle: description != null && description!.isNotEmpty
            ? Text(description!)
            : null,

        // Trailing: action buttons or reorder handle
        trailing: _buildTrailingActions(context),

        // Tap handler
        onTap: onTap,
      ),
    );
  }

  /// Build carousel layout card (optimized for horizontal scrolling)
  Widget _buildCarouselCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 280, // Fixed width for carousel
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image section (larger for carousel)
              SizedBox(
                height: 180,
                child: _buildImageSection(context, fit: BoxFit.cover),
              ),
              // Text section
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (year != null) _buildYearBadge(context),
                      ],
                    ),
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build image section with TappableImage or fallback icon
  Widget _buildImageSection(BuildContext context, {BoxFit? fit}) {
    final primaryImage = _primaryImageUrl;

    if (primaryImage != null && primaryImage.isNotEmpty) {
      return TappableImage.network(
        imageUrl: primaryImage,
        fit: fit ?? BoxFit.cover,
        heroTag: heroTag,
        errorWidget: _buildFallbackIcon(context),
      );
    }

    return _buildFallbackIcon(context);
  }

  /// Build fallback icon when no image is available
  Widget _buildFallbackIcon(BuildContext context) {
    return Container(
      color: (iconColor ?? Colors.amber).withValues(alpha: 0.2),
      child: Center(
        child: Icon(
          customIcon ?? Icons.emoji_events,
          size: 64,
          color: iconColor ?? Colors.amber,
        ),
      ),
    );
  }

  /// Build avatar with optional badge for list view
  Widget _buildAvatarWithBadge(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Avatar
        _primaryImageUrl != null && _primaryImageUrl!.isNotEmpty
            ? CircleAvatar(
                radius: 24,
                backgroundImage: NetworkImage(_primaryImageUrl!),
                onBackgroundImageError: (error, stackTrace) {
                  debugPrint('Error loading award image: $error');
                },
              )
            : CircleAvatar(
                radius: 24,
                backgroundColor: iconColor ?? Colors.amber,
                child: Icon(
                  customIcon ?? Icons.emoji_events,
                  color: Colors.white,
                  size: 24,
                ),
              ),

        // Badge (image count or custom)
        if (_hasMultipleImages || badgeCount != null)
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${badgeCount ?? imageUrls!.length}',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build title with optional year badge
  Widget _buildTitleWithBadge(BuildContext context) {
    if (year == null && badgeText == null) {
      return Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        if (year != null) _buildYearBadge(context),
        if (badgeText != null) _buildTextBadge(context, badgeText!),
      ],
    );
  }

  /// Build year badge
  Widget _buildYearBadge(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        year.toString(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
      ),
    );
  }

  /// Build text badge (for custom badge text)
  Widget _buildTextBadge(BuildContext context, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onTertiaryContainer,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  /// Build trailing actions (edit/delete/promote buttons or reorder handle)
  Widget? _buildTrailingActions(BuildContext context) {
    if (showReorderHandle) {
      return ReorderableDragStartListener(
        index: 0, // Will be overridden by parent
        child: const Icon(Icons.drag_handle),
      );
    }

    final actions = <Widget>[];

    if (onPromote != null && !isWeb) {
      actions.add(
        IconButton(
          icon: Icon(
            isPromoted ? Icons.star : Icons.star_border,
            size: 20,
            color: isPromoted ? Colors.amber : null,
          ),
          onPressed: onPromote,
          tooltip: isPromoted
              ? 'Promoted to Team Accomplishment'
              : 'Promote to Team Accomplishment',
          color:
              isPromoted ? Colors.amber : Theme.of(context).colorScheme.primary,
        ),
      );
    }

    if (onEdit != null && !isWeb) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.edit, size: 20),
          onPressed: onEdit,
          tooltip: 'Edit',
        ),
      );
    }

    if (onDelete != null && !isWeb) {
      actions.add(
        IconButton(
          icon: const Icon(Icons.delete, size: 20),
          onPressed: onDelete,
          tooltip: 'Delete',
        ),
      );
    }

    if (actions.isEmpty) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions,
    );
  }
}
