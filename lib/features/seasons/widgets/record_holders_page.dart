import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/features/teams/models/team.dart';
import 'package:team_sync/core/services/database_service.dart';
import 'package:team_sync/core/widgets/breadcrumbs.dart';
import 'package:team_sync/core/widgets/common_page_header.dart';
import 'package:team_sync/features/seasons/widgets/record_holders_view.dart';
import 'package:team_sync/core/widgets/standard_appbar.dart';

class RecordHoldersPage extends StatelessWidget {
  final Team team;
  const RecordHoldersPage({required this.team, super.key});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: buildStandardAppBar(
        context: context,
        team: team,
        title: Text(loc.recordHolders),
      ),
      body: Column(
        children: [
          CommonPageHeader(team: team),
          Breadcrumbs(
            items: buildTeamBreadcrumbs(
              databaseId: DatabaseService.instance.publicShareId ?? '',
              teamName: team.fullName,
              additionalLabel: 'Records',
            ),
          ),
          Expanded(child: RecordHoldersView(team: team)),
        ],
      ),
    );
  }
}
