import 'dart:io';

import 'package:external_path/external_path.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/widgets/season_page.dart';
import 'package:team_sync/widgets/season_record.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Database _database;

  bool _exportingDB = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        title: const Text('Team Sync',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        actions: [
          GestureDetector(
              onTap: () async {
                await _exportDB(_database.path.split('/').last);
              },
              child: const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child:
                      Icon(Icons.import_export, size: 32, color: Colors.white70)))
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () {
            _createSeason();
          }),
      body: _exportingDB
          ? const Center(child: CircularProgressIndicator())
          : FutureBuilder(
              future: _loadSeasons(),
              builder:
                  (BuildContext context, AsyncSnapshot<List<Season>> snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final seasons = snapshot.data;
                  return ListView.builder(
                      itemCount: snapshot.data!.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          if (index == 0) {
                            return ListTile(
                                tileColor: Colors.black,
                                title: Center(child: SeasonRecord(seasons!)));
                          }
                        }

                        final season = seasons![index - 1];
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
                                        "Are you sure you want to delete this Season? All data associated with this Season will be deleted. This cannot be undone."),
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
                              await _database.delete('Seasons',
                                  where: 'id=?', whereArgs: [season.id]);
                              setState(() {});
                            },
                            child: ListTile(
                              title: Text(season.name,
                                  style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => SeasonPage(
                                        database: _database, season: season),
                                  ),
                                );
                              },
                            ));
                      });
                } else if (snapshot.hasError) {
                  return const Center(child: Text('Error loading DB'));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            ),
    );
  }

  Future<void> _openDatabase(String dbName) async {
    try {
      final databasesPath =
          await ExternalPath.getExternalStoragePublicDirectory(
              ExternalPath.DIRECTORY_DOWNLOADS);
      final path = '$databasesPath/MobileSoccer/$dbName';

      final File file = File('${await getDatabasesPath()}/$dbName');
      if (!file.existsSync()) {
        if (await Permission.manageExternalStorage.request().isGranted) {
          final data = File(path).readAsBytesSync();
          List<int> bytes =
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          await file.writeAsBytes(bytes, flush: true);
        }
      }

      _database = await openDatabase('${await getDatabasesPath()}/$dbName');
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _exportDB(String dbName) async {
    setState(() {
      _exportingDB = true;
    });

    try {
      final File sourceFile = File('${await getDatabasesPath()}/$dbName');

      final databasesPath =
          await ExternalPath.getExternalStoragePublicDirectory(
              ExternalPath.DIRECTORY_DOWNLOADS);
      final path = '$databasesPath/MobileSoccer/$dbName';
      final destFile = File(path);

      if (sourceFile.existsSync()) {
        if (await Permission.manageExternalStorage.request().isGranted) {
          final data = sourceFile.readAsBytesSync();
          List<int> bytes =
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
          await destFile.writeAsBytes(bytes, flush: true);
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        _exportingDB = false;
      });
    });
  }

  Future<List<Season>> _loadSeasons() async {
    await _openDatabase('SaintAlbert.db');

    final results = await _database.query('Seasons', orderBy: 'name DESC');
    final seasons =
        results.map((m) => Season.fromMap(m)).toList(growable: false);

    await Future.wait(seasons.map((s) async => await s.load(_database)));

    return seasons;
  }

  Future<void> _createSeason() async {
    final teams = await Team.all(_database);
    final entries = teams
        .map((t) => DropdownMenuEntry<int>(value: t.id, label: t.fullName))
        .toList(growable: false);

    int? selectedTeam;
    String? seasonName;

    if (!mounted) {
      return;
    }

    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Card(
              child: Padding(
                  padding: const EdgeInsets.all(50),
                  child: Column(children: [
                    TextField(
                        autofocus: true,
                        decoration:
                            const InputDecoration(labelText: 'Season Name'),
                        onChanged: (name) => seasonName = name),
                    const SizedBox(height: 30),
                    DropdownMenu(
                        onSelected: (teamId) => selectedTeam = teamId,
                        width: double.infinity,
                        label: const Text('Select Team'),
                        dropdownMenuEntries: entries),
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
                                    if (selectedTeam != null &&
                                        seasonName != null &&
                                        seasonName!.isNotEmpty) {
                                      await _saveSeason(
                                          seasonName!, selectedTeam!);

                                      if (mounted) {
                                        Navigator.pop(context);
                                        setState(() {});
                                      }
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

  Future<void> _saveSeason(String seasonName, int teamId) async {
    final allTeamSeasons = await _database
        .query('Seasons', where: 'teamId=?', whereArgs: [teamId]);
    int prevSeasonId = 0;
    for (var s in allTeamSeasons) {
      final season = Season.fromMap(s);
      if (season.id > prevSeasonId) {
        prevSeasonId = season.id;
      }
    }

    final newSeasonId = await _database
        .insert('Seasons', {'name': seasonName, 'teamId': teamId});

    final teamPlayers = await _database.query('Players',
        where: 'teamId=? AND seasonId=?', whereArgs: [teamId, prevSeasonId]);
    for (var p in teamPlayers) {
      final player = Player.fromMap(p);

      await _database.insert(
          'Players',
          {
            'id': player.id,
            'teamId': teamId,
            'seasonId': newSeasonId,
            'firstName': player.firstName,
            'lastName': player.lastName,
            'number': player.number
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }
}
