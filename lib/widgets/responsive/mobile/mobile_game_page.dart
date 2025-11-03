import 'package:eventify/eventify.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/widgets/custom_appbar.dart';
import 'package:team_sync/widgets/responsive/mobile/mobile_game_stats_page.dart';
import 'package:team_sync/widgets/responsive/views/game_view.dart';
import 'package:team_sync/widgets/scoreboard.dart';

class MobileGamePage extends StatefulWidget {
  final Season season;
  final Game game;

  const MobileGamePage({super.key, required this.season, required this.game});

  @override
  State<MobileGamePage> createState() => _MobileGamePageState();
}

class _MobileGamePageState extends State<MobileGamePage> {
  final EventEmitter _eventEmitter = EventEmitter();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
        appBar: CustomAppBar(
          team: widget.season.team,
          title: Text(widget.game.displayName(widget.season.teamId),
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          actions: widget.game.gameStatus.index < 9
              ? [
                  GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => MobileGameStatsPage(
                                season: widget.season, game: widget.game)));
                      },
                      child: const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(Icons.paste, size: 24))),
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
                          padding: EdgeInsets.all(5), child: Icon(Icons.add))),
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
                                          title: Text(
                                              AppLocalizations.of(context)!
                                                  .finalText),
                                          value: 9,
                                          groupValue: status,
                                          onChanged: (i) {
                                            setModalState(() {
                                              status = i;
                                            });
                                          },
                                        ),
                                        RadioListTile(
                                          title: Text(
                                              AppLocalizations.of(context)!
                                                  .finalOTText),
                                          value: 10,
                                          groupValue: status,
                                          onChanged: (i) {
                                            setModalState(() {
                                              status = i;
                                            });
                                          },
                                        ),
                                        RadioListTile(
                                          title: Text(
                                              AppLocalizations.of(context)!
                                                  .finalPKsText),
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
                          widget.game.endGame(selectedStatus);
                          setState(() {});
                        }
                      },
                      child: const Padding(
                          padding: EdgeInsets.all(5),
                          child: Icon(Icons.close, size: 24)))
                ]
              : [
                  GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => MobileGameStatsPage(
                                season: widget.season, game: widget.game)));
                      },
                      child: const Padding(
                          padding: EdgeInsets.only(right: 10),
                          child: Icon(Icons.paste, size: 24))),
                ],
          bottom: PreferredSize(
              preferredSize: Size(width, 100),
              child: Scoreboard(widget.game, widget.season)),
        ),
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
                      final promptToAdvance = widget.game.gameStatus.index <
                              9 &&
                          (widget.game.gameStatus == GameStatus.notStarted ||
                              widget.game.gameStatus == GameStatus.halftime ||
                              widget.game.gameStatus ==
                                  GameStatus.overtimeNotStarted ||
                              widget.game.gameStatus ==
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
                    })),
        body: GameView(
            season: widget.season,
            game: widget.game,
            eventEmitter: _eventEmitter));
  }
}
