import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/services/database_service.dart';

class ScoreboardWidget extends StatefulWidget {
  final Game? game;
  final Season? season;
  final int teamId;

  const ScoreboardWidget({
    Key? key,
    required this.game,
    required this.season,
    required this.teamId,
  }) : super(key: key);

  @override
  State<ScoreboardWidget> createState() => _ScoreboardWidgetState();
}

class _ScoreboardWidgetState extends State<ScoreboardWidget> {
  Timer? _updateTimer;
  Game? _currentGame;

  @override
  void initState() {
    super.initState();
    _currentGame = widget.game;
    _setupAutoUpdate();
  }

  @override
  void didUpdateWidget(ScoreboardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.game?.id != widget.game?.id) {
      _currentGame = widget.game;
      _setupAutoUpdate();
    }
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  void _setupAutoUpdate() {
    _updateTimer?.cancel();

    if (isLiveGame) {
      // Update every 5 seconds during live games
      _updateTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        if (!mounted) {
          timer.cancel();
          return;
        }
        await _reloadGameData();
      });
    }
  }

  Future<void> _reloadGameData() async {
    if (_currentGame == null) return;

    try {
      await _currentGame!.loadGameEvents();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      // Silently handle errors to avoid disrupting the UI
      debugPrint('Error reloading game data: $e');
    }
  }

  bool get isLiveGame {
    if (_currentGame == null) return false;
    return _currentGame!.gameStatus.index > 0 &&
        _currentGame!.gameStatus.index < 9;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentGame == null) {
      return Card(
        margin: const EdgeInsets.all(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.sports_soccer,
                size: 48,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No games yet',
                style: TextStyle(
                  fontSize: 16,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isHome = _currentGame!.isHomeTeam(widget.teamId);
    final leftTeam = _currentGame!.homeTeam;
    final rightTeam = _currentGame!.awayTeam;
    final leftScore = _currentGame!.homeTeamScore;
    final rightScore = _currentGame!.awayTeamScore;

    // Determine if user's team won/lost/tied
    final isWin = _currentGame!.isWin(widget.teamId);
    final isTie = _currentGame!.isTie;
    final isLoss = !isWin && !isTie && _currentGame!.gameStatus.index >= 9;

    // Check which team is the user's team for highlighting
    final isLeftTeamMine = leftTeam.id == widget.teamId;
    final isRightTeamMine = rightTeam.id == widget.teamId;

    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: isLiveGame ? 4 : 2,
      child: InkWell(
        onTap: widget.season != null
            ? () {
                final databaseId = DatabaseService.instance.publicShareId;
                if (databaseId != null) {
                  context.go(
                    '/team/$databaseId/season/${widget.season!.id}/game/${_currentGame!.id}',
                    extra: {
                      'season': widget.season,
                      'game': _currentGame,
                    },
                  );
                }
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: isLiveGame
                ? LinearGradient(
                    colors: [
                      leftTeam.color1.withOpacity(0.1),
                      leftTeam.color2.withOpacity(0.1),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header with status
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (isLiveGame)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Text(
                        DateFormat('MMM d, yyyy').format(_currentGame!.date),
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                    Text(
                      _currentGame!.gameStatus.display,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                            isLiveGame ? FontWeight.bold : FontWeight.normal,
                        color: isLiveGame
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Score display
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Home team (left)
                    Expanded(
                      child: Column(
                        children: [
                          if (leftTeam.logoUrl != null &&
                              leftTeam.logoUrl!.isNotEmpty)
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(leftTeam.logoUrl!),
                              backgroundColor: leftTeam.color1.withOpacity(0.2),
                            )
                          else
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: leftTeam.color1.withOpacity(0.2),
                              child: Icon(
                                Icons.sports_soccer,
                                color: leftTeam.color1,
                                size: 30,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            leftTeam.shortName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isLeftTeamMine
                                  ? FontWeight.w900
                                  : FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'HOME',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Score
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                leftScore.toString(),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: isLeftTeamMine && isWin && !isLiveGame
                                      ? Colors.green
                                      : isLeftTeamMine && isLoss && !isLiveGame
                                          ? Colors.red
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  '-',
                                  style: TextStyle(
                                    fontSize: 36,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withOpacity(0.3),
                                  ),
                                ),
                              ),
                              Text(
                                rightScore.toString(),
                                style: TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: isRightTeamMine && isWin && !isLiveGame
                                      ? Colors.green
                                      : isRightTeamMine && isLoss && !isLiveGame
                                          ? Colors.red
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                ),
                              ),
                            ],
                          ),
                          if (_currentGame!.gameStatus.index >= 9)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isWin
                                      ? Colors.green.withOpacity(0.2)
                                      : isLoss
                                          ? Colors.red.withOpacity(0.2)
                                          : Colors.grey.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isWin
                                      ? 'WIN'
                                      : isLoss
                                          ? 'LOSS'
                                          : 'TIE',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isWin
                                        ? Colors.green[700]
                                        : isLoss
                                            ? Colors.red[700]
                                            : Colors.grey[700],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Away team (right)
                    Expanded(
                      child: Column(
                        children: [
                          if (rightTeam.logoUrl != null &&
                              rightTeam.logoUrl!.isNotEmpty)
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: NetworkImage(rightTeam.logoUrl!),
                              backgroundColor:
                                  rightTeam.color1.withOpacity(0.2),
                            )
                          else
                            CircleAvatar(
                              radius: 30,
                              backgroundColor:
                                  rightTeam.color1.withOpacity(0.2),
                              child: Icon(
                                Icons.sports_soccer,
                                color: rightTeam.color1,
                                size: 30,
                              ),
                            ),
                          const SizedBox(height: 8),
                          Text(
                            rightTeam.shortName,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isRightTeamMine
                                  ? FontWeight.w900
                                  : FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'AWAY',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Description if available
                if (_currentGame!.description != null &&
                    _currentGame!.description!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 12.0),
                    child: Text(
                      _currentGame!.description!,
                      style: TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.6),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ), // closes InkWell
    ); // closes Card
  }
}
