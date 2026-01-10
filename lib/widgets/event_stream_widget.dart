import 'dart:async';

import 'package:flutter/material.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/game_event.dart';

import 'package:team_sync/widgets/responsive_player_avatar.dart';
import 'package:team_sync/widgets/stat_category_dialog.dart';

class EventStreamWidget extends StatefulWidget {
  final Game? game;
  final int? teamId;

  const EventStreamWidget({
    super.key,
    required this.game,
    this.teamId,
  });

  @override
  State<EventStreamWidget> createState() => _EventStreamWidgetState();
}

class _EventStreamWidgetState extends State<EventStreamWidget> {
  Timer? _updateTimer;
  Game? _currentGame;

  @override
  void initState() {
    super.initState();
    _currentGame = widget.game;
    _setupAutoUpdate();
  }

  @override
  void didUpdateWidget(EventStreamWidget oldWidget) {
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
      debugPrint('Error reloading game events: $e');
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
      return _buildNoGameView(context);
    }

    // Show events only during live games
    final showEvents = isLiveGame;

    return PageView(
      children: [
        // Page 1: Game Stats (always shown)
        _buildGameStatsPage(context),
        // Page 2: Live Events (only during live games)
        if (showEvents) _buildEventsPage(context),
      ],
    );
  }

  Widget _buildNoGameView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_soccer,
              size: 64,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No game to display',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Game details will appear here',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameStatsPage(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.bar_chart,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Game Stats',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (isLiveGame)
                Row(
                  children: [
                    Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Swipe for live events',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        Expanded(
          child: _buildGameStats(context),
        ),
      ],
    );
  }

  Widget _buildEventsPage(BuildContext context) {
    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.circle,
                size: 20,
                color: Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Live Game Events',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _buildEventStream(context),
        ),
      ],
    );
  }

  Widget _buildEventStream(BuildContext context) {
    final allEvents = _currentGame!.allGameEvents;

    if (allEvents.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.event_busy,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              Text(
                'No events yet',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Events will appear as the game progresses',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // ...existing code for filtering and sorting events...
    final filteredEvents = allEvents.where((event) {
      if (event.eventType == 'Period' &&
          event.display.toLowerCase().contains('halftime')) {
        return false;
      }
      return true;
    }).toList();

    final sortedEvents = List<GameEvent>.from(filteredEvents);
    sortedEvents.sort((a, b) => b.index.compareTo(a.index));

    final isCompleted = _currentGame!.gameStatus.index >= 9;

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: sortedEvents.length + (isCompleted ? 1 : 0),
      itemBuilder: (context, index) {
        if (isCompleted && index == 0) {
          return _buildFinalScoreTile(context);
        }
        final eventIndex = isCompleted ? index - 1 : index;
        final event = sortedEvents[eventIndex];
        return _buildEventItem(context, event);
      },
    );
  }

  Widget _buildEventItem(BuildContext context, GameEvent event) {
    final isMyTeam = widget.teamId != null && event.team.id == widget.teamId;
    final isPeriodEvent = event.eventType == 'Period';
    final isGoalOrAssist = _isGoalOrAssist(event);

    // Special styling for period events
    if (isPeriodEvent) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
              Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
            ],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.schedule,
              size: 18,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              event.display,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    // Regular event styling
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: isMyTeam
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Time badge column - consistent width for alignment
          SizedBox(
            width: 44,
            height: 44,
            child: isGoalOrAssist
                ? Container(
                    decoration: BoxDecoration(
                      color: _getEventColor(event.eventType).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        "${event.eventMinute}'",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _getEventColor(event.eventType),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      "${event.eventMinute}'",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.normal,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withOpacity(0.5),
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          // Event details
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Leading: Player Avatar OR Event Icon
                if (event.player?.displayImageForStats != null)
                  ResponsivePlayerAvatar(
                    player: event.player!,
                    avatarSize: 32,
                    useLatestImages: true,
                  )
                else
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _getEventColor(event.eventType).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getEventIcon(event.eventType),
                      size: 18,
                      color: _getEventColor(event.eventType),
                    ),
                  ),
                const SizedBox(width: 12),
                // Text Content: Event Title - Player Name
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: _getEventTitle(event),
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        if (event.player != null) ...[
                          TextSpan(
                            text: ' - ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                          TextSpan(
                            text: event.player!.displayName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.7),
                            ),
                          ),
                        ] else ...[
                          TextSpan(
                            text: ' - ',
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                          ),
                          TextSpan(
                            text: event.team.shortName,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withOpacity(0.5),
                            ),
                          ),
                        ]
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isGoalOrAssist(GameEvent event) {
    if (event.eventType == 'Assist') return true;
    if (event.eventType == 'Shot' || event.eventType == 'PenaltyKick') {
      return event.eventData == ShotResult.goal.index;
    }
    return false;
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'Shot':
        return Icons.sports_soccer;
      case 'PenaltyKick':
        return Icons.flag;
      case 'Assist':
        return Icons.transfer_within_a_station;
      case 'Save':
        return Icons.back_hand;
      case 'Offsides':
        return Icons.flag_outlined;
      case 'Foul':
        return Icons.warning;
      case 'Card':
        return Icons.credit_card;
      default:
        return Icons.event;
    }
  }

  Color _getEventColor(String eventType) {
    switch (eventType) {
      case 'Shot':
        return Colors.green;
      case 'PenaltyKick':
        return Colors.blue;
      case 'Assist':
        return Colors.teal;
      case 'Save':
        return Colors.orange;
      case 'Offsides':
        return Colors.amber;
      case 'Foul':
        return Colors.red;
      case 'Card':
        return Colors.red[900]!;
      default:
        return Colors.grey;
    }
  }

  String _getEventTitle(GameEvent event) {
    switch (event.eventType) {
      case 'Shot':
        if (event.eventData == ShotResult.goal.index) {
          return '⚽ GOAL!';
        } else if (event.eventData == ShotResult.onTargetSave.index) {
          return 'Shot on target (saved)';
        } else if (event.eventData == ShotResult.offTargetPost.index) {
          return 'Shot off post';
        } else if (event.eventData == ShotResult.offTarget.index) {
          return 'Shot off target';
        } else {
          return 'Shot blocked';
        }
      case 'PenaltyKick':
        if (event.eventData == ShotResult.goal.index) {
          return '⚽ Penalty Goal!';
        } else {
          return 'Penalty missed';
        }
      case 'Assist':
        return 'Assist';
      case 'Save':
        return 'Save';
      case 'Offsides':
        return 'Offsides';
      case 'Foul':
        return 'Foul';
      case 'Card':
        if (event.eventData == 0) {
          return '🟨 Yellow Card';
        } else if (event.eventData == 1) {
          return '🟨🟨 Second Yellow';
        } else {
          return '🟥 Red Card';
        }
      default:
        return event.eventType;
    }
  }

  Widget _buildFinalScoreTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.emoji_events,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                _currentGame!.gameStatus.display,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _currentGame!.homeTeam.shortName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentGame!.homeTeamScore.toString(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '-',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.3),
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      _currentGame!.awayTeam.shortName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentGame!.awayTeamScore.toString(),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildGameStats(BuildContext context) {
    // Calculate stats for both teams
    final homeStats = _calculateTeamStats(_currentGame!.homeTeam.id);
    final awayStats = _calculateTeamStats(_currentGame!.awayTeam.id);

    return SingleChildScrollView(
      child: Column(
        children: [
          // Team headers
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                // Home team name aligned with home values
                SizedBox(
                  width: 50,
                  child: Text(
                    _currentGame!.homeTeam.shortName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _currentGame!.homeTeam.color1,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                // Home bar space
                const Expanded(child: SizedBox()),
                const SizedBox(width: 8),
                // Away bar space
                const Expanded(child: SizedBox()),
                const SizedBox(width: 8),
                // Away team name aligned with away values
                SizedBox(
                  width: 50,
                  child: Text(
                    _currentGame!.awayTeam.shortName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _currentGame!.awayTeam.color1,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // Stats rows
          // Stats rows
          _buildStatRow(
              context, 'Goals', homeStats.goals, awayStats.goals, 'goals'),
          _buildStatRow(
              context, 'Shots', homeStats.shots, awayStats.shots, 'shots'),
          _buildStatRow(context, 'Shots on Goal', homeStats.shotsOnGoal,
              awayStats.shotsOnGoal, 'shotsOnGoal'),
          _buildStatRow(
              context, 'Saves', homeStats.saves, awayStats.saves, 'saves'),
          _buildStatRow(context, 'Assists', homeStats.assists,
              awayStats.assists, 'assists'),
          _buildStatRow(
              context, 'Fouls', homeStats.fouls, awayStats.fouls, 'fouls'),
          _buildStatRow(context, 'Offsides', homeStats.offsides,
              awayStats.offsides, 'offsides'),
          _buildStatRow(context, 'Yellow Cards', homeStats.yellows,
              awayStats.yellows, 'yellows'),
          _buildStatRow(
              context, 'Red Cards', homeStats.reds, awayStats.reds, 'reds'),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, int homeValue,
      int awayValue, String category) {
    final maxValue = homeValue > awayValue ? homeValue : awayValue;
    final homePercent = maxValue > 0 ? homeValue / maxValue : 0.0;
    final awayPercent = maxValue > 0 ? awayValue / maxValue : 0.0;

    // Determine which team is "our" team for the dialog
    final teamId = widget.teamId ?? _currentGame!.homeTeam.id;
    final isHomeTeam = teamId == _currentGame!.homeTeam.id;
    final teamTotal = isHomeTeam ? homeValue : awayValue;

    return InkWell(
        onTap: teamTotal > 0
            ? () => _showStatCategoryDialog(context, category, label, teamId)
            : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              // Label
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 6),
              // Values and bars
              Row(
                children: [
                  // Home value
                  SizedBox(
                    width: 30,
                    child: Text(
                      homeValue.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Home bar (right-to-left)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: FractionallySizedBox(
                        widthFactor: homePercent,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                _currentGame!.homeTeam.color1.withOpacity(0.7),
                            borderRadius: const BorderRadius.horizontal(
                              left: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Away bar (left-to-right)
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: awayPercent,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                _currentGame!.awayTeam.color1.withOpacity(0.7),
                            borderRadius: const BorderRadius.horizontal(
                              right: Radius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Away value
                  SizedBox(
                    width: 30,
                    child: Text(
                      awayValue.toString(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ));
  }

  Future<void> _showStatCategoryDialog(
      BuildContext context, String category, String label, int teamId) async {
    // Get player stats for this category
    final stats = await _currentGame!.getStats(teamId);
    final playerStats = await stats.getStatPlayers(category);

    if (!mounted) return;

    // Use the common dialog component
    await StatCategoryDialog.show(
      context: context,
      categoryName: label,
      playerStats: playerStats,
    );
  }

  _TeamStats _calculateTeamStats(int teamId) {
    int goals = 0;
    int shots = 0;
    int shotsOnGoal = 0;
    int saves = 0;
    int assists = 0;
    int fouls = 0;
    int offsides = 0;
    int yellows = 0;
    int reds = 0;

    for (final event in _currentGame!.allGameEvents) {
      // Count saves when opponent shots are saved (defending team makes saves)
      if (event.team.id != teamId) {
        if (event.eventType == 'Shot' &&
            event.eventData == ShotResult.onTargetSave.index) {
          saves++;
        }
        continue;
      }

      // Count stats for this team
      switch (event.eventType) {
        case 'Shot':
          shots++;
          if (event.eventData == ShotResult.goal.index) {
            goals++;
            shotsOnGoal++;
          } else if (event.eventData == ShotResult.onTargetSave.index) {
            shotsOnGoal++;
          }
          break;
        case 'PenaltyKick':
          if (event.eventData == ShotResult.goal.index) {
            goals++;
          }
          break;
        case 'Assist':
          assists++;
          break;
        case 'Foul':
          fouls++;
          break;
        case 'Offsides':
          offsides++;
          break;
        case 'Card':
          if (event.eventData == 0) {
            yellows++;
          } else if (event.eventData == 1 || event.eventData == 2) {
            reds++;
          }
          break;
      }
    }

    return _TeamStats(
      goals: goals,
      shots: shots,
      shotsOnGoal: shotsOnGoal,
      saves: saves,
      assists: assists,
      fouls: fouls,
      offsides: offsides,
      yellows: yellows,
      reds: reds,
    );
  }
}

class _TeamStats {
  final int goals;
  final int shots;
  final int shotsOnGoal;
  final int saves;
  final int assists;
  final int fouls;
  final int offsides;
  final int yellows;
  final int reds;

  _TeamStats({
    required this.goals,
    required this.shots,
    required this.shotsOnGoal,
    required this.saves,
    required this.assists,
    required this.fouls,
    required this.offsides,
    required this.yellows,
    required this.reds,
  });
}
