import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sqflite/sqflite.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/widgets/career_stats_page.dart';
import 'package:team_sync/widgets/history_versus_page.dart';
import 'package:team_sync/widgets/rounded_appbar.dart';
import 'package:team_sync/widgets/season_page.dart';
import 'package:team_sync/widgets/season_record.dart';
import 'package:team_sync/widgets/twitter_settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Database? _database;
  Team? _team;
  List<Season> _seasons = [];

  @override
  void initState() {
    super.initState();
    _load().then((_) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).secondaryHeaderColor,
      appBar: RoundedAppBar(
        title: const Text('Team Sync - Soccer',
            style: TextStyle(
                color: Colors.white70,
                fontSize: 24,
                fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: Visibility(
                visible: _database != null || _team != null,
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                        '${_team?.fullName ?? ''} (${_database?.path.split('/').last ?? ''})',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 24))))),
        actions: [
          Visibility(
              visible: _team != null,
              child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) =>
                            CareerStatsPage(database: _database!, team: _team!),
                      ),
                    );
                  },
                  child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.leaderboard, color: Colors.white70)))),
          Visibility(
              visible: _team != null,
              child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => HistoryVersusPage(
                            database: _database!, team: _team!),
                      ),
                    );
                  },
                  child: const Padding(
                      padding: EdgeInsets.only(right: 10),
                      child: Icon(Icons.manage_history_outlined,
                          color: Colors.white70)))),
          GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TwitterSettingsPage(),
                  ),
                );
              },
              child: const Padding(
                  padding: EdgeInsets.only(right: 10),
                  child: Icon(Icons.settings, color: Colors.white70)))
        ],
      ),
      floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.add),
          onPressed: () async {
            await _showCreateOptions(context);
          }),
      body: FutureBuilder(
        future: _load(),
        builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            if (_database == null) {
              return const Center(
                  child: Text('Please create or open a database',
                      style: TextStyle(fontSize: 24)));
            }

            if (_team == null) {
              return Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    const Text('No Team Found', style: TextStyle(fontSize: 24)),
                    GestureDetector(
                        onTap: () {
                          _handleSelection(context, 'team');
                        },
                        child: const Text('Create a new Team to start',
                            style:
                                TextStyle(fontSize: 18, color: Colors.blue))),
                  ]));
            }

            if (_seasons.isEmpty) {
              return Center(
                  child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                    const Text('No Seasons Found',
                        style: TextStyle(fontSize: 24)),
                    GestureDetector(
                        onTap: () {
                          _handleSelection(context, 'season');
                        },
                        child: const Text('Create a new Season to start',
                            style:
                                TextStyle(fontSize: 18, color: Colors.blue))),
                  ]));
            }

            return Column(children: [
              Card(
                  child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.all(
                          Radius.circular(20),
                        ),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Center(child: SeasonRecord(_seasons)))),
              Expanded(
                  child: Card(
                      child: ListView.separated(
                          separatorBuilder: (BuildContext context, int index) {
                            return Container(height: 2, color: Colors.grey);
                          },
                          itemCount: _seasons.length,
                          itemBuilder: (context, index) {
                            final season = _seasons[index];
                            return Dismissible(
                                key: Key(season.id.toString()),
                                background: Container(color: Colors.red),
                                behavior: HitTestBehavior.translucent,
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
                                  await _database!.delete('Seasons',
                                      where: 'id=?', whereArgs: [season.id]);
                                  setState(() {});
                                },
                                child: ListTile(
                                  title: Text(season.name,
                                      style: const TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold)),
                                  subtitle: Container(
                                      decoration: const BoxDecoration(
                                        color: Colors.grey,
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(20),
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(10),
                                      child: Center(
                                          child: SeasonRecord([season]))),
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => SeasonPage(
                                            database: _database!,
                                            season: season),
                                      ),
                                    );
                                  },
                                ));
                          })))
            ]);
          }
        },
      ),
    );
  }

  // This function shows the modal bottom sheet
  Future<void> _showCreateOptions(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      // Make the corners rounded
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext builderContext) {
        // Using a Wrap widget ensures the content is responsive and
        // won't overflow if the options are too tall.
        return Wrap(
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.folder_open, color: Colors.green.shade700),
              title: const Text('Open Existing Database'),
              onTap: () {
                // Close the bottom sheet first
                Navigator.of(builderContext).pop();
                // Then perform the action and show feedback
                _handleSelection(context, 'existingDatabase');
              },
            ),
            ListTile(
              leading:
                  Icon(Icons.storage_rounded, color: Colors.green.shade700),
              title: const Text('Create New Database'),
              onTap: () {
                // Close the bottom sheet first
                Navigator.of(builderContext).pop();
                // Then perform the action and show feedback
                _handleSelection(context, 'database');
              },
            ),
            Visibility(
                visible: _database != null,
                child: ListTile(
                  leading: Icon(Icons.save, color: Colors.green.shade700),
                  title: const Text('Export Current Database'),
                  onTap: () {
                    // Close the bottom sheet first
                    Navigator.of(builderContext).pop();
                    // Then perform the action and show feedback
                    _handleSelection(context, 'exportDB');
                  },
                )),
            Visibility(
                visible: _database != null && _team == null,
                child: ListTile(
                  leading: Icon(Icons.plus_one_rounded,
                      color: Colors.green.shade700),
                  title: const Text('Create Team'),
                  onTap: () {
                    // Close the bottom sheet first
                    Navigator.of(builderContext).pop();
                    // Then perform the action and show feedback
                    _handleSelection(context, 'team');
                  },
                )),
            Visibility(
                visible: _team != null,
                child: ListTile(
                  leading: Icon(Icons.filter_1_rounded,
                      color: Colors.green.shade700),
                  title: const Text('Create New Season'),
                  onTap: () {
                    // Close the bottom sheet first
                    Navigator.of(builderContext).pop();
                    // Then perform the action and show feedback
                    _handleSelection(context, 'season');
                  },
                )),
          ],
        );
      },
    );
  }

  // Helper function to handle the action and show a SnackBar
  Future<void> _handleSelection(BuildContext context, String option) async {
    switch (option) {
      case 'existingDatabase':
        final existingDB = await _pickFile();
        if (existingDB != null) {
          const storage = FlutterSecureStorage();
          await storage.write(key: 'last_db_used_path', value: existingDB);
          await _openDatabase();
        }
        return;
      case 'database':
        final saveDir = await _pickLocation();
        if (saveDir != null) {
          await _createDatabase(saveDir);
        }
        break;
      case 'exportDB':
        await FilePicker.platform.saveFile(
            fileName: _database!.path.split('/').last,
            bytes: File(_database!.path).readAsBytesSync());
        break;
      case 'team':
        _createTeam();
        break;
      case 'season':
        _createSeason();
        break;
    }
  }

  Future<void> _createDatabase(String saveDir) async {
    String databaseName = '';
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Card(
              child: Padding(
                  padding: const EdgeInsets.all(50),
                  child: Column(children: [
                    const Text(
                      'New Database',
                    ),
                    TextField(
                        autofocus: true,
                        decoration:
                            const InputDecoration(labelText: 'Database Name'),
                        onChanged: (name) => databaseName = name),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                              child: const Text('Save',
                                  style: TextStyle(fontSize: 20)),
                              onTap: () async {
                                if (databaseName.isNotEmpty) {
                                  const storage = FlutterSecureStorage();
                                  await storage.write(
                                      key: 'last_db_used_path',
                                      value: '$saveDir/$databaseName');

                                  setState(() {});
                                  Navigator.pop(context);
                                }
                              }),
                          GestureDetector(
                              child: const Text('Cancel',
                                  style: TextStyle(fontSize: 20)),
                              onTap: () {
                                Navigator.pop(context);
                              })
                        ])
                  ])));
        });
  }

  Future<void> _openDatabase() async {
    const storage = FlutterSecureStorage();
    String? databasePath = await storage.read(key: 'last_db_used_path');
    if (databasePath == null) {
      return;
    }

    try {
      if (Platform.isIOS
          ? await Permission.storage.request().isGranted
          : await Permission.manageExternalStorage.request().isGranted) {
        if (!databasePath.endsWith('.db')) {
          databasePath += '.db';
        }

        _database = await openDatabase(databasePath,
            version: 1, onCreate: _createDatabaseFile);

        final teamResult = await _database!.query('Teams', where: 'id=1');
        if (teamResult.isNotEmpty) {
          _team = Team.fromMap(teamResult.first);
          await _loadSeasons();
        } else {
          _team = null;
        }

        setState(() {});
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _load() async {
    if (_database == null) {
      const storage = FlutterSecureStorage();
      final lastDBUsed = await storage.read(key: 'last_db_used_path');
      if (lastDBUsed == null) {
        await _showCreateOptions(context);
      } else {
        await _openDatabase();
      }
    }
  }

  Future<void> _loadSeasons() async {
    if (_database == null) {
      return;
    }

    final results = await _database!.query('Seasons', orderBy: 'name DESC');
    _seasons = results.map((m) => Season.fromMap(m)).toList(growable: false);
    await Future.wait(_seasons.map((s) async => await s.load(_database!)));
    setState(() {});
  }

  Future<String?> _pickLocation() async {
    // 1. Request storage permission
    var status = Platform.isIOS
        ? await Permission.storage.request()
        : await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      openAppSettings(); // Guide user to settings
      return null;
    }

    try {
      // 2. Pick a folder
      String? dirPath = await FilePicker.platform.getDirectoryPath(
        dialogTitle: 'Select a Folder to Save Your Database',
      );
      return dirPath;
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  Future<String?> _pickFile() async {
    // 1. Request storage permission
    var status = Platform.isIOS
        ? await Permission.storage.request()
        : await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      openAppSettings(); // Guide user to settings
      return null;
    }

    try {
      // 2. Pick a file
      FilePickerResult? pickResult = await FilePicker.platform.pickFiles();
      if (pickResult == null) {
        return null;
      }

      return pickResult.files.single.path!;
    } catch (e) {
      debugPrint(e.toString());
    }
    return null;
  }

  Future<void> _createTeam() async {
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
                                      final team = await _saveTeam(
                                          teamName, teamShortName);
                                      setState(() {
                                        _team = team;
                                      });
                                      Navigator.pop(context);
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

  Future<Team> _saveTeam(String teamName, String teamShortName,
      {Color color1 = Colors.transparent,
      Color color2 = Colors.transparent}) async {
    final teamId = await _database!.insert('Teams', {
      'fullName': teamName,
      'shortName': teamShortName,
      'color1': color1.toARGB32(),
      'color2': color2.toARGB32()
    });

    return await Team.fromId(_database!, teamId);
  }

  Future<void> _createSeason() async {
    late String seasonName;

    showModalBottomSheet(
        context: context,
        builder: (context) {
          return Card(
              child: Padding(
                  padding: const EdgeInsets.all(50),
                  child: Column(children: [
                    const Text('New Season'),
                    TextField(
                        autofocus: true,
                        decoration:
                            const InputDecoration(labelText: 'Season Name'),
                        onChanged: (name) => seasonName = name),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          GestureDetector(
                              child: const Text('Save',
                                  style: TextStyle(fontSize: 20)),
                              onTap: () async {
                                await _database!.insert('Seasons',
                                    {'name': seasonName, 'teamId': _team!.id});

                                await _loadSeasons();
                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              }),
                          GestureDetector(
                              child: const Text('Cancel',
                                  style: TextStyle(fontSize: 20)),
                              onTap: () {
                                Navigator.pop(context);
                              })
                        ])
                  ])));
        });
  }

  Future<void> _createDatabaseFile(Database db, int version) async {
    await db.execute('''
    CREATE TABLE Teams (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      shortName TEXT NOT NULL
    )
  ''');

    await db.execute('''
    CREATE TABLE Seasons (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      teamId INTEGER NOT NULL,
      FOREIGN KEY (teamId) REFERENCES Teams (id) ON DELETE CASCADE
    )
  ''');

    await db.execute('''
    CREATE TABLE Players (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      number INTEGER
    )
  ''');

    await db.execute('''
    CREATE TABLE Games (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      seasonId INTEGER NOT NULL,
      date TEXT NOT NULL,
      opponent TEXT NOT NULL,
      isHomeGame INTEGER NOT NULL,
      goalsFor INTEGER,
      goalsAgainst INTEGER,
      notes TEXT,
      FOREIGN KEY (seasonId) REFERENCES Seasons (id) ON DELETE CASCADE
    )
  ''');

    await db.execute('''
    CREATE TABLE GameStats (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      gameId INTEGER NOT NULL,
      playerId INTEGER NOT NULL,
      goals INTEGER,
      assists INTEGER,
      saves INTEGER,
      FOREIGN KEY (gameId) REFERENCES Games (id) ON DELETE CASCADE,
      FOREIGN KEY (playerId) REFERENCES Players (id) ON DELETE CASCADE
    )
  ''');
  }
}
