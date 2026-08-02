import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/features/seasons/models/season.dart';
import 'package:team_sync/core/services/database_service.dart';
import 'package:team_sync/core/widgets/breadcrumbs.dart';
import 'package:team_sync/features/seasons/widgets/season_stats_view.dart';
import 'package:team_sync/core/widgets/standard_appbar.dart';

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
          Breadcrumbs(
            items: buildTeamBreadcrumbs(
              databaseId: DatabaseService.instance.publicShareId ?? '',
              teamName: season.team.fullName,
              seasonName: season.name,
              seasonId: season.id,
              additionalLabel: 'Stats',
            ),
          ),
          Expanded(child: SeasonStatsView(season: season)),
        ],
      ),
    );
  }
}
