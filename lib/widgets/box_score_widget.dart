import 'package:flutter/material.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/sport_strategy.dart';

class BoxScoreWidget extends StatefulWidget {
  final Game game;
  final Season season;
  final EdgeInsetsGeometry? margin;

  const BoxScoreWidget({
    super.key,
    required this.game,
    required this.season,
    this.margin,
  });

  @override
  State<BoxScoreWidget> createState() => _BoxScoreWidgetState();
}

class _BoxScoreWidgetState extends State<BoxScoreWidget> {
  late Future<List<GameEvent>> _eventsFuture;

  @override
  void initState() {
    super.initState();
    _eventsFuture = widget.game.loadGameEvents();
  }

  @override
  void didUpdateWidget(BoxScoreWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game.id != widget.game.id) {
      _eventsFuture = widget.game.loadGameEvents();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<GameEvent>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            widget.game.allGameEvents.isEmpty) {
          // Show a slim loading placeholder
          return Card(
            margin: widget.margin ??
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const SizedBox(
              height: 80,
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          );
        }
        return _buildTable(context);
      },
    );
  }

  Widget _buildTable(BuildContext context) {
    final game = widget.game;

    // Build displayPeriods from scoring events as the source of truth.
    // Scoring events always carry the correct eventPeriod for the half/quarter
    // in which the score occurred.
    final bool hasNoScoringEvents = game.scoringEvents.isEmpty;

    final Set<int> periodIndices = {};

    // Seed with standard periods based on game status so columns always appear
    // even when no goals were scored in a half.
    // Note: Final statuses (9=gameFinal, 10=gameFinalOT, 11=gameFinalPKs) are
    // handled explicitly — they are NOT contiguous with active play statuses.
    final statusIdx = game.gameStatus.index;

    // 1st Half: shown whenever the game has started
    if (statusIdx >= 1) {
      periodIndices.add(1);
    }

    // 2nd Half: shown once the game is past halftime (status 3+)
    if (statusIdx >= 3) {
      periodIndices.add(3);
    }

    // OT periods: only when the game actually went to overtime.
    // Active OT: 5=1st OT Half, 6=OT Halftime, 7=2nd OT Half, 8=Shootout
    // Final OT:  10=gameFinalOT, 11=gameFinalPKs
    const otStatuses = {5, 6, 7, 8, 10, 11};
    if (otStatuses.contains(statusIdx)) {
      periodIndices.add(5);
    }

    // 2nd OT: only when actively in 2nd OT (rely on scoring events for finals)
    if (statusIdx == 7 || statusIdx == 8) {
      periodIndices.add(7);
    }

    // Shootout: status 8 (active) or 11 (gameFinalPKs)
    if (statusIdx == 8 || statusIdx == 11) {
      periodIndices.add(8);
    }

    // Add any extra periods found in scoring events (handles edge cases /
    // games where OT goals exist but status is gameFinalOT only showing 1st OT)
    for (final event in game.scoringEvents) {
      final p = _normalizePeriod(event.eventPeriod);
      if (p > 0) {
        periodIndices.add(p);
      }
    }

    // If game hasn't started and has no events, fall back to allGameEvents
    if (periodIndices.isEmpty) {
      for (final event in game.allGameEvents) {
        final p = _normalizePeriod(event.eventPeriod);
        if (p > 0) {
          periodIndices.add(p);
        }
      }
      if (periodIndices.isEmpty) {
        periodIndices.add(1); // Bare minimum: show 1st Half
      }
    }

    // Sort periods chronologically
    final List<int> displayPeriods = (periodIndices.toList()..sort());

    // Calculate scores per period
    final Map<int, int> homeScoresByPeriod = {};
    final Map<int, int> awayScoresByPeriod = {};
    int homeTotal = 0;
    int awayTotal = 0;

    for (final int p in displayPeriods) {
      homeScoresByPeriod[p] = 0;
      awayScoresByPeriod[p] = 0;
    }

    for (final event in game.scoringEvents) {
      // Normalize so halftime/transition states merge into the active half
      final period = _normalizePeriod(event.eventPeriod);
      final value = SportStrategy.current.getEventValue(event);

      if (event.team.id == game.homeTeam.id) {
        homeScoresByPeriod[period] = (homeScoresByPeriod[period] ?? 0) + value;
        homeTotal += value;
      } else if (event.team.id == game.awayTeam.id) {
        awayScoresByPeriod[period] = (awayScoresByPeriod[period] ?? 0) + value;
        awayTotal += value;
      }
    }

    // For imported games without play-by-play events, use stored final scores.
    final int finalHomeScore =
        hasNoScoringEvents ? game.homeTeamScore : homeTotal;
    final int finalAwayScore =
        hasNoScoringEvents ? game.awayTeamScore : awayTotal;

    final theme = Theme.of(context);

    // Build the columns
    final List<DataColumn> columns = [
      DataColumn(
        label: Text(
          'Team',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    ];

    for (final p in displayPeriods) {
      columns.add(
        DataColumn(
          numeric: true,
          label: Text(
            GameStatus.values[p].display,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ),
      );
    }

    columns.add(
      DataColumn(
        numeric: true,
        label: Text(
          'T',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ),
    );

    // Build the rows
    final List<DataRow> rows = [
      _buildTeamRow(
        game.awayTeam,
        displayPeriods,
        awayScoresByPeriod,
        finalAwayScore,
        theme,
        hasNoScoringEvents,
      ),
      _buildTeamRow(
        game.homeTeam,
        displayPeriods,
        homeScoresByPeriod,
        finalHomeScore,
        theme,
        hasNoScoringEvents,
      ),
    ];

    return Card(
      margin: widget.margin ??
          const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowHeight: 40,
            dataRowMinHeight: 48,
            dataRowMaxHeight: 48,
            columnSpacing: 24,
            horizontalMargin: 16,
            dividerThickness: 0,
            columns: columns,
            rows: rows,
          ),
        ),
      ),
    );
  }

  /// Collapses halftime/transition game states into their preceding active
  /// playing period so the box score only shows meaningful scoring columns.
  ///
  /// GameStatus indices:
  ///   0 = Not Started    → skip (return 0)
  ///   1 = 1st Half       → 1st Half (1)
  ///   2 = Halftime       → 1st Half (1)
  ///   3 = 2nd Half       → 2nd Half (3)
  ///   4 = OT Not Started → skip (return 0)
  ///   5 = 1st OT Half    → 1st OT (5)
  ///   6 = OT Halftime    → 1st OT (5)
  ///   7 = 2nd OT Half    → 2nd OT (7)
  ///   8 = Shootout       → Shootout (8)
  ///   9-11 = Final *     → skip (return 0)
  int _normalizePeriod(int eventPeriod) {
    switch (eventPeriod) {
      case 0:
        return 0; // Not started — skip
      case 1:
        return 1; // 1st Half
      case 2:
        return 1; // Halftime → bucket into 1st Half
      case 3:
        return 3; // 2nd Half
      case 4:
        return 0; // OT Not Started — skip
      case 5:
        return 5; // 1st OT Half
      case 6:
        return 5; // OT Halftime → bucket into 1st OT Half
      case 7:
        return 7; // 2nd OT Half
      case 8:
        return 8; // Shootout
      default:
        return 0; // Final states (9,10,11) and unknown — skip
    }
  }

  DataRow _buildTeamRow(
    Team team,
    List<int> periods,
    Map<int, int> scoresByPeriod,
    int totalScore,
    ThemeData theme,
    bool hasNoScoringEvents,
  ) {
    final List<DataCell> cells = [
      DataCell(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: team.color1,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              team.shortName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ];

    for (final p in periods) {
      final scoreVal = scoresByPeriod[p] ?? 0;
      cells.add(
        DataCell(
          Text(
            hasNoScoringEvents ? '-' : scoreVal.toString(),
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ),
      );
    }

    cells.add(
      DataCell(
        Text(
          totalScore.toString(),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );

    return DataRow(cells: cells);
  }
}
