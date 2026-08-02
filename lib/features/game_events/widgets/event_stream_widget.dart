import 'dart:async';

import 'package:flutter/material.dart';
import 'package:team_sync/features/games/models/game.dart';
import 'package:team_sync/features/game_events/models/game_event.dart';
import 'package:team_sync/features/players/models/player.dart';

import 'package:team_sync/features/sports/services/sport_strategy.dart';
import 'package:team_sync/features/players/widgets/responsive_player_avatar.dart';
import 'package:team_sync/features/seasons/widgets/stat_category_dialog.dart';

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
  final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _currentGame = widget.game;
    _setupAutoUpdate();
  }

  @override
  void didUpdateWidget(EventStreamWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Always update _currentGame when widget.game changes
    _currentGame = widget.game;
    
    if (oldWidget.game?.id != widget.game?.id) {
      _setupAutoUpdate();
    } else if (oldWidget.game?.gameStatus != widget.game?.gameStatus) {
      _setupAutoUpdate();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
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
      controller: _pageController,
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

    // Check for imported events
    // If we have imported events (minute <= 0 or isFromImport), replace the stream list
    // with a link to the stats page
    final hasImportedEvents = allEvents.any((e) =>
        e.isFromImport || (e.eventType != 'Period' && e.eventMinute <= 0));

    if (hasImportedEvents) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'Game stats were imported',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Detailed play-by-play data is not available for imported games.',
                style: TextStyle(
                  fontSize: 14,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  _pageController.animateToPage(
                    0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                icon: const Icon(Icons.bar_chart),
                label: const Text('View Game Stats'),
              ),
            ],
          ),
        ),
      );
    }

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

    // Group minute 0 events (imported stats)
    final aggregatedEvents = <String, _AggregatedEvent>{};
    final timelineEvents = <GameEvent>[];

    for (var event in filteredEvents) {
      if (event.eventType != 'Period' &&
          (event.isFromImport || event.eventMinute <= 0)) {
        final key = '${event.player?.id ?? "team"}_${event.eventType}';

        final existing = aggregatedEvents[key];
        if (existing != null) {
          // Update existing aggregate
          aggregatedEvents[key] = _AggregatedEvent(existing.event,
              existing.count + 1, existing.totalValue + event.eventData);
        } else {
          // New aggregate
          aggregatedEvents[key] = _AggregatedEvent(event, 1, event.eventData);
        }
      } else {
        timelineEvents.add(event);
      }
    }

    // Sort timeline events normally
    timelineEvents.sort((a, b) => b.index.compareTo(a.index));

    final isCompleted = _currentGame!.gameStatus.index >= 9;

    // Combine lists: Timeline events first (newest), then aggregated stats
    final displayList = <dynamic>[...timelineEvents];

    // Add aggregated stats to the end (bottom of list)
    aggregatedEvents.forEach((key, aggregate) {
      displayList.add(aggregate);
    });

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: displayList.length + (isCompleted ? 1 : 0),
      itemBuilder: (context, index) {
        if (isCompleted && index == 0) {
          return _buildFinalScoreTile(context);
        }
        final itemIndex = isCompleted ? index - 1 : index;
        final item = displayList[itemIndex];

        if (item is _AggregatedEvent) {
          return _buildEventItem(
            context,
            item.event,
            count: item.count,
            totalValue: item.totalValue,
            isAggregate: true,
          );
        } else if (item is GameEvent) {
          return _buildEventItem(context, item);
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildEventItem(BuildContext context, GameEvent event,
      {int count = 1, int totalValue = 0, bool isAggregate = false}) {
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

    // Determine value to show in badge
    // For Points: show totalValue (e.g. 20)
    // For others: show count (e.g. 3)
    final badgeCount = event.eventType == 'Point' ? totalValue : count;

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
          // If aggregate, show count badge instead of time
          SizedBox(
            width: 44,
            height: 44,
            child: isAggregate
                ? Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .tertiaryContainer
                          .withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        event.eventType == 'Point'
                            ? "$badgeCount"
                            : "x$badgeCount",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color:
                              Theme.of(context).colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ),
                  )
                : isGoalOrAssist
                    ? Container(
                        decoration: BoxDecoration(
                          color:
                              _getEventColor(event.eventType).withOpacity(0.1),
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
                          text: _getEventTitle(event, count: badgeCount),
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
      // Basketball / Generic
      case 'Point':
        return Icons.sports_basketball;
      case 'Rebound':
        return Icons.arrow_upward;
      case 'Steal':
        return Icons.pan_tool;
      case 'Block':
        return Icons.block;
      case 'Turnover':
        return Icons.loop;
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
      // Basketball / Generic
      case 'Point':
        return Colors.green[700]!;
      case 'Rebound':
        return Colors.blue[700]!;
      case 'Steal':
        return Colors.deepPurple;
      case 'Block':
        return Colors.grey[800]!;
      case 'Turnover':
        return Colors.brown;
      default:
        return Colors.grey;
    }
  }

  String _getEventTitle(GameEvent event, {int count = 1}) {
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
        return count > 1 ? '$count Assists' : 'Assist';
      case 'Save':
        return count > 1 ? '$count Saves' : 'Save';
      case 'Offsides':
        return count > 1 ? '$count Offsides' : 'Offsides';
      case 'Foul':
        return count > 1 ? '$count Fouls' : 'Foul';
      case 'Card':
        if (event.eventData == 0) {
          return '🟨 Yellow Card';
        } else if (event.eventData == 1) {
          return '🟨🟨 Second Yellow';
        } else {
          return '🟥 Red Card';
        }
      case 'Point':
        return '$count Points';
      case 'Rebound':
        return '$count Rebounds';
      case 'Steal':
        return '$count Steals';
      case 'Block':
        return '$count Blocks';
      case 'Turnover':
        return '$count Turnovers';
      default:
        return count > 1 ? '$count ${event.eventType}s' : event.eventType;
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
          if (SportStrategy.current.sportId == 'basketball') ...[
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: _buildStatRow(context, 'Points', homeStats.points,
                    awayStats.points, 'points',
                    isHeader: true),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                trailing: const SizedBox.shrink(),
                showTrailingIcon: false,
                children: [
                  if (homeStats.threePointersAttempted > 0 ||
                      awayStats.threePointersAttempted > 0)
                    _buildShootingStatRow(
                        context,
                        '3 Point Field Goals',
                        homeStats.threePointersMade,
                        homeStats.threePointersAttempted,
                        awayStats.threePointersMade,
                        awayStats.threePointersAttempted,
                        'threePointersMade',
                        isSubStat: true),
                  if (homeStats.twoPointersAttempted > 0 ||
                      awayStats.twoPointersAttempted > 0)
                    _buildShootingStatRow(
                        context,
                        'Field Goals',
                        homeStats.twoPointersMade,
                        homeStats.twoPointersAttempted,
                        awayStats.twoPointersMade,
                        awayStats.twoPointersAttempted,
                        'twoPointersMade',
                        isSubStat: true),
                  if (homeStats.freeThrowsAttempted > 0 ||
                      awayStats.freeThrowsAttempted > 0)
                    _buildShootingStatRow(
                        context,
                        'Free Throws',
                        homeStats.freeThrowsMade,
                        homeStats.freeThrowsAttempted,
                        awayStats.freeThrowsMade,
                        awayStats.freeThrowsAttempted,
                        'freeThrowsMade',
                        isSubStat: true),
                ],
              ),
            ),
            Theme(
              data:
                  Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: _buildStatRow(context, 'Total Rebounds',
                    homeStats.rebounds, awayStats.rebounds, 'rebounds',
                    isHeader: true),
                tilePadding: EdgeInsets.zero,
                childrenPadding: EdgeInsets.zero,
                trailing: const SizedBox.shrink(),
                showTrailingIcon: false,
                children: [
                  if (homeStats.offRebounds > 0 || awayStats.offRebounds > 0)
                    _buildStatRow(
                        context,
                        'Off. Rebounds',
                        homeStats.offRebounds,
                        awayStats.offRebounds,
                        'offRebounds',
                        isSubStat: true),
                  if (homeStats.defRebounds > 0 || awayStats.defRebounds > 0)
                    _buildStatRow(
                        context,
                        'Def. Rebounds',
                        homeStats.defRebounds,
                        awayStats.defRebounds,
                        'defRebounds',
                        isSubStat: true),
                ],
              ),
            ),
            _buildStatRow(context, 'Assists', homeStats.assists,
                awayStats.assists, 'assists'),
            _buildStatRow(context, 'Steals', homeStats.steals, awayStats.steals,
                'steals'),
            _buildStatRow(context, 'Blocks', homeStats.blocks, awayStats.blocks,
                'blocks'),
            _buildStatRow(context, 'Turnovers', homeStats.turnovers,
                awayStats.turnovers, 'turnovers'),
            _buildStatRow(
                context, 'Fouls', homeStats.fouls, awayStats.fouls, 'fouls'),
          ] else ...[
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
            _buildStatRow(context, 'Corners', homeStats.corners,
                awayStats.corners, 'corners'),
            _buildStatRow(context, 'Offsides', homeStats.offsides,
                awayStats.offsides, 'offsides'),
            _buildStatRow(context, 'Yellow Cards', homeStats.yellows,
                awayStats.yellows, 'yellows'),
            _buildStatRow(
                context, 'Red Cards', homeStats.reds, awayStats.reds, 'reds'),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildStatRow(BuildContext context, String label, int homeValue,
      int awayValue, String category,
      {bool isHeader = false, bool isSubStat = false}) {
    final maxValue = homeValue > awayValue ? homeValue : awayValue;
    final homePercent = maxValue > 0 ? homeValue / maxValue : 0.0;
    final awayPercent = maxValue > 0 ? awayValue / maxValue : 0.0;

    // Determine which team is "our" team for the dialog
    final teamId = widget.teamId ?? _currentGame!.homeTeam.id;
    final isHomeTeam = teamId == _currentGame!.homeTeam.id;
    final teamTotal = isHomeTeam ? homeValue : awayValue;
    final padding = isSubStat
        ? const EdgeInsets.fromLTRB(32, 8, 32, 8)
        : isHeader
            ? const EdgeInsets.symmetric(vertical: 12.0)
            : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0);

    final margin = isHeader
        ? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0)
        : EdgeInsets.zero;

    final row = Container(
      width: double.infinity,
      margin: margin,
      decoration: isHeader
          ? BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      padding: padding,
      child: Column(
        children: [
          // Label
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isHeader) const SizedBox(width: 20), // Balance the icon
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isHeader ? FontWeight.bold : FontWeight.w500,
                  color: isHeader
                      ? Theme.of(context).colorScheme.onSurface
                      : Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
                ),
              ),
              if (isHeader) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.expand_more,
                  size: 16,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // Values and bars
          Row(
            children: [
              // Home value
              SizedBox(
                width: isSubStat ? 70 : 30,
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
                        color: _currentGame!.homeTeam.color1.withOpacity(0.7),
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
                        color: _currentGame!.awayTeam.color1.withOpacity(0.7),
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
                width: isSubStat ? 70 : 30,
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

    if (isHeader) return row;

    return InkWell(
        onTap: teamTotal > 0
            ? () => _showStatCategoryDialog(context, category, label, teamId)
            : null,
        child: row);
  }

  Future<void> _showStatCategoryDialog(
      BuildContext context, String category, String label, int teamId) async {
    // Get player stats for this category
    final stats = await _currentGame!.getStats(teamId);
    final playerStats = await stats.getStatPlayers(category);

    Map<Player, int>? playerAttempts;
    if (category == 'threePointersMade') {
      playerAttempts = await stats.getStatPlayers('threePointersAttempted');
    } else if (category == 'twoPointersMade') {
      playerAttempts = await stats.getStatPlayers('twoPointersAttempted');
    } else if (category == 'freeThrowsMade') {
      playerAttempts = await stats.getStatPlayers('freeThrowsAttempted');
    }

    if (!mounted) return;

    // Use the common dialog component
    await StatCategoryDialog.show(
      context: context,
      categoryName: label,
      playerStats: playerStats,
      playerAttempts: playerAttempts,
      showPlayerNumber: true, // Always show numbers for basketball
    );
  }

  Widget _buildShootingStatRow(
    BuildContext context,
    String label,
    int homeMade,
    int homeAttempted,
    int awayMade,
    int awayAttempted,
    String category, {
    bool isSubStat = false,
  }) {
    final homePct = homeAttempted > 0 ? (homeMade / homeAttempted) * 100 : 0.0;
    final awayPct = awayAttempted > 0 ? (awayMade / awayAttempted) * 100 : 0.0;

    final homePercentFactor =
        homeAttempted > 0 ? homeMade / homeAttempted : 0.0;
    final awayPercentFactor =
        awayAttempted > 0 ? awayMade / awayAttempted : 0.0;

    // Determine which team is "our" team for the dialog
    final teamId = widget.teamId ?? _currentGame!.homeTeam.id;
    final isHomeTeam = teamId == _currentGame!.homeTeam.id;
    final teamMade = isHomeTeam ? homeMade : awayMade;
    final padding = isSubStat
        ? const EdgeInsets.fromLTRB(32, 4, 32, 4)
        : const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0);

    return InkWell(
      onTap: teamMade > 0
          ? () => _showStatCategoryDialog(context, category, label, teamId)
          : null,
      child: Container(
        padding: padding,
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
                // Home value and percentage
                SizedBox(
                  width: 70,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$homeMade-$homeAttempted',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${homePct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Home bar (right-to-left)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FractionallySizedBox(
                      widthFactor: homePercentFactor.clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentGame!.homeTeam.color1.withOpacity(0.7),
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
                      widthFactor: awayPercentFactor.clamp(0.0, 1.0),
                      child: Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentGame!.awayTeam.color1.withOpacity(0.7),
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Away value and percentage
                SizedBox(
                  width: 70,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$awayMade-$awayAttempted',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '${awayPct.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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
    int corners = 0;

    // Basketball / Generic
    int points = 0;
    int threePointersMade = 0;
    int threePointersAttempted = 0;
    int twoPointersMade = 0;
    int twoPointersAttempted = 0;
    int freeThrowsMade = 0;
    int freeThrowsAttempted = 0;
    int rebounds = 0;
    int offRebounds = 0;
    int defRebounds = 0;
    int steals = 0;
    int turnovers = 0;
    int blocks = 0;

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
        case 'Corner':
          corners++;
          break;
        case 'Card':
          if (event.eventData == 0) {
            yellows++;
          } else if (event.eventData == 1 || event.eventData == 2) {
            reds++;
          }
          break;
        // Basketball / Generic
        case 'Point':
          points += event.eventData; // Points usually have value in eventData
          if (event.eventData == 3) {
            threePointersMade++;
            threePointersAttempted++;
          } else if (event.eventData == 2) {
            twoPointersMade++;
            twoPointersAttempted++;
          } else if (event.eventData == 1) {
            freeThrowsMade++;
            freeThrowsAttempted++;
          }
          break;
        case 'Miss':
          if (event.eventData == 3) {
            threePointersAttempted++;
          } else if (event.eventData == 2) {
            twoPointersAttempted++;
          } else if (event.eventData == 1) {
            freeThrowsAttempted++;
          }
          break;
        case 'Rebound':
          rebounds++;
          if (event.eventData == 2) {
            offRebounds++;
          } else if (event.eventData == 3) {
            defRebounds++;
          }
          break;
        case 'Steal':
          steals++;
          break;
        case 'Turnover':
          turnovers++;
          break;
        case 'Block':
          blocks++;
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
      corners: corners,
      points: points,
      threePointersMade: threePointersMade,
      threePointersAttempted: threePointersAttempted,
      twoPointersMade: twoPointersMade,
      twoPointersAttempted: twoPointersAttempted,
      freeThrowsMade: freeThrowsMade,
      freeThrowsAttempted: freeThrowsAttempted,
      rebounds: rebounds,
      offRebounds: offRebounds,
      defRebounds: defRebounds,
      steals: steals,
      turnovers: turnovers,
      blocks: blocks,
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
  final int corners;

  // Basketball / Generic
  final int points;
  final int threePointersMade;
  final int threePointersAttempted;
  final int twoPointersMade;
  final int twoPointersAttempted;
  final int freeThrowsMade;
  final int freeThrowsAttempted;
  final int rebounds;
  final int offRebounds;
  final int defRebounds;
  final int steals;
  final int turnovers;
  final int blocks;

  bool get hasBasketballStats =>
      points > 0 || rebounds > 0 || steals > 0 || turnovers > 0 || blocks > 0;

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
    this.corners = 0,
    this.points = 0,
    this.threePointersMade = 0,
    this.threePointersAttempted = 0,
    this.twoPointersMade = 0,
    this.twoPointersAttempted = 0,
    this.freeThrowsMade = 0,
    this.freeThrowsAttempted = 0,
    this.rebounds = 0,
    this.offRebounds = 0,
    this.defRebounds = 0,
    this.steals = 0,
    this.turnovers = 0,
    this.blocks = 0,
  });
}

class _AggregatedEvent {
  final GameEvent event;
  final int count;
  final int totalValue;

  _AggregatedEvent(this.event, this.count, [this.totalValue = 0]);
}
