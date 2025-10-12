import 'package:flutter/material.dart';
import 'package:team_sync/models/season.dart';

class SeasonRecord extends StatelessWidget {
  final List<Season> seasons;

  const SeasonRecord(this.seasons, {super.key});

  @override
  Widget build(BuildContext context) {
    final games =
        seasons.map((s) => s.games).toList(growable: false).expand((i) => i);
    final team = seasons.first.team;
    final teamId = team.id;

    int wins = games.where((g) => g.isWin(teamId)).length;
    int losses = games
        .where((g) => g.gameStatus.index >= 9 && !g.isWin(teamId) && !g.isTie)
        .length;
    int ties = games.where((g) => g.isTie).length;

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      team.fullName == 'Saint Albert'
          ? Image.asset('assets/images/jpgs/sa-crest.jpg',
              width: 42, height: 42)
          : Container(),
      Text('Record ($wins - $losses - $ties)',
          style: const TextStyle(
              color: Colors.white70, fontSize: 24, fontWeight: FontWeight.bold))
    ]);
  }
}
