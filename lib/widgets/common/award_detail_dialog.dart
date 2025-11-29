import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/widgets/common/tappable_image.dart';
import 'package:url_launcher/url_launcher.dart';

/// A universal detail dialog component for displaying award/accomplishment details
///
/// This component provides consistent styling and behavior for detail views:
/// - Team Awards
/// - Player Awards
/// - Team Accomplishments
///
/// Features:
/// - Single or multiple image display (carousel)
/// - Year badge display
/// - Description text
/// - External link button
/// - Edit action support
/// - Custom content sections
/// - Responsive sizing
///
/// Usage:
/// ```dart
/// AwardDetailDialog.show(
///   context,
///   title: 'State Champions',
///   description: 'Won the state championship',
///   imageUrl: 'https://...',
///   year: 2024,
///   url: 'https://news.com/article',
///   onEdit: () => _editAward(),
/// );
/// ```
class AwardDetailDialog extends StatelessWidget {
  /// The title of the award/accomplishment
  final String title;

  /// Optional description text
  final String? description;

  /// Single image URL (for awards with one image)
  final String? imageUrl;

  /// Multiple image URLs (for accomplishments with multiple images)
  final List<String>? imageUrls;

  /// Year to display as a badge
  final int? year;

  /// External URL to display as a link button
  final String? url;

  /// Custom header widget (replaces default header)
  final Widget? customHeader;

  /// Additional custom content widgets to display
  final List<Widget>? additionalContent;

  /// Callback for edit action
  ///
  /// IMPORTANT: This callback is called AFTER the dialog is automatically closed.
  /// Do NOT call Navigator.pop in your onEdit handler - the dialog handles this.
  final VoidCallback? onEdit;

  /// Icon to display in header
  final IconData headerIcon;

  /// Color for header icon
  final Color? headerIconColor;

  /// Hero tag prefix for image animations
  final String? heroTagPrefix;

  const AwardDetailDialog({
    super.key,
    required this.title,
    this.description,
    this.imageUrl,
    this.imageUrls,
    this.year,
    this.url,
    this.customHeader,
    this.additionalContent,
    this.onEdit,
    this.headerIcon = Icons.emoji_events,
    this.headerIconColor,
    this.heroTagPrefix,
  });

  /// Static method to show the dialog
  static Future<void> show(
    BuildContext context, {
    required String title,
    String? description,
    String? imageUrl,
    List<String>? imageUrls,
    int? year,
    String? url,
    Widget? customHeader,
    List<Widget>? additionalContent,
    VoidCallback? onEdit,
    IconData headerIcon = Icons.emoji_events,
    Color? headerIconColor,
    String? heroTagPrefix,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AwardDetailDialog(
        title: title,
        description: description,
        imageUrl: imageUrl,
        imageUrls: imageUrls,
        year: year,
        url: url,
        customHeader: customHeader,
        additionalContent: additionalContent,
        onEdit: onEdit,
        headerIcon: headerIcon,
        headerIconColor: headerIconColor,
        heroTagPrefix: heroTagPrefix,
      ),
    );
  }

  /// Get all available images
  List<String> get _allImages {
    if (imageUrls != null && imageUrls!.isNotEmpty) {
      return imageUrls!;
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return [imageUrl!];
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: customHeader ?? _buildDefaultHeader(context),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Year badge
              if (year != null) ...[
                _buildYearBadge(context),
                const SizedBox(height: 16),
              ],

              // Images
              if (_allImages.isNotEmpty) ...[
                _buildImageSection(context),
                const SizedBox(height: 20),
              ],

              // Description
              if (description != null && description!.isNotEmpty) ...[
                Text(
                  description!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
              ],

              // External link button
              if (url != null && url!.isNotEmpty) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _launchUrl(context, url!),
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('View More'),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Additional custom content
              if (additionalContent != null) ...additionalContent!,
            ],
          ),
        ),
      ),
      actions: [
        // Edit button
        if (onEdit != null)
          TextButton.icon(
            onPressed: () {
              Navigator.pop(context);
              onEdit!();
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit'),
          ),

        // Close button
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  /// Build default header with icon and title
  Widget _buildDefaultHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          headerIcon,
          color: headerIconColor ?? Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  /// Build year badge
  Widget _buildYearBadge(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          year.toString(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }

  /// Build image section (single image or carousel)
  Widget _buildImageSection(BuildContext context) {
    if (_allImages.length == 1) {
      return _buildSingleImage(context, _allImages[0]);
    }

    return _buildImageCarousel(context);
  }

  /// Build single image with TappableImage
  Widget _buildSingleImage(BuildContext context, String imageUrl) {
    return TappableImage.network(
      imageUrl: imageUrl,
      fit: BoxFit.contain,
      borderRadius: BorderRadius.circular(12),
      heroTag: heroTagPrefix != null ? '${heroTagPrefix}_detail' : null,
      errorWidget: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Icon(Icons.broken_image, size: 48),
        ),
      ),
    );
  }

  /// Build image carousel for multiple images
  Widget _buildImageCarousel(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 250,
          child: CarouselSlider(
            options: CarouselOptions(
              height: 250,
              viewportFraction: 1.0,
              enlargeCenterPage: false,
              enableInfiniteScroll: _allImages.length > 1,
              autoPlay: _allImages.length > 1,
              autoPlayInterval: const Duration(seconds: 3),
            ),
            items: _allImages.asMap().entries.map((entry) {
              final index = entry.key;
              final url = entry.value;
              return Builder(
                builder: (BuildContext context) {
                  return TappableImage.network(
                    imageUrl: url,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(12),
                    heroTag: heroTagPrefix != null
                        ? '${heroTagPrefix}_detail_$index'
                        : null,
                    errorWidget: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.broken_image,
                        size: 48,
                      ),
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${_allImages.length} images • Tap to view',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
              ),
        ),
      ],
    );
  }

  /// Launch external URL
  Future<void> _launchUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open link')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening link: $e')),
        );
      }
    }
  }
}
