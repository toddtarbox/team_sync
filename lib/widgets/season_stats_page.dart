import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/widgets/responsive/views/season_stats_view.dart';

class SeasonStatsPage extends StatelessWidget {
  final Database database;
  final Season season;

  const SeasonStatsPage(
      {required this.database, required this.season, super.key});

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
          title: Text('${season.name} Season Stats',
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
        ),
        body: SeasonStatsView(database: database, season: season));
  }
}
