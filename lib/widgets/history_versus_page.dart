import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/widgets/responsive/views/history_versus_view.dart';

class HistoryVersusPage extends StatelessWidget {
  final Database database;
  final Team team;

  const HistoryVersusPage(
      {required this.database, required this.team, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          leading: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const Icon(Icons.arrow_back, color: Colors.white70)),
          title: const Text('History Versus',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
        ),
        body: HistoryVersusView(database: database, team: team));
  }
}
