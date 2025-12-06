import 'package:change_case/change_case.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/season_stats.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/subscription_service.dart';
import 'package:team_sync/utils/navigation_helper.dart';
import 'package:team_sync/widgets/responsive_player_avatar.dart';

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
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  Future<SeasonStats?> _loadSeasonStats() async {
    return await widget.season.getStats();
  }

  Widget _buildModernStatsView(AppLocalizations loc, SeasonStats stats) {
    final teamColor = widget.season.team.color1;
    final teamName = widget.season.team.shortName;

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
                    loc.opponents.toUpperCase(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
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
              color: Colors.grey[600],
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

    for (final category in LeaderCategory.values) {
      final teamTotal = stats.teamStat(category);
      final opponentTotal = stats.opponentStat(category);

      // Skip rows where both teams have 0 stats
      if (teamTotal == 0 && opponentTotal == 0) {
        continue;
      }

      statRows.add(_buildStatRow(
        category.name.toSentenceCase().toTitleCase(),
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

  Widget _buildStatRow(
    String label,
    int teamValue,
    int opponentValue, {
    required LeaderCategory category,
    required SeasonStats stats,
    required Color teamColor,
  }) {
    final total = teamValue + opponentValue;
    final teamPercentage = total > 0 ? teamValue / total : 0.5;

    return InkWell(
      onTap: teamValue > 0 && category.name != 'corners'
          ? () => _showPlayerDetailsDialog(category, stats)
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
                  teamValue.toString(),
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
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                Text(
                  category.name == 'assists' ? '-' : opponentValue.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
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
                  if (opponentValue > 0 && category.name != 'assists')
                    Expanded(
                      flex: ((1 - teamPercentage) * 100).round().clamp(1, 100),
                      child: Container(
                        height: 8,
                        color: Colors.grey[400],
                      ),
                    ),
                ],
              ),
            ),
            if (teamValue > 0 && category.name != 'corners')
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
      LeaderCategory category, SeasonStats stats) async {
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
                      child: InkWell(
                        onTap: () {
                          if (!SubscriptionService.instance.isSubscribed) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: Text(loc.proFeature),
                                  content: Text(loc.playerProfilesProFeature),
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
                                color: widget.season.team.color1
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                count.toString(),
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
  }
}
