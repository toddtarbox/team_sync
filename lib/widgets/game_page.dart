import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/widgets/game_stats_page.dart';
import 'package:team_sync/widgets/scoreboard.dart';
import 'package:twitter_api_v2/twitter_api_v2.dart';

class GamePage extends StatefulWidget {
  final Database database;
  final Season season;
  final Game game;

  const GamePage(
      {super.key,
      required this.database,
      required this.season,
      required this.game});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  final format = DateFormat('E MMM dd, yyyy');

  late Game _game;

  late TwitterApi _twitterAPI;

  Save? _autoCreateSave;

  @override
  void initState() {
    _game = widget.game;

    _twitterAPI = TwitterApi(
        bearerToken: '',
        oauthTokens: const OAuthTokens(
          consumerKey: 'QwM9RNgW2q9yWlnRPc6B9sZcQ',
          consumerSecret: 'hkbNUSiuUo0CBwMpgseqpp88MvNuTRqawnNO9iliE5aFTGMlTq',
          accessToken: '2694291734-bt3lNQjkOpq2OQbgVxGJbNZkAVcWVWXUQ4g80By',
          accessTokenSecret: 'Oh7UzuPkIcKBgu2eWwdc5oE6YeMmJyTUhiClhMxwozuuA',
        ));

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (_autoCreateSave != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _editEvent(event: _autoCreateSave);
        _autoCreateSave = null;
      });
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back, color: Colors.white70)),
        title: Text(_game.displayName(widget.season.teamId),
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        actions: _game.gameStatus.index < 9
            ? [
                GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => GameStatsPage(
                              database: widget.database,
                              season: widget.season,
                              game: _game)));
                    },
                    child: const Padding(
                        padding: EdgeInsets.all(5),
                        child: Icon(Icons.paste,
                            size: 24, color: Colors.white70))),
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
                                    await _advanceGame();
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
                        child:
                            Icon(Icons.add, size: 24, color: Colors.white70))),
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
                        _game.endGame(widget.database, selectedStatus);
                        setState(() {});
                      }
                    },
                    child: const Padding(
                        padding: EdgeInsets.all(5),
                        child:
                            Icon(Icons.close, size: 24, color: Colors.white70)))
              ]
            : [
                GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                          builder: (context) => GameStatsPage(
                              database: widget.database,
                              season: widget.season,
                              game: _game)));
                    },
                    child: const Padding(
                        padding: EdgeInsets.only(right: 10),
                        child: Icon(Icons.paste,
                            size: 24, color: Colors.white70))),
              ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(100.0),
            child: Scoreboard(_game, widget.season)),
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () async {
            if (_game.gameStatus == GameStatus.notStarted ||
                _game.gameStatus == GameStatus.halftime ||
                _game.gameStatus == GameStatus.overtimeNotStarted ||
                _game.gameStatus == GameStatus.overtimeHalftime) {
              await _game.advanceGame(widget.database);
              setState(() {});
            }
            _editEvent();
          }),
      body: FutureBuilder(
        future: _loadGame(),
        builder: (BuildContext context, AsyncSnapshot<Game> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            final game = snapshot.data!;
            var itemCount = _game.scoringEvents.length +
                _game.gameEvents.length +
                _game.shootoutEvents.length +
                3;
            if (_game.shootoutEvents.isNotEmpty) {
              itemCount += 1;
            }

            return ListView.builder(
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return const ListTile(
                        title: Center(child: Text('Scoring Events')),
                        tileColor: Colors.black12);
                  }

                  if (index <= _game.scoringEvents.length) {
                    final event = _game.scoringEvents[index - 1];
                    return _getEventTile(event);
                  }

                  if (index == _game.scoringEvents.length + 1) {
                    return const ListTile(
                        title: Center(child: Text('All Game Events')),
                        tileColor: Colors.black12);
                  }

                  if (index >= _game.scoringEvents.length - 2 &&
                      index <
                          _game.gameEvents.length +
                              _game.scoringEvents.length +
                              2) {
                    final event =
                        game.gameEvents[index - _game.scoringEvents.length - 2];
                    return _getEventTile(event);
                  }

                  if (_game.shootoutEvents.isNotEmpty) {
                    if (index == _game.gameEvents.length + 2) {
                      return const ListTile(
                          title: Center(child: Text('End of Regulation')),
                          tileColor: Colors.black12);
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
                      return _getEventTile(event);
                    }
                  }

                  return const ListTile(
                      title: Center(child: Text('End of Game')),
                      tileColor: Colors.black12);
                });
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading Game Events'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Widget _getEventTile(GameEvent event) {
    final eventMinuteWidget = SizedBox(
        width: 48,
        child: Center(
            child: Text(
                event.eventMinute > 0
                    ? '${event.eventMinute.toString()}\''
                    : '',
                style: const TextStyle(fontSize: 20))));

    return Dismissible(
        key: UniqueKey(),
        background: Container(color: Colors.red),
        confirmDismiss: (_) {
          return showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text("Confirm Delete"),
                content: const Text(
                    "Are you sure you want to delete this Event? All data associated with this Event will be deleted. This cannot be undone."),
                actions: [
                  TextButton(
                    child: const Text("Continue"),
                    onPressed: () {
                      Navigator.pop(context, true);
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
            },
          );
        },
        onDismissed: (direction) async {
          await widget.database
              .delete('Events', where: 'id=?', whereArgs: [event.id]);
          setState(() {
            _game.updateScore(widget.database);
          });
        },
        child: ListTile(
            leading: event.eventType == 'Period' ||
                    event.team.id == _game.homeTeam.id
                ? event.image
                : eventMinuteWidget,
            trailing: event.eventType == 'Period' ||
                    event.team.id == _game.awayTeam.id
                ? event.image
                : eventMinuteWidget,
            title: Center(child: Text(event.display)),
            onTap: () {
              _editEvent(event: event);
            }));
  }

  Future<Game> _loadGame() async {
    await _game.loadGameEvents(widget.database);
    return _game;
  }

  Future<void> _editEvent({GameEvent? event}) async {
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
        .map((t) => DropdownMenuEntry<String>(value: t, label: t))
        .toList(growable: false);

    final eventPeriods = [
      '1st Half',
      '2nd Half',
      '1st Half Overtime',
      '2nd Half Overtime',
      'Penalty Kicks'
    ]
        .map((t) => DropdownMenuEntry<String>(value: t, label: t))
        .toList(growable: false);

    List<Player> awayTeamPlayers = await Player.listFromTeamIdSeasonId(
        widget.database, _game.awayTeam.id, _game.seasonId);
    List<Player> homeTeamPlayers = await Player.listFromTeamIdSeasonId(
        widget.database, _game.homeTeam.id, _game.seasonId);

    event ??= GameEvent.initial(
        team: event?.team ?? _game.awayTeam,
        game: _game,
        seasonId: _game.seasonId,
        whichTeam: 0,
        eventType: event?.eventType ?? 'Shot',
        eventMinute: event?.eventMinute ?? -1,
        eventPeriod: event?.eventPeriod ?? -1,
        eventData: event?.eventData ?? 0);

    int? team = event.team.id == _game.awayTeam.id ? 0 : 1;

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
            : event.eventPeriod == 2
                ? '2nd Half'
                : event.eventPeriod == 5
                    ? '1st Half Overtime'
                    : event.eventPeriod == 7
                        ? '2nd Half Overtime'
                        : '';

    event.eventPeriod =
        event.eventPeriod == -1 ? _game.gameStatus.index : event.eventPeriod;

    final initialShotResult = event.eventData == 0
        ? 'Goal'
        : event.eventData == 1
            ? 'Saved'
            : event.eventData == 2
                ? 'Post'
                : event.eventData == 3
                    ? 'Off Target'
                    : event.eventData == 4
                        ? 'Blocked'
                        : '';

    List<DropdownMenuEntry> playerEntries = team == 0
        ? awayTeamPlayers
            .map((p) =>
                DropdownMenuEntry<Player>(value: p, label: p.displayName))
            .toList(growable: false)
        : homeTeamPlayers
            .map((p) =>
                DropdownMenuEntry<Player>(value: p, label: p.displayName))
            .toList(growable: false);

    bool canSave = playerEntries.isEmpty || event.player != null;

    final shotResultEntries = ['Goal', 'Saved', 'Post', 'Off Target', 'Blocked']
        .map((t) => DropdownMenuEntry<String>(value: t, label: t))
        .toList(growable: false);

    showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return Card(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(children: [
                      Row(children: [
                        Expanded(
                            child: RadioListTile(
                          title: Text(_game.awayTeam.shortName),
                          value: 0,
                          groupValue: team,
                          onChanged: (i) {
                            playerEntries = awayTeamPlayers
                                .map((p) => DropdownMenuEntry<Player>(
                                    value: p, label: p.displayName))
                                .toList(growable: false);

                            setModalState(() {
                              team = i;
                              event!.team = _game.awayTeam;
                              canSave =
                                  playerEntries.isEmpty || event.player != null;
                            });
                          },
                        )),
                        Expanded(
                            child: RadioListTile(
                          title: Text(_game.homeTeam.shortName),
                          value: 1,
                          groupValue: team,
                          onChanged: (i) {
                            playerEntries = homeTeamPlayers
                                .map((p) => DropdownMenuEntry<Player>(
                                    value: p, label: p.displayName))
                                .toList(growable: false);

                            setModalState(() {
                              team = i;
                              event!.team = _game.homeTeam;
                              canSave =
                                  playerEntries.isEmpty || event.player != null;
                            });
                          },
                        )),
                      ]),
                      const SizedBox(height: 30),
                      DropdownMenu(
                          initialSelection: event!.eventType,
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

                            event!.eventType = type;
                            event.eventData = data;

                            setModalState(() {
                              canSave = event!.eventType == 'Corner' ||
                                  playerEntries.isEmpty ||
                                  event.player != null;
                            });
                          },
                          width: double.infinity,
                          label: const Text('Select Event Type'),
                          dropdownMenuEntries: eventEntries),
                      const SizedBox(height: 30),
                      Visibility(
                          visible: playerEntries.isNotEmpty,
                          child: DropdownMenu(
                              enabled: event.eventType != 'Corner' &&
                                  playerEntries.isNotEmpty,
                              initialSelection: event.player,
                              onSelected: (player) async {
                                event!.player = player;

                                setModalState(() {
                                  canSave = true;
                                });
                              },
                              width: double.infinity,
                              label: const Text('Select Player'),
                              dropdownMenuEntries: playerEntries)),
                      Visibility(
                          visible: playerEntries.isNotEmpty,
                          child: const SizedBox(height: 30)),
                      DropdownMenu(
                          initialSelection: initialStatus,
                          onSelected: (eventPeriod) async {
                            int period = 1;

                            if (eventPeriod == '1st Half') {
                              period = 1;
                            } else if (eventPeriod == '2nd Half') {
                              period = 2;
                            } else if (eventPeriod == '1st Half Overtime') {
                              period = 3;
                            } else if (eventPeriod == '2nd Half Overtime') {
                              period = 4;
                            } else if (eventPeriod == 'Penalty Kicks') {
                              period = 5;
                            }

                            event!.eventPeriod = period;

                            setModalState(() {
                              canSave = playerEntries.isEmpty ||
                                  event!.player != null;
                            });
                          },
                          width: double.infinity,
                          label: const Text('Select Period'),
                          dropdownMenuEntries: eventPeriods),
                      const SizedBox(height: 30),
                      Visibility(
                          visible: event.eventType == 'Shot',
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

                                event!.eventData = result;
                              },
                              width: double.infinity,
                              label: const Text('Shot Result'),
                              dropdownMenuEntries: shotResultEntries)),
                      const SizedBox(height: 20),
                      Visibility(
                          visible:
                              event.eventType == 'Shot' && event.eventData == 0,
                          child: TextFormField(
                              initialValue: event.eventMinute.toString(),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                  labelText: 'Game Minute (Goals Only)'),
                              onChanged: (minute) =>
                                  event!.eventMinute = int.parse(minute))),
                      const SizedBox(height: 20),
                      Row(
                          mainAxisAlignment: canSave
                              ? MainAxisAlignment.spaceEvenly
                              : MainAxisAlignment.center,
                          children: [
                            canSave
                                ? GestureDetector(
                                    onTap: () async {
                                      if (await _saveEvent(event!)) {
                                        if (mounted) {
                                          Navigator.pop(context);
                                          setState(() {});
                                        }
                                      }
                                    },
                                    child: const Text('Save',
                                        style: TextStyle(fontSize: 20)))
                                : Container(),
                            GestureDetector(
                                child: const Text('Cancel',
                                    style: TextStyle(fontSize: 20)),
                                onTap: () {
                                  Navigator.pop(context);
                                })
                          ])
                    ])));
          });
        });
  }

  Future<void> _advanceGame() async {
    await _game.advanceGame(widget.database);

    final periodEvent = Period(
        id: -1,
        player: null,
        team: _game.homeTeam,
        game: _game,
        seasonId: _game.seasonId,
        whichTeam: 0,
        eventType: 'Period',
        eventMinute: -1,
        eventPeriod: _game.gameStatus.index,
        eventData: _game.gameStatus.index);
    await _saveEvent(periodEvent);

    setState(() {});
  }

  Future<bool> _saveEvent(GameEvent event) async {
    if (event.eventType == 'Shot' &&
        event.eventData == 0 &&
        event.eventMinute <= 0) {
      return false;
    }

    if (event.eventPeriod >= 0) {
      await widget.database.insert(
          'Events',
          {
            'id': event.id == -1 ? null : event.id,
            'playerId': event.player?.id ?? -1,
            'teamId': event.team.id,
            'gameId': event.game.id,
            'seasonId': event.game.seasonId,
            'whichTeam': 0,
            'eventType': event.eventType,
            'eventLocation': '0,0',
            'eventMinute': event.eventMinute,
            'eventPeriod': event.eventPeriod,
            'eventData': event.eventData,
            'eventTextData': null
          },
          conflictAlgorithm: ConflictAlgorithm.replace);

      await _game.updateScore(widget.database);

      try {
        if (event.shouldTweet) {
          final tweetText = event.tweetText(_game);
          if (tweetText.isNotEmpty) {
            // await _twitterAPI.tweets.createTweet(
            //   text: tweetText,
            // );
          }
        }
      } catch (e) {}

      if (event.eventType == 'Shot' &&
          event.eventData == ShotResult.onTargetSave.index) {
        // Auto-create a Save event
        final team = event.team.id == _game.homeTeam.id
            ? _game.awayTeam
            : _game.homeTeam;
        final saveEvent = Save(
            id: -1,
            player: null,
            team: team,
            game: _game,
            seasonId: _game.seasonId,
            whichTeam: 0,
            eventType: 'Save',
            eventMinute: event.eventMinute,
            eventPeriod: event.eventPeriod,
            eventData: 0);
        setState(() {
          _autoCreateSave = saveEvent;
        });
      } else {
        setState(() {});
      }

      return true;
    }

    return false;
  }
}
