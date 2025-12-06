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
import 'package:team_sync/widgets/match_result_card.dart';
import 'package:team_sync/widgets/responsive/mobile/mobile_game_stats_page.dart';
import 'package:team_sync/widgets/responsive/views/game_stats_view.dart';
import 'package:team_sync/widgets/responsive/views/game_view.dart';
import 'package:team_sync/widgets/scoreboard_widget.dart';
import 'package:team_sync/widgets/standard_appbar.dart';

/// Unified responsive game page that works for mobile, tablet, and desktop
class GamePage extends StatefulWidget {
  final Season? season; // nullable to support deep links
  final Game game;

  const GamePage({super.key, required this.game, this.season});

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
    _game = widget.game;

    if (widget.season == null) {
      _seasonFuture = _loadSeasonForGame();
    } else {
      _seasonFuture = Future.value(widget.season);
    }

    super.initState();
  }

  Future<Season?> _loadSeasonForGame() async {
    try {
      // Ensure the database is opened if a shared database id exists in the URL
      try {
        final segments = Uri.base.pathSegments;
        final teamIndex = segments.indexOf('team');
        if (teamIndex != -1 && teamIndex + 1 < segments.length) {
          final dbId = segments[teamIndex + 1];
          if (DatabaseService.instance.publicShareId == null ||
              DatabaseService.instance.publicShareId != dbId) {
            await DatabaseService.instance.openFromId(dbId);
          }
        }
      } catch (_) {}
      final results = await DatabaseService.instance
          .query('Seasons', orderByChild: 'id', equalTo: widget.game.seasonId);
      if (results.isEmpty) return null;
      final season = Season.fromMap(results.first);
      await season.load();
      _loadedSeason = season;
      return season;
    } catch (e) {
      debugPrint('Error loading season for game: $e');
      return null;
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
        if (seasonSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: buildStandardAppBar(
              context: context,
              team: null,
              title: Text(_game.displayName(widget.game.seasonId),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final Season? resolvedSeason =
            seasonSnapshot.data ?? widget.season ?? _loadedSeason;

        if (resolvedSeason == null) {
          return Scaffold(
            appBar: buildStandardAppBar(
              context: context,
              team: null,
              title: Text(_game.displayName(widget.game.seasonId),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            body: const Center(
              child: Text('Error: Could not load season'),
            ),
          );
        }

        final gameView = GameView(
          season: resolvedSeason,
          game: _game,
          eventEmitter: _eventEmitter,
        );

        final gameStatsView = GameStatsView(
          season: resolvedSeason,
          game: _game,
          eventEmitter: _eventEmitter,
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
              child: const Icon(Icons.analytics),
              tooltip: loc.statistics,
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
    // Mobile: Show stats and match report buttons for completed games
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
        // Stats button
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (context) =>
                    MobileGameStatsPage(season: season, game: _game)));
          },
          child: const Padding(
            padding: EdgeInsets.all(5),
            child: Icon(Icons.paste, size: 24),
          ),
        ),
      ];
    }

    // In-progress game actions (mobile and tablet)
    if (_game.gameStatus.index < 9) {
      return [
        // Stats button (mobile only)
        if (!isTabletOrLarger)
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) =>
                      MobileGameStatsPage(season: season, game: _game)));
            },
            child: const Padding(
              padding: EdgeInsets.all(5),
              child: Icon(Icons.paste, size: 24),
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
