import 'dart:async';

import 'package:change_case/change_case.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/best_game_stats.dart';
import 'package:team_sync/models/calculation_progress.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season_stat.dart';
import 'package:team_sync/models/season_stats.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/event_service.dart';

enum StatType {
  career,
  season,
  game,
}

class RecordHoldersView extends StatefulWidget {
  final Team team;

  const RecordHoldersView({super.key, required this.team});

  @override
  State<RecordHoldersView> createState() => _RecordHoldersViewState();
}

class _RecordHoldersViewState extends State<RecordHoldersView>
    with AutomaticKeepAliveClientMixin {
  StatType _selectedStatType = StatType.career;
  final _progressController = StreamController<CalculationProgress>.broadcast();

  // Cache the Future for each stat type
  Future<dynamic>? _careerStatsFuture;
  Future<dynamic>? _seasonStatsFuture;
  Future<dynamic>? _gameStatsFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize the first future
    _careerStatsFuture = _loadAndCalculateStats();
    EventService().eventEmitter.on('eventCreated', context,
        (event, eventContext) {
      _clearCache();
    });
  }

  @override
  void dispose() {
    _progressController.close();
    super.dispose();
  }

  void _clearCache() {
    if (mounted) {
      setState(() {
        _careerStatsFuture = null;
        _seasonStatsFuture = null;
        _gameStatsFuture = null;
        // Re-run the calculation for the currently selected tab
        _getOrStartCalculationFuture();
      });
    }
  }

  Future<dynamic> _loadAndCalculateStats() async {
    final data = await _loadData();
    return await _calculateStats(data);
  }

  Future<dynamic> _getOrStartCalculationFuture() {
    switch (_selectedStatType) {
      case StatType.career:
        _careerStatsFuture ??= _loadAndCalculateStats();
        return _careerStatsFuture!;
      case StatType.season:
        _seasonStatsFuture ??= _loadAndCalculateStats();
        return _seasonStatsFuture!;
      case StatType.game:
        _gameStatsFuture ??= _loadAndCalculateStats();
        return _gameStatsFuture!;
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SegmentedButton<StatType>(
            segments: <ButtonSegment<StatType>>[
              ButtonSegment<StatType>(
                  value: StatType.career,
                  label: Text(AppLocalizations.of(context)!.career)),
              ButtonSegment<StatType>(
                  value: StatType.season,
                  label: Text(AppLocalizations.of(context)!.season)),
              ButtonSegment<StatType>(
                  value: StatType.game,
                  label: Text(AppLocalizations.of(context)!.game)),
            ],
            selected: <StatType>{_selectedStatType},
            onSelectionChanged: (Set<StatType> newSelection) {
              setState(() {
                _selectedStatType = newSelection.first;
              });
            },
          ),
        ),
        Expanded(
          child: FutureBuilder(
            future: _getOrStartCalculationFuture(),
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingList();
              } else if (snapshot.hasError) {
                debugPrintStack(stackTrace: snapshot.stackTrace);
                return Center(
                    child:
                        Text(AppLocalizations.of(context)!.errorLoadingStats));
              } else {
                return _buildLeaderList(snapshot.data);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingList() {
    return StreamBuilder<CalculationProgress>(
      stream: _progressController.stream,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.total > 0) {
          final progress = snapshot.data!;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress.current / progress.total,
                ),
                const SizedBox(height: 16),
                Text(
                    '${AppLocalizations.of(context)!.calculating} ${progress.message}'),
              ],
            ),
          );
        } else {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.calculating),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildLeaderList(dynamic stats) {
    return ListView.separated(
      itemCount: LeaderCategory.values.length,
      itemBuilder: (context, index) {
        final category = LeaderCategory.values[index];
        if (category == LeaderCategory.ownGoalsEarned ||
            category == LeaderCategory.secondYellowReds) {
          return Container();
        }

        if (_selectedStatType == StatType.season) {
          final categoryStats =
              (stats as Map<LeaderCategory, SeasonStat>)[category];
          if (categoryStats == null) {
            return Container();
          }
          return _buildSeasonStatTile(category, categoryStats);
        } else if (_selectedStatType == StatType.game) {
          final bestStat = (stats as BestGameStats).getBestStat(category);
          if (bestStat == null) {
            return Container();
          }
          return _buildGameStatTile(category, bestStat);
        } else {
          final categoryStats =
              (stats as Map<LeaderCategory, MapEntry<Player, int>>)[category];
          if (categoryStats == null) {
            return Container();
          }
          return _buildStatTile(category, categoryStats);
        }
      },
      separatorBuilder: (context, index) {
        return const Divider(height: 1);
      },
    );
  }

  Widget _buildSeasonStatTile(LeaderCategory category, SeasonStat topEntry) {
    return ListTile(
      title: Text(category.name.toSentenceCase().toTitleCase()),
      subtitle:
          Text('${topEntry.player.displayName} - ${topEntry.season.name}'),
      trailing: Text(topEntry.value.toString()),
      onTap: () async {
        showDialog(
            context: context,
            builder: (context) {
              return const Center(child: CircularProgressIndicator());
            });
        final categoryStats =
            await widget.team.getAllSeasonStatsForCategory(category);
        if (!mounted) return;
        Navigator.pop(context);
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    category.name.toSentenceCase().toTitleCase(),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: categoryStats.length,
                    itemBuilder: (context, index) {
                      final entry = categoryStats[index];
                      return ListTile(
                        title: Text(
                            '${entry.player.displayName} - ${entry.season.name}'),
                        trailing: Text(entry.value.toString()),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildGameStatTile(LeaderCategory category, BestGameStat bestStat) {
    return ListTile(
      title: Text(category.name.toSentenceCase().toTitleCase()),
      subtitle: Text(
          '${bestStat.player.displayName} - ${bestStat.game.displayName(bestStat.player.teamId)}'),
      trailing: Text(bestStat.value.toString()),
      onTap: () async {
        showDialog(
            context: context,
            builder: (context) {
              return const Center(child: CircularProgressIndicator());
            });
        final categoryStats =
            await widget.team.getAllGameStatsForCategory(category);
        if (!mounted) return;
        Navigator.pop(context);
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    category.name.toSentenceCase().toTitleCase(),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: categoryStats.length,
                    itemBuilder: (context, index) {
                      final entry = categoryStats[index];
                      return ListTile(
                        title: Text(
                            '${entry.player.displayName} - ${entry.game.displayName(entry.player.teamId)}'),
                        trailing: Text(entry.value.toString()),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStatTile(
      LeaderCategory category, MapEntry<Player, int> topEntry) {
    return ListTile(
      title: Text(category.name.toSentenceCase().toTitleCase()),
      subtitle: Text(topEntry.key.displayName),
      trailing: Text(topEntry.value.toString()),
      onTap: () async {
        showDialog(
            context: context,
            builder: (context) {
              return const Center(child: CircularProgressIndicator());
            });
        final categoryStats =
            await widget.team.getCareerStatsForCategory(category);
        if (!mounted) return;
        Navigator.pop(context);
        showModalBottomSheet(
          context: context,
          builder: (context) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    category.name.toSentenceCase().toTitleCase(),
                    style: const TextStyle(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: categoryStats.length,
                    itemBuilder: (context, index) {
                      final entry = categoryStats[index];
                      return ListTile(
                        title: Text(entry.key.displayName),
                        trailing: Text(entry.value.toString()),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<dynamic> _loadData() async {
    switch (_selectedStatType) {
      case StatType.career:
        return await widget.team.fetchAllDataForCareer();
      case StatType.season:
        return await widget.team.fetchAllDataForSeason();
      case StatType.game:
        return await widget.team.fetchAllDataForGame();
    }
  }

  Future<dynamic> _calculateStats(dynamic data) async {
    switch (_selectedStatType) {
      case StatType.career:
        return await widget.team
            .calculateCareerStats(data, progressController: _progressController);
      case StatType.season:
        return await widget.team.calculateBestSeasonStats(data,
            progressController: _progressController);
      case StatType.game:
        return await widget.team
            .calculateBestGameStats(data, progressController: _progressController);
    }
  }
}
