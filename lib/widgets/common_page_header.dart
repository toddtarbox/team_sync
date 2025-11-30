import 'package:flutter/material.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/widgets/responsive_avatar.dart';

/// A common page header widget that displays team information with logo and name.
/// Use this below your AppBar for consistent team branding across pages.
class CommonPageHeader extends StatelessWidget {
  final Team team;
  final double? height;
  final EdgeInsets? padding;

  const CommonPageHeader({
    super.key,
    required this.team,
    this.height,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final responsiveAvatar = ResponsiveAvatar(
      imageUrl: team.logoUrl,
      initials: team.fullName.isNotEmpty ? team.fullName[0] : '?',
    );

    return Container(
      height: height ?? 100,
      padding: padding ?? const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            team.color1,
            team.color2,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (team.logoUrl != null && team.logoUrl!.isNotEmpty)
            responsiveAvatar,
          if (team.logoUrl != null && team.logoUrl!.isNotEmpty)
            const SizedBox(width: 10),
          Flexible(
            child: Text(
              team.fullName,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
