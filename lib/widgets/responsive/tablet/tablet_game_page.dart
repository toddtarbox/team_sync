import 'package:eventify/eventify.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/common_page_header.dart';
import 'package:team_sync/widgets/responsive/views/game_stats_view.dart';
import 'package:team_sync/widgets/responsive/views/game_view.dart';
import 'package:team_sync/widgets/scoreboard.dart';
import 'package:team_sync/widgets/standard_appbar.dart';

class TabletGamePage extends StatefulWidget {
  final Season? season; // made nullable to support deep links
  final Game game;

  const TabletGamePage({super.key, required this.game, this.season});

  @override
  State<TabletGamePage> createState() => _TabletGamePageState();
}

class _TabletGamePageState extends State<TabletGamePage> {
  final EventEmitter _eventEmitter = EventEmitter();

  late Game _game;
  Future<Season?>? _seasonFuture; // will load if widget.season is null
  Season? _loadedSeason;

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
    final width = MediaQuery.of(context).size.width;

    // Resolve season via FutureBuilder so the page can be opened directly via deep link
    return FutureBuilder<Season?>(
      future: _seasonFuture,
      builder: (context, seasonSnapshot) {
        if (seasonSnapshot.connectionState == ConnectionState.waiting) {
          // Show a minimal scaffold while loading the season
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
          // Season could not be loaded - show an error scaffold
          return Scaffold(
            appBar: buildStandardAppBar(
              context: context,
              team: null,
              title: Text(_game.displayName(widget.game.seasonId),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            body: Center(child: Text('Season not found')),
          );
        }

        final gameView = GameView(
            season: resolvedSeason, game: _game, eventEmitter: _eventEmitter);

        final gameStatsView = GameStatsView(
            season: resolvedSeason, game: _game, eventEmitter: _eventEmitter);

        return Scaffold(
            appBar: buildStandardAppBar(
              context: context,
              team: resolvedSeason.team,
              title: Text(_game.displayName(resolvedSeason.teamId),
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              actions: _game.gameStatus.index < 9
                  ? [
                      GestureDetector(
                          onTap: () async {
                            await showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: const Text("Advance Game"),
                                    content: const Text(
                                        "Are you sure you want to advance to the next period?"),
                                    actions: [
                                      TextButton(
                                        child: const Text("Continue"),
                                        onPressed: () async {
                                          Navigator.pop(context, true);
                                          _eventEmitter.emit('advanceGame');
                                          setState(() {});
                                        },
                                      ),
                                      TextButton(
                                        child: const Text("Cancel"),
                                        onPressed: () {
                                          Navigator.pop(context, false);
                                        },
                                      ),
                                    ],
                                  );
                                });
                          },
                          child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(Icons.add, size: 24))),
                      GestureDetector(
                          onTap: () async {
                            final selectedStatus = await showDialog<int>(
                                context: context,
                                builder: (context) {
                                  int? status = 9;

                                  return StatefulBuilder(builder:
                                      (BuildContext context,
                                          StateSetter setModalState) {
                                    return AlertDialog(
                                      title: const Text('End Game'),
                                      content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            RadioListTile(
                                              title: const Text('Final'),
                                              value: 9,
                                              groupValue: status,
                                              onChanged: (i) {
                                                setModalState(() {
                                                  status = i;
                                                });
                                              },
                                            ),
                                            RadioListTile(
                                              title: const Text('Final OT'),
                                              value: 10,
                                              groupValue: status,
                                              onChanged: (i) {
                                                setModalState(() {
                                                  status = i;
                                                });
                                              },
                                            ),
                                            RadioListTile(
                                              title: const Text('Final PKs'),
                                              value: 11,
                                              groupValue: status,
                                              onChanged: (i) {
                                                setModalState(() {
                                                  status = i;
                                                });
                                              },
                                            )
                                          ]),
                                      actions: [
                                        TextButton(
                                          child: const Text("Continue"),
                                          onPressed: () {
                                            Navigator.pop(context, status);
                                          },
                                        ),
                                        TextButton(
                                          child: const Text("Cancel"),
                                          onPressed: () {
                                            Navigator.pop(context, null);
                                          },
                                        ),
                                      ],
                                    );
                                  });
                                });

                            if (selectedStatus != null) {
                              _game.endGame(selectedStatus);
                              setState(() {});
                            }
                          },
                          child: const Padding(
                              padding: EdgeInsets.all(5),
                              child: Icon(Icons.close, size: 24)))
                    ]
                  : [],
              bottom: PreferredSize(
                  preferredSize: Size(width, 100),
                  child: Scoreboard(_game, resolvedSeason)),
            ),
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
            floatingActionButton: kIsWeb
                ? null
                : Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          resolvedSeason.team.color1,
                          resolvedSeason.team.color2,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: FloatingActionButton(
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        child: const Icon(Icons.add),
                        onPressed: () async {
                          final promptToAdvance = _game.gameStatus.index < 9 &&
                              (_game.gameStatus == GameStatus.notStarted ||
                                  _game.gameStatus == GameStatus.halftime ||
                                  _game.gameStatus ==
                                      GameStatus.overtimeNotStarted ||
                                  _game.gameStatus ==
                                      GameStatus.overtimeHalftime);
                          if (promptToAdvance) {
                            final shouldAdvance = await showDialog<bool>(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                      title: const Text("Advance Game"),
                                      content: const Text(
                                          "Do you want to advance to the next period?"),
                                      actions: [
                                        TextButton(
                                          child: const Text("Advance"),
                                          onPressed: () async {
                                            Navigator.pop(context, true);
                                          },
                                        ),
                                        TextButton(
                                          child: const Text("Cancel"),
                                          onPressed: () {
                                            Navigator.pop(context, false);
                                          },
                                        ),
                                      ]);
                                });

                            if (shouldAdvance == true) {
                              _eventEmitter.emit('advanceGame');
                            }
                          }

                          _eventEmitter.emit('createEvent');
                          setState(() {});
                        })),
            body: Column(
              children: [
                CommonPageHeader(team: resolvedSeason.team),
                Expanded(
                  child: Row(children: [
                    SizedBox(width: width * .55, child: gameView),
                    SizedBox(width: width * .45, child: gameStatsView),
                  ]),
                ),
              ],
            ));
      },
    );
  }
}
