import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/game.dart';

class GameResult extends StatelessWidget {
  final Game game;
  final int teamId;

  const GameResult(this.game, this.teamId, {super.key});

  @override
  Widget build(BuildContext context) {
    final isWin = game.isWin(teamId);
    final color = isWin
        ? Colors.green
        : game.isTie
            ? Colors.grey
            : Colors.red;
    final text = isWin
        ? AppLocalizations.of(context)!.winAbbreviation
        : game.isTie
            ? AppLocalizations.of(context)!.tieAbbreviation
            : AppLocalizations.of(context)!.lossAbbreviation;

    return Text(text, style: TextStyle(color: color, fontSize: 40));
  }
}
