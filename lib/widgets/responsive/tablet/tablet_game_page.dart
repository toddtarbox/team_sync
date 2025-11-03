import 'package:eventify/eventify.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/widgets/custom_appbar.dart';
import 'package:team_sync/widgets/responsive/views/game_stats_view.dart';
import 'package:team_sync/widgets/responsive/views/game_view.dart';
import 'package:team_sync/widgets/scoreboard.dart';

class TabletGamePage extends StatefulWidget {
  final Season season;
  final Game game;

  const TabletGamePage({super.key, required this.season, required this.game});

  @override
  State<TabletGamePage> createState() => _TabletGamePageState();
}

class _TabletGamePageState extends State<TabletGamePage> {
  final EventEmitter _eventEmitter = EventEmitter();

  late Game _game;

  @override
  void initState() {
    _game = widget.game;

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    final gameView = GameView(
        season: widget.season, game: _game, eventEmitter: _eventEmitter);

    final gameStatsView = GameStatsView(
        season: widget.season, game: _game, eventEmitter: _eventEmitter);

    return Scaffold(
        appBar: CustomAppBar(
          team: widget.season.team,
          title: Text(_game.displayName(widget.season.teamId),
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
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
              child: Scoreboard(_game, widget.season)),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: kIsWeb
            ? null
            : Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.season.team.color1,
                      widget.season.team.color2,
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
                              _game.gameStatus == GameStatus.overtimeHalftime);
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
        body: Row(children: [
          SizedBox(width: width * .55, child: gameView),
          SizedBox(width: width * .45, child: gameStatsView),
        ]));
  }
}
