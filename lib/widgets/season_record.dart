import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/season.dart';

class SeasonRecord extends StatelessWidget {
  final List<Season> seasons;
  final bool singleSeason;

  const SeasonRecord(this.seasons, {this.singleSeason = true, super.key});

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

    final String leading = !singleSeason
        ? AppLocalizations.of(context)!.overall
        : AppLocalizations.of(context)!.season;

    final logoUrl = !singleSeason ? team.logoUrl : null;

    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      logoUrl != null && logoUrl.isNotEmpty
          ? GestureDetector(
              onDoubleTap: () {
                _showPhoto(context, logoUrl);
              },
              child: CircleAvatar(
                child: ClipOval(
                  child: Image.network(
                    logoUrl,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Text(team.fullName[0]);
                    },
                  ),
                ),
              ))
          : Container(),
      logoUrl != null && logoUrl.isNotEmpty
          ? const SizedBox(width: 10)
          : Container(),
      Text('$leading Record ($wins - $losses - $ties)',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))
    ]);
  }

  Future<void> _showPhoto(BuildContext context, String? logoUrl) async {
    if (logoUrl == null || logoUrl.isEmpty) {
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: PhotoView(
            imageProvider: NetworkImage(logoUrl),
          ),
        );
      },
    );
  }
}
