import 'package:change_case/change_case.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/features/seasons/models/season.dart';
import 'package:team_sync/features/seasons/models/season_stats.dart';
import 'package:team_sync/core/services/database_service.dart';
import 'package:team_sync/core/services/subscription_service.dart';
import 'package:team_sync/core/utils/navigation_helper.dart';
import 'package:team_sync/features/players/widgets/responsive_player_avatar.dart';
import 'package:team_sync/core/widgets/common/skeleton_container.dart';
import 'package:team_sync/features/sports/services/sport_strategy.dart'; // Added import for SportStrategy

class SeasonStatsView extends StatefulWidget {
  final Season season;

  const SeasonStatsView({super.key, required this.season});

  @override
  State<SeasonStatsView> createState() => _SeasonStatsViewState();
}

class _SeasonStatsViewState extends State<SeasonStatsView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _loadSeasonStats(),
        builder: (BuildContext context, AsyncSnapshot<SeasonStats?> snapshot) {
          final loc = AppLocalizations.of(context)!;

          if (snapshot.hasData) {
            final stats = snapshot.data!;
            return _buildModernStatsView(loc, stats);
          } else if (snapshot.hasError) {
            return Center(child: Text(loc.errorLoadingStats));
          } else {
            return _buildSkeletonView(context);
          }
        });
  }

  Widget _buildSkeletonView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Skeleton (Matches Modern View Header)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              // Use a subtle color to mimic the gradient/container
              color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Team Name Skeleton
                SkeletonContainer.rectangular(
                  width: 80,
                  height: 24,
                ),
                // VS Badge Skeleton
                SkeletonContainer.rectangular(
                  width: 50,
                  height: 36,
                  borderRadius: BorderRadius.circular(8),
                ),
                // Opponent Name Skeleton
                SkeletonContainer.rectangular(
                  width: 80,
                  height: 24,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Title Skeleton
          SkeletonContainer.rectangular(
            width: 120,
            height: 16,
          ),
          const SizedBox(height: 16),

          // Stat Rows Skeletons
          ...List.generate(
            6,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colorScheme.outlineVariant,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left Value
                        SkeletonContainer.rectangular(
                          width: 30,
                          height: 20,
                        ),
                        // Label
                        SkeletonContainer.rectangular(
                          width: 100,
                          height: 16,
                        ),
                        // Right Value
                        SkeletonContainer.rectangular(
                          width: 30,
                          height: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Bars Skeleton
                    Row(
                      children: [
                        Expanded(
                          child: SkeletonContainer.rectangular(
                            width: double.infinity,
                            height: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: SkeletonContainer.rectangular(
                            width: double.infinity,
                            height: 8,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // "Tap to see details" Skeleton
                    if (index % 2 == 0) // Randomly show for some rows
                      Align(
                        alignment: Alignment.center,
                        child: SkeletonContainer.rectangular(
                          width: 140,
                          height: 10,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<SeasonStats?> _loadSeasonStats() async {
    return await widget.season.getStats();
  }

  Widget _buildModernStatsView(AppLocalizations loc, SeasonStats stats) {
    final teamColor = widget.season.team.color1;
    final teamName = widget.season.team.shortName;
    final colorScheme = Theme.of(context).colorScheme;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with team names
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  teamColor.withValues(alpha: 0.1),
                  teamColor.withValues(alpha: 0.05),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: teamColor.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    teamName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: teamColor,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'VS',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    loc.opponents.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
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
            loc.seasonStats.toUpperCase(),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: colorScheme.secondary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 16),

          // Build all stat rows
          ..._buildAllStatRows(loc, stats, teamColor),
        ],
      ),
    );
  }

  List<Widget> _buildAllStatRows(
      AppLocalizations loc, SeasonStats stats, Color teamColor) {
    final statRows = <Widget>[];
    // Use SportStrategy to get categories
    for (final category in SportStrategy.current.leaderCategories) {
      if (category == 'points') {
        statRows.add(_buildCategoryHeader('Scoring'));
      } else if (category == 'rebounds') {
        statRows.add(_buildCategoryHeader('Rebounding'));
      } else if (category == 'assists') {
        statRows.add(_buildCategoryHeader('Other Stats'));
      }

      final teamTotal = stats.teamStat(category);
      final opponentTotal = stats.opponentStat(category);

      // Skip rows where both teams have 0 stats
      if (teamTotal == 0 && opponentTotal == 0) {
        continue;
      }

      statRows.add(_buildStatRow(
        category.toSentenceCase().toTitleCase(),
        teamTotal,
        opponentTotal,
        category: category,
        stats: stats,
        teamColor: teamColor,
      ));

      statRows.add(const SizedBox(height: 16));
    }

    return statRows;
  }

  Widget _buildCategoryHeader(String title) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      child: Row(
        children: [
          Expanded(child: Divider(color: colorScheme.outlineVariant)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: colorScheme.secondary,
                letterSpacing: 1.2,
              ),
            ),
          ),
          Expanded(child: Divider(color: colorScheme.outlineVariant)),
        ],
      ),
    );
  }

  Widget _buildStatRow(
    String label,
    int teamValue,
    int opponentValue, {
    required String category,
    required SeasonStats stats,
    required Color teamColor,
  }) {
    String teamDisplay;
    String opponentDisplay;

    if (category.contains('percentage')) {
      String madeKey = '';
      String missedKey = '';
      if (category == '3_point_percentage') {
        madeKey = '3_pointers';
        missedKey = '3_pointers_missed';
      } else if (category == '2_point_percentage') {
        madeKey = '2_pointers';
        missedKey = '2_pointers_missed';
      } else if (category == 'free_throw_percentage') {
        madeKey = 'free_throws';
        missedKey = 'free_throws_missed';
      }

      if (madeKey.isNotEmpty) {
        final teamMade = stats.teamStat(madeKey);
        final teamMissed = stats.teamStat(missedKey);
        final teamAttempts = teamMade + teamMissed;
        teamDisplay = '$teamValue% ($teamMade/$teamAttempts)';

        final opponentMade = stats.opponentStat(madeKey);
        final opponentMissed = stats.opponentStat(missedKey);
        final opponentAttempts = opponentMade + opponentMissed;
        opponentDisplay = '$opponentValue% ($opponentMade/$opponentAttempts)';
      } else {
        teamDisplay = '$teamValue%';
        opponentDisplay = '$opponentValue%';
      }
    } else {
      teamDisplay = teamValue.toString();
      opponentDisplay = category == 'assists' ? '-' : opponentValue.toString();
    }

    final total = teamValue + opponentValue;
    final teamPercentage = total > 0 ? teamValue / total : 0.5;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap:
          teamValue > 0 && category != 'corners' && category != 'ownGoalsEarned'
              ? () => _showPlayerDetailsDialog(category, stats)
              : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: colorScheme.outlineVariant,
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
                  teamDisplay,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: teamColor,
                  ),
                ),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  opponentDisplay,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Row(
                children: [
                  if (teamValue > 0)
                    Expanded(
                      flex: (teamPercentage * 100).round().clamp(1, 100),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              teamColor,
                              teamColor.withValues(alpha: 0.8),
                            ],
                          ),
                        ),
                      ),
                    ),
                  if (opponentValue > 0 && category != 'assists')
                    Expanded(
                      flex: ((1 - teamPercentage) * 100).round().clamp(1, 100),
                      child: Container(
                        height: 8,
                        color: colorScheme.surfaceContainerHighest,
                      ),
                    ),
                ],
              ),
            ),
            if (teamValue > 0 &&
                category != 'corners' &&
                category != 'ownGoalsEarned')
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Tap to see player details',
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
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
      String category, SeasonStats stats) async {
    final loc = AppLocalizations.of(context)!;

    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(title: Text(loc.loading));
      },
    );

    final stat = await stats.getStatPlayers(category);

    if (!mounted) return;
    Navigator.pop(context);

    if (stat.isEmpty) return;

    final sortedStats = List.from(stat.entries);
    sortedStats.sort((a, b) => b.value.compareTo(a.value));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            final colorScheme = Theme.of(context).colorScheme;
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8, bottom: 16),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      category.toSentenceCase().toTitleCase(),
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
                      controller: scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: sortedStats.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final player = sortedStats[index].key;
                        final count = sortedStats[index].value;

                        String displayValue = count.toString();
                        if (category.contains('percentage')) {
                          String madeKey = '';
                          String missedKey = '';
                          if (category == '3_point_percentage') {
                            madeKey = '3_pointers';
                            missedKey = '3_pointers_missed';
                          } else if (category == '2_point_percentage') {
                            madeKey = '2_pointers';
                            missedKey = '2_pointers_missed';
                          } else if (category == 'free_throw_percentage') {
                            madeKey = 'free_throws';
                            missedKey = 'free_throws_missed';
                          }

                          if (madeKey.isNotEmpty) {
                            // Helper to safely get player stat
                            int getPlayerStat(String key, int playerId) {
                              return stats.playerStats[key]?[playerId] ?? 0;
                            }

                            final made = getPlayerStat(madeKey, player.id);
                            final missed = getPlayerStat(missedKey, player.id);
                            final attempts = made + missed;
                            displayValue = '$count% ($made/$attempts)';
                          } else {
                            displayValue = '$count%';
                          }
                        }

                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: colorScheme.outlineVariant),
                          ),
                          child: InkWell(
                            onTap: () {
                              if (!kIsWeb &&
                                  !SubscriptionService.instance.isSubscribed) {
                                showDialog(
                                  context: context,
                                  builder: (BuildContext context) {
                                    return AlertDialog(
                                      title: Text(loc.proFeature),
                                      content:
                                          Text(loc.playerProfilesProFeature),
                                      actions: [
                                        TextButton(
                                          child: Text(loc.cancelButton),
                                          onPressed: () {
                                            Navigator.pop(context);
                                          },
                                        ),
                                        TextButton(
                                          child: Text(loc.goPro),
                                          onPressed: () async {
                                            Navigator.pop(context);
                                            await SubscriptionService.instance
                                                .purchaseSubscription();
                                          },
                                        ),
                                      ],
                                    );
                                  },
                                );
                                return;
                              }
                              final databaseId =
                                  DatabaseService.instance.publicShareId;
                              if (databaseId != null) {
                                NavigationHelper.navigateTo(
                                  context,
                                  '/team/$databaseId/season/${widget.season.id}/players/${player.id}',
                                  extra: {
                                    'player': player,
                                    'season': widget.season
                                  },
                                );
                              }
                            },
                            child: Row(
                              children: [
                                ResponsivePlayerAvatar(
                                  player: player,
                                  avatarSize: 48,
                                  useLatestImages: true,
                                  season: widget.season,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        player.displayName,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          player.displayNumbers,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
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
                                    color: widget.season.team.color1
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    displayValue,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: widget.season.team.color1,
                                    ),
                                  ),
                                ),
                              ],
                            ),
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
      },
    );
  }
}
