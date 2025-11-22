import 'dart:async';

import 'package:change_case/change_case.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/best_game_stats.dart';
import 'package:team_sync/models/calculation_progress.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/season_stat.dart';
import 'package:team_sync/models/season_stats.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/event_service.dart';
import 'package:team_sync/services/subscription_service.dart';
import 'package:team_sync/utils/navigation_helper.dart';
import 'package:team_sync/widgets/responsive_player_avatar.dart';

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
                  label: Text(AppLocalizations.of(context)!.careerLeaders)),
              ButtonSegment<StatType>(
                  value: StatType.season,
                  label: Text(AppLocalizations.of(context)!.bestSeason)),
              ButtonSegment<StatType>(
                  value: StatType.game,
                  label: Text(AppLocalizations.of(context)!.bestGame)),
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
                debugPrint(snapshot.error.toString());
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
            category == LeaderCategory.secondYellowReds ||
            category == LeaderCategory.corners) {
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
      leading: GestureDetector(
        onTap: () async {
          if (!kIsWeb && !SubscriptionService.instance.isSubscribed) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(AppLocalizations.of(context)!.proFeature),
                  content: Text(
                      AppLocalizations.of(context)!.playerProfilesProFeature),
                  actions: [
                    TextButton(
                      child: Text(AppLocalizations.of(context)!.cancelButton),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    TextButton(
                      child: Text(AppLocalizations.of(context)!.goPro),
                      onPressed: () async {
                        Navigator.pop(context);
                        await SubscriptionService.instance
                            .purchaseSubscription();
                      },
                    ),
                  ],
                );
              },
            );
            return;
          }

          // Ensure season is loaded before navigation
          await topEntry.season.load();

          // Try to get databaseId from current route or from DatabaseService
          final currentUri = GoRouterState.of(context).uri;
          String? databaseId;

          // Try to extract from current path
          final pathSegments = currentUri.pathSegments;
          if (pathSegments.isNotEmpty &&
              pathSegments[0] == 'team' &&
              pathSegments.length > 1) {
            databaseId = pathSegments[1];
          } else {
            databaseId = DatabaseService.instance.publicShareId;
          }

          if (databaseId != null) {
            NavigationHelper.navigateTo(
              context,
              '/team/$databaseId/season/${topEntry.season.id}/players/${topEntry.player.id}',
              extra: {
                'player': topEntry.player,
                'season': topEntry.season,
              },
            );
          }
        },
        child: ResponsivePlayerAvatar(player: topEntry.player, avatarSize: 40),
      ),
      trailing:
          Text(topEntry.value.toString(), style: const TextStyle(fontSize: 24)),
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
                        leading: GestureDetector(
                          onTap: () async {
                            if (!kIsWeb &&
                                !SubscriptionService.instance.isSubscribed) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(AppLocalizations.of(context)!
                                        .proFeature),
                                    content: Text(AppLocalizations.of(context)!
                                        .playerProfilesProFeature),
                                    actions: [
                                      TextButton(
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .cancelButton),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                      TextButton(
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .goPro),
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await SubscriptionService.instance
                                              .purchaseSubscription();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                              return;
                            }

                            // Ensure season is loaded before navigation
                            await entry.season.load();

                            // Try to get databaseId from current route or from DatabaseService
                            final currentUri = GoRouterState.of(context).uri;
                            String? databaseId;

                            // Try to extract from current path
                            final pathSegments = currentUri.pathSegments;
                            if (pathSegments.isNotEmpty &&
                                pathSegments[0] == 'team' &&
                                pathSegments.length > 1) {
                              databaseId = pathSegments[1];
                            } else {
                              databaseId =
                                  DatabaseService.instance.publicShareId;
                            }

                            if (databaseId != null) {
                              NavigationHelper.navigateTo(
                                context,
                                '/team/$databaseId/season/${entry.season.id}/players/${entry.player.id}',
                                extra: {
                                  'player': entry.player,
                                  'season': entry.season,
                                },
                              );
                            }
                          },
                          child: ResponsivePlayerAvatar(
                              player: entry.player, avatarSize: 40),
                        ),
                        trailing: Text(entry.value.toString(),
                            style: const TextStyle(fontSize: 24)),
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
          '${bestStat.player.displayName} - ${bestStat.season.name} - ${bestStat.game.displayName(bestStat.player.teamId)}'),
      trailing:
          Text(bestStat.value.toString(), style: const TextStyle(fontSize: 24)),
      leading: GestureDetector(
        onTap: () async {
          if (!kIsWeb && !SubscriptionService.instance.isSubscribed) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(AppLocalizations.of(context)!.proFeature),
                  content: Text(
                      AppLocalizations.of(context)!.playerProfilesProFeature),
                  actions: [
                    TextButton(
                      child: Text(AppLocalizations.of(context)!.cancelButton),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    TextButton(
                      child: Text(AppLocalizations.of(context)!.goPro),
                      onPressed: () async {
                        Navigator.pop(context);
                        await SubscriptionService.instance
                            .purchaseSubscription();
                      },
                    ),
                  ],
                );
              },
            );
            return;
          }

          // Ensure season is loaded before navigation
          await bestStat.season.load();

          // Try to get databaseId from current route or from DatabaseService
          final currentUri = GoRouterState.of(context).uri;
          String? databaseId;

          // Try to extract from current path
          final pathSegments = currentUri.pathSegments;
          if (pathSegments.isNotEmpty &&
              pathSegments[0] == 'team' &&
              pathSegments.length > 1) {
            databaseId = pathSegments[1];
          } else {
            databaseId = DatabaseService.instance.publicShareId;
          }

          if (databaseId != null) {
            NavigationHelper.navigateTo(
              context,
              '/team/$databaseId/season/${bestStat.season.id}/players/${bestStat.player.id}',
              extra: {
                'player': bestStat.player,
                'season': bestStat.season,
              },
            );
          }
        },
        child: ResponsivePlayerAvatar(player: bestStat.player, avatarSize: 40),
      ),
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
                            '${entry.player.displayName} - ${entry.season.name} - ${entry.game.displayName(entry.player.teamId)}'),
                        leading: GestureDetector(
                          onTap: () async {
                            if (!kIsWeb &&
                                !SubscriptionService.instance.isSubscribed) {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: Text(AppLocalizations.of(context)!
                                        .proFeature),
                                    content: Text(AppLocalizations.of(context)!
                                        .playerProfilesProFeature),
                                    actions: [
                                      TextButton(
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .cancelButton),
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                      ),
                                      TextButton(
                                        child: Text(
                                            AppLocalizations.of(context)!
                                                .goPro),
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          await SubscriptionService.instance
                                              .purchaseSubscription();
                                        },
                                      ),
                                    ],
                                  );
                                },
                              );
                              return;
                            }

                            // Ensure season is loaded before navigation
                            await entry.season.load();

                            // Try to get databaseId from current route or from DatabaseService
                            final currentUri = GoRouterState.of(context).uri;
                            String? databaseId;

                            // Try to extract from current path
                            final pathSegments = currentUri.pathSegments;
                            if (pathSegments.isNotEmpty &&
                                pathSegments[0] == 'team' &&
                                pathSegments.length > 1) {
                              databaseId = pathSegments[1];
                            } else {
                              databaseId =
                                  DatabaseService.instance.publicShareId;
                            }

                            if (databaseId != null) {
                              NavigationHelper.navigateTo(
                                context,
                                '/team/$databaseId/season/${entry.season.id}/players/${entry.player.id}',
                                extra: {
                                  'player': entry.player,
                                  'season': entry.season,
                                },
                              );
                            }
                          },
                          child: ResponsivePlayerAvatar(
                              player: entry.player, avatarSize: 40),
                        ),
                        trailing: Text(entry.value.toString(),
                            style: const TextStyle(fontSize: 24)),
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
      leading: GestureDetector(
        onTap: () async {
          if (!kIsWeb && !SubscriptionService.instance.isSubscribed) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text(AppLocalizations.of(context)!.proFeature),
                  content: Text(
                      AppLocalizations.of(context)!.playerProfilesProFeature),
                  actions: [
                    TextButton(
                      child: Text(AppLocalizations.of(context)!.cancelButton),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    TextButton(
                      child: Text(AppLocalizations.of(context)!.goPro),
                      onPressed: () async {
                        Navigator.pop(context);
                        await SubscriptionService.instance
                            .purchaseSubscription();
                      },
                    ),
                  ],
                );
              },
            );
            return;
          }

          // Load the season for this player
          showDialog(
            context: context,
            builder: (context) {
              return const Center(child: CircularProgressIndicator());
            },
          );

          final seasonResults = await DatabaseService.instance.query('Seasons',
              orderByChild: 'id', equalTo: topEntry.key.seasonId);

          if (!mounted) return;
          Navigator.pop(context);

          if (seasonResults.isNotEmpty) {
            final season = Season.fromMap(seasonResults.first);
            await season.load();

            if (!mounted) return;

            // Try to get databaseId from current route or from DatabaseService
            final currentUri = GoRouterState.of(context).uri;
            String? databaseId;

            // Try to extract from current path
            final pathSegments = currentUri.pathSegments;
            if (pathSegments.isNotEmpty &&
                pathSegments[0] == 'team' &&
                pathSegments.length > 1) {
              databaseId = pathSegments[1];
            } else {
              databaseId = DatabaseService.instance.publicShareId;
            }

            if (databaseId != null) {
              NavigationHelper.navigateTo(
                context,
                '/team/$databaseId/season/${season.id}/players/${topEntry.key.id}',
                extra: {
                  'player': topEntry.key,
                  'season': season,
                },
              );
            }
          }
        },
        child: ResponsivePlayerAvatar(player: topEntry.key, avatarSize: 40),
      ),
      trailing:
          Text(topEntry.value.toString(), style: const TextStyle(fontSize: 24)),
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
                        leading: GestureDetector(
                          onTap: () async {
                            // Load the season for this player
                            showDialog(
                              context: context,
                              builder: (context) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              },
                            );

                            final seasonResults = await DatabaseService.instance
                                .query('Seasons',
                                    orderByChild: 'id',
                                    equalTo: entry.key.seasonId);

                            if (!mounted) return;
                            Navigator.pop(context);

                            if (seasonResults.isNotEmpty) {
                              final season =
                                  Season.fromMap(seasonResults.first);
                              await season.load();

                              if (!mounted) return;

                              // Try to get databaseId from current route or from DatabaseService
                              final currentUri = GoRouterState.of(context).uri;
                              String? databaseId;

                              // Try to extract from current path
                              final pathSegments = currentUri.pathSegments;
                              if (pathSegments.isNotEmpty &&
                                  pathSegments[0] == 'team' &&
                                  pathSegments.length > 1) {
                                databaseId = pathSegments[1];
                              } else {
                                databaseId =
                                    DatabaseService.instance.publicShareId;
                              }

                              if (databaseId != null) {
                                NavigationHelper.navigateTo(
                                  context,
                                  '/team/$databaseId/season/${season.id}/players/${entry.key.id}',
                                  extra: {
                                    'player': entry.key,
                                    'season': season,
                                  },
                                );
                              }
                            }
                          },
                          child: ResponsivePlayerAvatar(
                              player: entry.key, avatarSize: 40),
                        ),
                        title: Text(entry.key.displayName),
                        trailing: Text(entry.value.toString(),
                            style: const TextStyle(fontSize: 24)),
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
        return await widget.team.calculateCareerStats(data,
            progressController: _progressController);
      case StatType.season:
        return await widget.team.calculateBestSeasonStats(data,
            progressController: _progressController);
      case StatType.game:
        return await widget.team.calculateBestGameStats(data,
            progressController: _progressController);
    }
  }
}
