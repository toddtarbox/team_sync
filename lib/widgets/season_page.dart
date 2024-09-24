import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/widgets/game_page.dart';
import 'package:team_sync/widgets/game_result.dart';
import 'package:team_sync/widgets/scoreboard.dart';
import 'package:team_sync/widgets/season_record.dart';

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
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
            },
            child: const Icon(Icons.arrow_back, color: Colors.white70)),
        title: Text(widget.season.name,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
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
            return ListView.builder(
                itemCount: season.games.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    if (index == 0) {
                      return ListTile(
                          tileColor: Colors.black,
                          title: Center(child: SeasonRecord([widget.season])));
                    }
                  }

                  final game = season.games[index - 1];
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
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(format.format(game.date)),
                          onTap: () {
                            _showGame(game: game);
                          }));
                });
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
        .toList(growable: false);

    final isHomeTeam = game == null || game.isHomeTeam(widget.season.teamId);

    final team = widget.season.team;

    final homeTeam = game != null ? game.homeTeam : team;
    final awayTeam = game != null
        ? game.awayTeam
        : Team(id: -1, fullName: '', shortName: '');
    game ??= Game.initial(
        seasonId: widget.season.id, homeTeam: homeTeam, awayTeam: awayTeam);

    int? location = isHomeTeam ? 0 : 1;
    bool canSave = game.gameStatus.index == 0;

    showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return Card(
                child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(children: [
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
                          label: const Text('Select Team'),
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
                              onPressed: () {
                                Navigator.of(context).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => GamePage(
                                        database: widget.database,
                                        season: widget.season,
                                        game: game!),
                                  ),
                                );
                              })
                          : Container(),
                      const Spacer(),
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
}
