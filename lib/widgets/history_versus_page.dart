import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/widgets/custom_appbar.dart';
import 'package:team_sync/widgets/responsive/views/history_versus_view.dart';

class HistoryVersusPage extends StatelessWidget {
  final Team team;

  const HistoryVersusPage({required this.team, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CustomAppBar(
          team: team,
          title: Text(AppLocalizations.of(context)!.historyVersus,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        body: HistoryVersusView(team: team));
  }
}
