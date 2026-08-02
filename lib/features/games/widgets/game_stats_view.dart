import 'package:change_case/change_case.dart';
import 'package:eventify/eventify.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/features/games/models/game.dart';
import 'package:team_sync/features/game_events/models/game_event.dart';
import 'package:team_sync/features/players/models/player.dart';
import 'package:team_sync/features/seasons/models/season.dart';

import 'package:team_sync/features/sports/services/sport_strategy.dart';
import 'package:team_sync/features/games/widgets/game_stats_display.dart';
import 'package:team_sync/features/seasons/widgets/stat_category_dialog.dart';
import 'package:team_sync/core/widgets/common/skeleton_container.dart';

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

class _GameStatsViewState extends State<GameStatsView> with AutomaticKeepAliveClientMixin {
  late Game _game;
  late List<ListTile> _statCategoryTiles;

  @override
  bool get wantKeepAlive => true;

  dynamic _eventCreatedListener;
  dynamic _advanceGameListener;
  dynamic _endGameListener;

  @override
  void initState() {
    _game = widget.game;

    _eventCreatedListener = widget.eventEmitter.on('eventCreated', context,
        (event, eventContext) async {
      await _loadStats();
      setState(() {});
    });

    _advanceGameListener = widget.eventEmitter.on('advanceGame', context, (event, eventContext) async {
      setState(() {});
    });

    _endGameListener = widget.eventEmitter.on('endGame', context, (event, eventContext) async {
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    _eventCreatedListener?.cancel();
    _advanceGameListener?.cancel();
    _endGameListener?.cancel();
    super.dispose();
  }
  @override
  void didUpdateWidget(GameStatsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) {
       _game = widget.game;
       _loadStats();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
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

    final playerStats = <String, Map<Player, int>>{};
    for (final category in SportStrategy.current.leaderCategories) {
      playerStats[category] = await stats.getStatPlayers(category);
    }

    _statCategoryTiles = SportStrategy.current.leaderCategories.map((category) {
      int teamTotalForCategory = 0;
      for (final stat in playerStats[category]!.entries) {
        teamTotalForCategory += stat.value;
      }

      int opponentTotalForCategory = 0;
      for (final event in _game.allGameEvents) {
        // Count legacy team corners separately since they didn't have player stats
        if (category == 'corners' &&
            event.eventType == 'Corner' &&
            event.team.id == widget.season.teamId &&
            event.player == null) {
          teamTotalForCategory++;
        }

        switch (category) {
          case 'goals':
            if (event.eventType == 'Shot' &&
                event.eventData == 0 &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case 'assists':
            break;
          case 'ownGoalsEarned':
            if (event.eventType == 'Shot' &&
                event.eventData == 0 &&
                event.player?.id == -2 &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case 'penaltyKickGoals':
            if (event.eventType == 'PenaltyKick' &&
                event.eventData == 0 &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case 'penaltyKicksTaken':
            if (event.eventType == 'PenaltyKick' &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case 'shots':
            if (event.eventType == 'Shot' &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case 'shotsOnGoal':
            if (event.eventType == 'Shot' &&
                (event.eventData == ShotResult.goal.index ||
                    event.eventData == ShotResult.onTargetSave.index) &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case 'shotsOffPost':
            if (event.eventType == 'Shot' &&
                event.eventData == ShotResult.offTargetPost.index &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case 'saves':
            if (event.eventType == 'Shot' &&
                event.eventData == ShotResult.onTargetSave.index &&
                event.team.id == widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case 'offsides':
            if (event.eventType == 'Offsides' &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case 'corners':
            if (event.eventType == 'Corner' &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case 'fouls':
            if (event.eventType == 'Foul' &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case 'yellows':
            if (event.eventType == 'Card' &&
                event.eventData == 0 &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case 'secondYellowReds':
            if (event.eventType == 'Card' &&
                event.eventData == 1 &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case 'reds':
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
            child: Text(category.toSentenceCase().toTitleCase(),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 24))),
        leading: InkWell(
            onTap: () async {
              if (teamTotalForCategory != 0) {
                if (!mounted) return;

                // Use the common dialog component
                await StatCategoryDialog.show(
                  context: context,
                  categoryName: category.toSentenceCase().toTitleCase(),
                  playerStats: playerStats[category]!,
                  showPlayerNumber: true,
                  season: widget.season,
                );
              }
            },
            child: Text(teamTotalForCategory.toString(),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    decoration:
                        category != 'corners' && teamTotalForCategory != 0
                            ? TextDecoration.underline
                            : null))),
        trailing: category == 'assists'
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
