import 'package:change_case/change_case.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/season_stats.dart';

class SeasonStatsView extends StatefulWidget {
  final Season season;

  const SeasonStatsView({super.key, required this.season});

  @override
  State<SeasonStatsView> createState() => _SeasonStatsViewState();
}

class _SeasonStatsViewState extends State<SeasonStatsView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _loadSeasonStats(),
        builder: (BuildContext context, AsyncSnapshot<SeasonStats?> snapshot) {
          if (snapshot.hasData) {
            final stats = snapshot.data!;
            final gamesPlayed = widget.season.games.length;

            final statCategoryTiles = LeaderCategory.values.map((category) {
              return ListTile(
                leadingAndTrailingTextStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
                title: Center(
                    child: Text(category.name.toSentenceCase().toTitleCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 24))),
                leading: GestureDetector(
                    onTap: () async {
                      final stat = await stats.getStatPlayers(category);
                      if (stat.isNotEmpty) {
                        final sortedStats = List.from(stat.entries);
                        sortedStats.sort((a, b) => b.value.compareTo(a.value));

                        showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return ListView.builder(
                                  itemCount: stat.length + 1,
                                  itemBuilder: (context, index) {
                                    if (index == 0) {
                                      return ListTile(
                                          title: Center(
                                              child: Text(
                                                  category.name.toTitleCase(),
                                                  style: const TextStyle(
                                                      fontSize: 20,
                                                      fontWeight:
                                                          FontWeight.bold))));
                                    }

                                    final player = sortedStats[index - 1].key;
                                    final count = sortedStats[index - 1].value;
                                    return ListTile(
                                      leading: Text(player.displayName,
                                          style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold)),
                                      title: Text(count.toString(),
                                          style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold)),
                                    );
                                  });
                            });
                      }
                    },
                    child: Text(
                        '${stats.teamStat(category)} (${(stats.teamStat(category) / gamesPlayed).toStringAsFixed(1)}/g)',
                        style: TextStyle(
                            decoration: stats.teamStat(category) > 0
                                ? TextDecoration.underline
                                : null))),
                trailing: Text(
                    '${stats.opponentStat(category)} (${(stats.opponentStat(category) / gamesPlayed).toStringAsFixed(1)}/g)'),
              );
            }).toList(growable: false);

            return ListView.separated(
                itemCount: statCategoryTiles.length + 1,
                itemBuilder: (context, index) {
                  if (index < statCategoryTiles.length) {
                    return statCategoryTiles[index];
                  } else {
                    return ListTile(
                      leadingAndTrailingTextStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 24),
                      title: const Center(
                          child: Text('Corners',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 24))),
                      leading: Text(
                        '${stats.teamCorners.toString()} (${(stats.teamCorners / gamesPlayed).toStringAsFixed(1)}/g)',
                      ),
                      trailing: Text(
                        '${stats.opponentCorners.toString()} (${(stats.opponentCorners / gamesPlayed).toStringAsFixed(1)}/g)',
                      ),
                    );
                  }
                },
                separatorBuilder: (context, index) {
                  return const Divider(height: 1);
                });
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading stats'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  Future<SeasonStats?> _loadSeasonStats() async {
    return await widget.season.getSeasonStats();
  }
}
