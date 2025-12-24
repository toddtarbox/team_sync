import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/utils/navigation_helper.dart';
import 'package:team_sync/widgets/responsive_avatar.dart';

/// A small responsive avatar specifically for Player objects.
///
/// This widget derives initials and profile image from the provided [player].
/// It shows a tooltip with the player's display name and navigates to the
/// player's profile when tapped (if a public database id is available).
class ResponsivePlayerAvatar extends StatefulWidget {
  final Player player;
  final double? avatarSize;
  final Color? avatarBackgroundColor;
  final Widget? avatarFallbackIcon;
  final bool isEdit;
  final bool preferProfileImage;
  final bool useLatestImages;
  final Season? season; // NEW: Season context for navigation

  const ResponsivePlayerAvatar({
    super.key,
    required this.player,
    this.avatarSize = 40,
    this.avatarBackgroundColor,
    this.avatarFallbackIcon,
    this.isEdit = false,
    this.preferProfileImage = false,
    this.useLatestImages = false,
    this.season, // NEW
  });

  @override
  State<ResponsivePlayerAvatar> createState() => _ResponsivePlayerAvatarState();
}

class _ResponsivePlayerAvatarState extends State<ResponsivePlayerAvatar> {
  Map<String, String?>? _latestImages;

  @override
  void initState() {
    super.initState();
    if (widget.useLatestImages) {
      _loadLatestImages();
    }
  }

  Future<void> _loadLatestImages() async {
    if (widget.player.id < 0) return;

    try {
      final images = await widget.player.findLatestAvailableImages();
      if (mounted) {
        setState(() {
          _latestImages = images;
        });
      }
    } catch (e) {
      // Fail silently and use default images
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the displayImageForStats helper which prioritizes:
    // headshot > profileImage > actionPhoto
    // Or displayImageForProfile if preferProfileImage is true
    String? imageUrl;

    if (_latestImages != null) {
      final profile = _latestImages!['profileImage'];
      final headshot = _latestImages!['headshot'];
      final action = _latestImages!['actionPhoto'];

      if (widget.preferProfileImage) {
        imageUrl = profile ?? headshot ?? action;
      } else {
        imageUrl = headshot ?? profile ?? action;
      }
    } else {
      imageUrl = widget.preferProfileImage
          ? widget.player.displayImageForProfile
          : widget.player.displayImageForStats;
    }

    // Build a generic ResponsiveAvatar with player-derived data
    final responsiveAvatar = ResponsiveAvatar(
      imageUrl: imageUrl,
      initials:
          '${widget.player.firstName.isNotEmpty ? widget.player.firstName[0] : ''}${widget.player.lastName.isNotEmpty ? widget.player.lastName[0] : ''}',
      size: widget.avatarSize,
      backgroundColor: widget.avatarBackgroundColor,
      fallbackIcon: widget.avatarFallbackIcon,
    );

    final radius = responsiveAvatar.computedRadius(context);

    final widgetWithTooltip =
        Tooltip(message: widget.player.displayName, child: responsiveAvatar);

    if (widget.player.id == -2) return widgetWithTooltip;

    final databaseId = DatabaseService.instance.publicShareId;

    // Check if we're already on this player's profile page
    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: widget.isEdit
          ? null
          : () {
              if (databaseId != null) {
                bool isOnPlayerProfile = false;
                try {
                  final currentLocation =
                      GoRouterState.of(context).uri.toString();
                  final playerProfileLocation =
                      '/team/$databaseId/player/${widget.player.id}';
                  isOnPlayerProfile =
                      currentLocation.contains(playerProfileLocation);
                } catch (_) {
                  // Fallback if GoRouterState is not found (e.g. in dialogs)
                }

                // If already on the player profile page, show larger view
                if (isOnPlayerProfile &&
                    widget.player.displayImageForProfile != null) {
                  _showLargeProfileImage(context);
                } else {
                  // Navigate to player profile page
                  String location;
                  Map<String, dynamic> extra = {'player': widget.player};

                  if (widget.season != null) {
                    // Use season-scoped route
                    location =
                        '/team/$databaseId/season/${widget.season!.id}/players/${widget.player.id}';
                    extra['season'] = widget.season;
                  } else {
                    // use global route (defaults to latest season)
                    location = '/team/$databaseId/player/${widget.player.id}';
                  }

                  NavigationHelper.navigateTo(context, location, extra: extra);
                }
              }
            },
      child: widgetWithTooltip,
    );
  }

  /// Shows a larger view of the player's profile image in a dialog
  void _showLargeProfileImage(BuildContext context) {
    // Use displayImageForProfile helper which prioritizes:
    // profileImage > headshot > actionPhoto
    final imageUrl = widget.player.displayImageForProfile;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 32),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                // Large profile image
                Flexible(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 200,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: widget.avatarBackgroundColor ??
                                      Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Text(
                                    '${widget.player.firstName.isNotEmpty ? widget.player.firstName[0] : ''}${widget.player.lastName.isNotEmpty ? widget.player.lastName[0] : ''}',
                                    style: const TextStyle(
                                      fontSize: 72,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              color: widget.avatarBackgroundColor ??
                                  Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                '${widget.player.firstName.isNotEmpty ? widget.player.firstName[0] : ''}${widget.player.lastName.isNotEmpty ? widget.player.lastName[0] : ''}',
                                style: const TextStyle(
                                  fontSize: 72,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                // Player name
                Text(
                  widget.player.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        offset: Offset(0, 1),
                        blurRadius: 3,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
