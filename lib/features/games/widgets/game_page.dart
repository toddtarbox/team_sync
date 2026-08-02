import 'dart:async';
import 'package:eventify/eventify.dart';
import 'package:photo_view/photo_view.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/features/games/models/game.dart';
import 'package:team_sync/features/game_events/models/game_event.dart';
import 'package:team_sync/features/seasons/models/season.dart';
import 'package:team_sync/core/services/database_service.dart';
import 'package:team_sync/features/data_import/services/bound_game_stats_importer_service.dart';
import 'package:team_sync/features/data_import/services/data_importer_service.dart';
import 'package:team_sync/features/data_import/models/import_models.dart';
import 'package:team_sync/features/social_media/widgets/adhoc_tweet_dialog.dart';
import 'package:team_sync/core/widgets/breadcrumbs.dart';
import 'package:team_sync/features/game_events/widgets/event_stream_widget.dart';
import 'package:team_sync/features/seasons/widgets/match_result_card.dart';
import 'package:team_sync/features/games/widgets/game_view.dart';
import 'package:team_sync/features/games/widgets/scoreboard_widget.dart';
import 'package:team_sync/core/widgets/standard_appbar.dart';
import 'package:team_sync/features/lineup/widgets/lineup_generator.dart';
import 'package:team_sync/features/games/widgets/box_score_widget.dart';
import 'package:team_sync/features/games/utils/game_action_helpers.dart';
import 'package:team_sync/features/game_events/services/speech_event_service.dart';

/// Unified responsive game page that works for mobile, tablet, and desktop
class GamePage extends StatefulWidget {
  final Season? season; // nullable to support deep links
  final Game game;
  final String? databaseId; // Add database ID for deep links

  const GamePage({super.key, required this.game, this.season, this.databaseId});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final EventEmitter _eventEmitter = EventEmitter();

  late Game _game;
  Future<Season?>? _seasonFuture;
  Season? _loadedSeason;
  bool _isStatsPanelOpen = false;
  bool _showBoxScore = true;
  bool _isListening = false;
  String _speechText = '';
  Completer<GameEvent?>? _speechCompleter;

  @override
  void initState() {
    super.initState();
    _game = widget.game;

    if (widget.season == null) {
      debugPrint(
          'GamePage: No season provided, loading for game ${widget.game.id}');
      _seasonFuture = _loadSeasonForGame();
    } else {
      debugPrint(
          'GamePage: Season provided: ${widget.season!.name} (ID: ${widget.season!.id})');
      _seasonFuture = _ensureSeasonLoaded(widget.season!);
    }
  }

  Future<Season> _ensureSeasonLoaded(Season season) async {
    try {
      // Check if team is initialized to verify the season object is fully loaded
      // ignore: unnecessary_statements
      season.team;
      return season;
    } catch (e) {
      debugPrint(
          'GamePage: Season passed via extra was not fully loaded. Loading now... Error: $e');
      await season.load();
      return season;
    }
  }

  Future<Season?> _loadSeasonForGame() async {
    try {
      // Use databaseId from widget (passed by router) instead of parsing URL
      final dbId = widget.databaseId;
      debugPrint('GamePage: _loadSeasonForGame started. dbId: $dbId');

      if (dbId != null && dbId.isNotEmpty) {
        // Check if database needs to be opened
        if (DatabaseService.instance.publicShareId != dbId) {
          debugPrint(
              'GamePage: Opening database inside GamePage: $dbId (Current: ${DatabaseService.instance.publicShareId})');
          // Add timeout to prevent infinite waiting
          final opened =
              await DatabaseService.instance.openFromId(dbId).timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              debugPrint('GamePage: Database open timed out');
              return false;
            },
          );

          if (!opened) {
            throw Exception(
                'Could not open shared database. The link may be invalid or expired.');
          }

          // Give database a moment to fully initialize
          await Future.delayed(const Duration(milliseconds: 500));
        } else {
          debugPrint('GamePage: Database already open for $dbId');
        }
      } else {
        throw Exception(
            'No shared database ID provided. Cannot load game data.');
      }

