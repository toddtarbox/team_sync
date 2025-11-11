import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:sqflite/sqflite.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/subscription_service.dart';
import 'package:team_sync/widgets/custom_appbar.dart';
import 'package:team_sync/widgets/history_versus_page.dart';
import 'package:team_sync/widgets/record_holders_page.dart';
import 'package:team_sync/widgets/season_record.dart';
import 'package:team_sync/widgets/seasons_list_view.dart';
import 'package:team_sync/widgets/settings_page.dart';

class HomePage extends StatefulWidget {
  final String? databaseId;
  const HomePage({super.key, this.databaseId});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Team? _team;
  List<Season> _seasons = [];
  late bool _isSubscribed;
  bool _isLoading = false;
  bool _isImporting = false;
  bool _isSharing = false;
  final _teamIdController = TextEditingController();

  final _welcomeKey = GlobalKey();
  final _fabKey = GlobalKey();
  final _fabKeyOnly = GlobalKey();
  @override
  void initState() {
    super.initState();
    SubscriptionService.instance.subscriptionState.listen((isSubscribed) {
      setState(() {
        _isSubscribed = isSubscribed;
      });
    });
    _isSubscribed = SubscriptionService.instance.isSubscribed;

    DatabaseService.instance.setProvider(FirebaseDBProvider());

    if (!kIsWeb) {
      ShowcaseView.register(
        hideFloatingActionWidgetForShowcase: [
          _settingsKey,
          _fabKeyOnly,
          _proKeyOnly
        ],
        globalFloatingActionWidget: (showcaseContext) => FloatingActionWidget(
          left: 16,
          bottom: 16,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => ShowcaseView.get().dismiss(),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffEE5366),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ),
        onStart: (index, key) {},
        onComplete: (index, key) {
          if (key == _settingsKey || key == _fabKeyOnly || key == _proKeyOnly) {
            SystemChrome.setSystemUIOverlayStyle(
              SystemUiOverlayStyle.light.copyWith(
                statusBarIconBrightness: Brightness.dark,
                statusBarColor: Colors.white,
              ),
            );
            if (!kIsWeb) {
              _showCreateOptions(context);
            }
          }
        },
        blurValue: 1,
        autoPlayDelay: const Duration(seconds: 3),
        globalTooltipActionConfig: const TooltipActionConfig(
          position: TooltipActionPosition.inside,
          alignment: MainAxisAlignment.spaceBetween,
          actionGap: 20,
        ),
        globalTooltipActions: [
          TooltipActionButton(
            type: TooltipDefaultActionType.previous,
            textStyle: const TextStyle(
              color: Colors.white,
            ),
            hideActionWidgetForShowcase: [
              _welcomeKey,
              _settingsKey,
              _fabKeyOnly,
              _proKeyOnly
            ],
          ),
          TooltipActionButton(
            type: TooltipDefaultActionType.next,
            textStyle: const TextStyle(
              color: Colors.white,
            ),
            hideActionWidgetForShowcase: [_fabKeyOnly, _proKeyOnly],
          ),
        ],
        onDismiss: (key) {
          debugPrint('Dismissed at $key');
        },
      );

      _checkIfFirstLaunch();
    }
  }

  final _goProKey = GlobalKey();
  final _settingsKey = GlobalKey();

  final _proKeyOnly = GlobalKey();

  Future<void> _checkIfFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        prefs.setBool('isFirstLaunch', false);

        ShowcaseView.get().startShowCase(
          [_welcomeKey, _fabKey, _goProKey, _settingsKey],
        );
      });
    }
  }

  @override
  void dispose() {
    if (!kIsWeb) {
      ShowcaseView.get().unregister();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb && widget.databaseId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('TeamSync Viewer')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Enter a 6-digit Team ID to view stats:',
                    style: TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                TextField(
                  controller: _teamIdController,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Team ID',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    if (_teamIdController.text.length == 6) {
                      context.go('/${_teamIdController.text}');
                    }
                  },
                  child: const Text('Load Team'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(
        team: _team,
        title: Text(AppLocalizations.of(context)!.soccerAnalytics,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(40),
            child: Visibility(
                visible:
                    DatabaseService.instance.path.isNotEmpty || _team != null,
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                              '${_team?.fullName ?? ''} (${DatabaseService.instance.path.split('/').last})',
                              style: const TextStyle(fontSize: 24)),
                          SizedBox(width: 10),
                          DatabaseService.instance.isLocalDatabase
                              ? Container()
                              : Icon(Icons.cloud_rounded,
                                  color: _isSubscribed ? Colors.yellow : null)
                        ])))),
        actions: [
          if (!kIsWeb &&
              _isSubscribed &&
              DatabaseService.instance.path.isNotEmpty &&
              !DatabaseService.instance.isLocalDatabase)
            IconButton(
              icon: const Icon(Icons.share, color: Colors.yellow),
              onPressed: () => _handleSelection(context, 'shareDatabase'),
            ),
          Visibility(
              visible: !kIsWeb,
              child: Showcase(
                key: _isSubscribed ? _proKeyOnly : _goProKey,
                description: _isSubscribed
                    ? 'Welcome to TeamSync Pro! You have access to all features, like web sharing and more!'
                    : 'Go Pro to access more features!',
                child: TextButton(
                  onPressed: () async {
                    if (!_isSubscribed) {
                      await SubscriptionService.instance.purchaseSubscription();
                      setState(() {});
                    }

                    if (_isSubscribed) {
                      ShowcaseView.get().startShowCase(
                        [_proKeyOnly],
                      );
                    }
                  },
                  child: Text(
                      _isSubscribed
                          ? AppLocalizations.of(context)!.pro
                          : AppLocalizations.of(context)!.goPro,
                      style: const TextStyle(color: Colors.yellow)),
                ),
              )),
          Visibility(
              visible: _team != null,
              child: IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => RecordHoldersPage(team: _team!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.leaderboard))),
          Visibility(
              visible: _team != null,
              child: IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => HistoryVersusPage(team: _team!),
                      ),
                    );
                  },
                  icon: const Icon(Icons.manage_history_outlined))),
          Visibility(
              visible: !kIsWeb,
              child: Showcase(
                key: _settingsKey,
                description: 'Access app settings here',
                child: IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SettingsPage(team: _team),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings)),
              ))
        ],
      ),
      floatingActionButton: kIsWeb
          ? null
          : Showcase(
              key:
                  DatabaseService.instance.path.isEmpty ? _fabKey : _fabKeyOnly,
              description: DatabaseService.instance.path.isEmpty
                  ? 'Tap here to create a new database'
                  : _team == null
                      ? 'Tap here to create a new Team'
                      : 'Tap here to add a new Season or change your team colors',
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _team?.color1 ?? Theme.of(context).primaryColor,
                      _team?.color2 ?? Theme.of(context).primaryColorDark,
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
                    await _showCreateOptions(context);
                  },
                ),
              ),
            ),
      body: Stack(
        children: [
          FutureBuilder(
            future: _load(),
            builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
              if (!snapshot.hasData ||
                  _isLoading ||
                  _isImporting ||
                  _isSharing) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                if (!kIsWeb && DatabaseService.instance.path.isEmpty) {
                  final welcomeChild = Center(
                      child: Text(
                          AppLocalizations.of(context)!
                              .pleaseCreateOrOpenADatabase,
                          style: const TextStyle(fontSize: 24)));
                  return Showcase(
                      key: _welcomeKey,
                      description:
                          'Welcome to TeamSync! Let\'s take a look around and get you started managing your team!',
                      child: welcomeChild);
                }

                if (!kIsWeb && _team == null) {
                  return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Text(AppLocalizations.of(context)!.noTeamFound,
                            style: const TextStyle(fontSize: 24)),
                        if (!kIsWeb)
                          GestureDetector(
                              onTap: () {
                                _handleSelection(context, 'team');
                              },
                              child: Text(
                                  AppLocalizations.of(context)!
                                      .createNewTeamToStart,
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary))),
                      ]));
                }

                if (!kIsWeb && _seasons.isEmpty) {
                  return Center(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                        Text(AppLocalizations.of(context)!.noSeasonsFound,
                            style: const TextStyle(fontSize: 24)),
                        if (!kIsWeb)
                          GestureDetector(
                              onTap: () {
                                _handleSelection(context, 'season');
                              },
                              child: Text(
                                  AppLocalizations.of(context)!
                                      .createNewSeasonToStart,
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary))),
                      ]));
                }

                if (_seasons.isEmpty) {
                  return Center(
                      child: Text(
                          'Unable to load the specified team. Please check the ID and try again.',
                          style: const TextStyle(fontSize: 24)));
                }

                return Column(children: [
                  Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _team?.color1 ?? Theme.of(context).primaryColor,
                            _team?.color2 ?? Theme.of(context).primaryColorDark,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(25),
                          bottomRight: Radius.circular(25),
                        ),
                      ),
                      child: Container(
                          color: Colors.transparent,
                          child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Center(
                                  child: SeasonRecord(_seasons,
                                      singleSeason: false))))),
                  Expanded(
                    child: SeasonsListView(seasons: _seasons),
                  )
                ]);
              }
            },
          ),
          if (_isImporting || _isSharing)
            Container(
              color: Colors.black.withOpacity(0.75),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                        _isSharing
                            ? 'Generating Share ID...'
                            : AppLocalizations.of(context)!.importingDatabase,
                        style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
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
          children: [
            ListTile(
              leading: Icon(Icons.cloud_sync_rounded,
                  color: Theme.of(context).colorScheme.secondary),
              title:
                  Text(AppLocalizations.of(context)!.openExistingCloudDatabase),
              onTap: () {
                // Close the bottom sheet first
                Navigator.of(builderContext).pop();
                // Then perform the action and show feedback
                _handleSelection(context, 'existingCloudDatabase');
              },
            ),
            ListTile(
              leading: Icon(Icons.cloud_rounded,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text(AppLocalizations.of(context)!.createNewCloudDatabase),
              onTap: () async {
                // Close the bottom sheet first
                Navigator.of(builderContext).pop();
                // Then perform the action and show feedback
                await _handleSelection(context, 'newCloudDatabase');
              },
            ),
            Visibility(
                visible: kDebugMode && DatabaseService.instance.isLocalDatabase,
                child: ListTile(
                  leading: Icon(Icons.cloud_upload_rounded,
                      color: Theme.of(context).colorScheme.secondary),
                  title: Text(AppLocalizations.of(context)!.convertToCloud),
                  onTap: () async {
                    // Close the bottom sheet first
                    Navigator.of(builderContext).pop();
                    // Then perform the action and show feedback
                    await _handleSelection(context, 'importCloudDatabase');
                  },
                )),
            Visibility(
                visible: kDebugMode,
                child: ListTile(
                  leading: Icon(Icons.settings_backup_restore_rounded,
                      color: Theme.of(context).colorScheme.secondary),
                  title: Text(AppLocalizations.of(context)!.openFromBackup),
                  onTap: () async {
                    // Close the bottom sheet first
                    Navigator.of(builderContext).pop();
                    // Then perform the action and show feedback
                    await _handleSelection(context, 'existingBackupDatabase');
                  },
                )),
            Visibility(
                visible:
                    DatabaseService.instance.path.isNotEmpty && _team == null,
                child: Divider(color: Theme.of(context).colorScheme.secondary)),
            Visibility(
                visible:
                    DatabaseService.instance.path.isNotEmpty && _team == null,
                child: ListTile(
                  leading: Icon(Icons.plus_one_rounded,
                      color: Theme.of(context).colorScheme.secondary),
                  title: Text(AppLocalizations.of(context)!.createTeam),
                  onTap: () async {
                    // Close the bottom sheet first
                    Navigator.of(builderContext).pop();
                    // Then perform the action and show feedback
                    await _handleSelection(context, 'team');
                  },
                )),
            Visibility(
                visible: _team != null,
                child: Divider(color: Theme.of(context).colorScheme.secondary)),
            Visibility(
                visible: _team != null,
                child: ListTile(
                  leading: Icon(Icons.photo,
                      color: Theme.of(context).colorScheme.secondary),
                  title: Text('Set Team Logo'),
                  onTap: () async {
                    // Close the bottom sheet first
                    Navigator.of(builderContext).pop();
                    // Then perform the action and show feedback
                    await _pickTeamLogo();
                  },
                )),
            Visibility(
                visible: _team != null,
                child: ListTile(
                  leading: Icon(Icons.color_lens,
                      color: Theme.of(context).colorScheme.secondary),
                  title: Text(AppLocalizations.of(context)!.setTeamColors),
                  onTap: () async {
                    // Close the bottom sheet first
                    Navigator.of(builderContext).pop();
                    // Then perform the action and show feedback
                    await _pickTeamColors();
                  },
                )),
            Visibility(
                visible: _team != null,
                child: ListTile(
                  leading: Icon(Icons.filter_1_rounded,
                      color: Theme.of(context).colorScheme.secondary),
                  title: Text(AppLocalizations.of(context)!.createNewSeason),
                  onTap: () async {
                    // Close the bottom sheet first
                    Navigator.of(builderContext).pop();
                    // Then perform the action and show feedback
                    await _handleSelection(context, 'season');
                  },
                )),
          ],
        );
      },
    );
  }

  // Helper function to handle the action and show a SnackBar
  Future<void> _handleSelection(BuildContext context, String option) async {
    // Capture the ScaffoldMessenger before the async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    switch (option) {
      case 'shareDatabase':
        setState(() {
          _isSharing = true;
        });
        try {
          final id = await DatabaseService.instance.shareDatabase();
          final url = 'https://team-sync-soccer.web.app/#/$id';

          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Share this URL'),
              content: SelectableText(url,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
                IconButton(
                  icon: const Icon(Icons.copy),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: url));
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Copied to clipboard!')),
                    );
                  },
                ),
              ],
            ),
          );
        } catch (e) {
          scaffoldMessenger.showSnackBar(SnackBar(
              content: Text('Error during share, please try again'),
              backgroundColor: Colors.red));
          debugPrint(e.toString());
        }
        setState(() {
          _isSharing = false;
        });
        break;
      case 'existingCloudDatabase':
        final databaseName = await _pickCloudDatabase();
        if (databaseName != null) {
          await _openCloudDatabase(databaseName);
        }
        return;
      case 'existingBackupDatabase':
        final existingDB = await _pickFile();
        if (existingDB != null) {
          await _openBackupDatabase(existingDB);
        }
        return;
      case 'newCloudDatabase':
        await _createDatabase();
        break;
      case 'importCloudDatabase':
        setState(() {
          _isImporting = true;
        });

        try {
          await DatabaseService.instance.importToCloud();
          scaffoldMessenger.showSnackBar(SnackBar(
            content: Text(AppLocalizations.of(context)!.databaseImported),
            backgroundColor: Colors.green,
          ));
        } catch (e) {
          debugPrint(e.toString());
          scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Error during import: $e'),
            backgroundColor: Colors.red,
          ));
        } finally {
          setState(() {
            _isImporting = false;
          });
        }
        break;
      case 'team':
        await _createTeam();
        ShowcaseView.get().startShowCase(
          [_fabKeyOnly],
        );
        break;
      case 'season':
        await _createSeason();
        ShowcaseView.get().startShowCase(
          [_fabKeyOnly],
        );
        break;
    }
  }

  Future<void> _createDatabase() async {
    String databaseName = '';
    await showModalBottomSheet(
        context: context,
        builder: (context) {
          return Card(
              child: Padding(
                  padding: const EdgeInsets.all(50),
                  child: Column(children: [
                    Text(AppLocalizations.of(context)!.newDatabase),
                    TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(context)!.databaseName),
                        onChanged: (name) => databaseName = name),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                              child: Text(AppLocalizations.of(context)!.save,
                                  style: const TextStyle(fontSize: 20)),
                              onPressed: () async {
                                if (databaseName.isNotEmpty) {
                                  await _openCloudDatabase(databaseName);

                                  setState(() {});
                                  Navigator.pop(context);
                                }
                              }),
                          TextButton(
                              child: Text(
                                  AppLocalizations.of(context)!.cancelButton,
                                  style: const TextStyle(fontSize: 20)),
                              onPressed: () {
                                Navigator.pop(context);
                              })
                        ])
                  ])));
        });
  }

  Future<void> _openBackupDatabase(String path) async {
    await DatabaseService.instance.close();
    if (!DatabaseService.instance.isLocalDatabase) {
      DatabaseService.instance.setProvider(LocalDatabaseProvider());
    }

    final backupFile = File(path);
    final importedFile = await backupFile
        .copy('${await getDatabasesPath()}/${backupFile.path.split('/').last}');

    await DatabaseService.instance.open(importedFile.path);

    final teamResult = await DatabaseService.instance
        .query('Teams', orderByChild: 'id', equalTo: 1);
    if (teamResult.isNotEmpty) {
      _team = Team.fromMap(teamResult.first);
      await _loadSeasons();
    } else {
      _team = null;
    }

    setState(() {});
    return;
  }

  Future<void> _openCloudDatabase(String databaseName) async {
    try {
      if (DatabaseService.instance.path.endsWith(databaseName)) {
        // Database is already open
        return;
      }

      DatabaseService.instance.setProvider(FirebaseDBProvider());

      await DatabaseService.instance.open(databaseName);

      const storage = FlutterSecureStorage();
      await storage.write(key: 'last_db_used', value: databaseName);

      final teamResult = await DatabaseService.instance
          .query('Teams', orderByChild: 'id', equalTo: 1);
      if (teamResult.isNotEmpty) {
        _team = Team.fromMap(teamResult.first);
        await _loadSeasons();
      } else {
        _team = null;
      }

      setState(() {});
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<bool> _load() async {
    if (widget.databaseId != null) {
      final dbId = widget.databaseId!;
      final opened = await DatabaseService.instance.openFromId(dbId);
      if (!opened) {
        return false;
      }

      final teamResult = await DatabaseService.instance
          .query('Teams', orderByChild: 'id', equalTo: 1);
      if (teamResult.isNotEmpty) {
        _team = Team.fromMap(teamResult.first);
        await _loadSeasons();
        setState(() {});
      } else {
        _team = null;
      }
    } else if (!kIsWeb) {
      // Mobile-specific loading
      const storage = FlutterSecureStorage();
      final lastDBUsed = await storage.read(key: 'last_db_used');
      if (lastDBUsed != null) {
        setState(() {
          _isLoading = true;
        });

        await _openCloudDatabase(lastDBUsed);

        setState(() {
          _isLoading = false;
        });
      }
    }

    return true;
  }

  Future<void> _loadSeasons() async {
    if (DatabaseService.instance.path.isEmpty) return;
    final results =
        await DatabaseService.instance.query('Seasons', orderBy: 'id DESC');
    _seasons = results.map((m) => Season.fromMap(m)).toList();
    await Future.wait(_seasons.map((s) async => await s.load()));
  }

  Future<String?> _pickCloudDatabase() async {
    if (DatabaseService.instance.isLocalDatabase) {
      await DatabaseService.instance.close();
      DatabaseService.instance.setProvider(FirebaseDBProvider());
    }

    final entries = await DatabaseService.instance.getAvailableDatabases();
    if (entries.isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.noCloudDatabasesFound),
          );
        },
      );
      return null;
    }

    return await showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Card(
              child: Padding(
                  padding: const EdgeInsets.all(50),
                  child: Column(children: [
                    Text(AppLocalizations.of(context)!.selectACloudDatabase),
                    DropdownMenu(
                        onSelected: (value) async {
                          Navigator.pop(context, value);
                        },
                        dropdownMenuEntries: entries
                            .map((e) => DropdownMenuEntry(value: e, label: e))
                            .toList())
                  ])));
        });
  }

  Future<String?> _pickFile() async {
    // 1. Request storage permission
    var status = Platform.isIOS
        ? await Permission.storage.request()
        : await Permission.manageExternalStorage.request();
    if (!status.isGranted) {
      await openAppSettings();

      status = Platform.isIOS
          ? await Permission.storage.request()
          : await Permission.manageExternalStorage.request();
      if (!status.isGranted) {
        return null;
      }
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

  Future<void> _pickTeamLogo() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      if (_team!.logoUrl != null && _team!.logoUrl!.isNotEmpty) {
        try {
          await FirebaseStorage.instance.refFromURL(_team!.logoUrl!).delete();
        } catch (e) {
          // Image may not exist, so we can ignore.
        }
      }
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('player_images/${DateTime.now().toIso8601String()}');
      await storageRef.putFile(File(pickedFile.path));
      final imageUrl = await storageRef.getDownloadURL();

      await DatabaseService.instance.update(
        'Teams',
        {'logoUrl': imageUrl},
        key: _team!.id.toString(),
      );

      final teamResult = await DatabaseService.instance
          .query('Teams', orderByChild: 'id', equalTo: _team!.id);
      if (teamResult.isNotEmpty) {
        setState(() {
          _team = Team.fromMap(teamResult.first);
        });
      }
    }
  }

  Future<void> _pickTeamColors() async {
    Color pickerColor1 = _team?.color1 ?? Colors.blue;
    Color pickerColor2 = _team?.color2 ?? Colors.red;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.pickTeamColors),
          content: SingleChildScrollView(
            child: Column(
              children: [
                Text(AppLocalizations.of(context)!.primaryColor),
                ColorPicker(
                  pickerColor: pickerColor1,
                  onColorChanged: (color) => pickerColor1 = color,
                ),
                Text(AppLocalizations.of(context)!.secondaryColor),
                ColorPicker(
                  pickerColor: pickerColor2,
                  onColorChanged: (color) => pickerColor2 = color,
                ),
              ],
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text(AppLocalizations.of(context)!.save),
              onPressed: () async {
                await DatabaseService.instance.update(
                  'Teams',
                  {
                    'color1': pickerColor1.toARGB32(),
                    'color2': pickerColor2.toARGB32()
                  },
                  key: _team!.id.toString(),
                );
                final teamResult = await DatabaseService.instance
                    .query('Teams', orderByChild: 'id', equalTo: _team!.id);
                if (teamResult.isNotEmpty) {
                  setState(() {
                    _team = Team.fromMap(teamResult.first);
                  });
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _createTeam() async {
    late String teamName;
    late String teamShortName;
    File? _imageFile;

    await showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return Card(
                child: Padding(
                    padding: const EdgeInsets.all(50),
                    child: Column(children: [
                      Text(AppLocalizations.of(context)!.newTeam),
                      GestureDetector(
                        onTap: SubscriptionService.instance.isSubscribed
                            ? () async {
                                final pickedFile = await ImagePicker()
                                    .pickImage(source: ImageSource.gallery);
                                if (pickedFile != null) {
                                  setModalState(() {
                                    _imageFile = File(pickedFile.path);
                                  });
                                }
                              }
                            : null,
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: _imageFile != null
                              ? FileImage(_imageFile!)
                              : (_team!.logoUrl != null &&
                                      _team!.logoUrl!.isNotEmpty
                                  ? NetworkImage(_team!.logoUrl!)
                                  : null) as ImageProvider?,
                          child: _imageFile == null &&
                                  (_team!.logoUrl == null ||
                                      _team!.logoUrl!.isEmpty)
                              ? const Icon(Icons.add_a_photo)
                              : null,
                        ),
                      ),
                      TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                              labelText:
                                  AppLocalizations.of(context)!.teamName),
                          onChanged: (name) => teamName = name),
                      TextField(
                          autofocus: true,
                          decoration: InputDecoration(
                              labelText:
                                  AppLocalizations.of(context)!.teamShortName),
                          onChanged: (name) => teamShortName = name),
                      const Spacer(),
                      TextButton(
                          onPressed: () {},
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                GestureDetector(
                                    child: Text(
                                        AppLocalizations.of(context)!.save,
                                        style: const TextStyle(fontSize: 20)),
                                    onTap: () async {
                                      if (teamName.isNotEmpty &&
                                          teamShortName.isNotEmpty) {
                                        await _saveTeam(teamName, teamShortName,
                                            logoUrl: _imageFile?.path);
                                        setState(() {});
                                        Navigator.pop(context);
                                      }
                                    }),
                                GestureDetector(
                                    child: Text(
                                        AppLocalizations.of(context)!
                                            .cancelButton,
                                        style: const TextStyle(fontSize: 20)),
                                    onTap: () {
                                      Navigator.pop(context);
                                    })
                              ]))
                    ])));
          });
        });
  }

  Future<void> _saveTeam(String teamName, String teamShortName,
      {Color? color1 = Colors.green,
      Color? color2 = Colors.green,
      String? logoUrl}) async {
    await DatabaseService.instance.insert('Teams', {
      'id': DateTime.now().millisecondsSinceEpoch,
      'fullName': teamName,
      'shortName': teamShortName,
      'color1': color1?.value,
      'color2': color2?.value,
      'logoUrl': logoUrl
    });
  }

  Future<void> _createSeason() async {
    late String seasonName;

    await showModalBottomSheet(
        context: context,
        builder: (context) {
          return Card(
              child: Padding(
                  padding: const EdgeInsets.all(50),
                  child: Column(children: [
                    Text(AppLocalizations.of(context)!.newSeason),
                    TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(context)!.seasonName),
                        onChanged: (name) => seasonName = name),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                              child: Text(AppLocalizations.of(context)!.save,
                                  style: const TextStyle(fontSize: 20)),
                              onPressed: () async {
                                await DatabaseService.instance
                                    .insert('Seasons', {
                                  'id': DateTime.now().millisecondsSinceEpoch,
                                  'name': seasonName,
                                  'teamId': _team!.id
                                });
                                await _loadSeasons();

                                setState(() {});
                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              }),
                          TextButton(
                              child: Text(
                                  AppLocalizations.of(context)!.cancelButton,
                                  style: const TextStyle(fontSize: 20)),
                              onPressed: () {
                                Navigator.pop(context);
                              })
                        ])
                  ])));
        });
  }
}
