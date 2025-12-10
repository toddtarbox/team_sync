import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/utils/navigation_helper.dart';

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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withOpacity(0.3),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.home,
            size: 16,
            color:
                Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          for (int i = 0; i < items.length; i++) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.color
                      ?.withOpacity(0.7),
                ),
              ),
            _buildBreadcrumbItem(context, items[i],
                isLast: i == items.length - 1),
          ],
        ],
      ),
    );
  }

  Widget _buildBreadcrumbItem(BuildContext context, BreadcrumbItem item,
      {required bool isLast}) {
    final baseColor =
        Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final linkColor = Colors.blue; // Standard blue link color

    final textStyle = TextStyle(
      fontSize: 14,
      color: isLast ? baseColor : linkColor,
      fontWeight: isLast ? FontWeight.w600 : FontWeight.normal,
    );

    if (isLast || item.route == null) {
      // Last item or no route - not clickable
      return Text(
        item.label,
        style: textStyle,
      );
    }

    // Clickable breadcrumb
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
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
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Text(
            item.label,
            style: textStyle.copyWith(
              decoration: TextDecoration.underline,
              decorationColor: linkColor,
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
    breadcrumbs.add(BreadcrumbItem(
      label: playerName,
      route: playerId != null ? '/team/$databaseId/player/$playerId' : null,
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
