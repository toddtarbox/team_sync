import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/widgets/common_page_header.dart';
import 'package:team_sync/widgets/responsive/views/season_stats_view.dart';
import 'package:team_sync/widgets/standard_appbar.dart';

class SeasonStatsPage extends StatelessWidget {
  final Season season;

  const SeasonStatsPage({super.key, required this.season});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildStandardAppBar(
        context: context,
        team: season.team,
        title: Text(season.name),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: Text(AppLocalizations.of(context)!.seasonStats,
                style: const TextStyle(fontSize: 24))),
      ),
      body: Column(
        children: [
          CommonPageHeader(team: season.team),
          Expanded(child: SeasonStatsView(season: season)),
        ],
      ),
    );
  }
}
