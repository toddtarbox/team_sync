import 'package:flutter/material.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/game_event.dart';

class EventStreamWidget extends StatelessWidget {
  final Game? game;
  final int? teamId;

  const EventStreamWidget({
    Key? key,
    required this.game,
    this.teamId,
  }) : super(key: key);

  bool get isLiveGame {
    if (game == null) return false;
    return game!.gameStatus.index > 0 && game!.gameStatus.index < 9;
  }

  @override
  Widget build(BuildContext context) {
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
                isLiveGame ? Icons.circle : Icons.event_note,
                size: 20,
                color: isLiveGame
                    ? Colors.red
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isLiveGame ? 'Live Game Events' : 'Game Events',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (isLiveGame)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        // Event stream content
        Expanded(
          flex: 2,
          child: _buildEventStream(context),
        ),
        // Divider
        Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).dividerColor,
        ),
        // Game stats section
        if (game != null) _buildGameStats(context),
      ],
    );
  }

  Widget _buildEventStream(BuildContext context) {
    if (game == null) {
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
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Game events will appear here',
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

    final allEvents = game!.allGameEvents;

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
                isLiveGame
                    ? 'Events will appear as the game progresses'
                    : 'No events were recorded for this game',
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

    // Filter out halftime period events
    final filteredEvents = allEvents.where((event) {
      if (event.eventType == 'Period' &&
          event.display.toLowerCase().contains('halftime')) {
        return false;
      }
      return true;
    }).toList();

    final sortedEvents = List<GameEvent>.from(filteredEvents);
    sortedEvents.sort((a, b) => b.index.compareTo(a.index));

    // Check if game is completed
    final isCompleted = game!.gameStatus.index >= 9;

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: sortedEvents.length + (isCompleted ? 1 : 0),
      itemBuilder: (context, index) {
        // Show final score tile at the top for completed games
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
    final isMyTeam = teamId != null && event.team.id == teamId;
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time badge - only show for goals and assists
          if (isGoalOrAssist)
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _getEventColor(event.eventType).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "${event.eventMinute}'",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _getEventColor(event.eventType),
                    ),
                  ),
                ],
              ),
            ),
          if (isGoalOrAssist) const SizedBox(width: 12),
          // Event details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _getEventIcon(event.eventType),
                      size: 16,
                      color: _getEventColor(event.eventType),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _getEventTitle(event),
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (event.player != null)
                  Text(
                    event.player!.displayName,
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                    ),
                  ),
                Text(
                  event.team.shortName,
                  style: TextStyle(
                    fontSize: 12,
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
                game!.gameStatus.display,
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
                      game!.homeTeam.shortName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game!.homeTeamScore.toString(),
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
                      game!.awayTeam.shortName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game!.awayTeamScore.toString(),
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
    final homeStats = _calculateTeamStats(game!.homeTeam.id);
    final awayStats = _calculateTeamStats(game!.awayTeam.id);

    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Stats header
            Container(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(
                    Icons.bar_chart,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Game Stats',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
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
                      game!.homeTeam.shortName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: game!.homeTeam.color1,
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
                      game!.awayTeam.shortName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: game!.awayTeam.color1,
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
            _buildStatRow(context, 'Goals', homeStats.goals, awayStats.goals),
            _buildStatRow(context, 'Shots', homeStats.shots, awayStats.shots),
            _buildStatRow(context, 'Shots on Goal', homeStats.shotsOnGoal,
                awayStats.shotsOnGoal),
            _buildStatRow(context, 'Saves', homeStats.saves, awayStats.saves),
            _buildStatRow(
                context, 'Assists', homeStats.assists, awayStats.assists),
            _buildStatRow(context, 'Fouls', homeStats.fouls, awayStats.fouls),
            _buildStatRow(
                context, 'Offsides', homeStats.offsides, awayStats.offsides),
            _buildStatRow(
                context, 'Yellow Cards', homeStats.yellows, awayStats.yellows),
            _buildStatRow(context, 'Red Cards', homeStats.reds, awayStats.reds),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
      BuildContext context, String label, int homeValue, int awayValue) {
    final maxValue = homeValue > awayValue ? homeValue : awayValue;
    final homePercent = maxValue > 0 ? homeValue / maxValue : 0.0;
    final awayPercent = maxValue > 0 ? awayValue / maxValue : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        children: [
          // Label
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
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
                        color: game!.homeTeam.color1.withOpacity(0.7),
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
                        color: game!.awayTeam.color1.withOpacity(0.7),
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

    for (final event in game!.allGameEvents) {
      if (event.team.id != teamId) continue;

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
        case 'Save':
          saves++;
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
