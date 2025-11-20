import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:sqflite/sqflite.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/auth_service.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/database_sharing_service.dart';
import 'package:team_sync/services/subscription_service.dart';
import 'package:team_sync/services/twitter_service.dart';
import 'package:team_sync/utils/navigation_helper.dart';
import 'package:team_sync/widgets/adhoc_tweet_dialog.dart';
import 'package:team_sync/widgets/common_page_header.dart';
import 'package:team_sync/widgets/event_stream_widget.dart';
import 'package:team_sync/widgets/responsive_avatar.dart';
import 'package:team_sync/widgets/scoreboard_widget.dart';
import 'package:team_sync/widgets/season_record.dart';
import 'package:team_sync/widgets/standard_appbar.dart';
import 'package:team_sync/widgets/video_thumbnail.dart';
import 'package:url_launcher/url_launcher.dart';

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
  Game? _nextUpcomingGame;
  List<Season> _seasons = [];
  Game? _currentOrLastGame;
  Season? _currentSeason;
  late bool _isSubscribed;
  bool _isImporting = false;
  bool _isSharing = false;
  bool _isDrawerOpen =
      false; // Track drawer state for web - collapsed by default
  final _teamIdController = TextEditingController();
  late Future<bool> _loadFuture;
  Timer? _liveGameUpdateTimer;
  StreamSubscription<bool>? _subscriptionListener;

  final _welcomeKey = GlobalKey();
  final _fabKey = GlobalKey();
  final _fabKeyOnly = GlobalKey();
  final _goProKey = GlobalKey();
  final _settingsKey = GlobalKey();
  final _proKeyOnly = GlobalKey();

  @override
  void initState() {
    super.initState();
    _subscriptionListener =
        SubscriptionService.instance.subscriptionState.listen((isSubscribed) {
      if (mounted) {
        setState(() {
          _isSubscribed = isSubscribed;
        });
      }
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
    _subscriptionListener?.cancel();
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
                      NavigationHelper.navigateTo(
                          context, '/team/${_teamIdController.text}');
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
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      appBar: buildStandardAppBar(
        context: context,
        team: _team,
        title: const Text('TeamSync',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        actions: _buildAppBarActions(),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      body: Column(
        children: [
          if (_team != null) CommonPageHeader(team: _team!),
          _buildLiveBanner(),
          // Recent highlights (web only)
          if (kIsWeb) _buildRecentHighlights(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    return [
      // Show "Go Pro" button only if not subscribed and not on web
      if (!kIsWeb && !_isSubscribed)
        Showcase(
          key: _goProKey,
          description: DatabaseService.instance.path.isEmpty
              ? 'Subscribe to unlock premium features'
              : _team == null
                  ? 'Subscribe to unlock premium features'
                  : 'You have premium access',
          child: TextButton(
            onPressed: () async {
              await SubscriptionService.instance.purchaseSubscription();
              setState(() {});
            },
            child: const Text(
              'Go Pro',
              style: TextStyle(color: Colors.yellow),
            ),
          ),
        ),
      // More menu with all other actions
      if (!kIsWeb)
        Showcase(
          key: _settingsKey,
          description:
              'Tap here to access settings, records, history, and more',
          child: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              switch (value) {
                case 'tweet':
                  await AdhocTweetDialog.show(context, teamId: _team?.id);
                  break;
                case 'share':
                  await _shareDatabase();
                  break;
                case 'records':
                  final databaseId = DatabaseService.instance.publicShareId;
                  if (databaseId != null) {
                    NavigationHelper.navigateTo(
                        context, '/team/$databaseId/records',
                        extra: _team);
                  }
                  break;
                case 'history':
                  final databaseId = DatabaseService.instance.publicShareId;
                  if (databaseId != null) {
                    NavigationHelper.navigateTo(
                        context, '/team/$databaseId/history',
                        extra: _team);
                  }
                  break;
                case 'settings':
                  final databaseId = DatabaseService.instance.publicShareId;
                  if (databaseId != null) {
                    NavigationHelper.navigateTo(
                        context, '/team/$databaseId/settings',
                        extra: _team);
                  }
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                // Tweet option - show on mobile when team exists
                if (!kIsWeb && _team != null)
                  const PopupMenuItem<String>(
                    value: 'tweet',
                    child: Row(
                      children: [
                        Icon(Icons.send),
                        SizedBox(width: 12),
                        Text('Send Tweet'),
                      ],
                    ),
                  ),
                // Share option - show on mobile when subscribed
                if (!kIsWeb && _isSubscribed)
                  const PopupMenuItem<String>(
                    value: 'share',
                    child: Row(
                      children: [
                        Icon(Icons.share, color: Colors.yellow),
                        SizedBox(width: 12),
                        Text('Share Database'),
                      ],
                    ),
                  ),
                // Records option - show when team exists
                if (_team != null)
                  const PopupMenuItem<String>(
                    value: 'records',
                    child: Row(
                      children: [
                        Icon(Icons.leaderboard),
                        SizedBox(width: 12),
                        Text('Records'),
                      ],
                    ),
                  ),
                // History option - show when team exists
                if (_team != null)
                  const PopupMenuItem<String>(
                    value: 'history',
                    child: Row(
                      children: [
                        Icon(Icons.manage_history_outlined),
                        SizedBox(width: 12),
                        Text('History'),
                      ],
                    ),
                  ),
                // Settings option - always show
                const PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      Icon(Icons.settings),
                      SizedBox(width: 12),
                      Text('Settings'),
                    ],
                  ),
                ),
              ];
            },
          ),
        )
      else
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            switch (value) {
              case 'records':
                final databaseId = DatabaseService.instance.publicShareId;
                if (databaseId != null) {
                  NavigationHelper.navigateTo(
                      context, '/team/$databaseId/records',
                      extra: _team);
                }
                break;
              case 'history':
                final databaseId = DatabaseService.instance.publicShareId;
                if (databaseId != null) {
                  NavigationHelper.navigateTo(
                      context, '/team/$databaseId/history',
                      extra: _team);
                }
                break;
              case 'settings':
                final databaseId = DatabaseService.instance.publicShareId;
                if (databaseId != null) {
                  NavigationHelper.navigateTo(
                      context, '/team/$databaseId/settings',
                      extra: _team);
                }
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              // Records option - show when team exists
              if (_team != null)
                const PopupMenuItem<String>(
                  value: 'records',
                  child: Row(
                    children: [
                      Icon(Icons.leaderboard),
                      SizedBox(width: 12),
                      Text('Records'),
                    ],
                  ),
                ),
              // History option - show when team exists
              if (_team != null)
                const PopupMenuItem<String>(
                  value: 'history',
                  child: Row(
                    children: [
                      Icon(Icons.manage_history_outlined),
                      SizedBox(width: 12),
                      Text('History'),
                    ],
                  ),
                ),
              // Settings option - always show
              const PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(Icons.settings),
                    SizedBox(width: 12),
                    Text('Settings'),
                  ],
                ),
              ),
            ];
          },
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
            // Show loading while future is not done
            if (snapshot.connectionState == ConnectionState.waiting ||
                snapshot.connectionState == ConnectionState.active) {
              return const Center(child: CircularProgressIndicator());
            }

            // Show additional loading states
            if (_isImporting || _isSharing) {
              return const Center(child: CircularProgressIndicator());
            }

            // Show error if future completed with error
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error: ${snapshot.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loadFuture = _load();
                        });
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Future completed successfully, show content
            return _buildMainContent();
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
                // Enhanced Overall Record Card
                Card(
                  elevation: 4,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.3),
                          Theme.of(context).colorScheme.surfaceContainerHigh,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emoji_events,
                              color: Theme.of(context).colorScheme.primary,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                _getTeamPerformanceTitle(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SeasonRecord(_seasons,
                            singleSeason: false, isOverall: true),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              // Section header for individual seasons
              if (_seasons.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'Seasons',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
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
                      NavigationHelper.navigateTo(
                          context, '/team/$databaseId/season/${season.id}',
                          extra: season);
                    }
                  },
                  child: Card(
                    elevation: 3,
                    clipBehavior: Clip.antiAlias,
                    color: Theme.of(context).colorScheme.surface,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Header section with gradient background
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                season.team.color1.withValues(alpha: 0.15),
                                season.team.color2.withValues(alpha: 0.10),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (season.team.logoUrl != null &&
                                  season.team.logoUrl!.isNotEmpty) ...[
                                ResponsiveAvatar(
                                  size: 24,
                                  imageUrl: season.team.logoUrl,
                                  initials: season.team.fullName[0],
                                ),
                                const SizedBox(width: 12),
                              ],
                              Flexible(
                                child: Text(
                                  season.name,
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
                                  textAlign: TextAlign.center,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (season.logoUrl != null &&
                                  season.logoUrl!.isNotEmpty) ...[
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () {
                                    _showSeasonPhoto(context, season.logoUrl);
                                  },
                                  child: ResponsiveAvatar(
                                    size: 24,
                                    imageUrl: season.logoUrl,
                                    initials: season.name[0],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Stats section
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: SeasonRecord([season]),
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
      color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.75),
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
                style: TextStyle(
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }

  // Data loading methods
  Future<bool> _load() async {
    try {
      if (widget.databaseId != null) {
        final result = await _loadFromDatabaseId();
        return result;
      } else if (!kIsWeb) {
        final result = await _loadLocalDatabase();
        return result;
      }
      return true;
    } catch (e, stackTrace) {
      debugPrint('[TeamHomePage] Error in _load: $e');
      debugPrint('[TeamHomePage] Stack trace: $stackTrace');
      rethrow;
    }
  }

  Future<bool> _loadFromDatabaseId() async {
    final dbId = widget.databaseId!;
    final opened = await DatabaseService.instance.openFromId(dbId);
    if (!opened) {
      return false;
    }

    final teamResult = await DatabaseService.instance
        .query('Teams', orderBy: 'id', equalTo: 1);
    if (teamResult.isNotEmpty) {
      // First try team with id=1
      var teamMap = teamResult.firstWhere(
        (t) => t['id'] == 1,
        orElse: () => teamResult.first,
      );

      final team = Team.fromMap(teamMap);
      if (_team == null) {
        setState(() {
          _team = team;
        });
      } else {
        _team = team;
      }
      await _loadSeasons();
    }
    return true;
  }

  Future<bool> _loadLocalDatabase() async {
    try {
      const storage = FlutterSecureStorage();
      final lastDBUsed = await storage.read(key: 'last_db_used');

      if (lastDBUsed != null && lastDBUsed.isNotEmpty) {
        await DatabaseService.instance.open(lastDBUsed);
      }

      if (DatabaseService.instance.path.isNotEmpty) {
        final teamResult = await DatabaseService.instance
            .query('Teams', orderBy: 'id', equalTo: 1);
        if (teamResult.isNotEmpty) {
          _team = Team.fromMap(teamResult.first);
          await _loadSeasons();
        }
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('[TeamHomePage] Error in _loadLocalDatabase: $e');
      debugPrint('[TeamHomePage] Stack trace: $stackTrace');
      return false;
    }
  }

  Future<void> _loadSeasons() async {
    if (_team == null) {
      return;
    }

    final teamId = _team!.id;
    _seasons = await Season.fromTeamId(teamId);

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

  /// Get Team Performance title with "since YYYY" from oldest season
  String _getTeamPerformanceTitle() {
    if (_seasons.isEmpty) {
      return 'Team Performance';
    }

    // Seasons are sorted most recent first, so the last one is the oldest
    final oldestSeason = _seasons.last;

    // Try to extract a 4-digit year from the season name
    final yearMatch = RegExp(r'\b(19|20)\d{2}\b').firstMatch(oldestSeason.name);

    if (yearMatch != null) {
      final year = yearMatch.group(0);
      return 'Team Performance (Since $year)';
    }

    return 'Team Performance';
  }

  Future<void> _loadCurrentOrLastGame() async {
    if (_team == null) return;

    try {
      // Get all games for this team
      final games = await Game.listFromTeamId(_team!.id);

      if (games.isEmpty) {
        _currentOrLastGame = null;
        _nextUpcomingGame = null;
        return;
      }

      final now = DateTime.now();

      // Compute upcoming games (future dates) to show a "next game" banner on web
      final upcomingGames =
          games.where((game) => game.date.isAfter(now)).toList();
      upcomingGames.sort((a, b) => a.date.compareTo(b.date));
      _nextUpcomingGame = upcomingGames.isNotEmpty ? upcomingGames.first : null;

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
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Error loading current/last game: $e');
      _currentOrLastGame = null;
      _nextUpcomingGame = null;
    }
  }

  void _startLiveGameUpdateTimer() {
    _liveGameUpdateTimer?.cancel();

    // Only start timer if there's actually a current game to update
    if (_currentOrLastGame == null) {
      return;
    }

    // Only update live games (status between 1-8)
    final isLiveGame = _currentOrLastGame!.gameStatus.index > 0 &&
        _currentOrLastGame!.gameStatus.index < 9;

    if (!isLiveGame) {
      return;
    }

    _liveGameUpdateTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        _loadCurrentOrLastGame().then((_) {
          if (mounted) setState(() {});
        });
      }
    });
  }

  // Action handlers
  /// Ensures user is signed in before accessing cloud features.
  /// Shows sign-in dialog if not signed in.
  /// Returns true if user is signed in, false otherwise.
  Future<bool> _ensureUserSignedIn() async {
    if (FirebaseAuth.instance.currentUser != null) {
      return true;
    }

    if (!mounted) return false;

    // Show sign-in dialog
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Sign In Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You need to sign in to access cloud databases.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.g_mobiledata),
                  label: const Text('Sign in with Google'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  onPressed: () async {
                    try {
                      await AuthService.instance.signInWithGoogle();
                      if (mounted) {
                        Navigator.of(context).pop(true);
                      }
                    } catch (e) {
                      debugPrint('Google sign-in error: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Sign-in failed: ${e.toString()}'),
                            backgroundColor:
                                Theme.of(context).colorScheme.error,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
              // Only show Apple sign-in on iOS and web
              if (AuthService.instance.isAppleSignInAvailable) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.apple),
                    label: const Text('Sign in with Apple'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                      backgroundColor:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
                    ),
                    onPressed: () async {
                      try {
                        await AuthService.instance.signInWithApple();
                        if (mounted) {
                          Navigator.of(context).pop(true);
                        }
                      } catch (e) {
                        debugPrint('Apple sign-in error: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sign-in failed: ${e.toString()}'),
                              backgroundColor:
                                  Theme.of(context).colorScheme.error,
                            ),
                          );
                        }
                      }
                    },
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    return result == true;
  }

  /// Get the name of the authentication provider (Google or Apple)
  String _getAuthProviderName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'Unknown';

    // Check provider data to determine which provider was used
    for (var provider in user.providerData) {
      if (provider.providerId == 'google.com') {
        return 'Google';
      } else if (provider.providerId == 'apple.com') {
        return 'Apple';
      }
    }

    // Fallback - check email domain or display name
    if (user.email?.contains('@privaterelay.appleid.com') == true) {
      return 'Apple';
    }

    return 'Unknown';
  }

  /// Handle user logout
  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Log Out'),
          content: const Text(
            'Are you sure you want to log out? You will need to sign in again to access cloud databases.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Log Out'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        // Close any open database
        await DatabaseService.instance.close();

        // Sign out from Firebase
        await AuthService.instance.signOut();

        if (mounted) {
          // Clear local state
          setState(() {
            _team = null;
            _seasons = [];
            _currentOrLastGame = null;
            _nextUpcomingGame = null;
            _currentSeason = null;
          });

          // Show confirmation
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Logged out successfully'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error during logout: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error logging out: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _showCreateOptions(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext builderContext) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.cloud_sync_rounded,
                  color: Theme.of(context).colorScheme.secondary),
              title:
                  Text(AppLocalizations.of(context)!.openExistingCloudDatabase),
              onTap: () {
                Navigator.of(builderContext).pop();
                _handleSelection(context, 'existingCloudDatabase');
              },
            ),
            ListTile(
              leading: Icon(Icons.cloud_rounded,
                  color: Theme.of(context).colorScheme.secondary),
              title: Text(AppLocalizations.of(context)!.createNewCloudDatabase),
              onTap: () async {
                Navigator.of(builderContext).pop();
                await _handleSelection(context, 'newCloudDatabase');
              },
            ),
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
              ListTile(
                leading: Icon(Icons.videocam,
                    color: Theme.of(context).colorScheme.secondary),
                title: Text(AppLocalizations.of(context)!.setLiveLink),
                onTap: () {
                  Navigator.of(builderContext).pop();
                  _handleSelection(context, 'setLiveLink');
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
            backgroundColor: Theme.of(context).colorScheme.primary,
          ));
        } catch (e) {
          scaffoldMessenger.showSnackBar(SnackBar(
            content: Text('Error during import: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
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
      case 'setLiveLink':
        await _editLiveLink();
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
        .query('Teams', orderBy: 'id', equalTo: 1);
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

      // Check if user is signed in first
      if (!await _ensureUserSignedIn()) {
        return;
      }

      DatabaseService.instance.setProvider(FirebaseDBProvider());

      await DatabaseService.instance.open(databaseName);

      const storage = FlutterSecureStorage();
      await storage.write(key: 'last_db_used', value: databaseName);

      final teamResult = await DatabaseService.instance
          .query('Teams', orderBy: 'id', equalTo: 1);
      if (teamResult.isNotEmpty) {
        final team = Team.fromMap(teamResult.first);
        if (_team == null) {
          setState(() {
            _team = team;
          });
        } else {
          _team = team;
        }

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
    // Check if user is signed in first
    if (!await _ensureUserSignedIn()) {
      return null;
    }

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
                          child: ResponsiveAvatar(
                            backgroundImage: imageFile != null
                                ? FileImage(imageFile!)
                                : null,
                            initials: '',
                            fallbackIcon: const Icon(Icons.add_a_photo),
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
                if (mounted) {
                  Navigator.of(context).pop();
                }
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
      final databaseName = DatabaseService.instance.path;

      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => _DatabaseSharingDialog(
            publicUrl: url,
            databaseName: databaseName,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Error during share, please try again'),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
      debugPrint(e.toString());
    }
    setState(() {
      _isSharing = false;
    });
  }

  Future<void> _editLiveLink() async {
    if (_team == null) return;

    String liveLink = _team!.liveUrl ?? '';

    await showModalBottomSheet(
        context: context,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(AppLocalizations.of(context)!.setLiveLink,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.liveUrlLabel),
                  controller: TextEditingController(text: liveLink),
                  onChanged: (v) => liveLink = v,
                ),
                const SizedBox(height: 12),
                Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                          onPressed: () async {
                            // Save
                            await DatabaseService.instance.update(
                              'Teams',
                              {'liveUrl': liveLink},
                              key: _team!.id.toString(),
                            );
                            final teamResult = await DatabaseService.instance
                                .query('Teams',
                                    orderByChild: 'id', equalTo: _team!.id);
                            if (teamResult.isNotEmpty) {
                              setState(() {
                                _team = Team.fromMap(teamResult.first);
                              });
                            }
                            if (mounted) Navigator.pop(context);
                          },
                          child: Text(AppLocalizations.of(context)!.save)),
                      TextButton(
                          onPressed: () async {
                            // Remove
                            await DatabaseService.instance.update(
                              'Teams',
                              {'liveUrl': ''},
                              key: _team!.id.toString(),
                            );
                            final teamResult = await DatabaseService.instance
                                .query('Teams',
                                    orderByChild: 'id', equalTo: _team!.id);
                            if (teamResult.isNotEmpty) {
                              setState(() {
                                _team = Team.fromMap(teamResult.first);
                              });
                            }
                            if (mounted) Navigator.pop(context);
                          },
                          child:
                              Text(AppLocalizations.of(context)!.removeButton)),
                    ])
              ]),
            );
          });
        });
  }

  /// Generate and send a promotional tweet for the upcoming game
  Future<void> _tweetUpcomingGame() async {
    if (_nextUpcomingGame == null || _team == null) {
      return;
    }

    // Generate promotional tweet text
    final tweetText = _generateUpcomingGameTweet();

    // Show dialog with pre-filled tweet text that user can edit
    final textController = TextEditingController(text: tweetText);
    String editedText = tweetText;

    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Promote Upcoming Game'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Review and edit the promotional tweet below:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: textController,
                      decoration: const InputDecoration(
                        hintText: 'Tweet text',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 5,
                      maxLength: 280,
                      onChanged: (value) {
                        setDialogState(() {
                          editedText = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${editedText.length}/280 characters',
                      style: TextStyle(
                        color: editedText.length > 280
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context, false);
                  },
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: editedText.isEmpty || editedText.length > 280
                      ? null
                      : () {
                          Navigator.pop(context, true);
                        },
                  child: const Text('Send Tweet'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == true && editedText.isNotEmpty) {
      // Initialize Twitter with team credentials
      bool success = false;
      if (_team != null) {
        success = await TwitterService.instance
            .initializeWithTeamCredentials(_team!.id);
      } else {
        success =
            await TwitterService.instance.initializeWithLocalCredentials();
      }

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'Twitter is not configured. Please configure Twitter in Settings.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      final tweetSuccess = await TwitterService.instance.sendTweet(editedText);

      if (mounted) {
        if (tweetSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Game promotion tweet sent successfully! ⚽'),
              duration: const Duration(seconds: 3),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to send tweet. Please try again.'),
              duration: const Duration(seconds: 3),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  /// Generate promotional tweet text for upcoming game
  String _generateUpcomingGameTweet() {
    if (_nextUpcomingGame == null || _team == null) {
      return '';
    }

    final game = _nextUpcomingGame!;
    final team = _team!;

    // Format date and time
    final dateFormat = DateFormat('EEEE, MMMM d');
    final timeFormat = DateFormat('h:mm a');
    final date = dateFormat.format(game.date.toLocal());
    final time = timeFormat.format(game.date.toLocal());

    // Get opponent name
    final opponent = game.displayName(team.id);

    // Determine if home or away
    final isHome = game.homeTeam.id == team.id;
    final location = isHome ? 'vs' : '@';

    // Check if live URL is available
    final hasLiveUrl = team.liveUrl != null && team.liveUrl!.isNotEmpty;

    // Build the tweet with emojis
    final StringBuffer tweet = StringBuffer();

    // Add header with emoji
    tweet.writeln('⚽ GAME DAY! ⚽\n');

    // Add matchup
    tweet.writeln('$location $opponent');

    // Add date and time
    tweet.writeln('📅 $date');
    tweet.writeln('⏰ $time');

    // Add live streaming URL if available
    if (hasLiveUrl) {
      tweet.writeln('\n🔴 Watch Live:');
      tweet.writeln(team.liveUrl!);
    }

    // Add call to action
    tweet.write('\n');
    if (hasLiveUrl) {
      tweet.write('Join us for the match! 🎉');
    } else {
      tweet.write('Come support the team! 💪');
    }

    // Add hashtags (keep it short to stay under 280 chars)
    final teamHashtag = team.shortName.replaceAll(' ', '');
    tweet.write(' #$teamHashtag #GameDay');

    return tweet.toString();
  }

  /// Top banner shown on all platforms when a live game is in progress and a team-level liveUrl is set.
  Widget _buildLiveBanner() {
    // For the top banner treat the game as live only when a team-level liveUrl
    // is set and the current/last game is scheduled for today (local date).
    final nowLocal = DateTime.now();
    final isLive = _team != null &&
        _team!.liveUrl != null &&
        _team!.liveUrl!.isNotEmpty &&
        _currentOrLastGame != null &&
        (() {
          final g = _currentOrLastGame!.date.toLocal();
          return g.year == nowLocal.year &&
              g.month == nowLocal.month &&
              g.day == nowLocal.day;
        })();

    // Live banner — only if the conditions above are met
    if (isLive) {
      final url = _team!.liveUrl!;

      final loc = AppLocalizations.of(context)!;

      return GestureDetector(
        onTap: () async {
          try {
            final uri = Uri.parse(url);
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
            } else {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.unableToOpenLiveLink)));
              }
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(loc.unableToOpenLiveLink)));
            }
          }
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_team!.color1, _team!.color2],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.videocam, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  loc.liveBannerTapToWatch,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const Icon(Icons.open_in_new, color: Colors.white),
            ],
          ),
        ),
      );
    }

    // If not live, show upcoming-game banner (stay tuned message)
    if (_nextUpcomingGame != null && _team != null) {
      final loc = AppLocalizations.of(context)!;
      // Show date only (no time) for the upcoming game banner
      final fmt = DateFormat('E MMM d');
      final when = fmt.format(_nextUpcomingGame!.date.toLocal());
      final opponent = _nextUpcomingGame!.displayName(_team!.id);

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_team!.color1, _team!.color2],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.schedule, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${loc.nextGamePrefix} $opponent',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$when — ${loc.nextGameStayTuned}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            // Tweet button - show on mobile to promote upcoming game
            if (!kIsWeb)
              IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                tooltip: 'Promote game on Twitter',
                onPressed: () => _tweetUpcomingGame(),
              ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  /// Shows recent highlights (events with non-empty eventUrls) from the
  /// currently selected game. Visible on web only. Limits to 6 most recent
  /// events and shows buttons for each available URL on an event.
  Widget _buildRecentHighlights() {
    if (_currentOrLastGame == null || _team == null)
      return const SizedBox.shrink();

    return FutureBuilder<List<GameEvent>>(
      future: _currentOrLastGame!
          .loadGameEvents()
          .then((_) => _currentOrLastGame!.allGameEvents),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError || snapshot.data == null)
          return const SizedBox.shrink();

        final events = snapshot.data!;
        final loc = AppLocalizations.of(context)!;

        // Filter events that have a non-empty eventUrls field
        final eventsWithUrls = events
            .where((e) => e.eventUrls != null && e.eventUrls!.trim().isNotEmpty)
            .toList(growable: false);

        if (eventsWithUrls.isEmpty) return const SizedBox.shrink();

        // Most recent first (events are chronological); sort by index desc
        eventsWithUrls.sort((a, b) => b.index.compareTo(a.index));
        final displayEvents = eventsWithUrls.take(6).toList(growable: false);

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
                child: Text(
                  loc.highlights,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: displayEvents.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, idx) {
                    final ev = displayEvents[idx];
                    final urls = ev.eventUrls!
                        .split(',')
                        .map((u) => u.trim())
                        .where((u) => u.isNotEmpty)
                        .toList();

                    return SizedBox(
                      width: 320,
                      child: Card(
                        elevation: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Thumbnail for the first URL (if present)
                                  if (urls.isNotEmpty)
                                    VideoThumbnail(urls.first,
                                        width: 120, height: 68)
                                  else
                                    SizedBox(
                                        width: 40, height: 40, child: ev.image),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(ev.display,
                                            style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold)),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${ev.game.displayName(_team!.id)} — ${ev.eventMinute}\'',
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.7)),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                              const Spacer(),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: urls.asMap().entries.map((entry) {
                                  final uidx = entry.key;
                                  final url = entry.value;
                                  return ElevatedButton.icon(
                                    onPressed: () async {
                                      try {
                                        final uri = Uri.parse(url);
                                        if (await canLaunchUrl(uri)) {
                                          await launchUrl(uri,
                                              mode: LaunchMode
                                                  .externalApplication);
                                        } else {
                                          if (mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(SnackBar(
                                                    content: Text(
                                                        loc.couldNotOpenUrl(
                                                            url))));
                                          }
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(SnackBar(
                                                  content: Text(loc
                                                      .couldNotOpenUrl(url))));
                                        }
                                      }
                                    },
                                    icon: const Icon(Icons.play_circle_outline,
                                        size: 16),
                                    label: Text(urls.length > 1
                                        ? '${loc.videoLabel} ${uidx + 1}'
                                        : loc.watchLabel),
                                    style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8)),
                                  );
                                }).toList(),
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _showSeasonPhoto(BuildContext context, String? logoUrl) async {
    if (logoUrl == null || logoUrl.isEmpty) {
      return;
    }

    await showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: PhotoView(
            imageProvider: NetworkImage(logoUrl),
          ),
        );
      },
    );
  }
}

