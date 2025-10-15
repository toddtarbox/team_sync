import 'package:flutter/material.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/widgets/responsive/views/career_stats_view.dart';

class CareerLeadersPage extends StatelessWidget {
  final Team team;

  const CareerLeadersPage({required this.team, super.key});

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
          title: const Text('Career Leaders',
              style: TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
        ),
        body: CareerStatsView(team: team));
  }
}
