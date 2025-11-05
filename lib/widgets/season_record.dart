import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
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

    final String leading = seasons.length > 1
        ? AppLocalizations.of(context)!.overall
        : AppLocalizations.of(context)!.season;

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      team.logoUrl != null && team.logoUrl!.isNotEmpty
          ? CircleAvatar(
              child: ClipOval(
                child: Image.network(
                  team.logoUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Text(team.fullName[0]);
                  },
                ),
              ),
            )
          : Container(),
      team.logoUrl != null && team.logoUrl!.isNotEmpty
          ? const SizedBox(width: 10)
          : Container(),
      Text('$leading Record ($wins - $losses - $ties)',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
    ]);
  }
}
