import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:team_sync/models/player.dart';
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

  const ResponsivePlayerAvatar({
    super.key,
    required this.player,
    this.avatarSize,
    this.avatarBackgroundColor,
    this.avatarFallbackIcon,
    this.isEdit = false,
  });

  @override
  State<ResponsivePlayerAvatar> createState() => _ResponsivePlayerAvatarState();
}

class _ResponsivePlayerAvatarState extends State<ResponsivePlayerAvatar> {
  String? _profileImage;
  String? _actionPhoto;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  @override
  void didUpdateWidget(ResponsivePlayerAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reload images if player changed
    if (oldWidget.player.id != widget.player.id ||
        oldWidget.player.seasonId != widget.player.seasonId) {
      _loadImages();
    }
  }

  Future<void> _loadImages() async {
    // Find latest available images across all seasons
    final images = await widget.player.findLatestAvailableImages();
    if (mounted) {
      setState(() {
        _profileImage = images['profileImage'];
        _actionPhoto = images['actionPhoto'];
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use loaded images from state (which includes fallback to previous seasons)
    final imageUrl = (_profileImage != null && _profileImage!.isNotEmpty)
        ? _profileImage
        : _actionPhoto;

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
                final currentLocation =
                    GoRouterState.of(context).uri.toString();
                final playerProfileLocation =
                    '/team/$databaseId/season/${widget.player.seasonId}/players/${widget.player.id}';
                final isOnPlayerProfile =
                    currentLocation.contains(playerProfileLocation);

                // If already on the player profile page, show larger view
                if (isOnPlayerProfile &&
                    ((_profileImage != null && _profileImage!.isNotEmpty) ||
                        (_actionPhoto != null && _actionPhoto!.isNotEmpty))) {
                  _showLargeProfileImage(context);
                } else {
                  // Navigate to player profile page
                  final location =
                      '/team/$databaseId/season/${widget.player.seasonId}/players/${widget.player.id}';
                  NavigationHelper.navigateTo(context, location,
                      extra: {'player': widget.player});
                }
              }
            },
      child: widgetWithTooltip,
    );
  }

  /// Shows a larger view of the player's profile image in a dialog
  void _showLargeProfileImage(BuildContext context) {
    // Use loaded images from state (which includes fallback to previous seasons)
    final imageUrl = (_profileImage != null && _profileImage!.isNotEmpty)
        ? _profileImage
        : _actionPhoto;

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
