import 'package:eventify/eventify.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/breadcrumbs.dart';
import 'package:team_sync/widgets/common_page_header.dart';
import 'package:team_sync/widgets/responsive/views/game_stats_view.dart';
import 'package:team_sync/widgets/scoreboard_widget.dart';
import 'package:team_sync/widgets/standard_appbar.dart';

class MobileGameStatsPage extends StatelessWidget {
  final Season season;
  final Game game;

  final EventEmitter _eventEmitter = EventEmitter();

  MobileGameStatsPage({required this.season, required this.game, super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
        appBar: buildStandardAppBar(
          context: context,
          team: season.team,
          title: Text(game.displayName(season.teamId),
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          bottom: PreferredSize(
              preferredSize: Size(width, 100),
              child: ScoreboardWidget(
                compact: true,
                margin: EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 5),
                season: season,
                game: game,
                teamId: season.team.id,
              )),
        ),
        body: Column(
          children: [
            CommonPageHeader(team: season.team),
            Breadcrumbs(
              items: buildTeamBreadcrumbs(
                databaseId: DatabaseService.instance.publicShareId ?? '',
                teamName: season.team.fullName,
                seasonName: season.name,
                seasonId: season.id,
                gameName: game.displayName(season.teamId),
                additionalLabel: 'Stats',
              ),
            ),
            Expanded(
              child: GameStatsView(
                  season: season, game: game, eventEmitter: _eventEmitter),
            ),
          ],
        ));
  }
}
