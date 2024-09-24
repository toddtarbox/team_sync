import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/widgets/scoreboard.dart';

class GameStatsPage extends StatelessWidget {
  final Database database;
  final Season season;
  final Game game;

  const GameStatsPage(
      {required this.database,
      required this.season,
      required this.game,
      super.key});

  @override
  Widget build(BuildContext context) {
    final gameEvents = game.allGameEvents;
    final scoringEvents = game.allGameEvents
        .where((e) =>
            e.eventType == 'Shot' && e.eventData == 0 ||
            (e.eventType == 'PenaltyKick' &&
                e.eventData == 0 &&
                e.eventMinute > 0))
        .toList(growable: false)
        .reversed
        .toList(growable: false);

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          leading: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const Icon(Icons.arrow_back, color: Colors.white70)),
          title: Text(game.displayName(season.teamId),
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
        ),
        body: FutureBuilder(
            future: _loadStats(),
            builder:
                (BuildContext context, AsyncSnapshot<List<GameStat>> snapshot) {
              if (snapshot.hasData) {
                final stats = snapshot.data!;
                final statCategoryTiles = stats.map((stat) {
                  return ListTile(
                    leadingAndTrailingTextStyle: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 20),
                    title: Center(
                        child: Text(stat.name,
                            style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 20))),
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
                                                          fontWeight: FontWeight
                                                              .bold))));
                                        }

                                        final player = stat.playerStats.keys
                                            .toList()[index - 1];
                                        final count = stat.playerStats.values
                                            .toList()[index - 1];
                                        return ListTile(
                                          leading: Text(player.displayName,
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold)),
                                          title: Text(count.toString(),
                                              style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold)),
                                        );
                                      });
                                });
                          }
                        },
                        child: Text(stat.teamStat.toString(),
                            style: const TextStyle(
                                decoration: TextDecoration.underline))),
                    trailing: Text(stat.opponentStat.toString()),
                  );
                }).toList(growable: false);

                return ListView.separated(
                    itemCount:
                        scoringEvents.length + 3 + statCategoryTiles.length,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Scoreboard(game, season,
                            backgroundColor: Theme.of(context).primaryColor);
                      } else if (index == 1) {
                        return const ListTile(
                            tileColor: Colors.black,
                            title: Center(
                                child: Text('Scoring Summary',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold))));
                      } else if (index <= scoringEvents.length + 1) {
                        final event = scoringEvents[index - 2];
                        final assistEvent = gameEvents
                            .where((e) =>
                                e.id == event.id + 1 && e.eventType == 'Assist')
                            .firstOrNull;

                        return ListTile(
                            dense: true,
                            tileColor: Colors.black45,
                            titleTextStyle:
                                const TextStyle(color: Colors.white),
                            leadingAndTrailingTextStyle:
                                const TextStyle(color: Colors.white),
                            subtitleTextStyle:
                                const TextStyle(color: Colors.white70),
                            leading: event.team.id == season.team.id
                                ? SizedBox(
                                    width: 50,
                                    child: Text('${event.eventMinute}\'',
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)))
                                : const SizedBox(width: 50),
                            trailing: event.team.id != season.team.id
                                ? SizedBox(
                                    width: 50,
                                    child: Text('${event.eventMinute}\'',
                                        textAlign: TextAlign.end,
                                        style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold)))
                                : const SizedBox(width: 50),
                            title: event.team.id == season.team.id &&
                                    event.player != null
                                ? Text(event.player!.displayName,
                                    style: const TextStyle(fontSize: 24))
                                : event.team.id == season.team.id
                                    ? const Text('Own goal')
                                    : Container(),
                            subtitle: event.team.id == season.team.id &&
                                    assistEvent != null
                                ? Text(assistEvent.display,
                                    style: const TextStyle(fontSize: 18))
                                : event.eventType == 'PenaltyKick'
                                    ? Text('PK',
                                        style: const TextStyle(fontSize: 18),
                                        textAlign:
                                            event.team.id == season.team.id
                                                ? TextAlign.start
                                                : TextAlign.end)
                                    : event.team.id == season.team.id
                                        ? const Text('No assist',
                                            style: TextStyle(fontSize: 18))
                                        : Container(),
                            onTap: () {});
                      } else if (index == scoringEvents.length + 2) {
                        return const ListTile(
                            tileColor: Colors.black,
                            title: Center(
                                child: Text('Game Stats',
                                    style: TextStyle(
                                        color: Colors.white70,
                                        fontWeight: FontWeight.bold))));
                      } else {
                        return statCategoryTiles[
                            index - scoringEvents.length - 3];
                      }
                    },
                    separatorBuilder: (context, index) {
                      return const Divider(height: 1, color: Colors.black);
                    });
              } else if (snapshot.hasError) {
                return const Center(child: Text('Error loading stats'));
              } else {
                return const CircularProgressIndicator();
              }
            }));
  }

  Future<List<GameStat>> _loadStats() async {
    return Future.wait([
      {'name': 'Goals', 'dialogName': 'Goals', 'category': 'Shot', 'data': 0},
      {
        'name': 'Penalty Kicks Goals',
        'dialogName': 'Penalty Kicks Goals',
        'category': 'PenaltyKick',
        'data': 0
      },
      {'name': 'Shots', 'dialogName': 'Shots', 'category': 'Shot', 'data': -1},
      {
        'name': 'Assists',
        'dialogName': 'Assists',
        'category': 'Assist',
        'data': -1
      },
      {'name': 'Saves', 'dialogName': 'Saves', 'category': 'Save', 'data': -1},
      {'name': 'Fouls', 'dialogName': 'Fouls', 'category': 'Foul', 'data': -1},
      {
        'name': 'Corners',
        'dialogName': 'Shots off corners',
        'category': 'Corner',
        'data': -1
      },
      {
        'name': 'Yellow Cards',
        'dialogName': 'Yellow Cards',
        'category': 'Card',
        'data': 0
      },
      {
        'name': '2md Yellow Cards',
        'dialogName': '2md Yellow Cards',
        'category': 'Card',
        'data': 1
      },
      {
        'name': 'Red Cards',
        'dialogName': 'Red Cards',
        'category': 'Card',
        'data': 2
      },
    ].map((stat) async {
      return await game.getStats(
          database,
          stat['name'].toString(),
          stat['dialogName'].toString(),
          stat['category'].toString(),
          stat['data'] as int,
          season.teamId);
    }).toList(growable: false));
  }
}
