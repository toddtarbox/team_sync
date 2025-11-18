import 'package:flutter/material.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/breadcrumbs.dart';
import 'package:team_sync/widgets/common_page_header.dart';
import 'package:team_sync/widgets/responsive/views/record_holders_view.dart';
import 'package:team_sync/widgets/standard_appbar.dart';

class RecordHoldersPage extends StatelessWidget {
  final Team team;
  const RecordHoldersPage({required this.team, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildStandardAppBar(
        context: context,
        team: team,
        title: const Text('Record Holders'),
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
