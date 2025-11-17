import 'package:flutter/material.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/utils/navigation_helper.dart';
import 'package:team_sync/widgets/responsive_avatar.dart';

/// A small responsive avatar specifically for Player objects.
///
/// This widget derives initials and profile image from the provided [player].
/// It shows a tooltip with the player's display name and navigates to the
/// player's profile when tapped (if a public database id is available).
class ResponsivePlayerAvatar extends ResponsiveAvatar {
  final Player player;
  final double? avatarSize;
  final Color? avatarBackgroundColor;
  final Widget? avatarFallbackIcon;

  const ResponsivePlayerAvatar({
    super.key,
    required this.player,
    this.avatarSize,
    this.avatarBackgroundColor,
    this.avatarFallbackIcon,
  });

  @override
  Widget build(BuildContext context) {
    // Build a generic ResponsiveAvatar with player-derived data
    final responsiveAvatar = ResponsiveAvatar(
      imageUrl: player.profileImage,
      initials:
          '${player.firstName.isNotEmpty ? player.firstName[0] : ''}${player.lastName.isNotEmpty ? player.lastName[0] : ''}',
      size: avatarSize,
      backgroundColor: avatarBackgroundColor,
      fallbackIcon: avatarFallbackIcon,
    );

    final radius = responsiveAvatar.computedRadius(context);

    final widgetWithTooltip =
        Tooltip(message: player.displayName, child: responsiveAvatar);

    if (player.id == -2) return widgetWithTooltip;

    final databaseId = DatabaseService.instance.publicShareId;

    return InkWell(
      borderRadius: BorderRadius.circular(radius),
      onTap: () {
        if (databaseId != null) {
          final location =
              '/team/$databaseId/season/${player.seasonId}/players/${player.id}';
          NavigationHelper.navigateTo(context, location,
              extra: {'player': player});
        }
      },
      child: widgetWithTooltip,
    );
  }
}
