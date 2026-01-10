import 'package:change_case/change_case.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/widgets/common/skeleton_container.dart';

class CareerStatsView extends StatefulWidget {
  final Team team;

  const CareerStatsView({super.key, required this.team});

  @override
  State<CareerStatsView> createState() => _CareerStatsViewState();
}

class _CareerStatsViewState extends State<CareerStatsView> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _loadCareerStats(),
        builder: (BuildContext context,
            AsyncSnapshot<Map<String, MapEntry<Player, int>>> snapshot) {
          if (snapshot.hasData) {
            final stats = snapshot.data!;
            final statCategoryTiles = stats.entries.map((entry) {
              return ListTile(
                  title: GestureDetector(
                      onTap: () async {
                        showDialog(
                            barrierDismissible: false,
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                  title: Text(
                                      AppLocalizations.of(context)!.loading));
                            });

                        final stat = await widget.team
                            .getCareerStatsForCategory(entry.key);

                        if (!mounted) return;
                        Navigator.pop(context);

                        if (stat.isNotEmpty) {
                          showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (context) {
                                return Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        entry.key
                                            .toSentenceCase()
                                            .toTitleCase(),
                                        style: const TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Expanded(
                                      child: ListView.builder(
                                          itemCount: stat.length,
                                          itemBuilder: (context, index) {
                                            final statEntry = stat[index];
                                            return ListTile(
                                                title: Text(
                                                    statEntry.key.displayName,
                                                    style: const TextStyle(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                trailing: Text(
                                                    statEntry.value.toString(),
                                                    style: const TextStyle(
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.bold)));
                                          }),
                                    ),
                                  ],
                                );
                              });
                        }
                      },
                      child: Text(entry.key.toSentenceCase().toTitleCase())));
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
            debugPrint(snapshot.error.toString());
            debugPrintStack(stackTrace: snapshot.stackTrace);
            return Center(
                child: Text(AppLocalizations.of(context)!.errorLoadingStats));
          } else {
            return ListView.separated(
              itemCount: 8,
              padding: const EdgeInsets.all(16),
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: SkeletonContainer.rectangular(
                          width: double.infinity,
                          height: 20,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 40),
                      Icon(Icons.chevron_right,
                          color: Colors.grey.withOpacity(0.3)),
                    ],
                  ),
                );
              },
            );
          }
        });
  }

  Future<Map<String, MapEntry<Player, int>>> _loadCareerStats() async {
    final data = await widget.team.fetchAllDataForCareer();
    return await widget.team.calculateCareerStats(data);
  }
}
