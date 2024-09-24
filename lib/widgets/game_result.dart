import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/models/game.dart';

class GameResult extends StatelessWidget {
  final Game game;
  final int teamId;

  const GameResult(this.game, this.teamId, {super.key});

  @override
  Widget build(BuildContext context) {
    if (game.gameStatus.index < 9) {
      return const Text('');
    }

    Color color = Colors.black54;
    String result = game.isTie ? 'T' : '';
    int teamScore =
        game.isHomeTeam(teamId) ? game.homeTeamScore : game.awayTeamScore;
    int oppScore =
        game.isHomeTeam(teamId) ? game.awayTeamScore : game.homeTeamScore;

    if (result.isEmpty) {
      if (game.isWin(teamId)) {
        result = 'W';
        color = Colors.green;
      } else {
        result = 'L';
        color = Colors.red;
      }
    }

    return Text('$result ${teamScore.toString()} - ${oppScore.toString()}',
        style:
            TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold));
  }
}
