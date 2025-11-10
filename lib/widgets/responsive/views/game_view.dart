import 'package:dart_twitter_api/twitter_api.dart';
import 'package:eventify/eventify.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:sqflite/sqflite.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/event_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final format = DateFormat('E MMM dd, yyyy');

  late Game _game;

  late TwitterApi _twitterAPI;

  Save? _autoCreateSave;

  @override
  void initState() {
    _game = widget.game;

    widget.eventEmitter.on('createEvent', context, (event, eventContext) async {
      await _editEvent();
    });

    widget.eventEmitter.on('advanceGame', context, (event, eventContext) async {
      await _advanceGame();
    });

    widget.eventEmitter.on('loadSettings', context,
        (event, eventContext) async {
      const storage = FlutterSecureStorage();
      _twitterAPI = TwitterApi(
          client: TwitterClient(
        consumerKey: await storage.read(key: 'twitter_consumer_key') ?? '',
        consumerSecret:
            await storage.read(key: 'twitter_consumer_secret') ?? '',
        token: await storage.read(key: 'twitter_access_token') ?? '',
        secret: await storage.read(key: 'twitter_access_token_secret') ?? '',
      ));
    });
    widget.eventEmitter.emit('loadSettings');

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
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

    return FutureBuilder(
        future: _loadGameEvents(),
        builder:
            (BuildContext context, AsyncSnapshot<List<GameEvent>> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            var itemCount = _game.scoringEvents.length +
                _game.gameEvents.length +
                _game.shootoutEvents.length +
                3;
            if (_game.shootoutEvents.isNotEmpty) {
              itemCount += 1;
            }

            bool showScoringEvents =
                ResponsiveBreakpoints.of(context).largerThan(MOBILE);

            return ListView.builder(
                itemCount: itemCount,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Visibility(
                        visible: showScoringEvents,
                        child: const ListTile(
                            title: Center(child: Text('Scoring Events'))));
                  }

                  if (index <= _game.scoringEvents.length) {
                    final event = _game.scoringEvents[index - 1];
                    return Visibility(
                        visible: showScoringEvents,
                        child: _getEventTile(event));
                  }

                  if (index == _game.scoringEvents.length + 1) {
                    return const ListTile(
                        title: Center(child: Text('All Game Events')));
                  }

                  if (index >= _game.scoringEvents.length - 2 &&
                      index <
                          _game.gameEvents.length +
                              _game.scoringEvents.length +
                              2) {
                    final event = _game
                        .gameEvents[index - _game.scoringEvents.length - 2];
                    return _getEventTile(event);
                  }

                  if (_game.shootoutEvents.isNotEmpty) {
                    if (index == _game.gameEvents.length + 2) {
                      return const ListTile(
                          title: Center(child: Text('End of Regulation')));
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
                      title: Center(child: Text('End of Game')));
                });
          } else if (snapshot.hasError) {
            debugPrint(snapshot.error.toString());
            debugPrintStack(stackTrace: snapshot.stackTrace);
            return const Center(child: Text('Error loading events'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        });
  }

  Future<void> _launchUrl(String url) async {
    await launchUrl(Uri.parse(url));
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

    final scoreWidget = event.eventMinute > 0 &&
            (event.eventType == 'Shot' || event.eventType == 'PenaltyKick') &&
            event.eventData == ShotResult.goal.index
        ? SizedBox(
            width: 50,
            child: Center(
                child: Text(
                    _game.getScore(widget.season.teamId,
                        minute: event.eventMinute),
                    style: const TextStyle(fontSize: 20))))
        : null;

    final linkWidget = event.eventUrls?.isNotEmpty ?? false
        ? Center(
            child: IconButton(
                icon: Icon(Icons.link, color: Colors.blue),
                onPressed: () {
                  _launchUrl(event.eventUrls!);
                }))
        : Container();

    final opponent = !widget.game.isHomeTeam(widget.season.teamId)
        ? widget.game.homeTeam
        : widget.game.awayTeam;

    final eventCard = ListTile(
        leading: eventMinuteWidget,
        trailing: scoreWidget,
        title: Row(children: [
          event.image,
          const SizedBox(width: 10),
          Text(event.eventType == 'Shot' &&
                  event.eventData == ShotResult.goal.index &&
                  ((event.player == null &&
                          event.team.id == widget.season.teamId) ||
                      event.player?.id == -2)
              ? event.team.id == widget.season.teamId
                  ? 'Own goal by ${opponent.shortName}'
                  : 'Own goal'
              : event.display),
          linkWidget
        ]),
        subtitle: Visibility(
            visible: event.eventType != 'Period',
            child: Text(event.player?.displayName ?? event.team.shortName)),
        onTap: () {
          _editEvent(event: event);
        });

    if (kIsWeb) {
      return eventCard;
    }

    return Dismissible(
        key: Key(event.id.toString()),
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
          await DatabaseService.instance
              .delete('Events', where: 'id=?', whereArgs: [event.id]);
          setState(() {
            _game.updateScore();
          });
        },
        child: eventCard);
  }

  Future<List<GameEvent>> _loadGameEvents() async {
    return await _game.loadGameEvents();
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
        .map((p) => DropdownMenuEntry<Player>(value: p, label: p.displayName))
        .toList();

    List<DropdownMenuEntry> awayPlayerEntries = awayTeamPlayers
        .map((p) => DropdownMenuEntry<Player>(value: p, label: p.displayName))
        .toList();

    var playerEntries = awayPlayerEntries;

    final shotResultEntries = ['Goal', 'Saved', 'Post', 'Off Target', 'Blocked']
        .map((t) => DropdownMenuEntry<String>(value: t, label: t))
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
        scrollControlDisabledMaxHeightRatio: .75,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return Card(
                child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25),
                    child: Column(children: [
                      RadioGroup(
                          groupValue: event!.team == _game.awayTeam ? 0 : 1,
                          onChanged: (value) {
                            setModalState(() {
                              if (value == 0) {
                                event!.team = _game.awayTeam;
                                playerEntries = awayPlayerEntries;
                              } else {
                                event!.team = _game.homeTeam;
                                playerEntries = homePlayerEntries;
                              }
                            });
                          },
                          child: Row(children: [
                            Expanded(
                                child: RadioListTile<int>(
                              title: Text(_game.awayTeam.shortName),
                              value: 0,
                            )),
                            Expanded(
                                child: RadioListTile<int>(
                              title: Text(_game.homeTeam.shortName),
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
                              period = 2;
                            } else if (eventPeriod == '1st Half Overtime') {
                              period = 3;
                            } else if (eventPeriod == '2nd Half Overtime') {
                              period = 4;
                            } else if (eventPeriod == 'Penalty Kicks') {
                              period = 5;
                            }
                            setModalState(() {
                              event!.eventPeriod = period;
                            });
                          },
                          width: double.infinity,
                          label: const Text('Select Period'),
                          dropdownMenuEntries: eventPeriods),
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

                            setModalState(() {
                              event!.eventType = type;
                              event.eventData = data;
                            });
                          },
                          width: double.infinity,
                          label: const Text('Select Event Type'),
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
                                      event.eventData == ShotResult.goal.index),
                              menuHeight: 700,
                              initialSelection: event.player,
                              onSelected: (player) async {
                                setModalState(() {
                                  event!.player = player;
                                });
                              },
                              width: double.infinity,
                              label: const Text('Select Player'),
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
                              label: const Text('Shot Result'),
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
                                    initialValue: event.eventMinute.toString(),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                        labelText:
                                            'Game Minute (Goals and Assists Only)'),
                                    onChanged: (minute) => event!.eventMinute =
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
                                child: const Text('Save',
                                    style: TextStyle(fontSize: 20))),
                            TextButton(
                                onPressed: () async {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel',
                                    style: TextStyle(fontSize: 20)))
                          ])
                    ])));
          });
        });
  }

  Future<void> _advanceGame() async {
    await _game.advanceGame();

    final periodEvent = Period(
        id: -1,
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
        await DatabaseService.instance.insert(
            'Events',
            {
              'id': DateTime.now().millisecondsSinceEpoch,
              'playerId': event.player?.id ?? -1,
              'teamId': event.team.id,
              'gameId': event.game.id,
              'seasonId': event.game.seasonId,
              'eventType': event.eventType,
              'eventMinute': event.eventMinute,
              'eventPeriod': event.eventPeriod,
              'eventData': event.eventData,
              'eventUrls': event.eventUrls
            },
            conflictAlgorithm: ConflictAlgorithm.replace);
      } else {
        await DatabaseService.instance.update(
            'Events',
            {
              'playerId': event.player?.id ?? -1,
              'teamId': event.team.id,
              'gameId': event.game.id,
              'seasonId': event.game.seasonId,
              'eventType': event.eventType,
              'eventMinute': event.eventMinute,
              'eventPeriod': event.eventPeriod,
              'eventData': event.eventData,
              'eventUrls': event.eventUrls
            },
            where: 'id=?',
            whereArgs: [event.id]);
      }

      await _game.updateScore();

      try {
        if (event.shouldTweet) {
          final tweetText = event.tweetText(_game);
          if (tweetText.isNotEmpty) {
            await _twitterAPI.tweetService.update(
              status: tweetText,
            );
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
            eventType: 'Save',
            eventMinute: event.eventMinute,
            eventPeriod: -1,
            eventUrls: event.eventUrls ?? '',
            eventData: 0);
        setState(() {
          _autoCreateSave = saveEvent;
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
