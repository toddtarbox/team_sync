import 'package:flutter/material.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';

class Scoreboard extends StatelessWidget {
  final Game game;
  final Season season;
  final bool shortName;
  final Color color;
  final Color backgroundColor;

  const Scoreboard(this.game, this.season,
      {this.shortName = false,
      this.color = Colors.white70,
      this.backgroundColor = Colors.transparent,
      super.key});

  @override
  Widget build(BuildContext context) {
    final team = game.isHomeTeam(season.teamId) ? game.homeTeam : game.awayTeam;
    final opponent =
        !game.isHomeTeam(season.teamId) ? game.homeTeam : game.awayTeam;

    final teamName = shortName ? team.shortName : team.fullName;
    final opponentName = shortName ? opponent.shortName : opponent.fullName;

    final teamScore = game.isHomeTeam(season.teamId)
        ? game.homeTeamScore
        : game.awayTeamScore;
    final opponentScore = !game.isHomeTeam(season.teamId)
        ? game.homeTeamScore
        : game.awayTeamScore;

    return Container(
        color: backgroundColor,
        child: Column(children: [
          Text(game.gameStatus.display,
              style: TextStyle(
                  color: color, fontSize: 24, fontWeight: FontWeight.bold)),
          Stack(children: [
            Column(children: [
              Text(teamName,
                  style: TextStyle(
                      color: color, fontSize: 24, fontWeight: FontWeight.bold)),
              Text('$teamScore',
                  style: TextStyle(
                      color: color, fontSize: 24, fontWeight: FontWeight.bold)),
            ]),
            Align(
                alignment: Alignment.centerRight,
                child: Column(children: [
                  Text(opponentName,
                      style: TextStyle(
                          color: color,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                  Text('$opponentScore',
                      style: TextStyle(
                          color: color,
                          fontSize: 24,
                          fontWeight: FontWeight.bold)),
                ]))
          ]),
        ]));
  }
}
