import 'package:flutter/material.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/services/sport_strategy.dart';

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
    } else if (game.isTie && SportStrategy.current.sportId != 'basketball') {
      result = 'T';
      color = Colors.grey;
    } else {
      result = 'L';
      color = Colors.red;
    }

    return Container(
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 8),
        child: Text('$result ${teamScore.toString()} - ${oppScore.toString()}',
            maxLines: 1,
            softWrap: false,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold)));
  }
}
