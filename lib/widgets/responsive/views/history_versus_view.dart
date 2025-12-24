import 'dart:collection';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/widgets/common/skeleton_container.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';

class HistoryVersusView extends StatefulWidget {
  final Team team;

  const HistoryVersusView({super.key, required this.team});

  @override
  State<HistoryVersusView> createState() => _HistoryVersusViewState();
}

enum SortOption {
  recentFirst,
  teamName,
  mostGames,
  mostWins,
  winPercentage,
}

enum TimeFilter {
  allTime,
  currentSeason,
  lastSeason,
  last3Years,
  last5Years,
  last10Years,
}

class _HistoryVersusViewState extends State<HistoryVersusView> {
  List<Season> _allSeasons = [];
  SortOption _sortOption = SortOption.recentFirst;
  TimeFilter _timeFilter = TimeFilter.allTime;
  final Set<int> _expandedTeams =
      {}; // Track which team analytics are expanded (by team ID)

  @override
  void initState() {
    super.initState();
  }

  List<MapEntry<Team, List<Game>>> _sortTeams(
    Map<Team, List<Game>> history,
    SortOption sortOption,
  ) {
    final entries = history.entries.toList();

    switch (sortOption) {
      case SortOption.recentFirst:
        entries.sort((a, b) {
          // Only consider completed games (status >= 9)
          final aCompletedGames = a.value.where((g) => g.gameStatus.index >= 9);
          final bCompletedGames = b.value.where((g) => g.gameStatus.index >= 9);

          final aLatest = aCompletedGames.isNotEmpty
              ? aCompletedGames
                  .map((g) => g.date)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
              : DateTime(1900);
          final bLatest = bCompletedGames.isNotEmpty
              ? bCompletedGames
                  .map((g) => g.date)
                  .reduce((a, b) => a.isAfter(b) ? a : b)
              : DateTime(1900);
          return bLatest.compareTo(aLatest);
        });
        break;
      case SortOption.teamName:
        entries.sort((a, b) => a.key.fullName.compareTo(b.key.fullName));
        break;
      case SortOption.mostGames:
        entries.sort((a, b) => b.value.length.compareTo(a.value.length));
        break;
      case SortOption.mostWins:
        entries.sort((a, b) {
          final aWins = a.value.where((g) => g.isWin(widget.team.id)).length;
          final bWins = b.value.where((g) => g.isWin(widget.team.id)).length;
          return bWins.compareTo(aWins);
        });
        break;
      case SortOption.winPercentage:
        entries.sort((a, b) {
          final aWins = a.value.where((g) => g.isWin(widget.team.id)).length;
          final bWins = b.value.where((g) => g.isWin(widget.team.id)).length;
          final aTotal = a.value.length;
          final bTotal = b.value.length;
          final aPercentage = aTotal > 0 ? aWins / aTotal : 0.0;
          final bPercentage = bTotal > 0 ? bWins / bTotal : 0.0;
          return bPercentage.compareTo(aPercentage);
        });
        break;
    }

    return entries;
  }

  String _getSortLabel(SortOption option) {
    final loc = AppLocalizations.of(context)!;
    switch (option) {
      case SortOption.recentFirst:
        return loc.sortByRecent;
      case SortOption.teamName:
        return loc.sortByTeamName;
      case SortOption.mostGames:
        return loc.sortByMostGames;
      case SortOption.mostWins:
        return loc.sortByMostWins;
      case SortOption.winPercentage:
        return loc.sortByWinPercentage;
    }
  }

  String _getTimeFilterLabel(TimeFilter filter) {
    final loc = AppLocalizations.of(context)!;
    switch (filter) {
      case TimeFilter.allTime:
        return loc.allTime;
      case TimeFilter.currentSeason:
        return loc.currentSeason;
      case TimeFilter.lastSeason:
        return loc.lastSeason;
      case TimeFilter.last3Years:
        return loc.last3Years;
      case TimeFilter.last5Years:
        return loc.last5Years;
      case TimeFilter.last10Years:
        return loc.last10Years;
    }
  }

  /// Filter games based on selected seasons filter
  List<Game> _filterGamesByTime(
    List<Game> games, {
    Set<int>? globalSeasonIdsForRange,
  }) {
    switch (_timeFilter) {
      case TimeFilter.allTime:
        return games;

      default:
        if (globalSeasonIdsForRange == null ||
            globalSeasonIdsForRange.isEmpty) {
          return [];
        }

        // Return only completed games from the specified season range
        return games
            .where((g) =>
                globalSeasonIdsForRange.contains(g.seasonId) &&
                g.gameStatus.index >= 9)
            .toList();
    }
  }

  /// Apply time filter to the history map
  Map<Team, List<Game>> _applyTimeFilter(Map<Team, List<Game>> history) {
    Set<int>? globalSeasonIdsForRange;

    if (_timeFilter != TimeFilter.allTime) {
      if (_allSeasons.isNotEmpty) {
        final sortedSeasonIds = _allSeasons.map((s) => s.id).toList();

        if (_timeFilter != TimeFilter.currentSeason) {
          // Check if any games in the current season have been played.
          // If not, then don't consider the current season in history.
          final currentSeasonGames = history.values.where((games) => games.any(
              (game) =>
                  game.seasonId == sortedSeasonIds.first && game.isCompleted));
          if (currentSeasonGames.isEmpty) {
            sortedSeasonIds.removeWhere((id) => id == sortedSeasonIds.first);
          }
        }

        switch (_timeFilter) {
          case TimeFilter.currentSeason:
            globalSeasonIdsForRange = sortedSeasonIds.take(1).toSet();
            break;
          case TimeFilter.lastSeason:
            globalSeasonIdsForRange = sortedSeasonIds.take(1).toSet();
            break;
          case TimeFilter.last3Years:
            // Last 3 seasons = top 3 season IDs
            globalSeasonIdsForRange = sortedSeasonIds.take(3).toSet();
            break;
          case TimeFilter.last5Years:
            // Last 5 seasons = top 5 season IDs
            globalSeasonIdsForRange = sortedSeasonIds.take(5).toSet();
            break;
          case TimeFilter.last10Years:
            // Last 10 seasons = top 10 season IDs
            globalSeasonIdsForRange = sortedSeasonIds.take(10).toSet();
            break;
          default:
            break;
        }
      }
    }

    final filtered = <Team, List<Game>>{};

    for (final entry in history.entries) {
      final filteredGames = _filterGamesByTime(
        entry.value,
        globalSeasonIdsForRange: globalSeasonIdsForRange,
      );
      if (filteredGames.isNotEmpty) {
        filtered[entry.key] = filteredGames;
      }
    }

    return filtered;
  }