/// Database Sharing Dialog with Public URL and User Access Management
class _DatabaseSharingDialog extends StatefulWidget {
  final String publicUrl;
  final String databaseName;

  const _DatabaseSharingDialog({
    required this.publicUrl,
    required this.databaseName,
  });

  @override
  State<_DatabaseSharingDialog> createState() => _DatabaseSharingDialogState();
}

class _DatabaseSharingDialogState extends State<_DatabaseSharingDialog> {
  final _emailController = TextEditingController();
  String _accessLevel = 'read';
  bool _isLoading = false;
  List<Map<String, dynamic>> _sharedWith = [];
  bool _isProUser = false;

  @override
  void initState() {
    super.initState();
    _isProUser = SubscriptionService.instance.isSubscribed;
    _loadSharedUsers();
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _loadSharedUsers() async {
    if (!_isProUser) return;

    setState(() => _isLoading = true);
    try {
      final users = await DatabaseSharingService.instance
          .getDatabaseAccessList(widget.databaseName);
      if (mounted) {
        setState(() {
          _sharedWith = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading shared users: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _grantAccess() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    // Basic email validation
    if (!email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final success = await DatabaseSharingService.instance.grantDatabaseAccess(
        widget.databaseName,
        email,
        accessLevel: _accessLevel,
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Access granted to $email')),
          );
          _emailController.clear();
          await _loadSharedUsers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  const Text('Failed to grant access. User may not exist.'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error granting access: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _revokeAccess(String email) async {
    setState(() => _isLoading = true);
    try {
      final success = await DatabaseSharingService.instance
          .revokeDatabaseAccess(widget.databaseName, email);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Access revoked for $email')),
          );
          await _loadSharedUsers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to revoke access'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error revoking access: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share Database'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Public URL Section
              Text(
                'Public Share URL',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SelectableText(
                        widget.publicUrl,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.copy,
                          color: Theme.of(context).colorScheme.primary),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: widget.publicUrl));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('URL copied to clipboard!')),
                        );
                      },
                      tooltip: 'Copy URL',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Anyone with this URL can view this database (read-only)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Divider(height: 32),

              // User-Specific Sharing Section (Pro Only)
              if (_isProUser) ...[
                Text(
                  'Share with Specific Users',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Grant read or write access to specific TeamSync users',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 16),

                // Email Input
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'User Email',
                    hintText: 'user@example.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_isLoading,
                ),
                const SizedBox(height: 12),

                // Access Level Selector
                Text(
                  'Access Level',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: const [
                    ButtonSegment<String>(
                      value: 'read',
                      label: Text('Read Only'),
                      icon: Icon(Icons.visibility),
                    ),
                    ButtonSegment<String>(
                      value: 'write',
                      label: Text('Read & Write'),
                      icon: Icon(Icons.edit),
                    ),
                  ],
                  selected: {_accessLevel},
                  onSelectionChanged: _isLoading
                      ? null
                      : (Set<String> selected) {
                          setState(() => _accessLevel = selected.first);
                        },
                ),
                const SizedBox(height: 12),

                // Grant Access Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _grantAccess,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.person_add),
                    label: const Text('Grant Access'),
                  ),
                ),
                const SizedBox(height: 16),

                // Shared Users List
                if (_sharedWith.isNotEmpty) ...[
                  Text(
                    'Users with Access (${_sharedWith.length})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _sharedWith.length,
                      itemBuilder: (context, index) {
                        final user = _sharedWith[index];
                        final email = user['email']?.toString() ?? 'Unknown';
                        final accessLevel =
                            user['accessLevel']?.toString() ?? 'read';
                        final grantedAt = user['grantedAt'];

                        String timeAgo = '';
                        if (grantedAt != null) {
                          try {
                            final timestamp = grantedAt is int
                                ? grantedAt
                                : int.tryParse(grantedAt.toString());
                            if (timestamp != null) {
                              final date = DateTime.fromMillisecondsSinceEpoch(
                                  timestamp);
                              final diff = DateTime.now().difference(date);
                              if (diff.inDays > 0) {
                                timeAgo = '${diff.inDays}d ago';
                              } else if (diff.inHours > 0) {
                                timeAgo = '${diff.inHours}h ago';
                              } else {
                                timeAgo = '${diff.inMinutes}m ago';
                              }
                            }
                          } catch (e) {
                            // Ignore parsing errors
                          }
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(
                              email.isNotEmpty ? email[0].toUpperCase() : '?',
                            ),
                          ),
                          title: Text(email),
                          subtitle: Text(
                            '${accessLevel == 'read' ? 'Read Only' : 'Read & Write'}${timeAgo.isNotEmpty ? ' • $timeAgo' : ''}',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed:
                                _isLoading ? null : () => _revokeAccess(email),
                            tooltip: 'Revoke access',
                          ),
                        );
                      },
                    ),
                  ),
                ] else if (!_isLoading) ...[
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'No users have been granted access yet',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  ),
                ],
              ] else ...[
                // Pro Upgrade Prompt
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.amber[900]?.withValues(alpha: 0.2)
                        : Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.amber[700]!
                          : Colors.amber[300]!,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.star,
                          size: 48,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.amber[400]
                              : Colors.amber[700]),
                      const SizedBox(height: 12),
                      Text(
                        'Upgrade to Pro',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Upgrade to Pro to share your database with specific users and grant them read or write access.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () async {
                          await SubscriptionService.instance
                              .purchaseSubscription();
                          if (mounted) {
                            setState(() {
                              _isProUser =
                                  SubscriptionService.instance.isSubscribed;
                            });
                            if (_isProUser) {
                              await _loadSharedUsers();
                            }
                          }
                        },
                        icon: const Icon(Icons.upgrade),
                        label: const Text('Upgrade Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.tertiary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onTertiary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
