import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/subscription_service.dart';
import 'package:team_sync/widgets/career_stats_page.dart';
import 'package:team_sync/widgets/custom_appbar.dart';
import 'package:team_sync/widgets/history_versus_page.dart';
import 'package:team_sync/widgets/season_page.dart';
import 'package:team_sync/widgets/season_record.dart';
import 'package:team_sync/widgets/twitter_settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Team? _team;
  List<Season> _seasons = [];
  late bool _isSubscribed;

  @override
  void initState() {
    SubscriptionService.instance.subscriptionState.listen((isSubscribed) {
      setState(() {
        _isSubscribed = isSubscribed;
      });
    });
    _isSubscribed = SubscriptionService.instance.isSubscribed;

    DatabaseService.instance.setProvider(
        _isSubscribed ? FirebaseDBProvider() : LocalDatabaseProvider());

    _load().then((_) {
      setState(() {});
    });

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(
        title: const Text('Soccer Analytics',
            style: TextStyle(
                fontSize: 24,
                color: Colors.white70,
                fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: Visibility(
                visible:
                    DatabaseService.instance.path.isNotEmpty || _team != null,
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                        '${_team?.fullName ?? ''} (${DatabaseService.instance.path.split('/').last})',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 24))))),
        actions: [
          Visibility(
            visible: !_isSubscribed,
            child: TextButton(
              onPressed: () async {
                await SubscriptionService.instance.purchaseSubscription();
              },
              child:
                  const Text('Go Pro', style: TextStyle(color: Colors.white)),
            ),
          ),
          Visibility(
              visible: _team != null,
              child: IconButton(
                  color: Colors.white70,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CareerStatsPage(team: _team!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.leaderboard))),
          Visibility(
              visible: _team != null,
              child: IconButton(
                  color: Colors.white70,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => HistoryVersusPage(team: _team!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.manage_history_outlined))),
          IconButton(
              color: Colors.white70,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const TwitterSettingsPage(),
                  ),
                );
              },
              icon: const Icon(Icons.settings))
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
            if (DatabaseService.instance.path.isEmpty) {
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
                        child: Text('Create a new Team to start',
                            style: TextStyle(
                                fontSize: 18,
                                color:
                                    Theme.of(context).colorScheme.secondary))),
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
                        child: Text('Create a new Season to start',
                            style: TextStyle(
                                fontSize: 18,
                                color:
                                    Theme.of(context).colorScheme.secondary))),
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
                          child: Center(child: SeasonRecord(_seasons))))),
              Expanded(
                  child: Card(
                      color: Colors.white70,
                      child: ListView.builder(
                          itemCount: _seasons.length,
                          itemBuilder: (context, index) {
                            final season = _seasons[index];
                            return Dismissible(
                                key: Key(season.id.toString()),
                                background: Container(
                                    color: Theme.of(context).colorScheme.error),
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
                                  await DatabaseService.instance.delete(
                                      'Seasons',
                                      where: 'id=?',
                                      whereArgs: [season.id]);
                                  setState(() {});
                                },
                                child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SeasonPage(season: season),
                                        ),
                                      );
                                    },
                                    child: Card(
                                        child: Column(children: [
                                      Text(season.name,
                                          style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold)),
                                      Container(
                                          decoration: BoxDecoration(
                                              color: Colors.grey[500],
                                              borderRadius:
                                                  BorderRadius.circular(10)),
                                          padding: const EdgeInsets.all(5),
                                          margin: const EdgeInsets.all(10),
                                          child: Center(
                                              child: SeasonRecord([season]))),
                                    ]))));
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
            Visibility(
                visible: _isSubscribed,
                child: ListTile(
                  leading: Icon(Icons.cloud_sync_rounded,
                      color: Theme.of(context).colorScheme.secondary),
                  title: const Text('Open Existing Cloud Database'),
                  onTap: () {
                    // Close the bottom sheet first
                    Navigator.of(builderContext).pop();
                    // Then perform the action and show feedback
                    _handleSelection(context, 'existingCloudDatabase');
                  },
                )),
            Visibility(
                visible: !_isSubscribed,
                child: ListTile(
                  leading: Icon(Icons.folder_open,
                      color: Theme.of(context).colorScheme.secondary),
                  title: const Text('Open Existing Local Database'),
                  onTap: () {
                    // Close the bottom sheet first
                    Navigator.of(builderContext).pop();
                    // Then perform the action and show feedback
                    _handleSelection(context, 'existingLocalDatabase');
                  },
                )),
            Visibility(
                visible: _isSubscribed,
                child: ListTile(
                  leading: Icon(Icons.cloud_upload_rounded,
                      color: Theme.of(context).colorScheme.secondary),
                  title: const Text('Create New Cloud Database'),
                  onTap: () {
                    // Close the bottom sheet first
                    Navigator.of(builderContext).pop();
                    // Then perform the action and show feedback
                    _handleSelection(context, 'newCloudDatabase');
                  },
                )),
            Visibility(
                visible: !_isSubscribed,
                child: ListTile(
                  leading: Icon(Icons.storage_rounded,
                      color: Theme.of(context).colorScheme.secondary),
                  title: const Text('Create New Local Database'),
                  onTap: () {
                    // Close the bottom sheet first
                    Navigator.of(builderContext).pop();
                    // Then perform the action and show feedback
                    _handleSelection(context, 'newLocalDatabase');
                  },
                )),
            Visibility(
                visible:
                    !_isSubscribed && DatabaseService.instance.path.isNotEmpty,
                child: ListTile(
                  leading: Icon(Icons.save,
                      color: Theme.of(context).colorScheme.secondary),
                  title: const Text('Export Current Database'),
                  onTap: () {
                    // Close the bottom sheet first
                    Navigator.of(builderContext).pop();
                    // Then perform the action and show feedback
                    _handleSelection(context, 'exportDB');
                  },
                )),
            Visibility(
                visible:
                    DatabaseService.instance.path.isNotEmpty && _team == null,
                child: ListTile(
                  leading: Icon(Icons.plus_one_rounded,
                      color: Theme.of(context).colorScheme.secondary),
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
                      color: Theme.of(context).colorScheme.secondary),
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
      case 'existingCloudDatabase':
        if (await _pickCloudDatabase()) {
          await _openDatabase();
        }
        return;
      case 'existingLocalDatabase':
        final existingDB = await _pickFile();
        if (existingDB != null) {
          const storage = FlutterSecureStorage();
          await storage.write(key: 'last_db_used_path', value: existingDB);
          await _openDatabase();
        }
        return;
      case 'newCloudDatabase':
        await _createDatabase();
        break;
      case 'newLocalDatabase':
        final saveDir = await _pickLocation();
        if (saveDir != null) {
          await _createDatabase(saveDir: saveDir);
        }
        break;
      case 'exportDB':
        await FilePicker.platform.saveFile(
            fileName: DatabaseService.instance.path.split('/').last,
            bytes: File(DatabaseService.instance.path).readAsBytesSync());
        break;
      case 'team':
        _createTeam();
        break;
      case 'season':
        _createSeason();
        break;
    }
  }

  Future<void> _createDatabase({String? saveDir}) async {
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
                          TextButton(
                              child: const Text('Save',
                                  style: TextStyle(fontSize: 20)),
                              onPressed: () async {
                                if (databaseName.isNotEmpty) {
                                  const storage = FlutterSecureStorage();
                                  await storage.write(
                                      key: 'last_db_used_path',
                                      value: saveDir != null
                                          ? '$saveDir/$databaseName'
                                          : databaseName);
                                  await _openDatabase();

                                  setState(() {});
                                  Navigator.pop(context);
                                }
                              }),
                          TextButton(
                              child: const Text('Cancel',
                                  style: TextStyle(fontSize: 20)),
                              onPressed: () {
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
      final granted = _isSubscribed ||
          (Platform.isIOS
              ? await Permission.storage.request().isGranted
              : await Permission.manageExternalStorage.request().isGranted);

      if (granted) {
        if (!databasePath.endsWith('.db')) {
          databasePath += '.db';
        }

        await DatabaseService.instance.open(databasePath);

        final teamResult =
            await DatabaseService.instance.query('Teams', where: 'id=1');
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
    if (DatabaseService.instance.path.isEmpty) {
      const storage = FlutterSecureStorage();
      final lastDBUsed = await storage.read(key: 'last_db_used_path');
      if (lastDBUsed != null) {
        await _openDatabase();
      }
    } else {
      await _loadSeasons();
    }
  }

  Future<void> _loadSeasons() async {
    if (DatabaseService.instance.path.isEmpty) {
      return;
    }

    final results =
        await DatabaseService.instance.query('Seasons', orderBy: 'id DESC');
    _seasons = results.map((m) => Season.fromMap(m)).toList(growable: false);
    await Future.wait(_seasons.map((s) async => await s.load()));
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

  Future<bool> _pickCloudDatabase() async {
    final entries = await DatabaseService.instance.getAvailableDatabases();

    return await showModalBottomSheet(
            context: context,
            builder: (BuildContext context) {
              return Card(
                  child: Padding(
                      padding: const EdgeInsets.all(50),
                      child: Column(children: [
                        const Text(
                          'Select a Cloud Database',
                        ),
                        DropdownMenu(
                            onSelected: (value) async {
                              const storage = FlutterSecureStorage();
                              await storage.write(
                                  key: 'last_db_used_path', value: value);
                              Navigator.pop(context, true);
                            },
                            dropdownMenuEntries: entries
                                .map((e) =>
                                    DropdownMenuEntry(value: e, label: e))
                                .toList())
                      ])));
            }) ??
        false;
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
      FilePickerResult? pickResult = await FilePicker.platform
          .pickFiles(allowedExtensions: ['db'], type: FileType.custom);
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
    final teamId = await DatabaseService.instance.insert('Teams', {
      'fullName': teamName,
      'shortName': teamShortName,
      'color1': color1.value,
      'color2': color2.value
    });

    return await Team.fromId(teamId);
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
                          TextButton(
                              child: const Text('Save',
                                  style: TextStyle(fontSize: 20)),
                              onPressed: () async {
                                await DatabaseService.instance.insert('Seasons',
                                    {'name': seasonName, 'teamId': _team!.id});

                                setState(() {});
                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              }),
                          TextButton(
                              child: const Text('Cancel',
                                  style: TextStyle(fontSize: 20)),
                              onPressed: () {
                                Navigator.pop(context);
                              })
                        ])
                  ])));
        });
  }
}
