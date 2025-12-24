import 'package:change_case/change_case.dart';
import 'package:eventify/eventify.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/season_stats.dart';
import 'package:team_sync/widgets/game_stats_display.dart';
import 'package:team_sync/widgets/stat_category_dialog.dart';
import 'package:team_sync/widgets/common/skeleton_container.dart';

class GameStatsView extends StatefulWidget {
  final Season season;
  final Game game;
  final EventEmitter eventEmitter;

  const GameStatsView(
      {super.key,
      required this.season,
      required this.game,
      required this.eventEmitter});

  @override
  State<GameStatsView> createState() => _GameStatsViewState();
}

class _GameStatsViewState extends State<GameStatsView> {
  late Game _game;
  late List<ListTile> _statCategoryTiles;

  @override
  void initState() {
    _game = widget.game;

    widget.eventEmitter.on('eventCreated', context,
        (event, eventContext) async {
      await _loadStats();
      setState(() {});
    });

    widget.eventEmitter.on('advanceGame', context, (event, eventContext) async {
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return FutureBuilder(
        future: _loadStats(),
        builder: (BuildContext context, AsyncSnapshot<GameStats> snapshot) {
          if (snapshot.hasData) {
            return GameStatsDisplay(
              season: widget.season,
              game: _game,
              statCategoryTiles: _statCategoryTiles,
            );
          } else if (snapshot.hasError) {
            return Center(child: Text(loc.errorLoadingStats));
          } else {
            return _buildSkeletonView(context);
          }
        });
  }

  Widget _buildSkeletonView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Skeleton
          SkeletonContainer.rectangular(
            width: double.infinity,
            height: 100,
            borderRadius: BorderRadius.circular(12),
          ),
          const SizedBox(height: 24),

          // Title Skeleton
          SkeletonContainer.rectangular(
            width: 150,
            height: 20,
          ),
          const SizedBox(height: 16),

          // Stat Rows Skeletons
          ...List.generate(
            6,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SkeletonContainer.rectangular(
                width: double.infinity,
                height: 80,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<GameStats> _loadStats() async {
    await _game.loadGameEvents();
    final stats = await _game.getStats(widget.season.teamId);

    final playerStats = <LeaderCategory, Map<Player, int>>{};
    for (final category in LeaderCategory.values) {
      playerStats[category] = await stats.getStatPlayers(category);
    }

    _statCategoryTiles = LeaderCategory.values.map((category) {
      int teamTotalForCategory = 0;
      for (final stat in playerStats[category]!.entries) {
        teamTotalForCategory += stat.value;
      }

      int opponentTotalForCategory = 0;
      for (final event in _game.allGameEvents) {
        // Count team corners separately since they don't have player stats
        if (category == LeaderCategory.corners &&
            event.eventType == 'Corner' &&
            event.team.id == widget.season.teamId) {
          teamTotalForCategory++;
        }

        switch (category) {
          case LeaderCategory.goals:
            if (event.eventType == 'Shot' &&
                event.eventData == 0 &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case LeaderCategory.assists:
            break;
          case LeaderCategory.ownGoalsEarned:
            if (event.eventType == 'Shot' &&
                event.eventData == 0 &&
                event.player?.id == -2 &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case LeaderCategory.penaltyKickGoals:
            if (event.eventType == 'PenaltyKick' &&
                event.eventData == 0 &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case LeaderCategory.penaltyKicksTaken:
            if (event.eventType == 'PenaltyKick' &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case LeaderCategory.shots:
            if (event.eventType == 'Shot' &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case LeaderCategory.shotsOnGoal:
            if (event.eventType == 'Shot' &&
                (event.eventData == ShotResult.goal.index ||
                    event.eventData == ShotResult.onTargetSave.index) &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case LeaderCategory.shotsOffPost:
            if (event.eventType == 'Shot' &&
                event.eventData == ShotResult.offTargetPost.index &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case LeaderCategory.saves:
            if (event.eventType == 'Shot' &&
                event.eventData == ShotResult.onTargetSave.index &&
                event.team.id == widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case LeaderCategory.offsides:
            if (event.eventType == 'Offsides' &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case LeaderCategory.corners:
            if (event.eventType == 'Corner' &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case LeaderCategory.fouls:
            if (event.eventType == 'Foul' &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case LeaderCategory.yellows:
            if (event.eventType == 'Card' &&
                event.eventData == 0 &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case LeaderCategory.secondYellowReds:
            if (event.eventType == 'Card' &&
                event.eventData == 1 &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case LeaderCategory.reds:
            if (event.eventType == 'Card' &&
                event.eventData == 2 &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
        }
      }

      return ListTile(
        title: Center(
            child: Text(category.name.toSentenceCase().toTitleCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 24))),
        leading: InkWell(
            onTap: () async {
              if (teamTotalForCategory != 0) {
                if (!mounted) return;

                // Use the common dialog component
                await StatCategoryDialog.show(
                  context: context,
                  categoryName: category.name.toSentenceCase().toTitleCase(),
                  playerStats: playerStats[category]!,
                  showPlayerNumber: true,
                );
              }
            },
            child: Text(teamTotalForCategory.toString(),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    decoration:
                        category.name != 'corners' && teamTotalForCategory != 0
                            ? TextDecoration.underline
                            : null))),
        trailing: category.name == 'assists'
            ? Text('-',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 24))
            : Text(opponentTotalForCategory.toString(),
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
      );
    }).toList(growable: false);

    return stats;
  }
}
