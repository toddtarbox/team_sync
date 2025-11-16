import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
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
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/subscription_service.dart';
import 'package:team_sync/widgets/custom_appbar.dart';
import 'package:team_sync/widgets/event_stream_widget.dart';
import 'package:team_sync/widgets/scoreboard_widget.dart';
import 'package:team_sync/widgets/season_record.dart';

/// TeamSync-specific home page for single-team management
///
/// This page is designed for users managing a single team through a subscription.
/// Data is stored in subscriptionIds/{uid}/databases/{db}/ structure.
class TeamHomePage extends StatefulWidget {
  final String? databaseId;
  const TeamHomePage({super.key, this.databaseId});

  @override
  State<TeamHomePage> createState() => _TeamHomePageState();
}

class _TeamHomePageState extends State<TeamHomePage> {
  Team? _team;
  List<Season> _seasons = [];
  Game? _currentOrLastGame;
  Season? _currentSeason;
  late bool _isSubscribed;
  bool _isLoading = false;
  bool _isImporting = false;
  bool _isSharing = false;
  bool _isDrawerOpen =
      false; // Track drawer state for web - collapsed by default
  final _teamIdController = TextEditingController();
  late Future<bool> _loadFuture;
  Timer? _liveGameUpdateTimer;

  final _welcomeKey = GlobalKey();
  final _fabKey = GlobalKey();
  final _fabKeyOnly = GlobalKey();
  final _goProKey = GlobalKey();
  final _settingsKey = GlobalKey();
  final _proKeyOnly = GlobalKey();

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

    // Initialize the load future once
    _loadFuture = _load();

