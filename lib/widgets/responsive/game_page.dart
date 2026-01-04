import 'package:eventify/eventify.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/adhoc_tweet_dialog.dart';
import 'package:team_sync/widgets/breadcrumbs.dart';
import 'package:team_sync/widgets/event_stream_widget.dart';
import 'package:team_sync/widgets/match_result_card.dart';
import 'package:team_sync/widgets/responsive/views/game_view.dart';
import 'package:team_sync/widgets/scoreboard_widget.dart';
import 'package:team_sync/widgets/standard_appbar.dart';

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
              ScoreboardWidget(
                  game: _game,
                  season: resolvedSeason,
                  teamId: resolvedSeason.teamId),
              // Responsive layout
              Expanded(
                child: isTabletOrLarger
                    ? _buildTabletLayout(
                        gameView, gameStatsView, width, resolvedSeason, loc)
                    : gameView, // Mobile: just the game view
              ),
            ],
          ),
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
        if (!isTabletOrLarger)
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

    // In-progress game actions (mobile and tablet)
    if (_game.gameStatus.index < 9) {
      return [
        // Stats button (mobile phone only)
        if (!isTabletOrLarger)
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
        // Tweet button
        GestureDetector(
          onTap: () {
            AdhocTweetDialog.show(context,
                teamId: season.teamId, team: season.team);
          },
          child: const Padding(
            padding: EdgeInsets.all(5),
            child: Icon(Icons.send, size: 24),
          ),
        ),
        // Advance game button
        GestureDetector(
          onTap: () async {
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
          },
          child: const Padding(
            padding: EdgeInsets.all(5),
            child: Icon(Icons.add),
          ),
        ),
        // End game button
        GestureDetector(
          onTap: () async {
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
          },
          child: const Padding(
            padding: EdgeInsets.all(5),
            child: Icon(Icons.done, size: 24),
          ),
        ),
      ];
    }

    return [];
  }
}
