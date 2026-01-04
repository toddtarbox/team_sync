import 'package:flutter/material.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/widgets/responsive_player_avatar.dart';

/// A reusable dialog that displays stat category leaders with player names and values
class StatCategoryDialog {
  /// Shows a modal bottom sheet displaying players sorted by their stat values
  ///
  /// [context] - The build context
  /// [categoryName] - The name of the stat category (e.g., "Goals", "Assists")
  /// [playerStats] - Map of players to their stat values
  /// [showPlayerNumber] - Whether to show player numbers (default: false)
  /// [useModernStyle] - Whether to use modern style with colored badges (default: true)
  /// [onPlayerTap] - Optional callback when a player is tapped
  /// [maxPlayers] - Optional maximum number of players to show (default: show all)
  static Future<void> show({
    required BuildContext context,
    required String categoryName,
    required Map<Player, int> playerStats,
    bool showPlayerNumber = false,
    Function(Player)? onPlayerTap,
    int? maxPlayers,
    Season? season,
  }) async {
    // Sort players by stat value (highest first)
    final sortedStats = List<MapEntry<Player, int>>.from(playerStats.entries);
    sortedStats.sort((a, b) => b.value.compareTo(a.value));

    // Limit to maxPlayers if specified
    final displayStats = maxPlayers != null
        ? sortedStats.take(maxPlayers).toList()
        : sortedStats;

    if (!context.mounted) return;

    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _buildDialog(
          context,
          categoryName,
          displayStats,
          showPlayerNumber,
          onPlayerTap,
          season,
        );
      },
    );
  }

  /// Builds the dialog with rounded corners and colored badges
  static Widget _buildDialog(
    BuildContext context,
    String categoryName,
    List<MapEntry<Player, int>> sortedStats,
    bool showPlayerNumber,
    Function(Player)? onPlayerTap,
    Season? season,
  ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              // Player list
              Expanded(
                child: sortedStats.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No stats available',
                            style: TextStyle(
                              fontSize: 16,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: sortedStats.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final player = sortedStats[index].key;
                          final count = sortedStats[index].value;

                          final tile = Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest
                                  .withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                // Player avatar
                                ResponsivePlayerAvatar(
                                  player: player,
                                  avatarSize: 48,
                                  isEdit: false,
                                  useLatestImages: true,
                                  season: season,
                                ),
                                const SizedBox(width: 12),
                                // Player name and number
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        player.displayName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (showPlayerNumber)
                                        Text(
                                          '#${player.number}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onSurface
                                                .withValues(alpha: 0.6),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // Stat count badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    count.toString(),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );

                          // Wrap in InkWell if onPlayerTap is provided
                          if (onPlayerTap != null) {
                            return InkWell(
                              onTap: () => onPlayerTap(player),
                              borderRadius: BorderRadius.circular(12),
                              child: tile,
                            );
                          }

                          return tile;
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
