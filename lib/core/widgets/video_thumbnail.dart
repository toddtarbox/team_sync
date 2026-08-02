import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/core/widgets/common/skeleton_container.dart';
import 'package:url_launcher/url_launcher.dart';

/// A small thumbnail/preview for video links.
///
/// Currently supports YouTube thumbnails (auto-derived). For other URLs it
/// shows a generic play icon on a colored background. Tapping the thumbnail
/// will open [url] using url_launcher if provided.
class VideoThumbnail extends StatelessWidget {
  final String url;
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final void Function()? onTap;

  const VideoThumbnail(
    this.url, {
    super.key,
    this.width = 120,
    this.height = 68,
    this.borderRadius,
    this.onTap,
  });

  static String? _youtubeId(String url) {
    try {
      final uri = Uri.parse(url);
      // youtu.be short links
      if (uri.host.contains('youtu.be')) {
        final id = uri.pathSegments.isNotEmpty ? uri.pathSegments[0] : null;
        return id;
      }

      // youtube.com with v= or /embed/
      if (uri.host.contains('youtube.com')) {
        final v = uri.queryParameters['v'];
        if (v != null && v.isNotEmpty) return v;
        // check for /embed/ID
        final segments = uri.pathSegments;
        final embedIndex = segments.indexOf('embed');
        if (embedIndex != -1 && segments.length > embedIndex + 1) {
          return segments[embedIndex + 1];
        }
      }

      // Fallback heuristic: regex for 11-char id, but ONLY if it looks like a youtube link
      if (url.contains('youtube.com') || url.contains('youtu.be')) {
        final reg = RegExp(r'([0-9A-Za-z_-]{11})');
        final m = reg.firstMatch(url);
        if (m != null) return m.group(1);
      }
    } catch (_) {}
    return null;
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          Icons.play_circle_outline,
          size: width < 48 ? 28 : 40,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
        ),
      ),
    );
  }

  Future<void> _openUrl(BuildContext context) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch URL: $e');
      if (context.mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.couldNotOpenUrl(url))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final yt = _youtubeId(url);
    if (yt != null && yt.isNotEmpty) {
      final thumb = 'https://img.youtube.com/vi/$yt/hqdefault.jpg';
      return GestureDetector(
        onTap: onTap ?? () => _openUrl(context),
        child: ClipRRect(
          borderRadius: borderRadius ?? BorderRadius.circular(8),
          child: Image.network(
            thumb,
            width: width,
            height: height,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildPlaceholder(context),
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) {
                return Stack(children: [
                  child,
                  Positioned.fill(child: Container(color: Colors.black26))
                ]);
              }
              return SkeletonContainer.rectangular(
                width: width,
                height: height,
                borderRadius: borderRadius ?? BorderRadius.zero,
              );
            },
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap ?? () => _openUrl(context),
      child: _buildPlaceholder(context),
    );
  }
}