      // Now query for the season with timeout
      debugPrint('GamePage: Querying for season ${widget.game.seasonId}');
      final results = await DatabaseService.instance
          .query('Seasons', orderByChild: 'id', equalTo: widget.game.seasonId)
          .timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('GamePage: Season query timed out');
          return [];
        },
      );

      debugPrint('GamePage: Season query results count: ${results.length}');

      if (results.isEmpty) {
        throw Exception(
            'Season not found in database. The game data may not exist.');
      }

      final season = Season.fromMap(results.first);
      debugPrint('GamePage: Season map parsed. Loading details...');

      // Load season data with timeout
      await season.load().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          debugPrint('GamePage: Season data loading timed out');
          throw Exception('Season loading timed out');
        },
      );

      debugPrint(
          'GamePage: Season fully loaded. Players: ${season.players.length}');

      _loadedSeason = season;
      return season;
    } catch (e) {
      debugPrint('GamePage: Error loading season: $e');
      rethrow; // Let FutureBuilder handle the error
    }
  }

  Future<void> _importStatsFromBound(BuildContext context, int myTeamId) async {
    final url = _game.gameLinks;
    if (url == null || url.isEmpty) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(loc.importStats),
          content: Text(loc.importStatsConfirm),
          actions: [
            TextButton(
              child: Text(loc.cancel),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: Text(loc.importStatsButton),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    // Show loading
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      debugPrint('Importing game stats from: $url');
      final rows = await BoundGameStatsImporterService().parseGameStats(
        url: url,
        gameId: _game.id,
        teamId: myTeamId,
        seasonId: _game.seasonId,
      );

      debugPrint(
          'Parsed ${rows.length} event rows. Clearing old events and importing...');

      // Clear existing events for this game
      await DatabaseService.instance
          .delete('Events', orderByChild: 'gameId', equalTo: _game.id);

      // Import via DataImporter
      final result = await DataImporterService().importData(
        rows: rows,
        fileName: 'Manual Game Stats',
        entityType: 'GameEvent',
        // We use disableValidation: true largely because validating rigid constraints on events might be tricky
        // But let's try with default config first or minimal config.
        // Actually, let's keep validation on but handle errors.
        config: const ImportConfig(
          batchSize: 50,
        ),
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(
                'Imported ${result.successCount} events. ${result.errorCount} errors.')));
        // Refresh game data?
        // Trigger a reload or event emit?
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _showPhoto(BuildContext context, String? imageUrl) async {
    if (imageUrl == null || imageUrl.isEmpty) {
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: PhotoView(
            imageProvider: NetworkImage(imageUrl),
          ),
        );
      },
    );
  }

  Future<void> _processVoiceEvent(String text, Season resolvedSeason) async {
    setState(() {
      _isListening = false;
    });
    ScaffoldMessenger.of(context).clearSnackBars();

    if (text.isEmpty || text == 'Listening...') {
      if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
        _speechCompleter!.complete(null);
      }
      return;
    }

    if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
      _eventEmitter.emit('createEventSpeech', null, _speechCompleter!.future);

      // small delay so UI can show the spinner for at least a fraction of a second
      await Future.delayed(const Duration(milliseconds: 300));

      final event = await SpeechEventService.instance
          .parseEventTranscript(text, _game, resolvedSeason.id);
      _speechCompleter!.complete(event);

      if (event == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Could not understand event. Try again.')),
        );
      }
    }

    _speechText = '';
  }

  Future<void> _startVoiceEventMode(Season resolvedSeason) async {
    setState(() {
      _isListening = true;
      _speechText = 'Listening...';
    });

    _speechCompleter = Completer<GameEvent?>();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Listening for game event... (e.g. "Goal Todd Tarbox")'),
        duration: Duration(seconds: 15),
      ),
    );

    await SpeechEventService.instance.startListening(
      onResult: (text, isFinal) async {
        setState(() {
          _speechText = text;
        });

        if (isFinal) {
          await _processVoiceEvent(text, resolvedSeason);
        }
      },
      onError: (error) {
        setState(() {
          _isListening = false;
        });
        if (_speechCompleter != null && !_speechCompleter!.isCompleted) {
          _speechCompleter!.complete(null);
        }
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Speech Error: $error')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final width = MediaQuery.of(context).size.width;
    final isTabletOrLarger =
        ResponsiveBreakpoints.of(context).largerThan(MOBILE);

    return FutureBuilder<Season?>(
      future: _seasonFuture,
      builder: (context, seasonSnapshot) {
        // Show loading spinner while waiting
        if (seasonSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: buildStandardAppBar(
              context: context,
              team: null,
              title: Text(_game.displayName(widget.game.seasonId),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text(
                    'Loading...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          );
        }

        // Check for errors
        if (seasonSnapshot.hasError) {
          return Scaffold(
            appBar: buildStandardAppBar(
              context: context,
              team: null,
              title: Text(_game.displayName(widget.game.seasonId),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${seasonSnapshot.error}',
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _seasonFuture = _loadSeasonForGame();
                      });
                    },
                    child: Text(loc.retry),
                  ),
                ],
              ),
            ),
          );
        }

        final Season? resolvedSeason =
            seasonSnapshot.data ?? widget.season ?? _loadedSeason;

        // Show error if season couldn't be loaded
        if (resolvedSeason == null) {
          return Scaffold(
            appBar: buildStandardAppBar(
              context: context,
              team: null,
              title: Text(_game.displayName(widget.game.seasonId),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.warning_outlined,
                      size: 48, color: Colors.orange),
                  const SizedBox(height: 16),
                  const Text(
                    'Could not load season data',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'The database may not be accessible or the season may not exist.',
                    style: TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _seasonFuture = _loadSeasonForGame();
                      });
                    },
                    child: Text(loc.retry),
                  ),
                ],
              ),
            ),
          );
        }

        final gameView = GameView(
          season: resolvedSeason,
          game: _game,
          eventEmitter: _eventEmitter,
        );

        final gameStatsView = EventStreamWidget(
          game: _game,
          teamId: resolvedSeason.teamId,
        );

        return Scaffold(
          appBar: buildStandardAppBar(
            context: context,
            team: resolvedSeason.team,
            title: Text(_game.displayName(resolvedSeason.teamId),
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            actions: _buildAppBarActions(
                context, loc, resolvedSeason, isTabletOrLarger),
          ),
          body: Column(
            children: [
              if (kIsWeb)
                Breadcrumbs(
                  items: buildTeamBreadcrumbs(
                    databaseId: DatabaseService.instance.publicShareId ?? '',
                    teamName: resolvedSeason.team.fullName,
                    seasonName: resolvedSeason.name,
                    seasonId: resolvedSeason.id,
                    gameName: _game.displayName(resolvedSeason.teamId),
                  ),
                ),
              // Game Header Area: Overlay Scoreboard on Image if available
              if (_game.imageUrl != null && _game.imageUrl!.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _showPhoto(context, _game.imageUrl);
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 250),
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(_game.imageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withOpacity(0.8),
                            Colors.transparent,
                          ],
                          stops: const [0.0, 0.6],
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          ScoreboardWidget(
                            game: _game,
                            season: resolvedSeason,
                            teamId: resolvedSeason.teamId,
                            compact: true,
                            transparentBackground: true,
                            margin: const EdgeInsets.only(
                                left: 16, right: 16, top: 16),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _showBoxScore
                                ? BoxScoreWidget(
                                    game: _game,
                                    season: resolvedSeason,
                                  )
                                : const SizedBox(
                                    width: double.infinity, height: 0),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    ScoreboardWidget(
                      game: _game,
                      season: resolvedSeason,
                      teamId: resolvedSeason.teamId,
                      compact: false,
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _showBoxScore
                          ? BoxScoreWidget(
                              game: _game,
                              season: resolvedSeason,
                            )
                          : const SizedBox(width: double.infinity, height: 0),
                    ),
                  ],
                ),
              // Responsive layout
              Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (ScrollNotification notification) {
                    if (notification.metrics.axis == Axis.vertical) {
                      if (notification is UserScrollNotification) {
                        if (notification.direction == ScrollDirection.reverse) {
                          if (_showBoxScore)
                            setState(() => _showBoxScore = false);
                        } else if (notification.direction ==
                            ScrollDirection.forward) {
                          if (!_showBoxScore)
                            setState(() => _showBoxScore = true);
                        }
                      }
                      if (notification.metrics.pixels <= 0 && !_showBoxScore) {
                        setState(() => _showBoxScore = true);
                      }
                    }
                    return false;
                  },
                  child: isTabletOrLarger
                      ? _buildTabletLayout(
                          gameView, gameStatsView, width, resolvedSeason, loc)
                      : gameView, // Mobile: just the game view
                ),
              ),
            ],
          ),
          floatingActionButton: !kIsWeb
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    FloatingActionButton(
                      heroTag: 'voiceEventButton',
                      backgroundColor: _isListening
                          ? Colors.red
                          : Theme.of(context).colorScheme.primary,
                      onPressed: () async {
                        if (_isListening) {
                          SpeechEventService.instance.stopListening();
                          await _processVoiceEvent(_speechText, resolvedSeason);
                        } else {
                          await _startVoiceEventMode(resolvedSeason);
                        }
                      },
                      child: Icon(_isListening ? Icons.mic_off : Icons.mic),
                    ),
                    const SizedBox(height: 16),
                    FloatingActionButton(
                      heroTag: 'addEventButton',
                      child: const Icon(Icons.add),
                      onPressed: () async {
                        if (_game.gameStatus == GameStatus.notStarted ||
                            _game.gameStatus == GameStatus.halftime ||
                            _game.gameStatus == GameStatus.overtimeNotStarted ||
                            _game.gameStatus == GameStatus.overtimeHalftime) {
                          await _game.advanceGame();
                          if (mounted) {
                            setState(() {});
                          }
                        }
                        _eventEmitter.emit('createEvent');
                      },
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }

  // Build tablet/desktop layout with optional stats panel
  Widget _buildTabletLayout(
    Widget gameView,
    Widget gameStatsView,
    double width,
    Season season,
    AppLocalizations loc,
  ) {
    return Stack(
      children: [
        // Full-width game view
        gameView,
        // Sliding stats panel from right
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: 0,
          bottom: 0,
          right: _isStatsPanelOpen ? 0 : -width * 0.45,
          width: width * 0.45,
          child: Material(
            elevation: 8,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  // Panel header
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: season.team.color1,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          loc.statistics,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              _isStatsPanelOpen = false;
                            });
                          },
                          tooltip: loc.close,
                        ),
                      ],
                    ),
                  ),
                  // Stats content
                  Expanded(child: gameStatsView),
                ],
              ),
            ),
          ),
        ),
        // Floating button to open stats panel
        if (!_isStatsPanelOpen)
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'statsButton',
              backgroundColor: season.team.color1,
              onPressed: () {
                setState(() {
                  _isStatsPanelOpen = true;
                });
              },
              tooltip: loc.statistics,
              child: const Icon(Icons.analytics),
            ),
          ),
      ],
    );
  }

  // Build app bar actions based on screen size and game status
  List<Widget> _buildAppBarActions(
    BuildContext context,
    AppLocalizations loc,
    Season season,
    bool isTabletOrLarger,
  ) {
    // Mobile app (not web): Show match report and stats buttons for completed games
    if (!kIsWeb && _game.gameStatus.index >= 9) {
      return [
        // Match Report button
        GestureDetector(
          onTap: () {
            MatchResultCard.showMatchResultDialog(
              context,
              season: season,
              game: _game,
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(5),
            child: Icon(Icons.newspaper, size: 24),
          ),
        ),

        // Stats button (mobile phone only)
        if (!kIsWeb)
          GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (context) => SizedBox(
                  height: MediaQuery.of(context).size.height * 0.9,
                  child: EventStreamWidget(
                    game: _game,
                    teamId: season.teamId,
                  ),
                ),
              );
            },
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.analytics, size: 24),
            ),
          ),
        if (_game.gameLinks != null && _game.gameLinks!.contains('gobound.com'))
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Import Stats',
            onPressed: () => _importStatsFromBound(context, season.teamId),
          ),
      ];
    }

    // Web on mobile screen for completed games: Show stats button
    if (kIsWeb && !isTabletOrLarger && _game.gameStatus.index >= 9) {
      return [
        // Stats button
        GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => SizedBox(
                height: MediaQuery.of(context).size.height * 0.9,
                child: EventStreamWidget(
                  game: _game,
                  teamId: season.teamId,
                ),
              ),
            );
          },
          child: const Padding(
            padding: EdgeInsets.all(5),
            child: Icon(Icons.analytics, size: 24),
          ),
        ),
      ];
    }

    // Web Desktop (implicit in remaining logic or added generally)
    if (kIsWeb && isTabletOrLarger) {
      // We want to add the Import button to web desktop too
      // But _buildAppBarActions returns specific lists.
      // Current 'Web on mobile' block above returns early.
      // If isTabletOrLarger, it falls through to next blocks or empty.
      // The existing code doesn't explicitly handle Web Desktop Actions in a dedicated block that returns.
      // It falls through to 'In-progress game' or empty.
      // We should add a generic check or add to existing blocks.

      final actions = <Widget>[];
      return actions;
    }

    // In-progress game actions (mobile and tablet)
    if (!kIsWeb && _game.gameStatus.index < 9) {
      return [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            switch (value) {
              case 'advance':
                await showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: Text(loc.advanceGame),
                      content: const Text(
                          "Are you sure you want to advance to the next period?"),
                      actions: [
                        TextButton(
                          child: Text(loc.continueText),
                          onPressed: () async {
                            Navigator.pop(context, true);
                            _eventEmitter.emit('advanceGame');
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
                break;
              case 'end':
                final selectedStatus = await showDialog<int>(
                  context: context,
                  builder: (context) {
                    int? status = 9;
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          title: Text(loc.endGame),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RadioListTile(
                                title: Text(loc.finalText),
                                value: 9,
                                groupValue: status,
                                onChanged: (i) {
                                  setState(() {
                                    status = i;
                                  });
                                },
                              ),
                              RadioListTile(
                                title: Text(loc.finalOTText),
                                value: 10,
                                groupValue: status,
                                onChanged: (i) {
                                  setState(() {
                                    status = i;
                                  });
                                },
                              ),
                              RadioListTile(
                                title: Text(loc.finalPKsText),
                                value: 11,
                                groupValue: status,
                                onChanged: (i) {
                                  setState(() {
                                    status = i;
                                  });
                                },
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              child: Text(loc.continueText),
                              onPressed: () {
                                Navigator.pop(context, status);
                              },
                            ),
                            TextButton(
                              child: Text(loc.cancel),
                              onPressed: () {
                                Navigator.pop(context, null);
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
                if (selectedStatus != null) {
                  _eventEmitter.emit('endGame', null, selectedStatus);
                }
                break;
              case 'reset':
                final bool? confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('Reset Game'),
                      content: const Text(
                          "Are you sure you want to reset this game back to 'Not Started'? All events logged for this game will be deleted. This cannot be undone."),
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
                if (confirm == true) {
                  await _game.resetGame();
                  if (mounted) {
                    setState(() {});
                  }
                }
                break;
              case 'lineup':
                LineupGenerator.showLineupDialog(
                  context,
                  team: season.team,
                  players: season.players,
                  game: _game,
                );
                break;
              case 'live_link':
                GameActionHelpers.editLiveLink(
                  context: context,
                  game: _game,
                  team: season.team,
                  onUpdate: () {
                    if (mounted) setState(() {});
                  },
                );
                break;
              case 'tweet_preview':
                GameActionHelpers.tweetGameDay(
                  context: context,
                  game: _game,
                  team: season.team,
                  onUpdate: () {
                    if (mounted) setState(() {});
                  },
                );
                break;
              case 'tweet':
                AdhocTweetDialog.show(context,
                    teamId: season.teamId, team: season.team);
                break;
              case 'stats':
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  builder: (context) => SizedBox(
                    height: MediaQuery.of(context).size.height * 0.9,
                    child: EventStreamWidget(
                      game: _game,
                      teamId: season.teamId,
                    ),
                  ),
                );
                break;
            }
          },
          itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
            PopupMenuItem<String>(
              value: 'advance',
              child: ListTile(
                leading: const Icon(Icons.add),
                title: Text(loc.advanceGame),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem<String>(
              value: 'end',
              child: ListTile(
                leading: const Icon(Icons.done),
                title: Text(loc.endGame),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem<String>(
              value: 'reset',
              child: ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Reset Game'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'lineup',
              child: ListTile(
                leading: const Icon(Icons.sports_soccer),
                title: const Text('Generate Lineup'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem<String>(
              value: 'live_link',
              child: ListTile(
                leading: const Icon(Icons.link),
                title: Text(loc.setLiveLink),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem<String>(
              value: 'tweet_preview',
              child: ListTile(
                leading: const Icon(Icons.send_time_extension),
                title: Text(loc.tweetGameDay),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            PopupMenuItem<String>(
              value: 'tweet',
              child: ListTile(
                leading: const Icon(Icons.send),
                title: const Text('Tweet Update'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (!isTabletOrLarger)
              PopupMenuItem<String>(
                value: 'stats',
                child: ListTile(
                  leading: const Icon(Icons.analytics),
                  title: Text(loc.statistics),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
          ],
        ),
      ];
    }

    return [];
  }
}
