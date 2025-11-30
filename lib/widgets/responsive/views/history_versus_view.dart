import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/game.dart';
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

class _HistoryVersusViewState extends State<HistoryVersusView> {
  SortOption _sortOption = SortOption.recentFirst;

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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _loadHistory(),
        builder: (BuildContext context,
            AsyncSnapshot<Map<Team, List<Game>>?> snapshot) {
          if (snapshot.hasData) {
            final sortedEntries = _sortTeams(
              snapshot.data ?? {},
              _sortOption,
            );

            if (sortedEntries.isEmpty) {
              final loc = AppLocalizations.of(context)!;
              return Center(
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
                      loc.noMatchupHistoryYet,
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
              );
            }

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
                // Teams list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedEntries.length,
                    itemBuilder: (context, index) {
                      final entry = sortedEntries[index];
                      final team = entry.key;
                      final games = entry.value;
                      final loc = AppLocalizations.of(context)!;

                      int wins =
                          games.where((g) => g.isWin(widget.team.id)).length;
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
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                            image: NetworkImage(team.logoUrl!),
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
                                          color: team.color1.withOpacity(0.2),
                                        ),
                                        child: Center(
                                          child: Text(
                                            team.shortName.isNotEmpty
                                                ? team.shortName[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
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
                                              fontWeight: FontWeight.bold,
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
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: dominantColor.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: dominantColor.withOpacity(0.5),
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
                                  borderRadius: BorderRadius.circular(4),
                                  child: SizedBox(
                                    height: 8,
                                    child: Row(
                                      children: [
                                        if (wins > 0)
                                          Expanded(
                                            flex: wins,
                                            child:
                                                Container(color: Colors.green),
                                          ),
                                        if (losses > 0)
                                          Expanded(
                                            flex: losses,
                                            child: Container(color: Colors.red),
                                          ),
                                        if (ties > 0)
                                          Expanded(
                                            flex: ties,
                                            child:
                                                Container(color: Colors.grey),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Analytics section
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceVariant
                                        .withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(12),
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
                                      Row(
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
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      // Goals and streaks
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _buildAnalyticItem(
                                              context,
                                              loc.avgGoalsFor,
                                              _calculateAvgGoalsFor(games)
                                                  .toStringAsFixed(1),
                                              Icons.sports_soccer,
                                              Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildAnalyticItem(
                                              context,
                                              loc.avgGoalsAgainst,
                                              _calculateAvgGoalsAgainst(games)
                                                  .toStringAsFixed(1),
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
                                            child: _buildAnalyticItem(
                                              context,
                                              loc.biggestWin,
                                              '+${_calculateBiggestWin(games)}',
                                              Icons.trending_up,
                                              Colors.green,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildAnalyticItem(
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
                                            child: _buildAnalyticItem(
                                              context,
                                              loc.currentStreak,
                                              _calculateCurrentStreak(games),
                                              Icons.flash_on,
                                              dominantColor,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildAnalyticItem(
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
                                            child: _buildAnalyticItem(
                                              context,
                                              loc.cleanSheets,
                                              '${(_calculateCleanSheetPercentage(games) * 100).toStringAsFixed(0)}%',
                                              Icons.block,
                                              Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildAnalyticItem(
                                              context,
                                              loc.goalDifferential,
                                              _calculateGoalDifferential(
                                                          games) >=
                                                      0
                                                  ? '+${_calculateGoalDifferential(games)}'
                                                  : '${_calculateGoalDifferential(games)}',
                                              Icons.compare_arrows,
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
                                            child: _buildAnalyticItem(
                                              context,
                                              loc.homeRecord,
                                              _formatRecord(
                                                  _calculateHomeRecord(games)),
                                              Icons.home,
                                              Colors.teal,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: _buildAnalyticItem(
                                              context,
                                              loc.awayRecord,
                                              _formatRecord(
                                                  _calculateAwayRecord(games)),
                                              Icons.flight_takeoff,
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
                                        _calculatePointsPerGame(games)
                                            .toStringAsFixed(2),
                                        Icons.grade,
                                        Colors.indigo,
                                      ),
                                      // Tier 2 Analytics - Only show if data exists
                                      if (_hasTier2Analytics(games)) ...[
                                        const SizedBox(height: 8),
                                        // Tier 2 Analytics Row 1
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _buildAnalyticItem(
                                                context,
                                                loc.shootingAccuracy,
                                                '${(_calculateShootingAccuracy(games) * 100).toStringAsFixed(0)}%',
                                                Icons.gps_fixed,
                                                Colors.deepOrange,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildAnalyticItem(
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
                                              child: _buildAnalyticItem(
                                                context,
                                                loc.lateGoals,
                                                '${_calculateLateGoals(games)}',
                                                Icons.access_time,
                                                Colors.deepPurple,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: _buildAnalyticItem(
                                                context,
                                                loc.cardsPerGame,
                                                _calculateCardsPerGame(games)
                                                    .toStringAsFixed(2),
                                                Icons.style,
                                                Colors.yellow.shade700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      const SizedBox(height: 12),
                                      // Recent form
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            loc.recentForm,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.color
                                                  ?.withOpacity(0.7),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
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
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          } else if (snapshot.hasError) {
            return Center(
                child: Text(AppLocalizations.of(context)!.errorLoadingHistory));
          } else {
            return const Center(child: CircularProgressIndicator());
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
              const CircularProgressIndicator(),
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
