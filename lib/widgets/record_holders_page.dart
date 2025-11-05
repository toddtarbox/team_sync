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
                  team.logoUrl != null
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