    if (!kIsWeb) {
      _setupShowcase();
      _checkIfFirstLaunch();
    }
  }

  void _setupShowcase() {
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
          textStyle: const TextStyle(color: Colors.white),
          hideActionWidgetForShowcase: [
            _welcomeKey,
            _settingsKey,
            _fabKeyOnly,
            _proKeyOnly
          ],
        ),
        TooltipActionButton(
          type: TooltipDefaultActionType.next,
          textStyle: const TextStyle(color: Colors.white),
          hideActionWidgetForShowcase: [_fabKeyOnly, _proKeyOnly],
        ),
      ],
      onDismiss: (key) {
        debugPrint('Dismissed at $key');
      },
    );
  }

  Future<void> _checkIfFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;
    final hasSeenNoDatabasePrompt =
        prefs.getBool('hasSeenNoDatabasePrompt') ?? false;

    if (isFirstLaunch) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        prefs.setBool('isFirstLaunch', false);

        // Mark that we've shown the database prompt through the showcase
        const storage = FlutterSecureStorage();
        final lastDBUsed = await storage.read(key: 'last_db_used');
        if (lastDBUsed == null && DatabaseService.instance.path.isEmpty) {
          prefs.setBool('hasSeenNoDatabasePrompt', true);
        }

        ShowcaseView.get().startShowCase(
          [_welcomeKey, _fabKey, _goProKey, _settingsKey],
        );
      });
    } else if (!hasSeenNoDatabasePrompt) {
      // Check if user has no database after first launch
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        const storage = FlutterSecureStorage();
        final lastDBUsed = await storage.read(key: 'last_db_used');

        if (lastDBUsed == null && DatabaseService.instance.path.isEmpty) {
          prefs.setBool('hasSeenNoDatabasePrompt', true);
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            await _showDatabaseSetupPrompt();
          }
        }
      });
    }
  }

  Future<void> _showDatabaseSetupPrompt() async {
    final shouldShowOptions = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.welcomeToTeamSync),
          content: Text(AppLocalizations.of(context)!.noDatabaseFoundMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)!.remindMeLater),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppLocalizations.of(context)!.getStarted),
            ),
          ],
        );
      },
    );

    if (shouldShowOptions == true && mounted) {
      await _showCreateOptions(context);
    }
  }

  @override
  void dispose() {
    _liveGameUpdateTimer?.cancel();
    if (!kIsWeb) {
      ShowcaseView.get().unregister();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Web viewer mode - show team ID input
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
                      context.go('/team/${_teamIdController.text}');
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
      key: ValueKey(_team?.id), // Force rebuild when team changes
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: CustomAppBar(
        key: ValueKey('appbar_${_team?.id}'), // Force appbar rebuild
        team: _team,
        title: const Text('TeamSync',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        bottom: (DatabaseService.instance.path.isNotEmpty || _team != null)
            ? PreferredSize(
                preferredSize: const Size.fromHeight(80),
                child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_team?.logoUrl != null &&
                              _team!.logoUrl!.isNotEmpty)
                            CircleAvatar(
                              radius: 20,
                              child: ClipOval(
                                child: Image.network(
                                  _team!.logoUrl!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Text(_team!.fullName[0]);
                                  },
                                ),
                              ),
                            ),
                          if (_team?.logoUrl != null &&
                              _team!.logoUrl!.isNotEmpty)
                            const SizedBox(width: 10),
                          Text(_team?.fullName ?? 'TeamSync',
                              style: const TextStyle(fontSize: 18)),
                        ])))
            : null,
        actions: _buildAppBarActions(),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      body: _buildBody(),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      if (!kIsWeb && _isSubscribed)
        IconButton(
          icon: const Icon(Icons.share, color: Colors.yellow),
          onPressed: () => _shareDatabase(),
        ),
      if (!kIsWeb)
        Showcase(
          key: DatabaseService.instance.path.isEmpty ? _goProKey : _proKeyOnly,
          description: DatabaseService.instance.path.isEmpty
              ? 'Subscribe to unlock premium features'
              : _team == null
                  ? 'Subscribe to unlock premium features'
                  : 'You have premium access',
          child: TextButton(
            onPressed: () async {
              if (!_isSubscribed) {
                await SubscriptionService.instance.purchaseSubscription();
                setState(() {});
              }
            },
            child: Text(
              _isSubscribed ? 'Pro' : 'Go Pro',
              style: const TextStyle(color: Colors.yellow),
            ),
          ),
        ),
      if (_team != null)
        IconButton(
          onPressed: () {
            final databaseId = DatabaseService.instance.publicShareId;
            if (databaseId != null) {
              context.go('/team/$databaseId/records', extra: _team);
            }
          },
          icon: const Icon(Icons.leaderboard),
        ),
      if (_team != null)
        IconButton(
          onPressed: () {
            final databaseId = DatabaseService.instance.publicShareId;
            if (databaseId != null) {
              context.go('/team/$databaseId/history', extra: _team);
            }
          },
          icon: const Icon(Icons.manage_history_outlined),
        ),
      if (!kIsWeb)
        Showcase(
          key: _settingsKey,
          description: 'Configure your team settings',
          child: IconButton(
            onPressed: () {
              context.go('/settings');
            },
            icon: const Icon(Icons.settings),
          ),
        )
      else
        IconButton(
          onPressed: () {
            context.go('/settings');
          },
          icon: const Icon(Icons.settings),
        ),
    ];
  }

  Widget? _buildFloatingActionButton() {
    if (kIsWeb) {
      return (!_isDrawerOpen && _team != null
          ? FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isDrawerOpen = true;
                });
              },
              tooltip: 'Show game details',
              child: const Icon(Icons.event),
            )
          : null);
    }

    // Mobile - use Showcase (already registered)
    return Showcase(
      key: DatabaseService.instance.path.isEmpty ? _fabKey : _fabKeyOnly,
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
    );
  }

  Widget _buildBody() {
    return Stack(
      children: [
        FutureBuilder(
          future: _loadFuture,
          builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
            if (!snapshot.hasData || _isLoading || _isImporting || _isSharing) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return _buildMainContent();
            }
          },
        ),
        if (_isImporting || _isSharing) _buildLoadingOverlay(),
      ],
    );
  }

  Widget _buildMainContent() {
    if (!kIsWeb && DatabaseService.instance.path.isEmpty) {
      final welcomeChild = Center(
          child: Text(AppLocalizations.of(context)!.pleaseCreateOrOpenADatabase,
              style: const TextStyle(fontSize: 24)));
      return Showcase(
          key: _welcomeKey,
          description:
              'Welcome to TeamSync! Let\'s take a look around and get you started managing your team!',
          child: welcomeChild);
    }

    if (!kIsWeb && _team == null) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(AppLocalizations.of(context)!.noTeamFound,
            style: const TextStyle(fontSize: 24)),
        GestureDetector(
            onTap: () {
              _handleSelection(context, 'team');
            },
            child: Text(AppLocalizations.of(context)!.createNewTeamToStart,
                style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.secondary))),
      ]));
    }

    if (!kIsWeb && _seasons.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(AppLocalizations.of(context)!.noSeasonsFound,
            style: const TextStyle(fontSize: 24)),
        GestureDetector(
            onTap: () {
              _handleSelection(context, 'season');
            },
            child: Text(AppLocalizations.of(context)!.createNewSeasonToStart,
                style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.secondary))),
      ]));
    }

    // Main content with seasons
    return _buildSeasonsView();
  }

  Widget _buildSeasonsView() {
    if (kIsWeb && _isDrawerOpen) {
      return Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildSeasonsList(),
          ),
          Expanded(
            flex: 1,
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Stack(
                children: [
                  EventStreamWidget(
                    game: _currentOrLastGame,
                    teamId: _team?.id,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _isDrawerOpen = false;
                        });
                      },
                      tooltip: 'Close sidebar',
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context)
                            .colorScheme
                            .surface
                            .withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return _buildSeasonsList();
  }

  Widget _buildSeasonsList() {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              if (_currentSeason != null && _currentOrLastGame != null)
                ScoreboardWidget(
                  season: _currentSeason!,
                  game: _currentOrLastGame!,
                  teamId: _team!.id,
                ),
              if (_seasons.isNotEmpty) ...[
                const SizedBox(height: 16),
                SeasonRecord(_seasons, singleSeason: false),
              ],
              const SizedBox(height: 16),
              const Text(
                'Seasons',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ]),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final season = _seasons[index];
                final databaseId = DatabaseService.instance.publicShareId;

                return GestureDetector(
                  onTap: () {
                    if (databaseId != null) {
                      context.go('/team/$databaseId/season/${season.id}',
                          extra: season);
                    }
                  },
                  child: Card(
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              season.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(5),
                          margin: const EdgeInsets.all(10),
                          child: Center(child: SeasonRecord([season])),
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: _seasons.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.75),
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
    );
  }

  // Data loading methods
  Future<bool> _load() async {
    if (widget.databaseId != null) {
      return await _loadFromDatabaseId();
    } else if (!kIsWeb) {
      return await _loadLocalDatabase();
    }
    return true;
  }

  Future<bool> _loadFromDatabaseId() async {
    final dbId = widget.databaseId!;
    final opened = await DatabaseService.instance.openFromId(dbId);
    if (!opened) {
      return false;
    }

    final teamResult =
        await DatabaseService.instance.query('Teams', orderByChild: 'id');
    if (teamResult.isNotEmpty) {
      // First try team with id=1
      var teamMap = teamResult.firstWhere(
        (t) => t['id'] == 1,
        orElse: () => teamResult.first,
      );

      setState(() {
        _team = Team.fromMap(teamMap);
      });
      await _loadSeasons();
      setState(() {});
    }
    return true;
  }

  Future<bool> _loadLocalDatabase() async {
    const storage = FlutterSecureStorage();
    final lastDBUsed = await storage.read(key: 'last_db_used');
    if (lastDBUsed != null && lastDBUsed.isNotEmpty) {
      await DatabaseService.instance.open(lastDBUsed);
    }

    if (DatabaseService.instance.path.isNotEmpty) {
      final teamResult =
          await DatabaseService.instance.query('Teams', orderByChild: 'id');
      if (teamResult.isNotEmpty) {
        var teamMap = teamResult.firstWhere(
          (t) => t['id'] == 1,
          orElse: () => teamResult.first,
        );

        _team = Team.fromMap(teamMap);
        await _loadSeasons();
      }
    }

    return true;
  }

  Future<void> _loadSeasons() async {
    if (_team == null) return;

    _seasons = await Season.fromTeamId(_team!.id);

    if (_seasons.isNotEmpty) {
      await Future.wait(_seasons.map((s) async => await s.load()));
    }

    // Seasons are already sorted by Season.fromTeamId (most recent first)

    // Find current season and load current/last game
    _currentSeason = _seasons.isNotEmpty ? _seasons.first : null;

    if (_currentSeason != null) {
      await _loadCurrentOrLastGame();
      _startLiveGameUpdateTimer();
    }
  }

  Future<void> _loadCurrentOrLastGame() async {
    if (_team == null) return;

    try {
      // Get all games for this team
      final games = await Game.listFromTeamId(_team!.id);

      if (games.isEmpty) {
        _currentOrLastGame = null;
        return;
      }

      final now = DateTime.now();

      // Filter to only games that have started or completed
      final startedOrCompletedGames = games.where((game) {
        final isStarted = game.gameStatus.index > 0;
        final isNotInFuture = game.date.isBefore(now) ||
            (game.date.year == now.year &&
                game.date.month == now.month &&
                game.date.day == now.day);
        return isStarted || (game.gameStatus.index == 0 && isNotInFuture);
      }).toList();

      if (startedOrCompletedGames.isEmpty) {
        _currentOrLastGame = null;
        return;
      }

      // Sort games by date in descending order (most recent first)
      startedOrCompletedGames.sort((a, b) => b.date.compareTo(a.date));

      // First check for any live games (status between 1-8)
      final liveGames = startedOrCompletedGames
          .where(
              (game) => game.gameStatus.index > 0 && game.gameStatus.index < 9)
          .toList();

      if (liveGames.isNotEmpty) {
        _currentOrLastGame = liveGames.first;
      } else {
        _currentOrLastGame = startedOrCompletedGames.first;
      }

      // Load game events for the selected game
      if (_currentOrLastGame != null) {
        await _currentOrLastGame!.loadGameEvents();
      }
    } catch (e) {
      debugPrint('Error loading current/last game: $e');
      _currentOrLastGame = null;
    }
  }

  void _startLiveGameUpdateTimer() {
    _liveGameUpdateTimer?.cancel();
    _liveGameUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _loadCurrentOrLastGame().then((_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  // Action handlers
  Future<void> _showCreateOptions(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext builderContext) {
        return Wrap(
          children: [
            if (DatabaseService.instance.path.isEmpty) ...[
              ListTile(
                leading: Icon(Icons.cloud_sync_rounded,
                    color: Theme.of(context).colorScheme.secondary),
                title: Text(
                    AppLocalizations.of(context)!.openExistingCloudDatabase),
                onTap: () {
                  Navigator.of(builderContext).pop();
                  _handleSelection(context, 'existingCloudDatabase');
                },
              ),
              ListTile(
                leading: Icon(Icons.cloud_rounded,
                    color: Theme.of(context).colorScheme.secondary),
                title:
                    Text(AppLocalizations.of(context)!.createNewCloudDatabase),
                onTap: () async {
                  Navigator.of(builderContext).pop();
                  await _handleSelection(context, 'newCloudDatabase');
                },
              ),
            ],
            if (_team != null) ...[
              ListTile(
                leading: Icon(Icons.calendar_today,
                    color: Theme.of(context).colorScheme.secondary),
                title: Text(AppLocalizations.of(context)!.createNewSeason),
                onTap: () {
                  Navigator.of(builderContext).pop();
                  _handleSelection(context, 'season');
                },
              ),
              ListTile(
                leading: Icon(Icons.palette,
                    color: Theme.of(context).colorScheme.secondary),
                title: const Text('Change Team Colors'),
                onTap: () {
                  Navigator.of(builderContext).pop();
                  _handleSelection(context, 'teamColors');
                },
              ),
            ],
            if (DatabaseService.instance.path.isNotEmpty && _team == null)
              ListTile(
                leading: Icon(Icons.group,
                    color: Theme.of(context).colorScheme.secondary),
                title: const Text('Create New Team'),
                onTap: () {
                  Navigator.of(builderContext).pop();
                  _handleSelection(context, 'team');
                },
              ),
          ],
        );
      },
    );
  }

  Future<void> _handleSelection(BuildContext context, String option) async {
    // Capture the ScaffoldMessenger before the async gap
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    switch (option) {
      case 'existingCloudDatabase':
        final databaseName = await _pickCloudDatabase();
        if (databaseName != null) {
          await _openCloudDatabase(databaseName);
        }
        return;
      case 'existingBackupDatabase':
        if (!kIsWeb) {
          final existingDB = await _pickFile();
          if (existingDB != null) {
            await _openBackupDatabase(existingDB);
          }
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
        if (!kIsWeb) {
          ShowcaseView.get().startShowCase([_fabKeyOnly]);
        }
        break;
      case 'season':
        await _createSeason();
        if (!kIsWeb) {
          ShowcaseView.get().startShowCase([_fabKeyOnly]);
        }
        break;
      case 'teamColors':
        await _pickTeamColors();
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

  Future<void> _createTeam() async {
    late String teamName;
    late String teamShortName;
    File? imageFile;

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
                      if (!kIsWeb)
                        GestureDetector(
                          onTap: SubscriptionService.instance.isSubscribed
                              ? () async {
                                  final pickedFile = await ImagePicker()
                                      .pickImage(source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    setModalState(() {
                                      imageFile = File(pickedFile.path);
                                    });
                                  }
                                }
                              : null,
                          child: CircleAvatar(
                            radius: 50,
                            backgroundImage: imageFile != null
                                ? FileImage(imageFile!)
                                : null,
                            child: imageFile == null
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
                          decoration: InputDecoration(
                              labelText:
                                  AppLocalizations.of(context)!.teamShortName),
                          onChanged: (name) => teamShortName = name),
                      const Spacer(),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            TextButton(
                                child: Text(AppLocalizations.of(context)!.save,
                                    style: const TextStyle(fontSize: 20)),
                                onPressed: () async {
                                  if (teamName.isNotEmpty &&
                                      teamShortName.isNotEmpty) {
                                    await _saveTeam(teamName, teamShortName,
                                        logoUrl: imageFile?.path);
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
        });
  }

  Future<void> _saveTeam(String teamName, String teamShortName,
      {Color? color1 = Colors.green,
      Color? color2 = Colors.green,
      String? logoUrl}) async {
    final teamId = DateTime.now().millisecondsSinceEpoch;
    await DatabaseService.instance.insert('Teams', {
      'id': teamId,
      'fullName': teamName,
      'shortName': teamShortName,
      'color1': color1?.toARGB32(),
      'color2': color2?.toARGB32(),
      'logoUrl': logoUrl
    });

    // Load the new team
    final teamResult = await DatabaseService.instance
        .query('Teams', orderByChild: 'id', equalTo: teamId);
    if (teamResult.isNotEmpty) {
      _team = Team.fromMap(teamResult.first);
      await _loadSeasons();
      setState(() {});
    }
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
                                if (seasonName.isNotEmpty) {
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

  Future<void> _pickTeamColors() async {
    if (_team == null) return;

    Color pickerColor1 = _team!.color1;
    Color pickerColor2 = _team!.color2;

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

  Future<void> _shareDatabase() async {
    setState(() {
      _isSharing = true;
    });
    try {
      final id = await DatabaseService.instance.shareDatabase();
      final url = 'https://team-sync-soccer.web.app/#/team/$id';

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Share this URL'),
            content: SelectableText(url,
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied to clipboard!')),
                  );
                },
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Error during share, please try again'),
            backgroundColor: Colors.red));
      }
      debugPrint(e.toString());
    }
    setState(() {
      _isSharing = false;
    });
  }
}
