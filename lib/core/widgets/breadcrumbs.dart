import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/core/utils/navigation_helper.dart';

/// A breadcrumb item representing a navigation level
class BreadcrumbItem {
  final String label;
  final String? route;
  final Object? extra;

  const BreadcrumbItem({
    required this.label,
    this.route,
    this.extra,
  });
}

/// Breadcrumbs navigation widget for web
/// Shows navigation hierarchy starting from Home
class Breadcrumbs extends StatelessWidget {
  final List<BreadcrumbItem> items;

  const Breadcrumbs({
    super.key,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    // Only show breadcrumbs on web
    if (!kIsWeb) {
      return const SizedBox.shrink();
    }

    // Don't show if only home (no deeper navigation)
    if (items.length <= 1) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Icon(
              Icons.home_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            for (int i = 0; i < items.length; i++) ...[
              if (i > 0)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                ),
              _buildBreadcrumbItem(context, items[i],
                  isLast: i == items.length - 1),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBreadcrumbItem(BuildContext context, BreadcrumbItem item,
      {required bool isLast}) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isLast || item.route == null) {
      // Last item or no route - not clickable
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Text(
          item.label,
          style: TextStyle(
            fontSize: 14,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    // Clickable breadcrumb
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          if (item.route != null) {
            NavigationHelper.navigateTo(
              context,
              item.route!,
              extra: item.extra,
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            item.label,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

/// Helper function to build breadcrumbs for team pages
List<BreadcrumbItem> buildTeamBreadcrumbs({
  required String databaseId,
  required String teamName,
  String? seasonName,
  int? seasonId,
  String? playerName,
  int? playerId,
  String? gameName,
  String? additionalLabel,
}) {
  final List<BreadcrumbItem> breadcrumbs = [
    BreadcrumbItem(
      label: teamName,
      route: '/team/$databaseId',
    ),
  ];

  if (seasonName != null) {
    breadcrumbs.add(BreadcrumbItem(
      label: seasonName,
      route: seasonId != null ? '/team/$databaseId/season/$seasonId' : null,
    ));
  }

  if (playerName != null) {
    String? playerRoute;
    if (playerId != null) {
      if (seasonId != null) {
        playerRoute = '/team/$databaseId/season/$seasonId/players/$playerId';
      } else {
        playerRoute = '/team/$databaseId/player/$playerId';
      }
    }

    breadcrumbs.add(BreadcrumbItem(
      label: playerName,
      route: playerRoute,
    ));
  }

  if (gameName != null) {
    breadcrumbs.add(BreadcrumbItem(
      label: gameName,
      // Game route would go here if needed
    ));
  }

  if (additionalLabel != null) {
    breadcrumbs.add(BreadcrumbItem(
      label: additionalLabel,
    ));
  }

  return breadcrumbs;
}
