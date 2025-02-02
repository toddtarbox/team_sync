import 'package:eventify/eventify.dart';
import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/widgets/responsive/views/game_stats_view.dart';
import 'package:team_sync/widgets/responsive/views/game_view.dart';
import 'package:team_sync/widgets/scoreboard.dart';

class TabletGamePage extends StatefulWidget {
  final Database database;
  final Season season;
  final Game game;

  const TabletGamePage(
      {super.key,
      required this.database,
      required this.season,
      required this.game});

  @override
  State<TabletGamePage> createState() => _TabletGamePageState();
}

class _TabletGamePageState extends State<TabletGamePage> {
  final EventEmitter _eventEmitter = EventEmitter();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final gameView = GameView(
        database: widget.database,
        season: widget.season,
        game: widget.game,
        eventEmitter: _eventEmitter);

    final gameStatsView = GameStatsView(
        database: widget.database, season: widget.season, game: widget.game);

    return Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.primary,
          leading: GestureDetector(
              onTap: () {
                Navigator.of(context).pop();
              },
              child: const Icon(Icons.arrow_back, color: Colors.white70)),
          title: Text(widget.game.displayName(widget.season.teamId),
              style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 24,
                  fontWeight: FontWeight.bold)),
          actions: widget.game.gameStatus.index < 9
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
                          child: Icon(Icons.add,
                              size: 24, color: Colors.white70))),
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
                          widget.game.endGame(widget.database, selectedStatus);
                          setState(() {});
                        }
                      },
                      child: const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(Icons.close,
                              size: 24, color: Colors.white70)))
                ]
              : [],
          bottom: PreferredSize(
              preferredSize: Size(width, 100),
              child: Scoreboard(widget.game, widget.season)),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.add),
            onPressed: () {
              _eventEmitter.emit('createEvent');
            }),
        body: Row(children: [
          SizedBox(width: width * .55, child: gameView),
          SizedBox(width: width * .45, child: gameStatsView),
        ]));
  }
}
