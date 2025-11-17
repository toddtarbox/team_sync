import 'package:flutter/material.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/widgets/custom_appbar.dart';
import 'package:team_sync/widgets/responsive/views/record_holders_view.dart';

class RecordHoldersPage extends StatelessWidget {
  final Team team;
  const RecordHoldersPage({required this.team, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        team: team,
        title: const Text('Record Holders'),
      ),
      body: RecordHoldersView(team: team),
    );
  }
}
