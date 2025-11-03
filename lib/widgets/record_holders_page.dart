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
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(0),
            child: Container(
                padding: EdgeInsets.all(20),
                child:
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  team.fullName == 'Saint Albert'
                      ? Image.asset('assets/images/jpgs/sa-crest.jpg',
                          width: 42, height: 42)
                      : Container(),
                  team.fullName == 'Saint Albert'
                      ? const SizedBox(width: 10)
                      : Container(),
                  Text(team.fullName,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold))
                ]))),
      ),
      body: RecordHoldersView(team: team),
    );
  }
}
