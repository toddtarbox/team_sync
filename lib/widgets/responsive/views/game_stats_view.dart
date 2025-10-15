import 'package:auto_size_text/auto_size_text.dart';
import 'package:eventify/eventify.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';

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
        builder:
            (BuildContext context, AsyncSnapshot<List<GameStat>> snapshot) {
          if (snapshot.hasData) {
            final scoringEvents = _game.allGameEvents
                .where((e) =>
                    e.eventType == 'Shot' && e.eventData == 0 ||
                    (e.eventType == 'PenaltyKick' &&
                        e.eventData == 0 &&
                        e.eventMinute > 0))
                .toList(growable: false)
                .toList(growable: false);

            final assistEvents = _game.allGameEvents
                .where((e) => e.eventType == 'Assist')
                .toList(growable: false)
                .toList(growable: false);

            final stats = snapshot.data!;
            final statCategoryTiles = stats.map((stat) {
              return ListTile(
                leadingAndTrailingTextStyle: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 24),
                title: Center(
                    child: Text(stat.name,
                        style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 24))),
                leading: GestureDetector(
                    onTap: () {
                      if (stat.playerStats.isNotEmpty) {
                        final sortedStats = List.from(stat.playerStats.entries);
                        sortedStats.sort((a, b) => b.value.compareTo(a.value));

                        showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return ListView.builder(
                                  itemCount: sortedStats.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return ListTile(
                                          tileColor: Colors.black,
                                          title: Center(
                                              child: Text(stat.dialogName,
                                                  style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold))));
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
                    child: Text(stat.teamStat.toString(),
                        style: TextStyle(
                            decoration:
                                stat.name != 'Corners' && stat.teamStat > 0
                                    ? TextDecoration.underline
                                    : null))),
                trailing: Text(stat.opponentStat.toString()),
              );
            }).toList(growable: false);

            return ListView.separated(
                itemCount: scoringEvents.length + 2 + statCategoryTiles.length,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const ListTile(
                        tileColor: Colors.black,
                        title: Center(
                            child: Text('Scoring Summary',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold))));
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
                        tileColor: Colors.black45,
                        titleTextStyle: const TextStyle(color: Colors.white),
                        leading: AutoSizeText('${event.eventMinute}\'',
                            style: const TextStyle(color: Colors.white),
                            minFontSize: 14),
                        title: event.team.id == widget.season.team.id
                            ? AutoSizeText(event.player?.displayName ?? '',
                                style: const TextStyle(color: Colors.white),
                                minFontSize: 14)
                            : AutoSizeText(event.team.shortName,
                                style: const TextStyle(color: Colors.white),
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
                            style: const TextStyle(color: Colors.white70)),
                        trailing: Text(
                            maxLines: 1,
                            _game.getScore(widget.season.teamId,
                                minute: event.eventMinute),
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold)));
                  } else if (index == scoringEvents.length + 1) {
                    return const ListTile(
                        tileColor: Colors.black,
                        title: Center(
                            child: Text('Game Stats',
                                style: TextStyle(
                                    color: Colors.white70,
                                    fontWeight: FontWeight.bold))));
                  } else {
                    return statCategoryTiles[index - scoringEvents.length - 2];
                  }
                },
                separatorBuilder: (context, index) {
                  return const Divider(height: 1, color: Colors.black);
                });
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading stats'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  Future<List<GameStat>> _loadStats() async {
    await _game.loadGameEvents();

    return Future.wait([
      {
        'name': 'Goals',
        'dialogName': 'Goals',
        'category': 'Shot',
        'data': [0]
      },
      {
        'name': 'Penalty Kicks Goals',
        'dialogName': 'Penalty Kicks Goals',
        'category': 'PenaltyKick',
        'data': [0]
      },
      {
        'name': 'Penalty Kicks Taken',
        'dialogName': 'Penalty Kicks Taken',
        'category': 'PenaltyKick',
        'data': [-1]
      },
      {
        'name': 'Total Shots',
        'dialogName': 'Total Shots',
        'category': 'Shot',
        'data': [-1]
      },
      {
        'name': 'Shots on Goal',
        'dialogName': 'Shots on Goal',
        'category': 'Shot',
        'data': [0, 1]
      },
      {
        'name': 'Assists',
        'dialogName': 'Assists',
        'category': 'Assist',
        'data': [-1]
      },
      {
        'name': 'Saves',
        'dialogName': 'Saves',
        'category': 'Save',
        'data': [-1]
      },
      {
        'name': 'Fouls',
        'dialogName': 'Fouls',
        'category': 'Foul',
        'data': [-1]
      },
      {
        'name': 'Offsides',
        'dialogName': 'Offsides',
        'category': 'Offsides',
        'data': [-1]
      },
      {
        'name': 'Yellow Cards',
        'dialogName': 'Yellow Cards',
        'category': 'Card',
        'data': [0]
      },
      {
        'name': '2nd Yellow Cards',
        'dialogName': '2nd Yellow Cards',
        'category': 'Card',
        'data': [1]
      },
      {
        'name': 'Red Cards',
        'dialogName': 'Red Cards',
        'category': 'Card',
        'data': [2]
      },
      {
        'name': 'Corners',
        'dialogName': 'Corners',
        'category': 'Corner',
        'data': [-1]
      }
    ].map((stat) async {
      return await _game.getStats(
          stat['name'].toString(),
          stat['dialogName'].toString(),
          stat['category'].toString(),
          stat['data'] as List<int>,
          widget.season.teamId);
    }).toList(growable: false));
  }
}