  /// Build overall analytics section showing aggregate stats for filtered period
  Widget _buildOverallAnalytics(Map<Team, List<Game>> history) {
    final loc = AppLocalizations.of(context)!;

    // Collect all games from all opponents
    final allGames = <Game>[];
    for (final games in history.values) {
      allGames.addAll(games);
    }

    // Calculate overall statistics
    final stats = _calculateAggregateStats(allGames);

    if (stats.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Icon(
                Icons.analytics,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                loc.overallStatistics,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              // Show filter indicator
              if (_timeFilter != TimeFilter.allTime)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getTimeFilterLabel(_timeFilter),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
            ],
          ),
        ),
        // Analytics cards grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 600;

            if (isWide) {
              // 2x2 grid for wider screens
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsSummaryCard(
                          loc.recordSummary,
                          Icons.emoji_events,
                          Colors.amber,
                          [
                            _buildStatRow2(loc.totalGames,
                                '${stats['totalGames']}', Icons.sports_soccer),
                            _buildStatRow2(loc.wins, '${stats['wins']}',
                                Icons.trending_up),
                            _buildStatRow2(loc.losses, '${stats['losses']}',
                                Icons.trending_down),
                            _buildStatRow2(
                                loc.ties, '${stats['ties']}', Icons.remove),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnalyticsSummaryCard(
                          loc.goalAnalytics,
                          Icons.sports_score,
                          Colors.green,
                          [
                            _buildStatRow2(loc.totalGoalsScored,
                                '${stats['totalGoalsScored']}', Icons.north),
                            _buildStatRow2(loc.totalGoalsConceded,
                                '${stats['totalGoalsConceded']}', Icons.south),
                            _buildStatRow2(
                                loc.avgGoalsPerGame,
                                stats['avgGoalsPerGame']!.toStringAsFixed(2),
                                Icons.functions),
                            _buildStatRow2(
                                loc.goalDifferential,
                                stats['goalDifferential']! >= 0
                                    ? '+${stats['goalDifferential']}'
                                    : '${stats['goalDifferential']}',
                                Icons.compare_arrows),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsSummaryCard(
                          loc.streaksRecords,
                          Icons.flash_on,
                          Colors.purple,
                          [
                            _buildStatRow2(
                                loc.longestWinStreak,
                                '${stats['longestWinStreak']}W',
                                Icons.trending_up),
                            _buildStatRow2(
                                loc.biggestVictory,
                                '+${stats['biggestVictory']}',
                                Icons.celebration),
                            _buildStatRow2(loc.cleanSheets,
                                '${stats['cleanSheets']}', Icons.shield),
                            _buildStatRow2(
                                loc.winPercentage,
                                '${(stats['winPercentage']! * 100).toStringAsFixed(1)}%',
                                Icons.percent),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnalyticsSummaryCard(
                          loc.homeAwayAnalysis,
                          Icons.home,
                          Colors.blue,
                          [
                            _buildStatRow2(
                                loc.homeRecord,
                                '${stats['homeWins']}-${stats['homeLosses']}-${stats['homeTies']}',
                                Icons.home),
                            _buildStatRow2(
                                loc.awayRecord,
                                '${stats['awayWins']}-${stats['awayLosses']}-${stats['awayTies']}',
                                Icons.flight_takeoff),
                            _buildStatRow2(
                                loc.homeWinPercentage,
                                '${(stats['homeWinPct']! * 100).toStringAsFixed(0)}%',
                                Icons.home_outlined),
                            _buildStatRow2(
                                loc.awayWinPercentage,
                                '${(stats['awayWinPct']! * 100).toStringAsFixed(0)}%',
                                Icons.flight_outlined),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              );
            } else {
              // Carousel for narrow screens
              final carouselItems = [
                _buildAnalyticsSummaryCard(
                  loc.recordSummary,
                  Icons.emoji_events,
                  Colors.amber,
                  [
                    _buildStatRow2(loc.totalGames, '${stats['totalGames']}',
                        Icons.sports_soccer),
                    _buildStatRow2(
                        loc.wins, '${stats['wins']}', Icons.trending_up),
                    _buildStatRow2(
                        loc.losses, '${stats['losses']}', Icons.trending_down),
                    _buildStatRow2(loc.ties, '${stats['ties']}', Icons.remove),
                  ],
                ),
                _buildAnalyticsSummaryCard(
                  loc.goalAnalytics,
                  Icons.sports_score,
                  Colors.green,
                  [
                    _buildStatRow2(loc.totalGoalsScored,
                        '${stats['totalGoalsScored']}', Icons.north),
                    _buildStatRow2(loc.totalGoalsConceded,
                        '${stats['totalGoalsConceded']}', Icons.south),
                    _buildStatRow2(
                        loc.avgGoalsPerGame,
                        stats['avgGoalsPerGame']!.toStringAsFixed(2),
                        Icons.functions),
                    _buildStatRow2(
                        loc.goalDifferential,
                        stats['goalDifferential']! >= 0
                            ? '+${stats['goalDifferential']}'
                            : '${stats['goalDifferential']}',
                        Icons.compare_arrows),
                  ],
                ),
                _buildAnalyticsSummaryCard(
                  loc.streaksRecords,
                  Icons.flash_on,
                  Colors.purple,
                  [
                    _buildStatRow2(loc.longestWinStreak,
                        '${stats['longestWinStreak']}W', Icons.trending_up),
                    _buildStatRow2(loc.biggestVictory,
                        '+${stats['biggestVictory']}', Icons.celebration),
                    _buildStatRow2(loc.cleanSheets, '${stats['cleanSheets']}',
                        Icons.shield),
                    _buildStatRow2(
                        loc.winPercentage,
                        '${(stats['winPercentage']! * 100).toStringAsFixed(1)}%',
                        Icons.percent),
                  ],
                ),
                _buildAnalyticsSummaryCard(
                  loc.homeAwayAnalysis,
                  Icons.home,
                  Colors.blue,
                  [
                    _buildStatRow2(
                        loc.homeRecord,
                        '${stats['homeWins']}-${stats['homeLosses']}-${stats['homeTies']}',
                        Icons.home),
                    _buildStatRow2(
                        loc.awayRecord,
                        '${stats['awayWins']}-${stats['awayLosses']}-${stats['awayTies']}',
                        Icons.flight_takeoff),
                    _buildStatRow2(
                        loc.homeWinPercentage,
                        '${(stats['homeWinPct']! * 100).toStringAsFixed(0)}%',
                        Icons.home_outlined),
                    _buildStatRow2(
                        loc.awayWinPercentage,
                        '${(stats['awayWinPct']! * 100).toStringAsFixed(0)}%',
                        Icons.flight_outlined),
                  ],
                ),
              ];

              return _AnalyticsCarousel(items: carouselItems);
            }
          },
        ),
      ],
    );
  }

  /// Build individual analytics summary card
  Widget _buildAnalyticsSummaryCard(
    String title,
    IconData icon,
    Color color,
    List<Widget> stats,
  ) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: color.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.08),
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...stats,
          ],
        ),
      ),
    );
  }

  /// Build stat row for analytics summary cards
  Widget _buildStatRow2(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: 14,
            color: Theme.of(context)
                .colorScheme
                .onSurfaceVariant
                .withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate aggregate statistics from all filtered games
  Map<String, num> _calculateAggregateStats(List<Game> allGames) {
    final stats = <String, num>{};

    final now = DateTime.now();

    // Only consider completed games from the past
    final completedGames = allGames
        .where((g) => g.gameStatus.index >= 9 && g.date.isBefore(now))
        .toList();

    if (completedGames.isEmpty) {
      return stats;
    }

    // Sort games chronologically for streak calculations
    final sortedGames = List<Game>.from(completedGames)
      ..sort((a, b) => a.date.compareTo(b.date));

    int wins = 0, losses = 0, ties = 0;
    int homeWins = 0, homeLosses = 0, homeTies = 0;
    int awayWins = 0, awayLosses = 0, awayTies = 0;
    int totalGoalsScored = 0, totalGoalsConceded = 0;
    int cleanSheets = 0;
    int longestWinStreak = 0, currentWinStreak = 0;
    int biggestVictory = 0;

    for (final game in sortedGames) {
      final isHome = game.isHomeTeam(widget.team.id);
      final goalsFor = isHome ? game.homeTeamScore : game.awayTeamScore;
      final goalsAgainst = isHome ? game.awayTeamScore : game.homeTeamScore;
      final goalDiff = goalsFor - goalsAgainst;

      totalGoalsScored += goalsFor;
      totalGoalsConceded += goalsAgainst;

      if (goalsAgainst == 0) cleanSheets++;
      if (goalDiff > biggestVictory) biggestVictory = goalDiff;

      // Track wins/losses/ties
      if (game.isWin(widget.team.id)) {
        wins++;
        currentWinStreak++;
        if (currentWinStreak > longestWinStreak) {
          longestWinStreak = currentWinStreak;
        }

        if (isHome) {
          homeWins++;
        } else {
          awayWins++;
        }
      } else if (game.isTie) {
        ties++;
        currentWinStreak = 0;

        if (isHome) {
          homeTies++;
        } else {
          awayTies++;
        }
      } else {
        losses++;
        currentWinStreak = 0;

        if (isHome) {
          homeLosses++;
        } else {
          awayLosses++;
        }
      }
    }

    final totalGames = completedGames.length;
    final homeGames = homeWins + homeLosses + homeTies;
    final awayGames = awayWins + awayLosses + awayTies;

    stats['totalGames'] = totalGames;
    stats['wins'] = wins;
    stats['losses'] = losses;
    stats['ties'] = ties;
    stats['winPercentage'] = totalGames > 0 ? wins / totalGames : 0;

    stats['totalGoalsScored'] = totalGoalsScored;
    stats['totalGoalsConceded'] = totalGoalsConceded;
    stats['avgGoalsPerGame'] =
        totalGames > 0 ? totalGoalsScored / totalGames : 0;
    stats['goalDifferential'] = totalGoalsScored - totalGoalsConceded;

    stats['longestWinStreak'] = longestWinStreak;
    stats['biggestVictory'] = biggestVictory;
    stats['cleanSheets'] = cleanSheets;

    stats['homeWins'] = homeWins;
    stats['homeLosses'] = homeLosses;
    stats['homeTies'] = homeTies;
    stats['homeWinPct'] = homeGames > 0 ? homeWins / homeGames : 0;

    stats['awayWins'] = awayWins;
    stats['awayLosses'] = awayLosses;
    stats['awayTies'] = awayTies;
    stats['awayWinPct'] = awayGames > 0 ? awayWins / awayGames : 0;

    return stats;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _loadHistory(),
        builder: (BuildContext context,
            AsyncSnapshot<Map<Team, List<Game>>?> snapshot) {
          if (snapshot.hasData) {
            // Apply time filter first
            final filteredHistory = _applyTimeFilter(snapshot.data ?? {});

            final sortedEntries = _sortTeams(
              filteredHistory,
              _sortOption,
            );

            return Column(
              children: [
                // Sorting chips
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: SortOption.values.map((option) {
                        final isSelected = _sortOption == option;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_getSortLabel(option)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _sortOption = option;
                              });
                            },
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            selectedColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Time filter chips
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: TimeFilter.values.map((filter) {
                        final isSelected = _timeFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(_getTimeFilterLabel(filter)),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _timeFilter = filter;
                              });
                            },
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            selectedColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                  : Theme.of(context).colorScheme.onSurface,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context)
                                      .colorScheme
                                      .outline
                                      .withOpacity(0.3),
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                // Teams list with analytics header or empty state
                Expanded(
                  child: sortedEntries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.sports_soccer,
                                size: 64,
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                AppLocalizations.of(context)!
                                    .noMatchupHistoryYet,
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.color
                                      ?.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: sortedEntries.length +
                              1, // +1 for analytics header
                          itemBuilder: (context, index) {
                            // First item is the analytics section
                            if (index == 0 && sortedEntries.isNotEmpty) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16),
                                child: _buildOverallAnalytics(filteredHistory),
                              );
                            }

                            // Adjust index for actual team entries
                            final adjustedIndex = index - 1;
                            if (adjustedIndex < 0 ||
                                adjustedIndex >= sortedEntries.length) {
                              return const SizedBox.shrink();
                            }

                            final entry = sortedEntries[adjustedIndex];
                            final team = entry.key;
                            final games = entry
                                .value; // Already filtered by _applyTimeFilter
                            final loc = AppLocalizations.of(context)!;

                            // Games are already filtered by _applyTimeFilter, no need to filter again
                            int wins = games
                                .where((g) => g.isWin(widget.team.id))
                                .length;
                            int losses = games
                                .where((g) =>
                                    g.gameStatus.index >= 9 &&
                                    !g.isWin(widget.team.id) &&
                                    !g.isTie)
                                .length;
                            int ties = games.where((g) => g.isTie).length;
                            final totalGames = games.length;
                            final winPercentage =
                                totalGames > 0 ? (wins / totalGames) : 0.0;

                            final dominantColor = (wins > losses)
                                ? Colors.green
                                : (wins < losses)
                                    ? Colors.red
                                    : Colors.grey;

                            return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: dominantColor.withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () =>
                                      _showMatchupDetails(context, team, games),
                                  borderRadius: BorderRadius.circular(16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Team name and logo row
                                        Row(
                                          children: [
                                            // Team Logo/Avatar
                                            if (team.logoUrl != null &&
                                                team.logoUrl!.isNotEmpty)
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  image: DecorationImage(
                                                    image: NetworkImage(
                                                        team.logoUrl!),
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              )
                                            else
                                              Container(
                                                width: 48,
                                                height: 48,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: team.color1
                                                      .withOpacity(0.2),
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    team.shortName.isNotEmpty
                                                        ? team.shortName[0]
                                                            .toUpperCase()
                                                        : '?',
                                                    style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      color: team.color1,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(width: 16),
                                            // Team name and record
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    team.fullName,
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    totalGames == 1
                                                        ? '1 ${loc.gamesSingular}'
                                                        : '$totalGames ${loc.gamesPlural}',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Theme.of(context)
                                                          .textTheme
                                                          .bodyMedium
                                                          ?.color
                                                          ?.withOpacity(0.6),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            // Win percentage badge
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: dominantColor
                                                    .withOpacity(0.15),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                                border: Border.all(
                                                  color: dominantColor
                                                      .withOpacity(0.5),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                '${(winPercentage * 100).toStringAsFixed(0)}%',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: dominantColor,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        // Record display with visual bars
                                        Row(
                                          children: [
                                            // Wins
                                            _buildRecordStat(
                                              context,
                                              loc.winAbbreviation,
                                              wins,
                                              Colors.green,
                                              winPercentage,
                                            ),
                                            const SizedBox(width: 12),
                                            // Losses
                                            _buildRecordStat(
                                              context,
                                              loc.lossAbbreviation,
                                              losses,
                                              Colors.red,
                                              totalGames > 0
                                                  ? (losses / totalGames)
                                                  : 0.0,
                                            ),
                                            const SizedBox(width: 12),
                                            // Ties
                                            _buildRecordStat(
                                              context,
                                              loc.tieAbbreviation,
                                              ties,
                                              Colors.grey,
                                              totalGames > 0
                                                  ? (ties / totalGames)
                                                  : 0.0,
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        // Progress bar showing win/loss distribution
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          child: SizedBox(
                                            height: 8,
                                            child: Row(
                                              children: [
                                                if (wins > 0)
                                                  Expanded(
                                                    flex: wins,
                                                    child: Container(
                                                        color: Colors.green),
                                                  ),
                                                if (losses > 0)
                                                  Expanded(
                                                    flex: losses,
                                                    child: Container(
                                                        color: Colors.red),
                                                  ),
                                                if (ties > 0)
                                                  Expanded(
                                                    flex: ties,
                                                    child: Container(
                                                        color: Colors.grey),
                                                  ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        // Analytics section - Collapsible
                                        Column(
                                          children: [
                                            // Analytics header with expand/collapse button
                                            InkWell(
                                              onTap: () {
                                                setState(() {
                                                  if (_expandedTeams
                                                      .contains(team.id)) {
                                                    _expandedTeams
                                                        .remove(team.id);
                                                  } else {
                                                    _expandedTeams.add(team.id);
                                                  }
                                                });
                                              },
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest
                                                      .withOpacity(0.3),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .outline
                                                        .withOpacity(0.2),
                                                  ),
                                                ),
                                                child: Row(
                                                  children: [
                                                    Icon(
                                                      Icons.analytics,
                                                      size: 16,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      loc.analytics,
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        color: Theme.of(context)
                                                            .colorScheme
                                                            .primary,
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Icon(
                                                      _expandedTeams
                                                              .contains(team.id)
                                                          ? Icons.expand_less
                                                          : Icons.expand_more,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            // Expandable analytics content
                                            if (_expandedTeams
                                                .contains(team.id)) ...[
                                              const SizedBox(height: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surfaceContainerHighest
                                                      .withOpacity(0.3),
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .outline
                                                        .withOpacity(0.2),
                                                  ),
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    // Goals and streaks
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child:
                                                              _buildAnalyticItem(
                                                            context,
                                                            loc.avgGoalsFor,
                                                            _calculateAvgGoalsFor(
                                                                    games)
                                                                .toStringAsFixed(
                                                                    1),
                                                            Icons.sports_soccer,
                                                            Colors.green,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Expanded(
                                                          child:
                                                              _buildAnalyticItem(
                                                            context,
                                                            loc.avgGoalsAgainst,
                                                            _calculateAvgGoalsAgainst(
                                                                    games)
                                                                .toStringAsFixed(
                                                                    1),
                                                            Icons.shield,
                                                            Colors.red,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child:
                                                              _buildAnalyticItem(
                                                            context,
                                                            loc.biggestWin,
                                                            '+${_calculateBiggestWin(games)}',
                                                            Icons.trending_up,
                                                            Colors.green,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Expanded(
                                                          child:
                                                              _buildAnalyticItem(
                                                            context,
                                                            loc.biggestLoss,
                                                            '-${_calculateBiggestLoss(games)}',
                                                            Icons.trending_down,
                                                            Colors.red,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child:
                                                              _buildAnalyticItem(
                                                            context,
                                                            loc.currentStreak,
                                                            _calculateCurrentStreak(
                                                                games),
                                                            Icons.flash_on,
                                                            dominantColor,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Expanded(
                                                          child:
                                                              _buildAnalyticItem(
                                                            context,
                                                            loc.longestWinStreak,
                                                            '${_calculateLongestWinStreak(games)}W',
                                                            Icons.emoji_events,
                                                            Colors.amber,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    // Tier 1 Analytics Row 1
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child:
                                                              _buildAnalyticItem(
                                                            context,
                                                            loc.cleanSheets,
                                                            '${(_calculateCleanSheetPercentage(games) * 100).toStringAsFixed(0)}%',
                                                            Icons.block,
                                                            Colors.blue,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Expanded(
                                                          child:
                                                              _buildAnalyticItem(
                                                            context,
                                                            loc.goalDifferential,
                                                            _calculateGoalDifferential(
                                                                        games) >=
                                                                    0
                                                                ? '+${_calculateGoalDifferential(games)}'
                                                                : '${_calculateGoalDifferential(games)}',
                                                            Icons
                                                                .compare_arrows,
                                                            _calculateGoalDifferential(
                                                                        games) >=
                                                                    0
                                                                ? Colors.green
                                                                : Colors.red,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    // Tier 1 Analytics Row 2
                                                    Row(
                                                      children: [
                                                        Expanded(
                                                          child:
                                                              _buildAnalyticItem(
                                                            context,
                                                            loc.homeRecord,
                                                            _formatRecord(
                                                                _calculateHomeRecord(
                                                                    games)),
                                                            Icons.home,
                                                            Colors.teal,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            width: 8),
                                                        Expanded(
                                                          child:
                                                              _buildAnalyticItem(
                                                            context,
                                                            loc.awayRecord,
                                                            _formatRecord(
                                                                _calculateAwayRecord(
                                                                    games)),
                                                            Icons
                                                                .flight_takeoff,
                                                            Colors.purple,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    // Points Per Game
                                                    _buildAnalyticItem(
                                                      context,
                                                      loc.pointsPerGame,
                                                      _calculatePointsPerGame(
                                                              games)
                                                          .toStringAsFixed(2),
                                                      Icons.grade,
                                                      Colors.indigo,
                                                    ),
                                                    // Tier 2 Analytics - Only show if data exists
                                                    if (_hasTier2Analytics(
                                                        games)) ...[
                                                      const SizedBox(height: 8),
                                                      // Tier 2 Analytics Row 1
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                _buildAnalyticItem(
                                                              context,
                                                              loc.shootingAccuracy,
                                                              '${(_calculateShootingAccuracy(games) * 100).toStringAsFixed(0)}%',
                                                              Icons.gps_fixed,
                                                              Colors.deepOrange,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child:
                                                                _buildAnalyticItem(
                                                              context,
                                                              loc.comebackWins,
                                                              '${_calculateComebackWins(games)}',
                                                              Icons.trending_up,
                                                              Colors.lightGreen,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 8),
                                                      // Tier 2 Analytics Row 2
                                                      Row(
                                                        children: [
                                                          Expanded(
                                                            child:
                                                                _buildAnalyticItem(
                                                              context,
                                                              loc.lateGoals,
                                                              '${_calculateLateGoals(games)}',
                                                              Icons.access_time,
                                                              Colors.deepPurple,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 8),
                                                          Expanded(
                                                            child:
                                                                _buildAnalyticItem(
                                                              context,
                                                              loc.cardsPerGame,
                                                              _calculateCardsPerGame(
                                                                      games)
                                                                  .toStringAsFixed(
                                                                      2),
                                                              Icons.style,
                                                              Colors.yellow
                                                                  .shade700,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                    const SizedBox(height: 12),
                                                    // Recent form
                                                    Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          loc.recentForm,
                                                          style: TextStyle(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: Theme.of(
                                                                    context)
                                                                .textTheme
                                                                .bodySmall
                                                                ?.color
                                                                ?.withOpacity(
                                                                    0.7),
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 6),
                                                        _buildFormIndicator(
                                                          context,
                                                          _getRecentForm(games),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ));
                          },
                        ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(
                child: Text(AppLocalizations.of(context)!.errorLoadingHistory));
          } else {
            return ListView.separated(
              itemCount: 8,
              padding: const EdgeInsets.all(16),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        SkeletonContainer.circular(size: 48),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SkeletonContainer.rectangular(
                                width: 150,
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
                  ),
                );
              },
            );
          }
        });
  }

  Widget _buildAnalyticItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.color
                        ?.withOpacity(0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormIndicator(BuildContext context, String form) {
    if (form == '-') {
      return Text(
        form,
        style: const TextStyle(
          fontSize: 14,
          color: Colors.grey,
        ),
      );
    }

    final results = form.split(' ');
    return Wrap(
      spacing: 4,
      children: results.map((result) {
        Color color;
        if (result == 'W') {
          color = Colors.green;
        } else if (result == 'L') {
          color = Colors.red;
        } else {
          color = Colors.grey;
        }

        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: color,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              result,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecordStat(
    BuildContext context,
    String label,
    int count,
    Color color,
    double percentage,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMatchupDetails(
    BuildContext context,
    Team? team,
    List<Game> games,
  ) async {
    games.sort((a, b) => b.date.compareTo(a.date));

    // Show a temp progress dialog
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonContainer.rectangular(
                          width: 200,
                          height: 24,
                          borderRadius: BorderRadius.circular(4)), // Header
                      const SizedBox(height: 16),
                      // Grid of cards
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: List.generate(
                            4,
                            (index) => SkeletonContainer.rectangular(
                                height: 100,
                                borderRadius: BorderRadius.circular(12))),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(AppLocalizations.of(context)!.loading),
            ],
          ),
        );
      },
    );

    await Future.wait(
      games.map((g) async => await g.loadGameEvents()).toList(growable: false),
    );

    // Dismiss the dialog
    if (context.mounted) Navigator.pop(context);

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      if (team?.logoUrl != null && team!.logoUrl!.isNotEmpty)
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: NetworkImage(team.logoUrl!),
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: team?.color1.withOpacity(0.2) ??
                                Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.2),
                          ),
                          child: Center(
                            child: Text(
                              team?.shortName.isNotEmpty == true
                                  ? team!.shortName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: team?.color1 ??
                                    Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${AppLocalizations.of(context)!.versus} ${team?.fullName ?? AppLocalizations.of(context)!.unknown}',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${games.length} ${games.length == 1 ? AppLocalizations.of(context)!.gamesSingular : AppLocalizations.of(context)!.gamesPlural}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color
                                    ?.withOpacity(0.6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                // Games list
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: games.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final game = games[index];
                      final isCompleted = game.gameStatus.index >= 9;
                      final isWin = isCompleted && game.isWin(widget.team.id);
                      final isTie = isCompleted && game.isTie;
                      final isLoss = isCompleted && !isWin && !isTie;

                      final color = isWin
                          ? Colors.green
                          : isLoss
                              ? Colors.red
                              : isTie
                                  ? Colors.grey
                                  : Colors.blue; // Upcoming/in-progress games

                      final loc = AppLocalizations.of(context)!;
                      final resultText = isWin
                          ? loc.winAbbreviation
                          : isLoss
                              ? loc.lossAbbreviation
                              : isTie
                                  ? loc.tieAbbreviation
                                  : '-'; // Upcoming/in-progress games

                      return Card(
                        elevation: 1,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: color.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              // Result badge
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: color.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    resultText,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Game info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      game.displayName(widget.team.id),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${game.date.month}/${game.date.day}/${game.date.year}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.color
                                            ?.withOpacity(0.6),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Score
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  game.getScore(widget.team.id),
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
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

  Future<SplayTreeMap<Team, List<Game>>?> _loadHistory() async {
    _allSeasons = await Season.fromTeamId(widget.team.id);

    final allGames = await widget.team.getGameHistory(widget.team.id);

    final gameHistory = SplayTreeMap<Team, List<Game>>(
        (a, b) => a.fullName.compareTo(b.fullName));
    for (final game in allGames) {
      final team =
          game.isHomeTeam(widget.team.id) ? game.awayTeam : game.homeTeam;
      gameHistory.putIfAbsent(team, () => []);
      gameHistory[team]?.add(game);
    }

    return gameHistory;
  }

  // Calculate average goals scored by our team
  double _calculateAvgGoalsFor(List<Game> games) {
    if (games.isEmpty) return 0.0;
    final completedGames = games.where((g) => g.gameStatus.index >= 9).toList();
    if (completedGames.isEmpty) return 0.0;

    int totalGoals = 0;
    for (var game in completedGames) {
      if (game.isHomeTeam(widget.team.id)) {
        totalGoals += game.homeTeamScore;
      } else {
        totalGoals += game.awayTeamScore;
      }
    }
    return totalGoals / completedGames.length;
  }

  // Calculate average goals conceded by our team
  double _calculateAvgGoalsAgainst(List<Game> games) {
    if (games.isEmpty) return 0.0;
    final completedGames = games.where((g) => g.gameStatus.index >= 9).toList();
    if (completedGames.isEmpty) return 0.0;

    int totalGoals = 0;
    for (var game in completedGames) {
      if (game.isHomeTeam(widget.team.id)) {
        totalGoals += game.awayTeamScore;
      } else {
        totalGoals += game.homeTeamScore;
      }
    }
    return totalGoals / completedGames.length;
  }

  // Calculate biggest win margin
  int _calculateBiggestWin(List<Game> games) {
    int biggest = 0;
    for (var game in games) {
      if (game.gameStatus.index >= 9 && game.isWin(widget.team.id)) {
        int margin;
        if (game.isHomeTeam(widget.team.id)) {
          margin = game.homeTeamScore - game.awayTeamScore;
        } else {
          margin = game.awayTeamScore - game.homeTeamScore;
        }
        if (margin > biggest) biggest = margin;
      }
    }
    return biggest;
  }

  // Calculate biggest loss margin
  int _calculateBiggestLoss(List<Game> games) {
    int biggest = 0;
    for (var game in games) {
      if (game.gameStatus.index >= 9 &&
          !game.isWin(widget.team.id) &&
          !game.isTie) {
        int margin;
        if (game.isHomeTeam(widget.team.id)) {
          margin = game.awayTeamScore - game.homeTeamScore;
        } else {
          margin = game.homeTeamScore - game.awayTeamScore;
        }
        if (margin > biggest) biggest = margin;
      }
    }
    return biggest;
  }

  // Calculate current streak (W/L/T)
  String _calculateCurrentStreak(List<Game> games) {
    if (games.isEmpty) return '-';

    final completedGames = games.where((g) => g.gameStatus.index >= 9).toList();
    if (completedGames.isEmpty) return '-';

    // Sort by date, most recent first
    completedGames.sort((a, b) => b.date.compareTo(a.date));

    final firstGame = completedGames.first;
    String streakType;
    if (firstGame.isWin(widget.team.id)) {
      streakType = 'W';
    } else if (firstGame.isTie) {
      streakType = 'T';
    } else {
      streakType = 'L';
    }

    int count = 1;
    for (int i = 1; i < completedGames.length; i++) {
      final game = completedGames[i];
      bool matches = false;

      if (streakType == 'W' && game.isWin(widget.team.id)) {
        matches = true;
      } else if (streakType == 'T' && game.isTie) {
        matches = true;
      } else if (streakType == 'L' &&
          !game.isWin(widget.team.id) &&
          !game.isTie) {
        matches = true;
      }

      if (matches) {
        count++;
      } else {
        break;
      }
    }

    return '$count$streakType';
  }

  // Calculate longest winning streak
  int _calculateLongestWinStreak(List<Game> games) {
    if (games.isEmpty) return 0;

    final completedGames = games.where((g) => g.gameStatus.index >= 9).toList();
    completedGames.sort((a, b) => a.date.compareTo(b.date));

    int longest = 0;
    int current = 0;

    for (var game in completedGames) {
      if (game.isWin(widget.team.id)) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 0;
      }
    }

    return longest;
  }

  // Get recent form (last 5 games)
  String _getRecentForm(List<Game> games) {
    final completedGames = games.where((g) => g.gameStatus.index >= 9).toList();
    if (completedGames.isEmpty) return '-';

    completedGames.sort((a, b) => b.date.compareTo(a.date));
    final recentGames = completedGames.take(5).toList();

    final form = recentGames.map((game) {
      if (game.isWin(widget.team.id)) return 'W';
      if (game.isTie) return 'T';
      return 'L';
    }).join(' ');

    return form;
  }

  // Calculate clean sheets (games with 0 goals conceded)
  int _calculateCleanSheets(List<Game> games) {
    final completedGames = games.where((g) => g.gameStatus.index >= 9).toList();
    if (completedGames.isEmpty) return 0;

    int cleanSheets = 0;
    for (var game in completedGames) {
      int goalsAgainst;
      if (game.isHomeTeam(widget.team.id)) {
        goalsAgainst = game.awayTeamScore;
      } else {
        goalsAgainst = game.homeTeamScore;
      }
      if (goalsAgainst == 0) cleanSheets++;
    }
    return cleanSheets;
  }

  // Calculate clean sheet percentage
  double _calculateCleanSheetPercentage(List<Game> games) {
    final completedGames = games.where((g) => g.gameStatus.index >= 9).toList();
    if (completedGames.isEmpty) return 0.0;
    return _calculateCleanSheets(games) / completedGames.length;
  }

  // Calculate goal differential (total goals for - goals against)
  int _calculateGoalDifferential(List<Game> games) {
    final completedGames = games.where((g) => g.gameStatus.index >= 9).toList();
    if (completedGames.isEmpty) return 0;

    int goalsFor = 0;
    int goalsAgainst = 0;

    for (var game in completedGames) {
      if (game.isHomeTeam(widget.team.id)) {
        goalsFor += game.homeTeamScore;
        goalsAgainst += game.awayTeamScore;
      } else {
        goalsFor += game.awayTeamScore;
        goalsAgainst += game.homeTeamScore;
      }
    }

    return goalsFor - goalsAgainst;
  }

  // Calculate home record (W-L-T)
  Map<String, int> _calculateHomeRecord(List<Game> games) {
    final homeGames = games
        .where((g) => g.gameStatus.index >= 9 && g.isHomeTeam(widget.team.id))
        .toList();

    int wins = homeGames.where((g) => g.isWin(widget.team.id)).length;
    int ties = homeGames.where((g) => g.isTie).length;
    int losses = homeGames.length - wins - ties;

    return {
      'wins': wins,
      'losses': losses,
      'ties': ties,
      'total': homeGames.length
    };
  }

  // Calculate away record (W-L-T)
  Map<String, int> _calculateAwayRecord(List<Game> games) {
    final awayGames = games
        .where((g) => g.gameStatus.index >= 9 && !g.isHomeTeam(widget.team.id))
        .toList();

    int wins = awayGames.where((g) => g.isWin(widget.team.id)).length;
    int ties = awayGames.where((g) => g.isTie).length;
    int losses = awayGames.length - wins - ties;

    return {
      'wins': wins,
      'losses': losses,
      'ties': ties,
      'total': awayGames.length
    };
  }

  // Calculate points per game (3 for win, 1 for tie, 0 for loss)
  double _calculatePointsPerGame(List<Game> games) {
    final completedGames = games.where((g) => g.gameStatus.index >= 9).toList();
    if (completedGames.isEmpty) return 0.0;

    int totalPoints = 0;
    for (var game in completedGames) {
      if (game.isWin(widget.team.id)) {
        totalPoints += 3;
      } else if (game.isTie) {
        totalPoints += 1;
      }
    }

    return totalPoints / completedGames.length;
  }

  // Format record as W-L-T
  String _formatRecord(Map<String, int> record) {
    if (record['total'] == 0) return '-';
    return '${record['wins']}-${record['losses']}-${record['ties']}';
  }

  // Calculate shooting accuracy percentage (shots on goal / total shots)
  double _calculateShootingAccuracy(List<Game> games) {
    final completedGames = games.where((g) => g.gameStatus.index >= 9).toList();
    if (completedGames.isEmpty) return 0.0;

    int totalShots = 0;
    int shotsOnGoal = 0;

    for (var game in completedGames) {
      final events = game.gameEvents
          .where((e) => e.team.id == widget.team.id && e.eventType == 'Shot')
          .toList();

      totalShots += events.length;

      // Count shots on goal (saved or scored)
      for (var event in events) {
        // eventData: 0=goal, 1=saved, 2=post, 3=off target, 4=blocked
        if (event.eventData == 0 || event.eventData == 1) {
          shotsOnGoal++;
        }
      }
    }

    if (totalShots == 0) return 0.0;
    return shotsOnGoal / totalShots;
  }

  // Calculate comeback wins (wins where team was losing at some point)
  int _calculateComebackWins(List<Game> games) {
    final completedGames = games.where((g) => g.gameStatus.index >= 9).toList();
    if (completedGames.isEmpty) return 0;

    int comebackWins = 0;

    for (var game in completedGames) {
      if (!game.isWin(widget.team.id)) continue;

      // Check if team was ever losing during the game
      final scoringEvents = game.scoringEvents;
      int teamScore = 0;
      int opponentScore = 0;
      bool wasLosing = false;

      for (var event in scoringEvents) {
        if (event.team.id == widget.team.id) {
          teamScore++;
        } else {
          opponentScore++;
        }

        if (teamScore < opponentScore) {
          wasLosing = true;
        }
      }

      if (wasLosing) comebackWins++;
    }

    return comebackWins;
  }

  // Calculate late goals (goals scored in 80+ minute)
  int _calculateLateGoals(List<Game> games) {
    final completedGames = games.where((g) => g.gameStatus.index >= 9).toList();
    if (completedGames.isEmpty) return 0;

    int lateGoals = 0;

    for (var game in completedGames) {
      final teamGoals = game.scoringEvents
          .where((e) => e.team.id == widget.team.id && e.eventMinute >= 80)
          .toList();
      lateGoals += teamGoals.length;
    }

    return lateGoals;
  }

  // Calculate cards per game (yellows + reds)
  double _calculateCardsPerGame(List<Game> games) {
    final completedGames = games.where((g) => g.gameStatus.index >= 9).toList();
    if (completedGames.isEmpty) return 0.0;

    int totalCards = 0;

    for (var game in completedGames) {
      final cardEvents = game.gameEvents
          .where((e) => e.team.id == widget.team.id && e.eventType == 'Card')
          .toList();
      totalCards += cardEvents.length;
    }

    return totalCards / completedGames.length;
  }

  // Check if Tier 2 analytics have any meaningful data
  bool _hasTier2Analytics(List<Game> games) {
    // Check if there are any shots (needed for shooting accuracy)
    bool hasShots = false;
    for (var game in games.where((g) => g.gameStatus.index >= 9)) {
      if (game.gameEvents
          .any((e) => e.team.id == widget.team.id && e.eventType == 'Shot')) {
        hasShots = true;
        break;
      }
    }

    // Check for comeback wins
    final comebackWins = _calculateComebackWins(games);

    // Check for late goals
    final lateGoals = _calculateLateGoals(games);

    // Check for cards
    final cardsPerGame = _calculateCardsPerGame(games);

    // Show Tier 2 if any of these have data
    return hasShots || comebackWins > 0 || lateGoals > 0 || cardsPerGame > 0;
  }
}

/// Carousel widget for displaying analytics cards on smaller screens
class _AnalyticsCarousel extends StatefulWidget {
  final List<Widget> items;

  const _AnalyticsCarousel({required this.items});

  @override
  State<_AnalyticsCarousel> createState() => _AnalyticsCarouselState();
}

class _AnalyticsCarouselState extends State<_AnalyticsCarousel> {
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CarouselSlider.builder(
          options: CarouselOptions(
            height: 220,
            viewportFraction: 0.9,
            enlargeCenterPage: true,
            enableInfiniteScroll: false,
            onPageChanged: (index, reason) {
              setState(() {
                _currentPage = index;
              });
            },
          ),
          itemCount: widget.items.length,
          itemBuilder: (context, index, realIndex) {
            return widget.items[index];
          },
        ),
        const SizedBox(height: 12),
        // Page indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.items.length,
            (index) => Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentPage == index
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
