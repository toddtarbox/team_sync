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
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/event_service.dart';
import 'package:team_sync/services/subscription_service.dart';
import 'package:team_sync/utils/navigation_helper.dart';
import 'package:team_sync/widgets/responsive_player_avatar.dart';
import 'package:team_sync/widgets/stat_category_dialog.dart';
import 'package:team_sync/widgets/common/skeleton_container.dart';
import 'package:team_sync/services/sport_strategy.dart'; // Added import for SportStrategy
import 'package:team_sync/models/career_stat_entry.dart';

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

  // Current future being displayed
  Future<dynamic>? _currentFuture;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Initialize the first future
    _careerStatsFuture = _loadAndCalculateStats();
    _currentFuture = _careerStatsFuture;
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
        _currentFuture = _getOrStartCalculationFuture();
      });
    }
  }

  void _invalidateBestGameCache() async {
    if (mounted) {
      // Clear the database cache first
      await BestGameStats.clearCache(widget.team.id);

      setState(() {
        _gameStatsFuture = null;
        // If currently viewing best game stats, refresh immediately
        if (_selectedStatType == StatType.game) {
          _currentFuture = _getOrStartCalculationFuture();
        }
      });

      // Show confirmation message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Best game cache invalidated'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showActionMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Invalidate Best Game Cache'),
                  subtitle: const Text('Clear cached best game statistics'),
                  onTap: () {
                    Navigator.pop(context);
                    _invalidateBestGameCache();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.clear_all),
                  title: const Text('Clear All Caches'),
                  subtitle: const Text('Clear all cached statistics'),
                  onTap: () {
                    Navigator.pop(context);
                    _clearCache();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('All caches cleared'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
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
    return Stack(
      children: [
        Column(
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
                    // Update current future to trigger loading state in FutureBuilder
                    _currentFuture = _getOrStartCalculationFuture();
                  });
                },
              ),
            ),
            Expanded(
              child: FutureBuilder(
                future: _currentFuture,
                builder:
                    (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return _buildLoadingList();
                  } else if (snapshot.hasError) {
                    debugPrint(snapshot.error.toString());
                    debugPrintStack(stackTrace: snapshot.stackTrace);
                    return Center(
                        child: Text(
                            AppLocalizations.of(context)!.errorLoadingStats));
                  } else {
                    return _buildLeaderList(snapshot.data);
                  }
                },
              ),
            ),
          ],
        ),
        // Action menu button (mobile only)
        if (!kIsWeb)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              mini: true,
              onPressed: () {
                _showActionMenu(context);
              },
              child: const Icon(Icons.more_vert),
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
          // Show skeleton while calculating/loading
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 8,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    SkeletonContainer.circular(size: 40),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonContainer.rectangular(
                            width: double.infinity,
                            height: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          const SizedBox(height: 8),
                          SkeletonContainer.rectangular(
                            width: 100,
                            height: 14,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
      },
    );
  }

  Widget _buildLeaderList(dynamic stats) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: SportStrategy.current.leaderCategories.length,
      itemBuilder: (context, index) {
        final category = SportStrategy.current.leaderCategories[index];
        if (category == 'ownGoalsEarned' ||
            category == 'secondYellowReds' ||
            category == 'corners') {
          return const SizedBox.shrink();
        }

        Widget tile;
        if (_selectedStatType == StatType.season) {
          final categoryStats = (stats as Map<String, SeasonStat>)[category];
          if (categoryStats == null) {
            return const SizedBox.shrink();
          }
          tile = _buildSeasonStatTile(category, categoryStats);
        } else if (_selectedStatType == StatType.game) {
          final bestStat = (stats as BestGameStats).getBestStat(category);
          if (bestStat == null) {
            return const SizedBox.shrink();
          }
          tile = _buildGameStatTile(category, bestStat);
        } else {
          final categoryStats =
              (stats as Map<String, CareerStatEntry>)[category];
          if (categoryStats == null) {
            return const SizedBox.shrink();
          }
          tile = _buildStatTile(category, categoryStats);
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: tile,
          ),
        );
      },
    );
  }

  Widget _buildSeasonStatTile(String category, SeasonStat topEntry) {
    return InkWell(
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
        _showSeasonStatsModal(context, category, categoryStats);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () async {
                if (!kIsWeb && !SubscriptionService.instance.isSubscribed) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(AppLocalizations.of(context)!.proFeature),
                        content: Text(AppLocalizations.of(context)!
                            .playerProfilesProFeature),
                        actions: [
                          TextButton(
                            child: Text(
                                AppLocalizations.of(context)!.cancelButton),
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

                await topEntry.season.load();
                final currentUri = GoRouterState.of(context).uri;
                String? databaseId;
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
                    '/team/$databaseId/player/${topEntry.player.id}',
                    extra: {
                      'player': topEntry.player,
                      'season': topEntry.season,
                    },
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: ResponsivePlayerAvatar(
                    player: topEntry.player,
                    avatarSize: 48,
                    season: topEntry.season,
                    useLatestImages: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.toSentenceCase().toTitleCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    topEntry.player.displayName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    topEntry.season.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(alpha: 0.7),
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                topEntry.value.toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSeasonStatsModal(
      BuildContext context, String category, List<SeasonStat> categoryStats) {
    // Sort by stat value in descending order and limit to top 25
    final sortedStats = List<SeasonStat>.from(categoryStats)
      ..sort((a, b) => b.value.compareTo(a.value));
    final top25Stats = sortedStats.take(25).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      category.toSentenceCase().toTitleCase(),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: top25Stats.length,
                      itemBuilder: (context, index) {
                        final entry = top25Stats[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 1,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: GestureDetector(
                              onTap: () async {
                                if (!kIsWeb &&
                                    !SubscriptionService
                                        .instance.isSubscribed) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(
                                            AppLocalizations.of(context)!
                                                .proFeature),
                                        content: Text(
                                            AppLocalizations.of(context)!
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

                                await entry.season.load();
                                final currentUri =
                                    GoRouterState.of(context).uri;
                                String? databaseId;
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
                                    '/team/$databaseId/player/${entry.player.id}',
                                    extra: {
                                      'player': entry.player,
                                      'season': entry.season,
                                    },
                                  );
                                }
                              },
                              child: ResponsivePlayerAvatar(
                                  player: entry.player,
                                  avatarSize: 40,
                                  season: entry.season,
                                  useLatestImages: true),
                            ),
                            title: Text(
                              entry.player.displayName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(entry.season.name),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                entry.value.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer,
                                    ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGameStatTile(String category, BestGameStat bestStat) {
    return InkWell(
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
        _showGameStatsModal(context, category, categoryStats);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () async {
                if (!kIsWeb && !SubscriptionService.instance.isSubscribed) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(AppLocalizations.of(context)!.proFeature),
                        content: Text(AppLocalizations.of(context)!
                            .playerProfilesProFeature),
                        actions: [
                          TextButton(
                            child: Text(
                                AppLocalizations.of(context)!.cancelButton),
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

                await bestStat.season.load();
                final currentUri = GoRouterState.of(context).uri;
                String? databaseId;
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
                    '/team/$databaseId/player/${bestStat.player.id}',
                    extra: {
                      'player': bestStat.player,
                      'season': bestStat.season,
                    },
                  );
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: ResponsivePlayerAvatar(
                    player: bestStat.player,
                    avatarSize: 48,
                    season: bestStat.season,
                    useLatestImages: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.toSentenceCase().toTitleCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    bestStat.player.displayName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${bestStat.season.name} - ${bestStat.game.displayName(bestStat.player.teamId)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.color
                              ?.withValues(alpha: 0.7),
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                bestStat.displayValue ?? bestStat.value.toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showGameStatsModal(
      BuildContext context, String category, List<BestGameStat> categoryStats) {
    // Sort by stat value in descending order and limit to top 25
    final sortedStats = List<BestGameStat>.from(categoryStats)
      ..sort((a, b) => b.value.compareTo(a.value));
    final top25Stats = sortedStats.take(25).toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(vertical: 12),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Theme.of(context).dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    child: Text(
                      category.toSentenceCase().toTitleCase(),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: top25Stats.length,
                      itemBuilder: (context, index) {
                        final entry = top25Stats[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          elevation: 1,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            leading: GestureDetector(
                              onTap: () async {
                                if (!kIsWeb &&
                                    !SubscriptionService
                                        .instance.isSubscribed) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(
                                            AppLocalizations.of(context)!
                                                .proFeature),
                                        content: Text(
                                            AppLocalizations.of(context)!
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

                                await entry.season.load();
                                final currentUri =
                                    GoRouterState.of(context).uri;
                                String? databaseId;
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
                                    '/team/$databaseId/player/${entry.player.id}',
                                    extra: {
                                      'player': entry.player,
                                      'season': entry.season,
                                    },
                                  );
                                }
                              },
                              child: ResponsivePlayerAvatar(
                                  player: entry.player,
                                  avatarSize: 40,
                                  season: entry.season,
                                  useLatestImages: true),
                            ),
                            title: Text(
                              entry.player.displayName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                                '${entry.season.name} - ${entry.game.displayName(entry.player.teamId)}'),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondaryContainer,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                entry.value.toString(),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSecondaryContainer,
                                    ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatTile(String category, CareerStatEntry topEntry) {
    return InkWell(
      onTap: () async {
        showDialog(
            context: context,
            builder: (context) {
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: 8,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(
                      children: [
                        SkeletonContainer.circular(size: 40),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonContainer.rectangular(
                                width: double.infinity,
                                height: 16,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              const SizedBox(height: 8),
                              SkeletonContainer.rectangular(
                                width: 100,
                                height: 14,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            });
        final categoryStats =
            await widget.team.getCareerStatsForCategory(category);
        if (!mounted) return;
        Navigator.pop(context);
        _showCareerStatsModal(context, category, categoryStats);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            GestureDetector(
              onTap: () async {
                if (!kIsWeb && !SubscriptionService.instance.isSubscribed) {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text(AppLocalizations.of(context)!.proFeature),
                        content: Text(AppLocalizations.of(context)!
                            .playerProfilesProFeature),
                        actions: [
                          TextButton(
                            child: Text(
                                AppLocalizations.of(context)!.cancelButton),
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
                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: 8,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            children: [
                              SkeletonContainer.circular(size: 40),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SkeletonContainer.rectangular(
                                      width: double.infinity,
                                      height: 16,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    const SizedBox(height: 8),
                                    SkeletonContainer.rectangular(
                                      width: 100,
                                      height: 14,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );

                final seasonResults = await DatabaseService.instance.query(
                    'Seasons',
                    orderByChild: 'id',
                    equalTo: topEntry.player.seasonId);

                if (!mounted) return;
                Navigator.pop(context);

                if (seasonResults.isNotEmpty) {
                  final season = Season.fromMap(seasonResults.first);
                  await season.load();

                  if (!mounted) return;

                  final currentUri = GoRouterState.of(context).uri;
                  String? databaseId;
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
                      '/team/$databaseId/player/${topEntry.player.id}',
                      extra: {
                        'player': topEntry.player,
                        'season': season,
                      },
                    );
                  }
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: ResponsivePlayerAvatar(
                    player: topEntry.player,
                    avatarSize: 48,
                    useLatestImages: true),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.toSentenceCase().toTitleCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    topEntry.player.displayName,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                topEntry.displayValue ?? topEntry.value.toString(),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCareerStatsModal(BuildContext context, String category,
      List<CareerStatEntry> categoryStats) async {
    // Convert list to map for StatCategoryDialog
    final playerStatsMap = <Player, int>{};
    final displayValues = <Player, String>{};

    for (final entry in categoryStats) {
      playerStatsMap[entry.player] = entry.value;
      if (entry.displayValue != null) {
        displayValues[entry.player] = entry.displayValue!;
      }
    }

    // Show dialog with navigation callback
    await StatCategoryDialog.show(
      context: context,
      categoryName: category.toSentenceCase().toTitleCase(),
      playerStats: playerStatsMap,
      displayValues: displayValues,
      showPlayerNumber: true,
      onPlayerTap: (player) => _showPlayerDetailsDialog(player, null),
      season: null,
      maxPlayers: 25, // Show top 25
    );
  }

  Future<void> _showPlayerDetailsDialog(Player player, Season? season) async {
    // Check subscription before navigating
    if (!kIsWeb && !SubscriptionService.instance.isSubscribed) {
      if (mounted) Navigator.pop(context); // Close the stats dialog first

      final loc = AppLocalizations.of(context)!;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(loc.proFeature),
            content: Text(loc.playerProfilesProFeature),
            actions: [
              TextButton(
                child: Text(loc.cancelButton),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
              TextButton(
                child: Text(loc.goPro),
                onPressed: () async {
                  Navigator.pop(context);
                  await SubscriptionService.instance.purchaseSubscription();
                },
              ),
            ],
          );
        },
      );
      return;
    }

    // Close the dialog first
    Navigator.pop(context);

    Season? targetSeason = season;

    if (targetSeason == null) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return const Center(child: CircularProgressIndicator());
        },
      );

      // Load the season for this player
      final seasonResults = await DatabaseService.instance.query(
        'Seasons',
        orderByChild: 'id',
        equalTo: player.seasonId,
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading

      if (seasonResults.isNotEmpty) {
        targetSeason = Season.fromMap(seasonResults.first);
        await targetSeason.load();
      }
    }

    if (!mounted || targetSeason == null) return;

    final currentUri = GoRouterState.of(context).uri;
    String? databaseId;
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
        '/team/$databaseId/season/${targetSeason.id}/players/${player.id}',
        extra: {
          'player': player,
          'season': targetSeason,
        },
      );
    }
  }

  Future<dynamic> _loadData() async {
    switch (_selectedStatType) {
      case StatType.career:
        return await widget.team.fetchAllDataForCareer();
      case StatType.season:
        return await widget.team.fetchAllDataForSeason();
      case StatType.game:
        // For game stats, we don't need to fetch all data upfront
        // The getBestGameStats method will handle loading from cache or calculating
        return null;
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
        // Use the new cached method that loads from database or calculates if needed
        return await widget.team
            .getBestGameStats(progressController: _progressController);
    }
  }
}
