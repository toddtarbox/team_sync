import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';

class PlayersPage extends StatefulWidget {
  final Database database;
  final Season season;

  const PlayersPage({super.key, required this.database, required this.season});

  @override
  State<PlayersPage> createState() => _PlayersPageState();
}

class _PlayersPageState extends State<PlayersPage> {
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
            _showPlayer();
          }),
      body: FutureBuilder(
        future: _loadSeasonPlayers(),
        builder: (BuildContext context, AsyncSnapshot<Season> snapshot) {
          if (snapshot.hasData && snapshot.data != null) {
            final season = snapshot.data!;
            return ListView.builder(
                itemCount: season.players.length,
                itemBuilder: (context, index) {
                  final player = season.players[index];
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
                                  "Are you sure you want to delete this Player? All season data associated with this Player will be deleted. This cannot be undone."),
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
                        await widget.database.delete('Players',
                            where: 'id=? AND teamId=? AND seasonId=?', whereArgs: [player.id, season.teamId, season.id]);
                        setState(() {});
                      },
                      child: ListTile(
                          title: Text(player.displayName,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          onTap: () {
                            _showPlayer(player: player);
                          }));
                });
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error loading Season Players'));
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<Season> _loadSeasonPlayers() async {
    await widget.season.load(widget.database);
    return widget.season;
  }

  void _showPlayer({Player? player}) {
    player ??= Player(id: -1, teamId: widget.season.teamId, seasonId: widget.season.id, firstName: '', lastName: '', number: 0);

    showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return Card(
                child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(children: [
                      TextFormField(autofocus: true, decoration:
                        const InputDecoration(labelText: 'First Name'), initialValue: player!.firstName,
                        onChanged: (name) => player!.firstName = name),
                      TextFormField(decoration:
                      const InputDecoration(labelText: 'Last Name'), initialValue: player.lastName,
                          onChanged: (name) => player!.lastName = name),
                      const Spacer(),
                      Row(
                          mainAxisAlignment: player!.firstName.isNotEmpty && player.lastName.isNotEmpty
                              ? MainAxisAlignment.spaceEvenly
                              : MainAxisAlignment.center,
                          children: [
                            player.firstName.isNotEmpty && player.lastName.isNotEmpty
                                ? GestureDetector(
                                    onTap: () async {
                                      await widget.database.insert(
                                          'Players',
                                          {
                                            'id': player!.id == -1 ? null : player.id,
                                            'teamId': widget.season.teamId,
                                            'seasonId': widget.season.id,
                                            'firstName': player.firstName,
                                            'lastName': player.lastName,
                                            'number': player.number
                                          },
                                          conflictAlgorithm: ConflictAlgorithm.replace);

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
