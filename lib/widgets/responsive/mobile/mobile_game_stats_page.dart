import 'package:eventify/eventify.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/widgets/responsive/views/game_stats_view.dart';
import 'package:team_sync/widgets/scoreboard.dart';

class MobileGameStatsPage extends StatelessWidget {
  final Season season;
  final Game game;

  final EventEmitter _eventEmitter = EventEmitter();

  MobileGameStatsPage({required this.season, required this.game, super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          leading: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const Icon(Icons.arrow_back)),
          title: Text(game.displayName(season.teamId),
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          bottom: PreferredSize(
              preferredSize: Size(width, 100), child: Scoreboard(game, season)),
        ),
        body: GameStatsView(
            season: season, game: game, eventEmitter: _eventEmitter));
  }
}
