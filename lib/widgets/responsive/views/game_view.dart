import 'dart:io';

import 'package:eventify/eventify.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/event_service.dart';
import 'package:team_sync/services/twitter_service.dart';
import 'package:team_sync/widgets/adhoc_tweet_dialog.dart';
import 'package:team_sync/widgets/responsive_player_avatar.dart';
import 'package:team_sync/widgets/tweet_preview_dialog.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:team_sync/widgets/common/skeleton_container.dart';

class GameView extends StatefulWidget {
  final Season season;
  final Game game;
  final EventEmitter eventEmitter;

  const GameView(
      {super.key,
      required this.season,
      required this.game,
      required this.eventEmitter});

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  GameEvent? _autoCreateSave;
  GameEvent? _autoCreateAssist;
  late Game _game;

  @override
  void initState() {
    _game = widget.game;

    widget.eventEmitter.on('createEvent', context, (event, eventContext) async {
      await _editEvent();
    });

    widget.eventEmitter.on('advanceGame', context, (event, eventContext) async {
      await _advanceGame();
    });

    widget.eventEmitter.on('sendTweet', context, (event, eventContext) async {
      await AdhocTweetDialog.show(context,
          teamId: widget.season.teamId, team: widget.season.team);
    });

    widget.eventEmitter.on('loadSettings', context,
        (event, eventContext) async {
      // Initialize Twitter with team credentials once at startup
      await TwitterService.instance
          .ensureInitialized(teamId: widget.season.teamId);
    });
    widget.eventEmitter.emit('loadSettings');

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_autoCreateSave != null) {
      if (_autoCreateSave!.team.id == widget.season.teamId) {
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          await _editEvent(event: _autoCreateSave);
          _autoCreateSave = null;
        });
      } else {
        _saveEvent(_autoCreateSave!);
        _autoCreateSave = null;
      }
    }

    if (_autoCreateAssist != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final assistEvent = _autoCreateAssist!;
        final goalEventId = assistEvent.eventData; // This is the goal event ID

        final shouldCreateAssist = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            final loc = AppLocalizations.of(context)!;
            return AlertDialog(
              title: Text(loc.addAssistQuestion),
              content: const Text(
                  "Was this goal assisted? Select 'Yes' to assign an assist or 'No' for unassisted goal."),
              actions: [
                TextButton(
                  child: const Text("Yes"),
                  onPressed: () {
                    Navigator.pop(context, true);
                  },
                ),
                TextButton(
                  child: const Text("No"),
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                ),
              ],
            );
          },
        );

        Player? assistPlayer;
        if (shouldCreateAssist == true) {
          await _editEvent(event: assistEvent);
          // Get the assist player after it's been assigned
          assistPlayer = assistEvent.player;
        }

        setState(() {
          _autoCreateAssist = null;
        });

        // Now send the goal tweet with assist information (if any)
        await _sendGoalTweet(goalEventId, assistPlayer);
      });
    }

    return FutureBuilder(
        future: _loadGameEvents(),
        builder:
            (BuildContext context, AsyncSnapshot<List<GameEvent>> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            // Web layout: side-by-side scoring events and stats
            // Always use web layout on web platform (shows only scoring events)
            if (kIsWeb) {
              return _buildWebLayout(loc);
            }

            // Mobile layout: full event list with reordering

            var itemCount = _game.scoringEvents.length +
                _game.gameEvents.length +
                _game.shootoutEvents.length +
                3;
            if (_game.shootoutEvents.isNotEmpty) {
              itemCount += 1;
            }

            // Always show scoring events on mobile
            bool showScoringEvents = true;

            // Enable reorder only on mobile
            final bool enableReorder = !kIsWeb;

            // Reuse the same itemBuilder for both reorderable and non-reorderable lists
            Widget itemBuilder(BuildContext context, int index) {
              if (index == 0) {
                return Visibility(
                    key: const ValueKey('scoring-header'),
                    visible: showScoringEvents,
                    child: const ListTile(
                        title: Center(child: Text('Scoring Events'))));
              }

              if (index <= _game.scoringEvents.length) {
                final event = _game.scoringEvents[index - 1];
                return Visibility(
                    key: ValueKey('scoring-${event.id}'),
                    visible: showScoringEvents,
                    child: Column(
                      children: [
                        _getEventTile(event, loc),
                        const Divider(height: 1),
                      ],
                    ));
              }

              if (index == _game.scoringEvents.length + 1) {
                return ListTile(
                    key: const ValueKey('events-header'),
                    title: const Center(child: Text('All Game Events')));
              }

              if (index >= _game.scoringEvents.length + 2 &&
                  index <
                      _game.gameEvents.length +
                          _game.scoringEvents.length +
                          2) {
                final event =
                    _game.gameEvents[index - _game.scoringEvents.length - 2];
                return KeyedSubtree(
                    key: ValueKey('event-${event.id}'),
                    child: Column(
                      children: [
                        _getEventTile(event, loc),
                        const Divider(height: 1),
                      ],
                    ));
              }

              if (_game.shootoutEvents.isNotEmpty) {
                if (index == _game.gameEvents.length + 2) {
                  return ListTile(
                      key: const ValueKey('regulation-end'),
                      title: Center(child: Text(loc.endOfRegulation)));
                }

                if (index >=
                        _game.scoringEvents.length +
                            1 +
                            _game.gameEvents.length +
                            1 +
                            1 &&
                    index < itemCount - 1) {
                  final event = _game.shootoutEvents[index -
                      _game.scoringEvents.length -
                      2 -
                      _game.gameEvents.length -
                      1];
                  return KeyedSubtree(
                      key: ValueKey('shootout-${event.id}'),
                      child: Column(
                        children: [
                          _getEventTile(event, loc),
                          const Divider(height: 1),
                        ],
                      ));
                }
              }

              return ListTile(
                  key: const ValueKey('game-end'),
                  title: Center(child: Text(loc.endOfGame)));
            }

            if (enableReorder) {
              return ReorderableListView.builder(
                  itemCount: itemCount,
                  onReorder: (oldIndex, newIndex) async {
                    // Calculate start of game events section
                    int gameEventsStart = _game.scoringEvents.length + 2;

                    // Only allow reordering within game events section
                    if (oldIndex < gameEventsStart ||
                        newIndex < gameEventsStart) {
                      return;
                    }

                    // Convert to game events list index
                    int oldEventIndex = oldIndex - gameEventsStart;
                    int newEventIndex = newIndex - gameEventsStart;

                    if (newEventIndex > _game.gameEvents.length) {
                      newEventIndex = _game.gameEvents.length;
                    }

                    if (oldEventIndex < 0 ||
                        oldEventIndex >= _game.gameEvents.length ||
                        newEventIndex < 0 ||
                        newEventIndex >= _game.gameEvents.length) {
                      return;
                    }

                    // Get the event being moved
                    final event = _game.gameEvents[oldEventIndex];

                    // Remove from old position
                    _game.gameEvents.removeAt(oldEventIndex);

                    // Insert at new position
                    if (newEventIndex > oldEventIndex) {
                      newEventIndex -= 1;
                    }
                    _game.gameEvents.insert(newEventIndex, event);

                    // Update indices in database
                    for (int i = 0; i < _game.gameEvents.length; i++) {
                      final currentEvent = _game.gameEvents[i];
                      currentEvent.index = i;
                      await DatabaseService.instance.update(
                        'Events',
                        {'index': currentEvent.index},
                        key: currentEvent.id.toString(),
                      );
                    }

                    setState(() {});
                  },
                  itemBuilder: itemBuilder);
            } else {
              // Non-mobile: plain scrollable list without reordering
              return ListView.builder(
                  itemCount: itemCount, itemBuilder: itemBuilder);
            }
          } else if (snapshot.hasError) {
            debugPrint(snapshot.error.toString());
            debugPrintStack(stackTrace: snapshot.stackTrace);
            return Center(child: Text(loc.errorLoadingEvents));
          } else {
            return _buildSkeletonView(context);
          }
        });
  }

  Widget _buildSkeletonView(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          SkeletonContainer.rectangular(
            width: double.infinity,
            height: 120,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 24),
          // Tab bar placeholder
          SkeletonContainer.rectangular(
            width: double.infinity,
            height: 48,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 24),
          // Content placeholder
          SkeletonContainer.rectangular(
            width: double.infinity,
            height: 300,
            borderRadius: BorderRadius.circular(12),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
  }

  Widget _getEventTile(GameEvent event, AppLocalizations loc) {
    final opponent = !widget.game.isHomeTeam(widget.season.teamId)
        ? widget.game.homeTeam
        : widget.game.awayTeam;

    final assistEvents = widget.game.allGameEvents
        .where((e) => e.eventType == 'Assist')
        .toList(growable: false);

    final assistEvent = assistEvents
        .where((e) =>
            event.eventType == 'Shot' &&
                event.eventData == ShotResult.goal.index &&
                (((e.id == event.id + 1) ||
                        e.eventMinute == event.eventMinute) &&
                    e.eventType == 'Assist') ||
            e.eventData == event.id)
        .firstOrNull;

    // Determine event color based on type
    final Color eventColor = _getEventColor(event);
    final bool isGoal = event.isGoalEvent;
    final bool isPeriodEvent = event.eventType == 'Period';

    // Responsive sizing based on screen width
    final isLargeScreen = ResponsiveBreakpoints.of(context).largerThan(MOBILE);
    final bool isWeb = kIsWeb;

    // Use smaller, more compact layout on smaller screens
    final bool useCompactLayout = !isLargeScreen || !isWeb;

    final eventCard = Container(
      margin: EdgeInsets.symmetric(
        horizontal: useCompactLayout ? 4 : 16,
        vertical: useCompactLayout ? 4 : 8,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPeriodEvent
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.3)
              : eventColor.withValues(alpha: 0.2),
          width: isPeriodEvent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          _editEvent(event: event);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(useCompactLayout ? 10 : 20),
          child: useCompactLayout
              ? _buildCompactEventLayout(
                  event, loc, eventColor, isGoal, opponent, assistEvent)
              : _buildLargeEventLayout(
                  event, loc, eventColor, isGoal, opponent, assistEvent),
        ),
      ),
    );

    if (kIsWeb) {
      return eventCard;
    }

    return Dismissible(
        key: Key(event.id.toString()),
        direction: DismissDirection.endToStart,
        dismissThresholds: const {
          DismissDirection.endToStart: 0.7,
        },
        movementDuration: const Duration(milliseconds: 200),
        resizeDuration: const Duration(milliseconds: 200),
        crossAxisEndOffset: 0.0,
        background: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.red, Colors.redAccent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delete, color: Colors.white, size: 32),
              SizedBox(height: 4),
              Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        confirmDismiss: (_) {
          return showDialog(
            context: context,
            builder: (BuildContext context) {
              final loc = AppLocalizations.of(context)!;
              return AlertDialog(
                title: Text(loc.confirmDelete),
                content: const Text(
                    "Are you sure you want to delete this Event? All data associated with this Event will be deleted. This cannot be undone."),
                actions: [
                  TextButton(
                    child: Text(loc.continueText),
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                  ),
                  TextButton(
                    child: Text(loc.cancel),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                ],
              );
            },
          );
        },
        onDismissed: (direction) async {
          await DatabaseService.instance
              .delete('Events', key: event.id.toString());
          setState(() {
            _game.updateScore();
          });
        },
        child: eventCard);
  }

  // Compact layout for small screens - vertical stacking
  Widget _buildCompactEventLayout(
    GameEvent event,
    AppLocalizations loc,
    Color eventColor,
    bool isGoal,
    Team opponent,
    GameEvent? assistEvent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top row: Icon/Avatar, Title - Player, Score
        Row(
          children: [
            // Leading: Player Avatar OR Event Icon
            if (event.player?.displayImageForStats != null)
              ResponsivePlayerAvatar(
                player: event.player!,
                avatarSize: 32,
                season: widget.season,
                useLatestImages: true,
              )
            else
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: eventColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: eventColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Center(
                    child: SizedBox(
                        width: 18,
                        height: 18,
                        child: FittedBox(child: event.image))),
              ),
            const SizedBox(width: 10),
            // Event title and player name
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: event.eventType == 'Shot' &&
                                  event.eventData == ShotResult.goal.index &&
                                  ((event.player == null &&
                                          event.team.id ==
                                              widget.season.teamId) ||
                                      event.player?.id == -2)
                              ? event.team.id == widget.season.teamId
                                  ? 'Own goal by ${opponent.shortName}'
                                  : 'Own goal'
                              : event.display,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isGoal ? eventColor : null,
                          ),
                        ),
                        if (event.player != null && event.player!.id != -2) ...[
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
                        ] else if (event.eventType != 'Period') ...[
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
                  ),
                  // Minute badge
                  if (event.eventMinute > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: eventColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: eventColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '${event.eventMinute}\'',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: eventColor,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Score + Video link
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (event.eventUrls?.isNotEmpty ?? false) ...[
                  GestureDetector(
                    onTap: () => _launchUrl(event.eventUrls!),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.play_circle_outline,
                        size: 18,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                if (event.eventMinute > 0 &&
                    (event.eventType == 'Shot' ||
                        event.eventType == 'PenaltyKick') &&
                    event.eventData == ShotResult.goal.index)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          eventColor.withValues(alpha: 0.2),
                          eventColor.withValues(alpha: 0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: eventColor.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      _game.getScore(widget.season.teamId,
                          minute: event.eventMinute),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: eventColor,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        // Removed separate Player info container
        // Assist info
        if (assistEvent != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.sports_soccer,
                  size: 14,
                  color: Colors.green,
                ),
                const SizedBox(width: 6),
                Text(
                  loc.assistedBy,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                if (assistEvent.player != null &&
                    assistEvent.player!.id != -2) ...[
                  ResponsivePlayerAvatar(
                    player: assistEvent.player!,
                    avatarSize: 24,
                    season: widget.season,
                    useLatestImages: true,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    assistEvent.player?.displayName ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Large layout for big screens - horizontal layout
  Widget _buildLargeEventLayout(
    GameEvent event,
    AppLocalizations loc,
    Color eventColor,
    bool isGoal,
    Team opponent,
    GameEvent? assistEvent,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Time and Icon/Avatar section
        Column(
          children: [
            // Event icon or Avatar
            if (event.player?.displayImageForStats != null)
              ResponsivePlayerAvatar(
                player: event.player!,
                avatarSize: 72,
                season: widget.season,
                useLatestImages: true,
              )
            else
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: eventColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: eventColor.withValues(alpha: 0.3),
                    width: 3,
                  ),
                ),
                child: Center(child: event.image),
              ),
            // Event minute
            if (event.eventMinute > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: eventColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: eventColor.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: Text(
                  '${event.eventMinute}\'',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: eventColor,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(width: 24),
        // Event details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Event type, team, and player name
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: event.eventType == 'Shot' &&
                                    event.eventData == ShotResult.goal.index &&
                                    ((event.player == null &&
                                            event.team.id ==
                                                widget.season.teamId) ||
                                        event.player?.id == -2)
                                ? event.team.id == widget.season.teamId
                                    ? 'Own goal by ${opponent.shortName}'
                                    : 'Own goal'
                                : event.display,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: isGoal ? eventColor : null,
                            ),
                          ),
                          if (event.player != null &&
                              event.player!.id != -2) ...[
                            TextSpan(
                              text: ' - ',
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                            TextSpan(
                              text: event.player!.displayName,
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                            ),
                          ] else if (event.eventType != 'Period') ...[
                            TextSpan(
                              text: ' - ',
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                            TextSpan(
                              text: event.team.shortName,
                              style: TextStyle(
                                fontSize: 18,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.5),
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ),
                  // Video link indicator
                  if (event.eventUrls?.isNotEmpty ?? false)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      child: GestureDetector(
                        onTap: () => _launchUrl(event.eventUrls!),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.blue.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.play_circle_outline,
                            size: 28,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              // Removed separate Player info container (lines 828-881)
              // Assist information
              if (assistEvent != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sports_soccer,
                        size: 20,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        loc.assistedBy,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.green,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (assistEvent.player != null &&
                          assistEvent.player!.id != -2) ...[
                        ResponsivePlayerAvatar(
                          player: assistEvent.player!,
                          avatarSize: 40,
                        ),
                        const SizedBox(width: 12),
                      ],
                      Expanded(
                        child: Text(
                          assistEvent.player?.displayName ?? '',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        // Score display for goals
        if (event.eventMinute > 0 &&
            (event.eventType == 'Shot' || event.eventType == 'PenaltyKick') &&
            event.eventData == ShotResult.goal.index)
          Container(
            margin: const EdgeInsets.only(left: 8),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  eventColor.withValues(alpha: 0.2),
                  eventColor.withValues(alpha: 0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: eventColor.withValues(alpha: 0.4),
                width: 3,
              ),
            ),
            child: Text(
              _game.getScore(widget.season.teamId, minute: event.eventMinute),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: eventColor,
              ),
            ),
          ),
      ],
    );
  }

  // Helper method to get event color based on type
  Color _getEventColor(GameEvent event) {
    if (event.isGoalEvent) {
      return Colors.green;
    } else if (event.eventType == 'Assist') {
      return Colors.lightGreen;
    } else if (event.eventType == 'Save') {
      return Colors.blue;
    } else if (event.eventType == 'Shot') {
      return Colors.orange;
    } else if (event.eventType == 'Card') {
      return event.eventData == 2 ? Colors.red : Colors.amber;
    } else if (event.eventType == 'Foul') {
      return Colors.deepOrange;
    } else if (event.eventType == 'Corner') {
      return Colors.purple;
    } else if (event.eventType == 'Offsides') {
      return Colors.brown;
    } else if (event.eventType == 'Period') {
      return Colors.grey;
    }
    return Colors.grey;
  }

  // Build web-specific layout with scoring events
  Widget _buildWebLayout(AppLocalizations loc) {
    return Container(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: widget.season.team.color1.withValues(alpha: 0.1),
              border: Border(
                bottom: BorderSide(
                  color: widget.season.team.color1.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sports_soccer,
                  color: widget.season.team.color1,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  loc.scoringEvents,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: widget.season.team.color1,
                  ),
                ),
              ],
            ),
          ),
          // Scoring events list
          Expanded(
            child: _game.scoringEvents.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.sports_soccer_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            loc.noScoringEventsYet,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(8),
                    itemCount: _game.scoringEvents.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final event = _game.scoringEvents[index];
                      return _getEventTile(event, loc);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<List<GameEvent>> _loadGameEvents() async {
    return await _game.loadGameEvents();
  }

  /// Send a tweet for a goal event, including assist information if provided
  Future<void> _sendGoalTweet(int goalEventId, Player? assistPlayer) async {
    try {
      // Find the goal event
      final goalEvent =
          _game.allGameEvents.firstWhere((e) => e.id == goalEventId);

      if (!goalEvent.isGoalEvent) return;

      // Check if game is in progress
      final gameInProgress = _game.gameStatus != GameStatus.notStarted &&
          _game.gameStatus != GameStatus.gameFinal &&
          _game.gameStatus != GameStatus.gameFinalOT &&
          _game.gameStatus != GameStatus.gameFinalPKs;

      if (!gameInProgress && !kDebugMode) return;

      // Generate tweet text with assist information
      String tweetText;
      if (goalEvent.player != null) {
        tweetText =
            '(${goalEvent.eventMinute}\') Goal by ${goalEvent.player!.displayName}';
        if (assistPlayer != null) {
          tweetText += '\nAssist: ${assistPlayer.displayName}';
        }
      } else {
        tweetText =
            '(${goalEvent.eventMinute}\') Goal by ${goalEvent.team.shortName}';
      }

      tweetText = '$tweetText\n\n${_game.tweetStatus()}';

      // Check if goal scorer has a profile image
      File? playerImageFile;
      if (goalEvent.player != null &&
          goalEvent.player!.profileImage != null &&
          goalEvent.player!.profileImage!.isNotEmpty) {
        try {
          final response =
              await http.get(Uri.parse(goalEvent.player!.profileImage!));
          if (response.statusCode == 200) {
            final tempDir = await getTemporaryDirectory();
            final imageFile = File(
                '${tempDir.path}/player_${goalEvent.player!.id}_${DateTime.now().millisecondsSinceEpoch}.jpg');
            await imageFile.writeAsBytes(response.bodyBytes);
            playerImageFile = imageFile;
          }
        } catch (e) {
          debugPrint('Error downloading player image for tweet: $e');
        }
      }

      if (mounted) {
        // Show tweet preview dialog - it handles initialization and sending internally
        await TweetPreviewDialog.show(
          context,
          initialText: tweetText,
          teamId: widget.season.teamId,
          team: widget.season.team,
          imageFile: playerImageFile,
          eventContext: 'GOAL!',
        );
      }
    } catch (e) {
      debugPrint('Error sending goal tweet: $e');
    }
  }

  Future<void> _editEvent({GameEvent? event}) async {
    if (kIsWeb) {
      return;
    }

    if (event?.eventType == 'Period') {
      return;
    }

    final eventEntries = [
      'Save',
      'Shot',
      'Assist',
      'Offsides',
      'Foul',
      'Corner',
      'Penalty Kick',
      'Yellow Card',
      '2nd Yellow Card',
      'Red Card'
    ]
        .map((t) => DropdownMenuEntry<String>(
            value: t,
            label: t,
            style: ButtonStyle(
                textStyle:
                    WidgetStateProperty.all(const TextStyle(fontSize: 18)))))
        .toList(growable: false);

    final eventPeriods = [
      '1st Half',
      '2nd Half',
      '1st Half Overtime',
      '2nd Half Overtime',
      'Penalty Kicks'
    ]
        .map((t) => DropdownMenuEntry<String>(
            value: t,
            label: t,
            style: ButtonStyle(
                textStyle:
                    WidgetStateProperty.all(const TextStyle(fontSize: 18)))))
        .toList(growable: false);

    List<Player> awayTeamPlayers =
        await Player.listFromTeamIdSeasonId(_game.awayTeam.id, _game.seasonId);
    List<Player> homeTeamPlayers =
        await Player.listFromTeamIdSeasonId(_game.homeTeam.id, _game.seasonId);

    event ??= GameEvent.initial(
        team: event?.team ?? _game.awayTeam,
        game: _game,
        seasonId: _game.seasonId,
        eventType: event?.eventType ?? 'Shot',
        eventMinute: event?.eventMinute ?? -1,
        eventPeriod: event?.eventPeriod ?? -1,
        eventUrls: event?.eventUrls ?? '',
        eventData: event?.eventData ?? 0);

    final initialStatus = event.eventPeriod == -1
        ? _game.gameStatus == GameStatus.firstHalf
            ? '1st Half'
            : _game.gameStatus == GameStatus.secondHalf
                ? '2nd Half'
                : _game.gameStatus == GameStatus.firstHalfOvertime
                    ? '1st Half Overtime'
                    : _game.gameStatus == GameStatus.secondHalfOvertime
                        ? '2nd Half Overtime'
                        : ''
        : event.eventPeriod == 1
            ? '1st Half'
            : event.eventPeriod == 3
                ? '2nd Half'
                : event.eventPeriod == 5
                    ? '1st Half Overtime'
                    : event.eventPeriod == 7
                        ? '2nd Half Overtime'
                        : event.eventPeriod == 8
                            ? 'Penalty Kicks'
                            : '';

    event.eventPeriod =
        event.eventPeriod == -1 ? _game.gameStatus.index : event.eventPeriod;

    final initialShotResult = event.eventData == ShotResult.goal.index
        ? 'Goal'
        : event.eventData == ShotResult.onTargetSave.index
            ? 'Saved'
            : event.eventData == ShotResult.offTargetPost.index
                ? 'Post'
                : event.eventData == ShotResult.offTarget.index
                    ? 'Off Target'
                    : event.eventData == ShotResult.onTargetBlock.index
                        ? 'Blocked'
                        : '';

    List<DropdownMenuEntry> homePlayerEntries = homeTeamPlayers
        .map((p) => DropdownMenuEntry<Player>(
            value: p,
            label: p.displayName,
            leadingIcon: ResponsivePlayerAvatar(
                player: p,
                avatarSize: 32,
                season: widget.season,
                useLatestImages: true),
            style: ButtonStyle(
                textStyle:
                    WidgetStateProperty.all(const TextStyle(fontSize: 24)))))
        .toList();

    List<DropdownMenuEntry> awayPlayerEntries = awayTeamPlayers
        .map((p) => DropdownMenuEntry<Player>(
            value: p,
            label: p.displayName,
            leadingIcon: ResponsivePlayerAvatar(
                player: p,
                avatarSize: 32,
                season: widget.season,
                useLatestImages: true),
            style: ButtonStyle(
                textStyle:
                    WidgetStateProperty.all(const TextStyle(fontSize: 24)))))
        .toList();

    var playerEntries = event.team.id == _game.homeTeam.id
        ? homePlayerEntries
        : awayPlayerEntries;

    final shotResultEntries = ['Goal', 'Saved', 'Post', 'Off Target', 'Blocked']
        .map((t) => DropdownMenuEntry<String>(
            value: t,
            label: t,
            style: ButtonStyle(
                textStyle:
                    WidgetStateProperty.all(const TextStyle(fontSize: 18)))))
        .toList(growable: false);

    final ownGoalPlayer = Player(
      id: -2,
      teamId: event.team.id,
      seasonId: widget.season.id,
      firstName: 'Own',
      lastName: 'Goal',
      number: -1,
    );

    showModalBottomSheet(
        // ignore: use_build_context_synchronously
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) {
          final loc = AppLocalizations.of(context)!;
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return Card(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: SingleChildScrollView(
                      child: Column(children: [
                        RadioGroup(
                            groupValue: event!.team == _game.homeTeam ? 0 : 1,
                            onChanged: (value) {
                              setModalState(() {
                                if (value == 0) {
                                  event!.team = _game.homeTeam;
                                  playerEntries = homePlayerEntries;
                                } else {
                                  event!.team = _game.awayTeam;
                                  playerEntries = awayPlayerEntries;
                                }
                              });
                            },
                            child: Row(children: [
                              Expanded(
                                  child: RadioListTile<int>(
                                title: Text(_game.homeTeam.shortName),
                                value: 0,
                              )),
                              Expanded(
                                  child: RadioListTile<int>(
                                title: Text(_game.awayTeam.shortName),
                                value: 1,
                              )),
                            ])),
                        const SizedBox(height: 30),
                        DropdownMenu(
                            initialSelection: initialStatus,
                            onSelected: (eventPeriod) async {
                              int period = 1;

                              if (eventPeriod == '1st Half') {
                                period = 1;
                              } else if (eventPeriod == '2nd Half') {
                                period = 3;
                              } else if (eventPeriod == '1st Half Overtime') {
                                period = 5;
                              } else if (eventPeriod == '2nd Half Overtime') {
                                period = 7;
                              } else if (eventPeriod == 'Penalty Kicks') {
                                period = 8;
                              }
                              setModalState(() {
                                event!.eventPeriod = period;
                              });
                            },
                            width: double.infinity,
                            textStyle: const TextStyle(fontSize: 18),
                            label: Text(loc.selectPeriod,
                                style: TextStyle(fontSize: 18)),
                            dropdownMenuEntries: eventPeriods),
                        const SizedBox(height: 30),
                        DropdownMenu(
                            initialSelection: event.eventType,
                            onSelected: (eventType) async {
                              String type = eventType!.replaceAll(' ', '');
                              int data = 0;

                              if (type == 'YellowCard') {
                                type = 'Card';
                              } else if (type == '2ndYellowCard') {
                                type = 'Card';
                                data = 1;
                              } else if (type == 'RedCard') {
                                type = 'Card';
                                data = 2;
                              }

                              setModalState(() {
                                event!.eventType = type;
                                event.eventData = data;
                              });
                            },
                            width: double.infinity,
                            textStyle: const TextStyle(fontSize: 18),
                            label: Text(loc.selectEventType,
                                style: TextStyle(fontSize: 18)),
                            dropdownMenuEntries: eventEntries),
                        Visibility(
                            visible: playerEntries.isNotEmpty,
                            child: const SizedBox(height: 30)),
                        Visibility(
                            visible: playerEntries.isNotEmpty,
                            child: DropdownMenu(
                                enabled: (event.eventType != 'Corner' &&
                                        playerEntries.isNotEmpty) ||
                                    (event.eventType == 'Shot' &&
                                        event.eventData ==
                                            ShotResult.goal.index),
                                menuHeight: 700,
                                initialSelection: event.player,
                                onSelected: (player) async {
                                  setModalState(() {
                                    event!.player = player;
                                  });
                                },
                                width: double.infinity,
                                textStyle: const TextStyle(fontSize: 18),
                                label: const Text('Select Player',
                                    style: TextStyle(fontSize: 18)),
                                dropdownMenuEntries: playerEntries)),
                        const SizedBox(height: 30),
                        Visibility(
                            visible: event.eventType == 'Shot' ||
                                event.eventType == 'PenaltyKick',
                            child: DropdownMenu(
                                initialSelection: initialShotResult,
                                onSelected: (shotResult) async {
                                  int result = -1;

                                  if (shotResult == 'Goal') {
                                    result = 0;
                                  } else if (shotResult == 'Saved') {
                                    result = 1;
                                  } else if (shotResult == 'Post') {
                                    result = 2;
                                  } else if (shotResult == 'Off Target') {
                                    result = 3;
                                  } else if (shotResult == 'Blocked') {
                                    result = 4;
                                  }

                                  setModalState(() {
                                    event!.eventData = result;
                                  });
                                },
                                width: double.infinity,
                                textStyle: const TextStyle(fontSize: 18),
                                label: const Text('Shot Result',
                                    style: TextStyle(fontSize: 18)),
                                dropdownMenuEntries: shotResultEntries)),
                        const SizedBox(height: 20),
                        Visibility(
                            visible: ((event.eventType == 'Shot' ||
                                        event.eventType == 'PenaltyKick') &&
                                    event.eventData == ShotResult.goal.index) ||
                                event.eventType == 'Assist',
                            child: Row(children: [
                              Expanded(
                                  child: TextFormField(
                                      initialValue:
                                          event.eventMinute.toString(),
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                          labelText:
                                              'Game Minute (Goals and Assists Only)'),
                                      onChanged: (minute) =>
                                          event!.eventMinute =
                                              int.tryParse(minute) ?? -1)),
                              Expanded(
                                  child: Checkbox(
                                      value: event.player?.id == -2,
                                      onChanged: (value) {
                                        setModalState(() {
                                          event!.player = value!
                                              ? ownGoalPlayer
                                              : event.player;
                                        });
                                      })),
                              const Text('Own Goal')
                            ])),
                        const SizedBox(height: 20),
                        TextFormField(
                            initialValue: event.eventUrls,
                            decoration: const InputDecoration(
                                labelText: 'Video or photo URL'),
                            onChanged: (url) => event!.eventUrls = url),
                        const SizedBox(height: 20),
                        Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              TextButton(
                                  onPressed: () async {
                                    if (mounted) {
                                      final canSave = ((event!.eventType ==
                                                      'Shot' ||
                                                  event.eventType ==
                                                      'PenaltyKick') &&
                                              (event.eventData ==
                                                      ShotResult.goal.index &&
                                                  event.eventMinute > 0)) ||
                                          (event.eventType != 'Shot' ||
                                              event.eventType != 'PenaltyKick');
                                      if (!canSave) {
                                        return;
                                      }

                                      Navigator.pop(context);
                                      setState(() {});

                                      await _saveEvent(event);
                                    }
                                  },
                                  child: Text(loc.save,
                                      style: TextStyle(fontSize: 20))),
                              TextButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                  },
                                  child: Text(loc.cancel,
                                      style: TextStyle(fontSize: 20)))
                            ])
                      ]),
                    )));
          });
        });
  }

  Future<void> _advanceGame() async {
    await _game.advanceGame();

    final periodEvent = Period(
        id: -1,
        index: -1,
        player: null,
        team: _game.homeTeam,
        game: _game,
        seasonId: _game.seasonId,
        eventType: 'Period',
        eventMinute: -1,
        eventPeriod: _game.gameStatus.index,
        eventUrls: '',
        eventData: _game.gameStatus.index);
    await _saveEvent(periodEvent);

    setState(() {});
  }

  Future<bool> _saveEvent(GameEvent event) async {
    if (event.eventType == 'Shot' &&
        event.eventData == ShotResult.goal.index &&
        event.eventMinute <= 0) {
      return false;
    }

    if (event.eventPeriod >= 0) {
      if (event.id == -1) {
        final newId = DateTime.now().millisecondsSinceEpoch;
        await DatabaseService.instance.insert('Events', {
          'id': newId,
          'index': newId,
          'playerId': event.player?.id ?? -1,
          'teamId': event.team.id,
          'gameId': event.game.id,
          'seasonId': event.game.seasonId,
          'teamId_seasonId': '${event.team.id}_${event.game.seasonId}',
          'eventType': event.eventType,
          'eventMinute': event.eventMinute,
          'eventPeriod': event.eventPeriod,
          'eventData': event.eventData,
          'eventUrls': event.eventUrls
        });
      } else {
        await DatabaseService.instance.update(
            'Events',
            {
              'playerId': event.player?.id ?? -1,
              'teamId': event.team.id,
              'gameId': event.game.id,
              'seasonId': event.game.seasonId,
              'teamId_seasonId': '${event.team.id}_${event.game.seasonId}',
              'eventType': event.eventType,
              'eventMinute': event.eventMinute,
              'eventPeriod': event.eventPeriod,
              'eventData': event.eventData,
              'eventUrls': event.eventUrls
            },
            key: event.id.toString());
      }

      await _game.updateScore();

      // Only send tweets when game is in progress (but NOT for goals - those are sent after assist dialog)
      final gameInProgress = _game.gameStatus != GameStatus.notStarted &&
          _game.gameStatus != GameStatus.gameFinal &&
          _game.gameStatus != GameStatus.gameFinalOT &&
          _game.gameStatus != GameStatus.gameFinalPKs;

      // Don't tweet goals here - they'll be tweeted after assist dialog
      if (event.shouldTweet && !event.isGoalEvent && gameInProgress) {
        final tweetText = event.tweetText(_game);
        if (tweetText.isNotEmpty) {
          if (mounted) {
            // Show tweet preview dialog - it handles initialization and sending internally
            await TweetPreviewDialog.show(
              context,
              initialText: tweetText,
              teamId: widget.season.teamId,
              team: widget.season.team,
            );
          }
        }
      }

      if (event.eventType == 'Shot' &&
          event.eventData == ShotResult.onTargetSave.index) {
        // Auto-create a Save event
        final team = event.team.id == _game.homeTeam.id
            ? _game.awayTeam
            : _game.homeTeam;
        final saveEvent = Save(
            id: -1,
            index: -1,
            player: null,
            team: team,
            game: _game,
            seasonId: _game.seasonId,
            eventType: 'Save',
            eventMinute: event.eventMinute,
            eventPeriod: event.eventPeriod,
            eventUrls: event.eventUrls ?? '',
            eventData: event.id);
        setState(() {
          _autoCreateSave = saveEvent;
        });
      } else if (event.isGoalEvent &&
          event.player?.id != -2 &&
          event.team.id == widget.season.teamId) {
        // Auto-create an Assist event for goals by our team (excluding own goals)
        final assistEvent = Assist(
            id: -1,
            index: -1,
            player: null,
            team: event.team,
            game: _game,
            seasonId: _game.seasonId,
            eventType: 'Assist',
            eventMinute: event.eventMinute,
            eventPeriod: event.eventPeriod,
            eventUrls: event.eventUrls ?? '',
            eventData: event.id);
        setState(() {
          _autoCreateAssist = assistEvent;
        });
      } else {
        setState(() {});
      }

      EventService().eventEmitter.emit('eventCreated');

      return true;
    }

    return false;
  }
}
