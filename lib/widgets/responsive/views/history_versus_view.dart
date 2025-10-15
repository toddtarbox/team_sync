import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/team.dart';

class HistoryVersusView extends StatefulWidget {
  final Team team;

  const HistoryVersusView({super.key, required this.team});

  @override
  State<HistoryVersusView> createState() => _HistoryVersusViewState();
}

class _HistoryVersusViewState extends State<HistoryVersusView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _loadHistory(),
        builder: (BuildContext context,
            AsyncSnapshot<Map<Team, List<Game>>?> snapshot) {
          if (snapshot.hasData) {
            return ListView.separated(
                itemCount: snapshot.data?.keys.length ?? 0,
                itemBuilder: (context, index) {
                  final team =
                      snapshot.data?.keys.toList(growable: false)[index];
                  final games = snapshot.data?[team] ?? [];

                  int wins = games.where((g) => g.isWin(widget.team.id)).length;
                  int losses = games
                      .where((g) =>
                          g.gameStatus.index >= 9 &&
                          !g.isWin(widget.team.id) &&
                          !g.isTie)
                      .length;
                  int ties = games.where((g) => g.isTie).length;

                  final color = (wins > losses) ? Colors.green : Colors.red;

                  return GestureDetector(
                      onTap: () async {
                        games.sort((a, b) => b.date.compareTo(a.date));

                        // Show a temp progress dialog
                        showDialog(
                            context: context,
                            builder: (context) {
                              return const AlertDialog(
                                  title: Text('Loading...'));
                            });

                        await Future.wait(games
                            .map((g) async => await g.loadGameEvents())
                            .toList(growable: false));

                        // Dismiss the dialog
                        Navigator.pop(context);

                        showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return ListView.builder(
                                  itemCount: games.length,
                                  itemBuilder: (context, index) {
                                    final game = games[index];
                                    final color = game.isWin(widget.team.id)
                                        ? Colors.green
                                        : game.isTie
                                            ? Colors.grey
                                            : Colors.red;

                                    return ListTile(
                                        title: Text(
                                            '${game.date.month}/${game.date.day}/${game.date.year} ${game.displayName(widget.team.id)}',
                                            style: const TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)),
                                        trailing: Text(
                                            game.getScore(widget.team.id),
                                            style: TextStyle(
                                                color: color,
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold)));
                                  });
                            });
                      },
                      child: ListTile(
                          leading: Text(team?.fullName ?? '',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          trailing: (Text('$wins - $losses - $ties',
                              style: TextStyle(
                                  color: color,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)))));
                },
                separatorBuilder: (context, index) {
                  return const Divider(height: 1, color: Colors.black);
                });
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading history'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  Future<SplayTreeMap<Team, List<Game>>?> _loadHistory() async {
    final allGames = await widget.team.getGameHistory(widget.team.id);

    final gameHistory = SplayTreeMap<Team, List<Game>>(
        (a, b) => a.fullName.compareTo(b.fullName));
    for (final game in allGames) {
      final team =
          game.isHomeTeam(widget.team.id) ? game.awayTeam : game.homeTeam;
      gameHistory.putIfAbsent(team, () => []);
      gameHistory[team]?.add(game);
    }

    return gameHistory;
  }
}
