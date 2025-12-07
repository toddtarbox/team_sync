import 'package:change_case/change_case.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/season_stats.dart';
import 'package:team_sync/widgets/responsive_player_avatar.dart';

/// Reusable widget to display game statistics in a modern layout
/// Shows team comparison with visual bars and player detail drill-down
class GameStatsDisplay extends StatelessWidget {
  final Season season;
  final Game game;
  final List<ListTile> statCategoryTiles;

  const GameStatsDisplay({
    super.key,
    required this.season,
    required this.game,
    required this.statCategoryTiles,
  });

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Always show home team on left, away team on right
    final homeTeamColor = game.homeTeam.id == season.teamId
        ? season.team.color1
        : Colors.grey[700]!;
    final awayTeamColor = game.awayTeam.id == season.teamId
        ? season.team.color1
        : Colors.grey[700]!;

    final homeTeamName = game.homeTeam.shortName;
    final awayTeamName = game.awayTeam.shortName;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with team names (home always on left)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  season.team.color1.withValues(alpha: 0.1),
                  season.team.color1.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: season.team.color1.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    homeTeamName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: homeTeamColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    awayTeamName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: awayTeamColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats Section
          Text(
            loc.gameStats.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Build all stat rows
          ..._buildAllStatRows(context),
        ],
      ),
    );
  }

  List<Widget> _buildAllStatRows(BuildContext context) {
    final statRows = <Widget>[];
    final isHomeTeam = game.isHomeTeam(season.teamId);

    for (int i = 0; i < statCategoryTiles.length; i++) {
      final tile = statCategoryTiles[i];

      // Extract values from the ListTile (we stored them as Text widgets)
      final userTeamValue = int.parse((tile.leading as InkWell).child is Text
          ? ((tile.leading as InkWell).child as Text).data!
          : '0');
      final opponentValue = tile.trailing is Text
          ? (tile.trailing as Text).data == '-'
              ? 0
              : int.parse((tile.trailing as Text).data!)
          : 0;
      final label = (tile.title as Center).child is Text
          ? ((tile.title as Center).child as Text).data!
          : '';

      // Determine home and away values based on which team user is viewing
      final homeValue = isHomeTeam ? userTeamValue : opponentValue;
      final awayValue = isHomeTeam ? opponentValue : userTeamValue;

      // Skip rows where both teams have 0 stats
      if (homeValue == 0 && awayValue == 0) {
        continue;
      }

      statRows.add(_buildStatRow(
        context,
        label,
        homeValue,
        awayValue,
        showPlayerDetails: userTeamValue > 0,
        category: LeaderCategory.values[i],
        isHomeTeam: isHomeTeam,
      ));

      statRows.add(const SizedBox(height: 16));
    }

    return statRows;
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    int homeValue,
    int awayValue, {
    bool showPlayerDetails = false,
    required LeaderCategory category,
    required bool isHomeTeam,
  }) {
    final teamColor = season.team.color1;
    final total = homeValue + awayValue;
    final homePercentage = total > 0 ? homeValue / total : 0.5;

    // Color the user's team value with team color, opponent with gray
    final homeValueColor = isHomeTeam ? teamColor : Colors.grey[700]!;
    final awayValueColor = isHomeTeam ? Colors.grey[700]! : teamColor;

    return InkWell(
      onTap: showPlayerDetails && category.name != 'corners'
          ? () => _showPlayerDetailsDialog(context, category)
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.grey[300]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  homeValue.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: homeValueColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  awayValue.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: awayValueColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  if (homeValue > 0)
                    Expanded(
                      flex: (homePercentage * 100).round().clamp(1, 100),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isHomeTeam
                                ? [
                                    teamColor,
                                    teamColor.withValues(alpha: 0.8),
                                  ]
                                : [
                                    Colors.grey[400]!,
                                    Colors.grey[500]!,
                                  ],
                          ),
                        ),
                      ),
                    ),
                  if (awayValue > 0)
                    Expanded(
                      flex: ((1 - homePercentage) * 100).round().clamp(1, 100),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: isHomeTeam
                                ? [
                                    Colors.grey[400]!,
                                    Colors.grey[500]!,
                                  ]
                                : [
                                    teamColor,
                                    teamColor.withValues(alpha: 0.8),
                                  ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (showPlayerDetails && category.name != 'corners')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Tap to see player details',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPlayerDetailsDialog(
      BuildContext context, LeaderCategory category) async {
    final playerStats = await _getPlayerStatsForCategory(category);
    final sortedStats = List.from(playerStats.entries);
    sortedStats.sort((a, b) => b.value.compareTo(a.value));

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
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
                  category.name.toSentenceCase().toTitleCase(),
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
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedStats.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final player = sortedStats[index].key;
                    final count = sortedStats[index].value;
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        children: [
                          ResponsivePlayerAvatar(
                            player: player,
                            avatarSize: 48,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  player.displayName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '#${player.number}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: season.team.color1.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              count.toString(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: season.team.color1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Map<Player, int>> _getPlayerStatsForCategory(
      LeaderCategory category) async {
    final stats = await game.getStats(season.teamId);
    return await stats.getStatPlayers(category);
  }
}
