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
  teamName,
  mostGames,
  mostWins,
  winPercentage,
  recentFirst,
}

class _HistoryVersusViewState extends State<HistoryVersusView> {
  SortOption _sortOption = SortOption.teamName;

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
    }

    return entries;
  }

  String _getSortLabel(SortOption option) {
    final loc = AppLocalizations.of(context)!;
    switch (option) {
      case SortOption.teamName:
        return loc.sortByTeamName;
      case SortOption.mostGames:
        return loc.sortByMostGames;
      case SortOption.mostWins:
        return loc.sortByMostWins;
      case SortOption.winPercentage:
        return loc.sortByWinPercentage;
      case SortOption.recentFirst:
        return loc.sortByRecent;
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
}
