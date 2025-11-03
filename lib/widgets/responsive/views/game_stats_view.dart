import 'package:auto_size_text/auto_size_text.dart';
import 'package:change_case/change_case.dart';
import 'package:eventify/eventify.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/season_stats.dart';

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
    return FutureBuilder(
        future: _loadStats(),
        builder: (BuildContext context, AsyncSnapshot<GameStats> snapshot) {
          if (snapshot.hasData) {
            final scoringEvents = _game.allGameEvents
                .where((e) =>
                    e.eventType == 'Shot' && e.eventData == 0 ||
                    (e.eventType == 'PenaltyKick' &&
                        e.eventData == 0 &&
                        e.eventMinute > 0))
                .toList(growable: false);

            final assistEvents = _game.allGameEvents
                .where((e) => e.eventType == 'Assist')
                .toList(growable: false);

            return ListView.separated(
                itemCount: scoringEvents.length + 2 + _statCategoryTiles.length,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const ListTile(
                        title: Center(
                            child: Text('Scoring Summary',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))));
                  } else if (index <= scoringEvents.length) {
                    final event = scoringEvents[index - 1];
                    final assistEvent = assistEvents
                        .where((e) =>
                            (e.id == event.id + 1 && e.eventType == 'Assist') ||
                            e.eventData == event.id)
                        .firstOrNull;

                    final opponent =
                        !widget.game.isHomeTeam(widget.season.teamId)
                            ? widget.game.homeTeam
                            : widget.game.awayTeam;

                    return ListTile(
                        leading: AutoSizeText('${event.eventMinute}\'',
                            minFontSize: 14),
                        title: event.team.id == widget.season.team.id
                            ? AutoSizeText(event.player?.displayName ?? '',
                                minFontSize: 14)
                            : AutoSizeText(event.team.shortName,
                                minFontSize: 14),
                        subtitle: AutoSizeText(
                          event.team.id == widget.season.team.id &&
                                  assistEvent != null
                              ? assistEvent.display
                              : event.eventType == 'PenaltyKick'
                                  ? 'PK'
                                  : event.team.id == widget.season.team.id
                                      ? event.player == null
                                          ? 'Own goal by ${opponent.shortName}'
                                          : 'No assist'
                                      : '',
                        ),
                        trailing: Text(
                            maxLines: 1,
                            _game.getScore(widget.season.teamId,
                                minute: event.eventMinute),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)));
                  } else if (index == scoringEvents.length + 1) {
                    return const ListTile(
                        title: Center(
                            child: Text('Game Stats',
                                style:
                                    TextStyle(fontWeight: FontWeight.bold))));
                  } else {
                    return _statCategoryTiles[index - scoringEvents.length - 2];
                  }
                },
                separatorBuilder: (context, index) {
                  return const Divider(height: 1);
                });
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading stats'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
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
        switch (category) {
          case LeaderCategory.goals:
            if (event.eventType == 'Shot' &&
                event.eventData == 0 &&
                event.team.id != widget.season.teamId) {
              opponentTotalForCategory++;
            }
            break;
          case LeaderCategory.assists:
          case LeaderCategory.ownGoalsEarned:
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
        leading: GestureDetector(
            onTap: () async {
              if (playerStats.isNotEmpty) {
                final sortedStats = List.from(playerStats[category]!.entries);
                sortedStats.sort((a, b) => b.value.compareTo(a.value));

                if (!mounted) return;
                showModalBottomSheet(
                    context: context,
                    builder: (context) {
                      return ListView.builder(
                          itemCount: sortedStats.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return ListTile(
                                  title: Center(
                                      child: Text(
                                          category.name
                                              .toSentenceCase()
                                              .toTitleCase(),
                                          style: const TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold))));
                            }

                            final player = sortedStats[index - 1].key;
                            final count = sortedStats[index - 1].value;
                            return ListTile(
                              leading: Text(player.displayName,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              title: Text(count.toString(),
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                            );
                          });
                    });
              }
            },
            child: Text(teamTotalForCategory.toString(),
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    decoration: category.name != 'Corners' &&
                            _game.allGameEvents
                                .where((e) =>
                                    e.eventType == category.name &&
                                    e.team.id == widget.season.teamId)
                                .isNotEmpty
                        ? TextDecoration.underline
                        : null))),
        trailing: Text(opponentTotalForCategory.toString(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
      );
    }).toList(growable: false);

    return stats;
  }
}
