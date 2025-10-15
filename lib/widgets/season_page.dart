import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:sqflite/sqflite.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/widgets/custom_appbar.dart';
import 'package:team_sync/widgets/game_result.dart';
import 'package:team_sync/widgets/players_page.dart';
import 'package:team_sync/widgets/responsive/mobile/mobile_game_page.dart';
import 'package:team_sync/widgets/responsive/tablet/tablet_game_page.dart';
import 'package:team_sync/widgets/scoreboard.dart';
import 'package:team_sync/widgets/season_record.dart';
import 'package:team_sync/widgets/season_stats_page.dart';

class SeasonPage extends StatefulWidget {
  final Database database;
  final Season season;

  const SeasonPage({super.key, required this.database, required this.season});

  @override
  State<SeasonPage> createState() => _SeasonPageState();
}

class _SeasonPageState extends State<SeasonPage> {
  final format = DateFormat('E MMM dd, yyyy');
  final saveFormat = DateFormat('MM.dd.yyyy');

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: Text(widget.season.name,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: Visibility(
                visible: widget.season.team.fullName == 'Saint Albert',
                child: Image.asset('assets/images/jpgs/sa-crest.jpg',
                    width: 64, height: 64))),
        actions: [
          GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => SeasonStatsPage(
                        database: widget.database, season: widget.season),
                  ),
                );
              },
              child: const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.paste, color: Colors.white70))),
          GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => PlayersPage(
                        database: widget.database, season: widget.season),
                  ),
                );
              },
              child: const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.person, color: Colors.white70)))
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            _showGame();
          }),
      body: FutureBuilder(
        future: _loadSeason(),
        builder: (BuildContext context, AsyncSnapshot<Season> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            final season = snapshot.data!;
            final games = season.games;

            if (games.isEmpty) {
              return Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    const Text('No Games Found',
                        style: TextStyle(fontSize: 24)),
                    GestureDetector(
                        onTap: () {
                          _showGame();
                        },
                        child: const Text('Create a new Game to start',
                            style:
                                TextStyle(fontSize: 18, color: Colors.blue))),
                  ]));
            }

            return Column(children: [
              Container(
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(25),
                        bottomRight: Radius.circular(25),
                      )),
                  child: Card(
                      color: Colors.black,
                      child: Padding(
                          padding: const EdgeInsets.all(10),
                          child:
                              Center(child: SeasonRecord([widget.season]))))),
              Expanded(
                  child: Card(
                      color: Colors.white70,
                      child: ListView.builder(
                          itemCount: games.length,
                          itemBuilder: (context, index) {
                            final game = games[index];
                            return Dismissible(
                                key: Key(game.id.toString()),
                                background: Container(color: Colors.red),
                                confirmDismiss: (_) {
                                  return showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("Confirm Delete"),
                                        content: const Text(
                                            "Are you sure you want to delete this Game? All data associated with this Game will be deleted. This cannot be undone."),
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
                                  await widget.database.delete('Games',
                                      where: 'id=?', whereArgs: [game.id]);
                                  setState(() {});
                                },
                                child: ListTile(
                                    minLeadingWidth: 90,
                                    leading: GameResult(game, season.teamId),
                                    title: Text(game.displayName(season.teamId),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(format.format(game.date)),
                                    onTap: () {
                                      game.gameStatus.index == 0
                                          ? _showGame(game: game)
                                          : _goToGame(game);
                                    }));
                          })))
            ]);
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading Season Games'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<Season> _loadSeason() async {
    await widget.season.load(widget.database);
    return widget.season;
  }

  void _showGame({Game? game}) {
    final entries = widget.season.teams
        .map((t) => DropdownMenuEntry<int>(value: t.id, label: t.fullName))
        .where((e) => e.value != widget.season.teamId)
        .toList(growable: false);

    final isHomeTeam = game == null || game.isHomeTeam(widget.season.teamId);

    final team = widget.season.team;

    final homeTeam = game != null ? game.homeTeam : team;
    final awayTeam = game != null ? game.awayTeam : team;
    game ??= Game.initial(
        seasonId: widget.season.id, homeTeam: homeTeam, awayTeam: awayTeam);

    int? location = isHomeTeam ? 0 : 1;
    bool canSave = game.gameStatus.index == 0;

    showModalBottomSheet(
        context: context,
        showDragHandle: true,
        scrollControlDisabledMaxHeightRatio: .75,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return Card(
                child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(children: [
                      const Text(
                        'Edit Game',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(height: 20),
                      Row(children: [
                        Expanded(
                            child: RadioListTile(
                          title: const Text('Home',
                              style: TextStyle(fontSize: 20)),
                          value: 0,
                          groupValue: location,
                          onChanged: (i) {
                            if (game!.gameStatus.index == 0) {
                              final tempTeam = game.homeTeam;
                              game.homeTeam = game.awayTeam;
                              game.awayTeam = tempTeam;

                              setModalState(() {
                                location = i;
                              });
                            }
                          },
                        )),
                        Expanded(
                            child: RadioListTile(
                          title: const Text('Away',
                              style: TextStyle(fontSize: 20)),
                          value: 1,
                          groupValue: location,
                          onChanged: (i) {
                            if (game!.gameStatus.index == 0) {
                              final tempTeam = game.homeTeam;
                              game.homeTeam = game.awayTeam;
                              game.awayTeam = tempTeam;

                              setModalState(() {
                                location = i;
                              });
                            }
                          },
                        )),
                      ]),
                      const SizedBox(height: 30),
                      TextButton(
                          onPressed: () {
                            _createOpponent();
                          },
                          child: const Text('Create New Opponent')),
                      const SizedBox(height: 30),
                      DropdownMenu(
                          enabled: game!.gameStatus.index == 0,
                          initialSelection:
                              isHomeTeam ? game.awayTeam.id : game.homeTeam.id,
                          onSelected: (teamId) async {
                            if (location == 0) {
                              game!.awayTeam =
                                  await Team.fromId(widget.database, teamId!);
                            } else {
                              game!.homeTeam =
                                  await Team.fromId(widget.database, teamId!);
                            }

                            setModalState(() {
                              canSave = true;
                            });
                          },
                          width: double.infinity,
                          label: const Text('Select Opponent'),
                          dropdownMenuEntries: entries),
                      const SizedBox(height: 30),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue),
                          onPressed: game.gameStatus.index == 0
                              ? () async {
                                  final date = await showDatePicker(
                                      context: context,
                                      initialDate: game!.date,
                                      firstDate: DateTime.now()
                                          .subtract(const Duration(days: 365)),
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 365)));
                                  if (date != null) {
                                    setModalState(() {
                                      game!.date = date;
                                    });
                                  }
                                }
                              : null,
                          child: SizedBox(
                              width: 200,
                              child: Center(
                                  child: Text(format.format(game.date),
                                      style: const TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20))))),
                      const SizedBox(height: 30),
                      const Divider(),
                      Scoreboard(game, widget.season,
                          color: Colors.black, shortName: true),
                      const Divider(),
                      const SizedBox(height: 30),
                      game.id != -1
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green),
                              child: const Text('Go to game',
                                  style: TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20)),
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await _goToGame(game!);
                                _loadSeason();
                              })
                          : Container(),
                      const SizedBox(height: 30),
                      Row(
                          mainAxisAlignment: canSave
                              ? MainAxisAlignment.spaceEvenly
                              : MainAxisAlignment.center,
                          children: [
                            canSave
                                ? GestureDetector(
                                    onTap: () async {
                                      await game!.saveGame(widget.database);

                                      if (mounted) {
                                        Navigator.pop(context);
                                        setState(() {});
                                      }
                                    },
                                    child: const Text('Save',
                                        style: TextStyle(fontSize: 20)))
                                : Container(),
                            GestureDetector(
                                onTap: () {
                                  Navigator.pop(context);
                                },
                                child: const Text('Cancel',
                                    style: TextStyle(fontSize: 20)))
                          ])
                    ])));
          });
        });
  }

  Future<void> _goToGame(Game game) async {
    if (ResponsiveBreakpoints.of(context).largerThan(MOBILE)) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => TabletGamePage(
              database: widget.database, season: widget.season, game: game!),
        ),
      );
    } else {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => MobileGamePage(
              database: widget.database, season: widget.season, game: game!),
        ),
      );
    }
  }

  void _createOpponent() {
    late String teamName;
    late String teamShortName;

    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Card(
              child: Padding(
                  padding: const EdgeInsets.all(50),
                  child: Column(children: [
                    const Text(
                      'New Team',
                    ),
                    TextField(
                        autofocus: true,
                        decoration:
                            const InputDecoration(labelText: 'Team Name'),
                        onChanged: (name) => teamName = name),
                    TextField(
                        autofocus: true,
                        decoration:
                            const InputDecoration(labelText: 'Team Short Name'),
                        onChanged: (name) => teamShortName = name),
                    const Spacer(),
                    TextButton(
                        onPressed: () {},
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              GestureDetector(
                                  child: const Text('Save',
                                      style: TextStyle(fontSize: 20)),
                                  onTap: () async {
                                    if (teamName.isNotEmpty &&
                                        teamShortName.isNotEmpty) {
                                      Navigator.pop(context);
                                      await _saveTeam(teamName, teamShortName);
                                      await _loadSeason();
                                      Navigator.pop(context);
                                      _showGame();
                                    }
                                  }),
                              GestureDetector(
                                  child: const Text('Cancel',
                                      style: TextStyle(fontSize: 20)),
                                  onTap: () {
                                    Navigator.pop(context);
                                  })
                            ]))
                  ])));
        });
  }

  Future<void> _saveTeam(String teamName, String teamShortName,
      {Color color1 = Colors.transparent,
      Color color2 = Colors.transparent}) async {
    await widget.database!.insert('Teams', {
      'fullName': teamName,
      'shortName': teamShortName,
      'color1': color1.toARGB32(),
      'color2': color2.toARGB32()
    });
  }
}
