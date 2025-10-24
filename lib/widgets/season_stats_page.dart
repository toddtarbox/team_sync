import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/widgets/custom_appbar.dart';
import 'package:team_sync/widgets/responsive/views/season_stats_view.dart';

class SeasonStatsPage extends StatelessWidget {
  final Season season;

  const SeasonStatsPage({super.key, required this.season});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        team: season.team,
        title: Text(season.name),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: Text(AppLocalizations.of(context)!.seasonStats,
                style: const TextStyle(fontSize: 24))),
      ),
      body: SeasonStatsView(season: season),
    );
  }
}
