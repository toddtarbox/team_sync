import 'package:flutter/material.dart';
import 'package:team_sync/models/game.dart';

class GameResult extends StatelessWidget {
  final Game game;
  final int teamId;

  const GameResult(this.game, this.teamId, {super.key});

  @override
  Widget build(BuildContext context) {
    if (game.gameStatus == GameStatus.notStarted) {
      return const Text('');
    }

    int teamScore =
        game.isHomeTeam(teamId) ? game.homeTeamScore : game.awayTeamScore;
    int oppScore =
        game.isHomeTeam(teamId) ? game.awayTeamScore : game.homeTeamScore;

    String result;
    Color color;
    if (game.isWin(teamId)) {
      result = 'W';
      color = Colors.green;
    } else if (game.isTie) {
      result = 'T';
      color = Colors.grey;
    } else {
      result = 'L';
      color = Colors.red;
    }

    return Container(
        width: 80,
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.all(5),
        child: Center(
            child: Text(
                '$result ${teamScore.toString()} - ${oppScore.toString()}',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold))));
  }
}
