import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/breadcrumbs.dart';
import 'package:team_sync/widgets/common_page_header.dart';
import 'package:team_sync/widgets/responsive/views/history_versus_view.dart';
import 'package:team_sync/widgets/standard_appbar.dart';

class HistoryVersusPage extends StatelessWidget {
  final Team team;

  const HistoryVersusPage({required this.team, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: buildStandardAppBar(
          context: context,
          team: team,
          title: Text(AppLocalizations.of(context)!.historyVersus,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        body: Column(
          children: [
            CommonPageHeader(team: team),
            Breadcrumbs(
              items: buildTeamBreadcrumbs(
                databaseId: DatabaseService.instance.publicShareId ?? '',
                teamName: team.fullName,
                additionalLabel: 'History',
              ),
            ),
            Expanded(child: HistoryVersusView(team: team)),
          ],
        ));
  }
}
