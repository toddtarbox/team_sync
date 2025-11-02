import 'package:change_case/change_case.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/career_stats.dart';
import 'package:team_sync/models/season_stats.dart';
import 'package:team_sync/models/team.dart';

class CareerStatsView extends StatefulWidget {
  final Team team;

  const CareerStatsView({super.key, required this.team});

  @override
  State<CareerStatsView> createState() => _CareerStatsViewState();
}

class _CareerStatsViewState extends State<CareerStatsView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _loadCareerStats(),
        builder: (BuildContext context, AsyncSnapshot<CareerStats?> snapshot) {
          if (snapshot.hasData) {
            final stats = snapshot.data!;
            final statCategoryTiles = LeaderCategory.values.map((category) {
              if (category == LeaderCategory.ownGoalsEarned ||
                  category == LeaderCategory.secondYellowReds) {
                return Container();
              }

              return ListTile(
                  title: GestureDetector(
                      onTap: () async {
                        // Show a temp progress dialog
                        showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                  title: Text(
                                      AppLocalizations.of(context)!.loading));
                            });

                        final stat = await stats.getStatPlayers(category);

                        // Dismiss the dialog
                        Navigator.pop(context);

                        if (stat.isNotEmpty) {
                          final sortedStats = List.from(stat.entries);
                          sortedStats
                              .sort((a, b) => b.value.compareTo(a.value));

                          showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return ListView.builder(
                                    itemCount: stat.length,
                                    itemBuilder: (context, index) {
                                      final stat = sortedStats[index];
                                      return ListTile(
                                          title: Text(stat.key.displayName,
                                              style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold)),
                                          trailing: Text(stat.value.toString(),
                                              style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight:
                                                      FontWeight.bold)));
                                    });
                              });
                        }
                      },
                      child:
                          Text(category.name.toSentenceCase().toTitleCase())));
            }).toList(growable: false);

            return ListView.separated(
                itemCount: statCategoryTiles.length,
                itemBuilder: (context, index) {
                  return statCategoryTiles[index];
                },
                separatorBuilder: (context, index) {
                  return const Divider(height: 1);
                });
          } else if (snapshot.hasError) {
            return Center(
                child: Text(AppLocalizations.of(context)!.errorLoadingStats));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  Future<CareerStats?> _loadCareerStats() async {
    return await widget.team.getCareerStats(widget.team.id);
  }
}
