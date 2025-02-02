import 'package:auto_size_text/auto_size_text.dart';
import 'package:eventify/eventify.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';

class GameStatsView extends StatefulWidget {
  final Database database;
  final Season season;
  final Game game;
  final EventEmitter eventEmitter;

  const GameStatsView(
      {super.key,
      required this.database,
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
                        showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return ListView.builder(
                                  itemCount: stat.playerStats.length + 1,
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

                                    final player = stat.playerStats.keys
                                        .toList()[index - 1];
                                    final count = stat.playerStats.values
                                        .toList()[index - 1];
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
                            decoration: stat.teamStat > 0
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

                    return ListTile(
                      tileColor: Colors.black45,
                      titleTextStyle: const TextStyle(color: Colors.white),
                      leading: event.team.id == widget.season.team.id
                          ? SizedBox(
                              width: 200,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    AutoSizeText(
                                        '${event.eventMinute}\'  ${event.player?.displayName ?? ''}',
                                        style: const TextStyle(
                                            color: Colors.white),
                                        minFontSize: 16),
                                    AutoSizeText(
                                        event.team.id ==
                                                    widget.season.team.id &&
                                                assistEvent != null
                                            ? assistEvent.display
                                            : event.eventType == 'PenaltyKick'
                                                ? 'PK'
                                                : event.team.id ==
                                                        widget.season.team.id
                                                    ? event.player == null
                                                        ? 'Own goal'
                                                        : 'No assist'
                                                    : '',
                                        style: const TextStyle(
                                            color: Colors.white70))
                                  ]))
                          : const SizedBox(width: 200),
                      title: Center(
                          child: Text(_game.getScore(event.eventMinute),
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold))),
                      trailing: event.team.id != widget.season.team.id
                          ? SizedBox(
                              width: 200,
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    AutoSizeText(
                                        '${event.team.shortName} ${event.eventMinute}\'',
                                        style: const TextStyle(
                                            color: Colors.white),
                                        minFontSize: 16),
                                    AutoSizeText(
                                        event.eventType == 'PenaltyKick'
                                            ? 'PK'
                                            : '',
                                        style: const TextStyle(
                                            color: Colors.white70))
                                  ]))
                          : const SizedBox(width: 200),
                    );
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
    await _game.loadGameEvents(widget.database);

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
        'name': 'Corners',
        'dialogName': 'Corners',
        'category': 'Corner',
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
    ].map((stat) async {
      return await _game.getStats(
          widget.database,
          stat['name'].toString(),
          stat['dialogName'].toString(),
          stat['category'].toString(),
          stat['data'] as List<int>,
          widget.season.teamId);
    }).toList(growable: false));
  }
}
