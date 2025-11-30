import 'dart:async';
import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/models/team_accomplishment.dart';
import 'package:team_sync/services/auth_service.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/database_sharing_service.dart';
import 'package:team_sync/services/subscription_service.dart';
import 'package:team_sync/services/twitter_service.dart';
import 'package:team_sync/utils/navigation_helper.dart';
import 'package:team_sync/widgets/adhoc_tweet_dialog.dart';
import 'package:team_sync/widgets/common/award_card.dart';
import 'package:team_sync/widgets/common/award_detail_dialog.dart';
import 'package:team_sync/widgets/common_page_header.dart';
import 'package:team_sync/widgets/data_import_page.dart';
import 'package:team_sync/widgets/event_stream_widget.dart';
import 'package:team_sync/widgets/lineup_generator.dart';
import 'package:team_sync/widgets/responsive_avatar.dart';
import 'package:team_sync/widgets/scoreboard_widget.dart';
import 'package:team_sync/widgets/season_record.dart';
import 'package:team_sync/widgets/standard_appbar.dart';
import 'package:team_sync/widgets/tweet_preview_dialog.dart';
import 'package:team_sync/widgets/video_thumbnail.dart';
import 'package:url_launcher/url_launcher.dart';

/// TeamSync-specific home page for single-team management
///
/// This page is designed for users managing a single team through a subscription.
/// Data is stored in subscriptionIds/{uid}/databases/{db}/ structure.
class TeamHomePage extends StatefulWidget {
  final String? databaseId;
  final Team? initialTeam; // For testing only!!!

  const TeamHomePage({super.key, this.databaseId, this.initialTeam});

  @override
  State<TeamHomePage> createState() => _TeamHomePageState();
}

class _TeamHomePageState extends State<TeamHomePage> {
  Team? _team;
  Game? _nextUpcomingGame;
  List<Season> _seasons = [];
  List<Season> _importedSeasons = [];
  List<TeamAccomplishment> _accomplishments = [];
  Game? _currentOrLastGame;
  List<Game> _lastFiveGames = []; // For carousel when no live game
  int _currentCarouselPage = 0; // Track current page in carousel
  Season? _currentSeason;
  late bool _isSubscribed;
  bool _isSharing = false;
  bool _isDrawerOpen =
      false; // Track drawer state for web - collapsed by default
  bool _accomplishmentsExpanded = true; // Track accomplishments section state
  bool _isLoadingImportedSeasons =
      false; // Track if imported seasons are loading
  bool _allSeasonsLoaded =
      false; // Track if all seasons (regular + imported) are fully loaded
  final _teamIdController = TextEditingController();
  final PageController _accomplishmentsPageController = PageController();
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

    // Use injected team if provided (for testing)
    if (widget.initialTeam != null) {
      _team = widget.initialTeam;
    }

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

    // Check authentication status after load completes (for mobile only)
    if (!kIsWeb) {
      _loadFuture.then((_) {
        // Check if user is signed in after a short delay to let the UI settle
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted && FirebaseAuth.instance.currentUser == null) {
            _ensureUserSignedIn();
          }
        });
      });
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
    _accomplishmentsPageController.dispose();
    if (!kIsWeb) {
      ShowcaseView.get().unregister();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Web viewer mode - show team ID input
    if (kIsWeb && widget.databaseId == null) {
      return Scaffold(
        appBar: AppBar(title: Text(loc.teamSyncViewer)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(loc.enterTeamIdPrompt,
                    style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 10),
                TextField(
                  controller: _teamIdController,
                  maxLength: 6,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: loc.teamId,
                    border: const OutlineInputBorder(),
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
                  child: Text(loc.loadTeam),
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
        title: Text(loc.teamSync,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        actions: _buildAppBarActions(),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      body: Column(
        children: [
          if (_team != null)
            CommonPageHeader(
              team: _team!,
              showSummary: _team!.summary != null && _team!.summary!.isNotEmpty,
              summaryMessage: _team!.summary,
              onSummaryChanged: () {
                setState(() {
                  _loadFuture = _load();
                });
              },
            ),
          _buildLiveBanner(),
          // Recent highlights (web only)
          if (kIsWeb) _buildRecentHighlights(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  List<Widget> _buildAppBarActions() {
    if (!kIsWeb && FirebaseAuth.instance.currentUser == null) {
      return [];
    }

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
                  // For settings, use publicShareId if available, otherwise use 'local'
                  // Settings should work even when not signed in for local databases
                  final databaseId =
                      DatabaseService.instance.publicShareId ?? 'local';
                  NavigationHelper.navigateTo(
                      context, '/team/$databaseId/settings',
                      extra: _team);
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              final loc = AppLocalizations.of(context)!;
              return [
                // Tweet option - show on mobile when team exists
                if (!kIsWeb && _team != null)
                  PopupMenuItem<String>(
                    value: 'tweet',
                    child: Row(
                      children: [
                        const Icon(Icons.send),
                        const SizedBox(width: 12),
                        Text(loc.sendTweet),
                      ],
                    ),
                  ),
                // Share option - show on mobile when subscribed AND signed in
                if (!kIsWeb &&
                    _isSubscribed &&
                    FirebaseAuth.instance.currentUser != null)
                  PopupMenuItem<String>(
                    value: 'share',
                    child: Row(
                      children: [
                        const Icon(Icons.share, color: Colors.yellow),
                        const SizedBox(width: 12),
                        Text(loc.shareDatabase),
                      ],
                    ),
                  ),
                // Records option - show when team exists
                if (_team != null)
                  PopupMenuItem<String>(
                    value: 'records',
                    child: Row(
                      children: [
                        const Icon(Icons.leaderboard),
                        const SizedBox(width: 12),
                        Text(loc.records),
                      ],
                    ),
                  ),
                // History option - show when team exists
                if (_team != null)
                  PopupMenuItem<String>(
                    value: 'history',
                    child: Row(
                      children: [
                        const Icon(Icons.analytics_outlined),
                        const SizedBox(width: 12),
                        Text(loc.history),
                      ],
                    ),
                  ),
                // Settings option - always show
                PopupMenuItem<String>(
                  value: 'settings',
                  child: Row(
                    children: [
                      const Icon(Icons.settings),
                      const SizedBox(width: 12),
                      Text(loc.settings),
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
                // For settings on web, use publicShareId if available, otherwise use 'local'
                final databaseId =
                    DatabaseService.instance.publicShareId ?? 'local';
                NavigationHelper.navigateTo(
                    context, '/team/$databaseId/settings',
                    extra: _team);
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            final loc = AppLocalizations.of(context)!;
            return [
              // Records option - show when team exists
              if (_team != null)
                PopupMenuItem<String>(
                  value: 'records',
                  child: Row(
                    children: [
                      const Icon(Icons.leaderboard),
                      const SizedBox(width: 12),
                      Text(loc.records),
                    ],
                  ),
                ),
              // History option - show when team exists
              if (_team != null)
                PopupMenuItem<String>(
                  value: 'history',
                  child: Row(
                    children: [
                      const Icon(Icons.analytics_outlined),
                      const SizedBox(width: 12),
                      Text(loc.history),
                    ],
                  ),
                ),
              // Settings option - always show
              PopupMenuItem<String>(
                value: 'settings',
                child: Row(
                  children: [
                    const Icon(Icons.settings),
                    const SizedBox(width: 12),
                    Text(loc.settings),
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
            if (_isSharing) {
              return const Center(child: CircularProgressIndicator());
            }

            // Show error if future completed with error
            if (snapshot.hasError) {
              final loc = AppLocalizations.of(context)!;
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(loc.errorMessage(snapshot.error.toString())),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _loadFuture = _load();
                        });
                      },
                      child: Text(loc.retry),
                    ),
                  ],
                ),
              );
            }

            // Future completed successfully, show content
            return _buildMainContent();
          },
        ),
        if (_isSharing) _buildLoadingOverlay(),
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
      final screenWidth = MediaQuery.of(context).size.width;
      final useOverlay = screenWidth < 900; // Use overlay on smaller screens

      if (useOverlay) {
        // Overlay mode for smaller screens
        return Stack(
          children: [
            _buildSeasonsList(),
            // Semi-transparent backdrop
            Positioned.fill(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _isDrawerOpen = false;
                  });
                },
                child: Container(
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ),
            ),
            // Drawer sliding in from right
            Positioned(
              top: 0,
              bottom: 0,
              right: 0,
              width: screenWidth * 0.85, // 85% of screen width
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(-2, 0),
                    ),
                  ],
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
      } else {
        // Side-by-side mode for larger screens
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
    }

    return _buildSeasonsList();
  }

  Widget _buildGamesCarousel() {
    final loc = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                loc.recentGames,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 200, // Fixed height for the carousel
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.9),
            itemCount: _lastFiveGames.length,
            onPageChanged: (index) {
              setState(() {
                _currentCarouselPage = index;
              });
            },
            itemBuilder: (context, index) {
              final game = _lastFiveGames[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4.0),
                child: ScoreboardWidget(
                  season: _currentSeason!,
                  game: game,
                  teamId: _team!.id,
                  compact: true,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        // Page indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _lastFiveGames.length,
            (index) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == _currentCarouselPage
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSeasonsList() {
    final loc = AppLocalizations.of(context)!;
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.all(16.0),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Show carousel of last 5 games or single live/last game
              if (_currentSeason != null && _currentOrLastGame != null) ...[
                if (_lastFiveGames.isEmpty)
                  // Show single live or last game
                  ScoreboardWidget(
                    season: _currentSeason!,
                    game: _currentOrLastGame!,
                    teamId: _team!.id,
                  )
                else
                  // Show carousel of last 5 games
                  _buildGamesCarousel(),
              ],
              if (_seasons.isNotEmpty) ...[
                const SizedBox(height: 16),
                // Enhanced Overall Record Card - Only show when all seasons are loaded
                if (_allSeasonsLoaded)
                  InkWell(
                    onTap: () {
                      final databaseId = DatabaseService.instance.publicShareId;
                      if (databaseId != null) {
                        NavigationHelper.navigateTo(
                          context,
                          '/team/$databaseId/history',
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Card(
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
                              Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHigh,
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SeasonRecord([..._seasons, ..._importedSeasons],
                                singleSeason: false, isOverall: true),
                          ],
                        ),
                      ),
                    ),
                  ),
                // Show loading placeholder when seasons are still loading
                if (!_allSeasonsLoaded)
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
                              Text(
                                loc.teamPerformance,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                loc.loadingAllSeasons,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
              ],
              // Team Accomplishments Section (Collapsible)
              // Show if there are accomplishments OR if user is admin (to allow adding first one)
              if (_accomplishments.isNotEmpty ||
                  (!kIsWeb &&
                      _team?.isTeamAdmin(
                              FirebaseAuth.instance.currentUser?.uid) ==
                          true)) ...[
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _accomplishmentsExpanded = !_accomplishmentsExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _accomplishmentsExpanded
                                    ? Icons.keyboard_arrow_down
                                    : Icons.keyboard_arrow_right,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                loc.teamAccomplishments,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                          if (!kIsWeb &&
                              _team?.isTeamAdmin(
                                      FirebaseAuth.instance.currentUser?.uid) ==
                                  true)
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              onPressed: () => _showAddAccomplishmentDialog(),
                              tooltip: loc.addAccomplishment,
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Show content when expanded
                if (_accomplishmentsExpanded) ...[
                  // Show empty state if no accomplishments
                  if (_accomplishments.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        elevation: 1,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: Theme.of(context).colorScheme.outlineVariant,
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              Icon(
                                Icons.emoji_events_outlined,
                                size: 48,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'No team accomplishments yet',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap + to add championships, milestones, and awards',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant
                                      .withValues(alpha: 0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  // Show accomplishments - carousel on web, list on mobile
                  if (_accomplishments.isNotEmpty)
                    if (kIsWeb)
                      // Web: Carousel view
                      _buildAccomplishmentsCarousel()
                    else if (_team?.isTeamAdmin(
                                FirebaseAuth.instance.currentUser?.uid) ==
                            true &&
                        _accomplishments.length > 1)
                      // Mobile admin: Reorderable list
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        onReorder: _onReorderAccomplishments,
                        children: _accomplishments
                            .map((accomplishment) => Padding(
                                  key: ValueKey(accomplishment.id),
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child:
                                      _buildAccomplishmentCard(accomplishment),
                                ))
                            .toList(),
                      )
                    else
                      // Mobile non-admin or single item: Regular list
                      ..._accomplishments
                          .map((accomplishment) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildAccomplishmentCard(accomplishment),
                              ))
                          .toList(),
                ],
              ],
              const SizedBox(height: 24),
              // Section header for individual seasons
              if (_seasons.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        loc.seasons,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
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
                        // Season image banner (if available)
                        if (season.logoUrl != null &&
                            season.logoUrl!.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _showSeasonPhoto(context, season.logoUrl);
                            },
                            child: Container(
                              height: 180,
                              decoration: BoxDecoration(
                                image: DecorationImage(
                                  image: NetworkImage(season.logoUrl!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
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
                              // Edit button for admins on mobile
                              if (!kIsWeb &&
                                  _team?.isTeamAdmin(FirebaseAuth
                                          .instance.currentUser?.uid) ==
                                      true) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: Icon(
                                    Icons.edit,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  onPressed: () =>
                                      _showEditSeasonNameDialog(season),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
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
        // Imported Seasons Section
        if (_importedSeasons.isNotEmpty || _isLoadingImportedSeasons) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                  left: 20, right: 20, top: 32, bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.cloud_download,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Imported Seasons',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_isLoadingImportedSeasons) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.primary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  Expanded(
                    child: Divider(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final season = _importedSeasons[index];
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
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Season image banner (if available)
                          if (season.logoUrl != null &&
                              season.logoUrl!.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _showSeasonPhoto(context, season.logoUrl);
                              },
                              child: Container(
                                height: 180,
                                decoration: BoxDecoration(
                                  image: DecorationImage(
                                    image: NetworkImage(season.logoUrl!),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          // Header section with gradient background
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.08),
                                  Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_download,
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
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
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
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
                childCount: _importedSeasons.length,
              ),
            ),
          ),
        ],
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

    _team = widget.initialTeam; // For testing only!!!

    if (_team == null) {
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
    final allSeasons = await Season.fromTeamId(teamId);

    // Separate seasons into regular and imported FIRST (before loading data)
    final regularSeasons =
        allSeasons.where((s) => s.isFromImport != true).toList();
    final importedSeasons =
        allSeasons.where((s) => s.isFromImport == true).toList();

    // Find current season (most recent regular season)
    _currentSeason = regularSeasons.isNotEmpty ? regularSeasons.first : null;

    // Load ONLY the current season first (highest priority - blocks initial render)
    if (_currentSeason != null) {
      await _currentSeason!.load();

      // Update state immediately with just current season so UI can render NOW
      if (mounted) {
        setState(() {
          _seasons = [_currentSeason!]; // Start with just current season
          _importedSeasons = [];
          _allSeasonsLoaded = false; // Not all seasons loaded yet
        });
      }

      // Load current/last game asynchronously (don't block)
      _loadCurrentOrLastGame().then((_) {
        _startLiveGameUpdateTimer();
      });
    } else {
      // No seasons at all - update state to show empty
      if (mounted) {
        setState(() {
          _seasons = [];
          _importedSeasons = [];
          _allSeasonsLoaded = true; // No seasons to load
        });
      }
    }

    // Load remaining regular seasons in background (progressive)
    if (regularSeasons.length > 1) {
      _loadRemainingRegularSeasonsAsync(
          regularSeasons.sublist(1), importedSeasons.isNotEmpty);
    } else if (importedSeasons.isEmpty) {
      // Only current season and no imports - mark as fully loaded
      if (mounted) {
        setState(() {
          _allSeasonsLoaded = true;
        });
      }
    }

    // Load team accomplishments asynchronously (don't block)
    _loadAccomplishments(teamId);

    // Load imported seasons in the background (don't block)
    if (importedSeasons.isNotEmpty) {
      _loadImportedSeasonsAsync(importedSeasons);
    }
  }

  /// Load remaining regular seasons asynchronously in the background
  Future<void> _loadRemainingRegularSeasonsAsync(
      List<Season> remainingSeasons, bool hasImportedSeasons) async {
    try {
      // Load each season individually and update UI progressively
      for (final season in remainingSeasons) {
        await season.load();
        if (mounted) {
          setState(() {
            _seasons.add(season);
          });
        }
      }

      // If no imported seasons, mark as fully loaded after regular seasons complete
      if (!hasImportedSeasons && mounted) {
        setState(() {
          _allSeasonsLoaded = true;
        });
      }
    } catch (e) {
      debugPrint('[TeamHomePage] Error loading remaining seasons: $e');
    }
  }

  /// Load imported seasons asynchronously in the background
  Future<void> _loadImportedSeasonsAsync(List<Season> importedSeasons) async {
    if (mounted) {
      setState(() {
        _isLoadingImportedSeasons = true;
      });
    }

    try {
      // Load each imported season individually and update UI progressively
      for (final season in importedSeasons) {
        await season.load();
        if (mounted) {
          setState(() {
            _importedSeasons.add(season);
          });
        }
      }
    } catch (e) {
      debugPrint('[TeamHomePage] Error loading imported seasons: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingImportedSeasons = false;
          _allSeasonsLoaded =
              true; // All seasons (regular + imported) are now loaded
        });
      }
    }
  }

  /// Load team accomplishments asynchronously
  Future<void> _loadAccomplishments(int teamId) async {
    try {
      final accomplishments = await TeamAccomplishment.listFromTeamId(teamId);
      if (mounted) {
        setState(() {
          _accomplishments = accomplishments;
        });
      }
    } catch (e) {
      debugPrint('[TeamHomePage] Error loading accomplishments: $e');
    }
  }

  /// Get Team Performance title with "since YYYY" from oldest season
  String _getTeamPerformanceTitle() {
    final loc = AppLocalizations.of(context)!;

    // Combine both regular and imported seasons to find the truly oldest
    final allSeasons = [..._seasons, ..._importedSeasons];

    if (allSeasons.isEmpty) {
      return loc.teamPerformance;
    }

    // Seasons are sorted most recent first, so the last one is the oldest
    final oldestSeason = allSeasons.last;

    // Try to extract a 4-digit year from the season name
    final yearMatch = RegExp(r'\b(19|20)\d{2}\b').firstMatch(oldestSeason.name);

    if (yearMatch != null) {
      final year = yearMatch.group(0);
      return loc.teamPerformanceSince(year!);
    }

    return loc.teamPerformance;
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
        // Clear carousel when there's a live game
        _lastFiveGames = [];
        _currentCarouselPage = 0;
      } else {
        _currentOrLastGame = startedOrCompletedGames.first;
        // Get last 5 completed games for carousel (only completed games, status 9+)
        _lastFiveGames = startedOrCompletedGames
            .where((game) => game.gameStatus.index >= 9)
            .take(5)
            .toList();
        _currentCarouselPage = 0; // Reset to first page
        // Load game events for each of the last 5 games
        for (final game in _lastFiveGames) {
          await game.loadGameEvents();
        }
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
      _lastFiveGames = [];
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
        final loc = AppLocalizations.of(context)!;
        return AlertDialog(
          title: Text(loc.signInRequired),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                loc.signInToAccessCloudDatabases,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.g_mobiledata),
                  label: Text(loc.signInWithGoogle),
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
                            content: Text(loc.signInFailed(e.toString())),
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
                    label: Text(loc.signInWithApple),
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
          actions: [],
        );
      },
    );

    return result == true;
  }

  Future<void> _showCreateOptions(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
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
                title: Text(loc.changeTeamColors),
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
              ListTile(
                leading: Icon(Icons.sports_soccer,
                    color: Theme.of(context).colorScheme.secondary),
                title: Text(loc.generateLineupImage),
                onTap: () {
                  Navigator.of(builderContext).pop();
                  _handleSelection(context, 'generateLineup');
                },
              ),
              ListTile(
                leading: Icon(Icons.cloud_upload,
                    color: Theme.of(context).colorScheme.secondary),
                title: Text(loc.importSeason),
                subtitle: Text(loc.importTeamsPlayersGamesStats),
                onTap: () {
                  Navigator.of(builderContext).pop();
                  if (_team != null) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DataImportPage(team: _team),
                      ),
                    );
                  } else {
                    context.go('/import');
                  }
                },
              ),
            ],
            if (DatabaseService.instance.path.isNotEmpty && _team == null)
              ListTile(
                leading: Icon(Icons.group,
                    color: Theme.of(context).colorScheme.secondary),
                title: Text(loc.createNewTeam),
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

    switch (option) {
      case 'existingCloudDatabase':
        final databaseName = await _pickCloudDatabase();
        if (databaseName != null) {
          await _openCloudDatabase(databaseName);
        }
        return;
      case 'newCloudDatabase':
        await _createDatabase();
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
      case 'generateLineup':
        await _generateLineup();
        break;
    }
  }

  Future<void> _createDatabase() async {
    // Check if user is signed in first
    if (!await _ensureUserSignedIn()) {
      return;
    }

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

  // Future<void> _openBackupDatabase(String path) async {
  //   await DatabaseService.instance.close();
  //   if (!DatabaseService.instance.isLocalDatabase) {
  //     DatabaseService.instance.setProvider(LocalDatabaseProvider());
  //   }

  //   final backupFile = File(path);
  //   final importedFile = await backupFile
  //       .copy('${await getDatabasesPath()}/${backupFile.path.split('/').last}');

  //   await DatabaseService.instance.open(importedFile.path);

  //   final teamResult = await DatabaseService.instance
  //       .query('Teams', orderBy: 'id', equalTo: 1);
  //   if (teamResult.isNotEmpty) {
  //     _team = Team.fromMap(teamResult.first);
  //     await _loadSeasons();
  //   } else {
  //     _team = null;
  //   }

  //   setState(() {});
  //   return;
  // }

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

  // Future<String?> _pickFile() async {
  //   // 1. Request storage permission
  //   var status = Platform.isIOS
  //       ? await Permission.storage.request()
  //       : await Permission.manageExternalStorage.request();
  //   if (!status.isGranted) {
  //     await openAppSettings();

  //     status = Platform.isIOS
  //         ? await Permission.storage.request()
  //         : await Permission.manageExternalStorage.request();
  //     if (!status.isGranted) {
  //       return null;
  //     }
  //   }

  //   try {
  //     // 2. Pick a file
  //     FilePickerResult? pickResult = await FilePicker.platform.pickFiles();
  //     if (pickResult == null) {
  //       return null;
  //     }

  //     return pickResult.files.single.path!;
  //   } catch (e) {
  //     debugPrint(e.toString());
  //   }
  //   return null;
  // }

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
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(loc.errorDuringShare),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
      debugPrint(e.toString());
    }
    setState(() {
      _isSharing = false;
    });
  }

  Future<void> _editLiveLink({Game? game}) async {
    if (_team == null) return;

    // Use provided game or default to next upcoming game
    final targetGame = game ?? _nextUpcomingGame ?? _currentOrLastGame;

    if (targetGame == null) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.noGameAvailableToSetLiveLink),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    String liveLink = targetGame.gameLinks ?? '';
    final hasLiveLink = liveLink.isNotEmpty;

    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          final loc = AppLocalizations.of(context)!;
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                top: 20,
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Show which game this link is for
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: _team!.color1.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _team!.color1.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.sports_soccer, color: _team!.color1, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          targetGame.displayName(_team!.id),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
                            // Save to game
                            await DatabaseService.instance.update(
                              'Games',
                              {'gameLinks': liveLink},
                              key: targetGame.id.toString(),
                            );

                            // Update local game object
                            targetGame.gameLinks = liveLink;

                            // Refresh state
                            setState(() {});

                            if (mounted) Navigator.pop(context);

                            // After saving, offer to tweet if link is not empty
                            if (liveLink.isNotEmpty && mounted) {
                              _promptTweetGameDay(liveLink, targetGame);
                            }
                          },
                          child: Text(AppLocalizations.of(context)!.save)),
                      TextButton(
                          onPressed: () async {
                            // Remove from game
                            await DatabaseService.instance.update(
                              'Games',
                              {'gameLinks': ''},
                              key: targetGame.id.toString(),
                            );

                            // Update local game object
                            targetGame.gameLinks = '';

                            // Refresh state
                            setState(() {});

                            if (mounted) Navigator.pop(context);
                          },
                          child:
                              Text(AppLocalizations.of(context)!.removeButton)),
                    ]),
                // Show "Tweet Game Day" button if link already exists
                if (hasLiveLink) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _promptTweetGameDay(liveLink, targetGame);
                      },
                      icon: const Icon(Icons.send, size: 18),
                      label: Text(loc.tweetGameDay),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1DA1F2),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ]),
            );
          });
        });
  }

  /// Public method to initiate game day tweet flow
  /// Reuses live link logic: prompts to set link if missing, checks game time, then tweets
  Future<void> _tweetGameDay() async {
    if (_team == null) return;

    final gameForTweet = _nextUpcomingGame ?? _currentOrLastGame;

    if (gameForTweet == null) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.noGameAvailableToTweetAbout),
            duration: const Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final liveLink = gameForTweet.gameLinks ?? '';

    if (liveLink.isEmpty) {
      // Prompt to set live link first
      final shouldSetLink = await showDialog<bool>(
        context: context,
        builder: (context) {
          final loc = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.link, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(child: Text(loc.setLiveStreamLink)),
              ],
            ),
            content: Text(
              'Would you like to add a live stream link for ${gameForTweet.displayName(_team!.id)}?\n\n'
              'This helps fans find where to watch the game.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(loc.skip),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(loc.addLink),
              ),
            ],
          );
        },
      );

      if (shouldSetLink == true && mounted) {
        // Show live link dialog for this specific game
        await _editLiveLink(game: gameForTweet);
        // After setting link, the dialog will automatically proceed with tweet
      } else if (shouldSetLink == false && mounted) {
        // User chose to skip, proceed without link (will generate generic tweet)
        await _promptTweetGameDay('', gameForTweet);
      }
      // If null (cancelled), do nothing
    } else {
      // Live link exists on this game, proceed with game day tweet
      await _promptTweetGameDay(liveLink, gameForTweet);
    }
  }

  Future<void> _promptTweetGameDay(String liveLink, Game? game) async {
    if (_team == null) return;

    // Check if Twitter is configured
    final isConfigured =
        await TwitterService.instance.isConfigured(teamId: _team!.id);

    if (!isConfigured) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Twitter is not configured. Please set up Twitter credentials in Settings.'),
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // Check if game time is not set (midnight/00:00)
    if (game != null && game.date.hour == 0 && game.date.minute == 0) {
      // Prompt user to set game time first
      final shouldSetTime = await showDialog<bool>(
        context: context,
        builder: (context) {
          final loc = AppLocalizations.of(context)!;
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.access_time, color: Colors.orange),
                const SizedBox(width: 12),
                Expanded(child: Text(loc.setGameTime)),
              ],
            ),
            content: Text(
              loc.noTimeSetPrompt,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(loc.skip),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(loc.setTime),
              ),
            ],
          );
        },
      );

      if (shouldSetTime == true && mounted) {
        // Show time picker
        final selectedTime = await showTimePicker(
          context: context,
          initialTime: const TimeOfDay(hour: 19, minute: 0), // Default 7:00 PM
          helpText: 'Select game time',
        );

        if (selectedTime != null && mounted) {
          // Update game with new time
          final updatedGameDate = DateTime(
            game.date.year,
            game.date.month,
            game.date.day,
            selectedTime.hour,
            selectedTime.minute,
          );

          // Save to database in ISO8601 format (Game.fromMap now handles this)
          try {
            await DatabaseService.instance.update(
              'Games',
              {'date': updatedGameDate.toIso8601String()},
              key: game.id.toString(),
            );

            // Update the game object's date directly
            game.date = updatedGameDate;

            if (mounted) {
              final loc = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        loc.gameTimeSet(selectedTime.format(context)),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              final loc = AppLocalizations.of(context)!;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(loc.errorUpdatingGameTime(e.toString())),
                  backgroundColor: Colors.red,
                ),
              );
            }
            return;
          }
        } else {
          // User cancelled time picker
          return;
        }
      } else if (shouldSetTime == false) {
        // User chose to skip, continue with tweet
      } else {
        // User cancelled dialog
        return;
      }
    }

    // Generate tweet text
    String tweetText = _generateGameDayTweet(game, liveLink);

    // Show preview dialog using common component
    final finalTweetText = await TweetPreviewDialog.show(
      context,
      initialText: tweetText,
      team: _team!,
    );

    // If user confirmed, send the tweet
    if (finalTweetText != null && finalTweetText.isNotEmpty) {
      try {
        // Initialize Twitter with team credentials
        final initialized = await TwitterService.instance
            .initializeWithTeamCredentials(_team!.id);

        if (!initialized) {
          // Try local credentials as fallback
          final localInit =
              await TwitterService.instance.initializeWithLocalCredentials();
          if (!localInit) {
            throw Exception('Failed to initialize Twitter');
          }
        }

        // Send the tweet
        final success = await TwitterService.instance.sendTweet(finalTweetText);

        if (success && mounted) {
          final loc = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Text(loc.gameDayTweetSentSuccessfully),
                ],
              ),
              backgroundColor: const Color(0xFF1DA1F2),
              duration: const Duration(seconds: 3),
            ),
          );
        } else if (!success && mounted) {
          throw Exception('Failed to send tweet');
        }
      } catch (e) {
        if (mounted) {
          final loc = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.errorSendingTweet(e.toString())),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  String _generateGameDayTweet(Game? game, String liveLink) {
    if (_team == null) return '';

    final teamName = _team!.shortName;
    final now = DateTime.now();

    if (game != null) {
      final gameDate = game.date;
      final isToday = gameDate.year == now.year &&
          gameDate.month == now.month &&
          gameDate.day == now.day;

      final opponent = game
          .displayName(_team!.id)
          .replaceAll('vs ', '')
          .replaceAll('@ ', '');
      final isHome = game.displayName(_team!.id).startsWith('vs');
      final location = isHome ? 'home' : 'away';

      // Format time in 12-hour format
      final hour = gameDate.hour == 0
          ? 12
          : (gameDate.hour > 12 ? gameDate.hour - 12 : gameDate.hour);
      final period = gameDate.hour >= 12 ? 'PM' : 'AM';
      final minute = gameDate.minute.toString().padLeft(2, '0');
      final timeStr = '$hour:$minute $period';

      if (isToday) {
        return '''🚨 GAME DAY! 🚨

$teamName takes on $opponent $location TODAY at $timeStr!

Watch LIVE: $liveLink

#$teamName #GameDay #Soccer ⚽🔥''';
      } else {
        final month = [
          'Jan',
          'Feb',
          'Mar',
          'Apr',
          'May',
          'Jun',
          'Jul',
          'Aug',
          'Sep',
          'Oct',
          'Nov',
          'Dec'
        ][gameDate.month - 1];
        final dateStr = '$month ${gameDate.day}';

        return '''🚨 GAME DAY! 🚨

$teamName vs $opponent
📅 $dateStr at $timeStr
🏟️ ${isHome ? 'Home' : 'Away'} game

Watch LIVE: $liveLink

#$teamName #Soccer''';
      }
    } else {
      // No game info, just generic announcement
      return '''🔴 LIVE STREAM AVAILABLE! 🔴

Watch $teamName in action!

$liveLink

#$teamName #LiveSoccer ⚽''';
    }
  }

  Future<void> _generateLineup() async {
    if (_team == null) return;

    // Get current season or let user pick one
    Season? selectedSeason = _currentSeason;

    if (selectedSeason == null && _seasons.isNotEmpty) {
      selectedSeason = _seasons.first;
    }

    if (selectedSeason == null) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.pleaseCreateSeasonFirst),
          ),
        );
      }
      return;
    }

    // Load players for the selected season
    final players = await Player.listFromTeamIdSeasonId(
      _team!.id,
      selectedSeason.id,
    );

    if (players.isEmpty) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.pleaseAddPlayersFirst),
          ),
        );
      }
      return;
    }

    // Show the lineup generator dialog
    if (mounted) {
      // Use next upcoming game or current live game (not the last played game)
      final gameForLineup = _nextUpcomingGame ?? _currentOrLastGame;

      await LineupGenerator.showLineupDialog(
        context,
        team: _team!,
        players: players,
        game: gameForLineup,
      );
    }
  }

  /// Generate and send a promotional tweet for the upcoming game
  /// Now uses the unified Tweet Game Day dialog
  Future<void> _tweetUpcomingGame() async {
    // Use the unified Tweet Game Day flow which handles everything:
    // - Live link checking/setting
    // - Game time validation
    // - Smart tweet generation
    // - Professional tweet dialog
    await _tweetGameDay();
  }

  /// Top banner shown on all platforms when a live game is in progress and the game has a live link.
  Widget _buildLiveBanner() {
    // For the top banner treat the game as live only when the game has a gameLinks
    // and the current/last game is scheduled for today (local date).
    final nowLocal = DateTime.now();

    bool isLive = false;
    if (_team != null &&
        _currentOrLastGame != null &&
        _currentOrLastGame!.gameLinks != null &&
        _currentOrLastGame!.gameLinks!.isNotEmpty) {
      try {
        final g = _currentOrLastGame!.date.toLocal();
        isLive = g.year == nowLocal.year &&
            g.month == nowLocal.month &&
            g.day == nowLocal.day;
      } catch (e) {
        debugPrint('Error checking live game date: $e');
        isLive = false;
      }
    }

    // Live banner — only if the conditions above are met
    if (isLive) {
      final url = _currentOrLastGame!.gameLinks!;

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

      // Safely get game date
      DateTime gameDate;
      try {
        gameDate = _nextUpcomingGame!.date.toLocal();
      } catch (e) {
        // If date conversion fails, skip banner
        debugPrint('Error converting game date: $e');
        return const SizedBox.shrink();
      }

      final opponent = _nextUpcomingGame!.displayName(_team!.id);
      final hasLiveLink = _nextUpcomingGame!.gameLinks != null &&
          _nextUpcomingGame!.gameLinks!.isNotEmpty;

      // Check if time is set (not midnight/00:00)
      final hasTime = gameDate.hour != 0 || gameDate.minute != 0;

      // Format date
      final dateFmt = DateFormat('E MMM d');
      final dateStr = dateFmt.format(gameDate);

      // Format time if set
      String whenText = dateStr;
      if (hasTime) {
        final hour = gameDate.hour == 0
            ? 12
            : (gameDate.hour > 12 ? gameDate.hour - 12 : gameDate.hour);
        final period = gameDate.hour >= 12 ? 'PM' : 'AM';
        final minute = gameDate.minute.toString().padLeft(2, '0');
        whenText = '$dateStr at $hour:$minute $period';
      }

      return GestureDetector(
        // Make banner tappable if live link exists
        onTap: hasLiveLink
            ? () async {
                final url = _nextUpcomingGame!.gameLinks!;
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
              }
            : null,
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
              Icon(
                hasLiveLink ? Icons.videocam : Icons.schedule,
                color: Colors.white,
              ),
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
                      hasLiveLink
                          ? '$whenText — Tap to watch live! 📺'
                          : '$whenText — ${loc.nextGameStayTuned}',
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
              // Show external link icon if live link exists
              if (hasLiveLink)
                const Icon(Icons.open_in_new, color: Colors.white),
            ],
          ),
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

  // Future<void> _launchUrl(String urlString) async {
  //   try {
  //     final url = Uri.parse(urlString);
  //     if (await canLaunchUrl(url)) {
  //       await launchUrl(url, mode: LaunchMode.externalApplication);
  //     }
  //   } catch (e) {
  //     debugPrint('Error launching URL: $e');
  //   }
  // }

  Widget _buildAccomplishmentsCarousel() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final height = constraints.maxWidth > 800 ? 360.0 : 180.0;
        return CarouselSlider(
          options: CarouselOptions(
            height: height,
            viewportFraction: 0.35,
            enlargeCenterPage: true,
            enlargeFactor: 0.2,
            enableInfiniteScroll: _accomplishments.length > 1,
            autoPlay: _accomplishments.length > 3,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 800),
            autoPlayCurve: Curves.fastOutSlowIn,
            pauseAutoPlayOnTouch: true,
          ),
          items: _accomplishments.map((accomplishment) {
            return Builder(
              builder: (BuildContext context) {
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: _buildAccomplishmentGridCard(accomplishment),
                );
              },
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildAccomplishmentGridCard(TeamAccomplishment accomplishment) {
    final imageUrls = accomplishment.allImageUrls;

    return AwardCard(
      title: accomplishment.title,
      description: accomplishment.description,
      imageUrl: accomplishment.primaryImageUrl,
      imageUrls: imageUrls,
      year: accomplishment.year,
      variant: AwardCardVariant.carousel,
      iconColor: Colors.amber,
      heroTag: 'accomplishment_${accomplishment.id}',
      onTap: () => _showAccomplishmentDetailsDialog(accomplishment),
    );
  }

  Widget _buildAccomplishmentCard(TeamAccomplishment accomplishment) {
    // Check if drag-to-reorder is active (admin with multiple items)
    final isDragToReorderActive = !kIsWeb &&
        _team?.isTeamAdmin(FirebaseAuth.instance.currentUser?.uid) == true &&
        _accomplishments.length > 1;

    final imageUrls = accomplishment.allImageUrls;

    return AwardCard(
      title: accomplishment.title,
      description: accomplishment.description,
      imageUrl: accomplishment.primaryImageUrl,
      imageUrls: imageUrls,
      year: accomplishment.year,
      variant: AwardCardVariant.list,
      iconColor: Colors.amber,
      isWeb: kIsWeb,
      showReorderHandle: isDragToReorderActive,
      onTap: () => _showAccomplishmentDetailsDialog(accomplishment),
      onEdit: !kIsWeb &&
              _team?.isTeamAdmin(FirebaseAuth.instance.currentUser?.uid) ==
                  true &&
              !isDragToReorderActive
          ? () => _showEditAccomplishmentDialog(accomplishment)
          : null,
      onDelete: !kIsWeb &&
              _team?.isTeamAdmin(FirebaseAuth.instance.currentUser?.uid) ==
                  true &&
              !isDragToReorderActive
          ? () => _deleteAccomplishment(accomplishment)
          : null,
    );
  }

  Future<void> _onReorderAccomplishments(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    setState(() {
      final item = _accomplishments.removeAt(oldIndex);
      _accomplishments.insert(newIndex, item);
    });

    // Update displayOrder for all accomplishments based on new positions
    try {
      for (int i = 0; i < _accomplishments.length; i++) {
        final accomplishment = _accomplishments[i];
        final updatedAccomplishment = TeamAccomplishment(
          id: accomplishment.id,
          teamId: accomplishment.teamId,
          title: accomplishment.title,
          description: accomplishment.description,
          imageUrls: accomplishment.allImageUrls,
          url: accomplishment.url,
          year: accomplishment.year,
          displayOrder: i, // Set displayOrder based on position
        );
        await updatedAccomplishment.save();
      }

      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.accomplishmentsReordered),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc.errorReordering(e.toString())),
          ),
        );
      }
    }
  }

  Future<void> _deleteAccomplishment(TeamAccomplishment accomplishment) async {
    final loc = AppLocalizations.of(context)!;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteAccomplishment),
        content: Text(loc.deleteAccomplishmentConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await accomplishment.delete();
        setState(() {
          _accomplishments.removeWhere((a) => a.id == accomplishment.id);
        });
        if (mounted) {
          final loc = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.accomplishmentDeleted),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final loc = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc.errorDeletingAccomplishment(e.toString())),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _showAccomplishmentDetailsDialog(TeamAccomplishment accomplishment) {
    AwardDetailDialog.show(
      context,
      title: accomplishment.title,
      description: accomplishment.description,
      imageUrls: accomplishment.allImageUrls,
      year: accomplishment.year,
      url: accomplishment.url,
      headerIcon: Icons.emoji_events,
      headerIconColor: Theme.of(context).colorScheme.primary,
      heroTagPrefix: 'accomplishment_image',
      onEdit: !kIsWeb &&
              _team?.isTeamAdmin(FirebaseAuth.instance.currentUser?.uid) == true
          ? () => _showEditAccomplishmentDialog(accomplishment)
          : null,
    );
  }

  void _showAddAccomplishmentDialog() {
    _showAccomplishmentDialog(null);
  }

  void _showEditAccomplishmentDialog(TeamAccomplishment accomplishment) {
    _showAccomplishmentDialog(accomplishment);
  }

  void _showAccomplishmentDialog(TeamAccomplishment? accomplishment) {
    final isEditing = accomplishment != null;
    final titleController =
        TextEditingController(text: accomplishment?.title ?? '');
    final descriptionController =
        TextEditingController(text: accomplishment?.description ?? '');
    final urlController =
        TextEditingController(text: accomplishment?.url ?? '');
    final yearController = TextEditingController(
      text: accomplishment?.year?.toString() ?? '',
    );
    final displayOrderController = TextEditingController(
      text: accomplishment?.displayOrder.toString() ?? '0',
    );
    List<String> imageUrls = List.from(accomplishment?.allImageUrls ?? []);
    bool isUploadingImage = false;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (context) {
        final loc = AppLocalizations.of(context)!;
        return StatefulBuilder(
          builder: (context, setState) => PopScope(
            canPop: !isSaving && !isUploadingImage,
            child: AlertDialog(
              title: Text(
                  isEditing ? loc.editAccomplishment : loc.addAccomplishment),
              content: SizedBox(
                width: MediaQuery.of(context).size.width * 0.9,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: loc.titleRequired,
                          hintText: loc.exampleStateChampions,
                        ),
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: descriptionController,
                        decoration: InputDecoration(
                          labelText: loc.description,
                          hintText: loc.optionalDetails,
                        ),
                        maxLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: yearController,
                        decoration: InputDecoration(
                          labelText: loc.year,
                          hintText: loc.exampleYear,
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 12),
                      // Multiple images upload section
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                loc.images,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (imageUrls.isNotEmpty)
                                Text(
                                  '${imageUrls.length} image${imageUrls.length == 1 ? '' : 's'}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                          if (imageUrls.length > 1)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                loc.tapImageToPrimary,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                              ),
                            ),
                          if (!kIsWeb)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                loc.selectMultipleImages,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      fontStyle: FontStyle.italic,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .secondary,
                                    ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          // Display existing images in a wrap (with max height)
                          if (imageUrls.isNotEmpty)
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxHeight: 250),
                              child: SingleChildScrollView(
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children:
                                      imageUrls.asMap().entries.map((entry) {
                                    final index = entry.key;
                                    final url = entry.value;
                                    return GestureDetector(
                                      onTap: imageUrls.length > 1 && index != 0
                                          ? () {
                                              // Move this image to be first (primary)
                                              setState(() {
                                                final img =
                                                    imageUrls.removeAt(index);
                                                imageUrls.insert(0, img);
                                              });
                                            }
                                          : null,
                                      child: Stack(
                                        children: [
                                          Container(
                                            width: 100,
                                            height: 100,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: index == 0
                                                    ? Theme.of(context)
                                                        .colorScheme
                                                        .primary
                                                    : Colors.grey,
                                                width: index == 0 ? 2 : 1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Image.network(
                                                url,
                                                fit: BoxFit.cover,
                                                errorBuilder: (context, error,
                                                    stackTrace) {
                                                  return Container(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .primaryContainer,
                                                    child: Icon(
                                                      Icons.emoji_events,
                                                      size: 32,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onPrimaryContainer,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                          ),
                                          Positioned(
                                            top: 2,
                                            right: 2,
                                            child: IconButton(
                                              icon: const Icon(Icons.close,
                                                  size: 18),
                                              onPressed: () {
                                                setState(() {
                                                  imageUrls.removeAt(index);
                                                });
                                              },
                                              style: IconButton.styleFrom(
                                                backgroundColor: Colors.red,
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.all(4),
                                                minimumSize: const Size(24, 24),
                                              ),
                                            ),
                                          ),
                                          // Show primary badge on first image
                                          if (index == 0)
                                            Positioned(
                                              bottom: 2,
                                              left: 2,
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .primary,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: Text(
                                                  loc.primary,
                                                  style: TextStyle(
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .onPrimary,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                          const SizedBox(height: 12),
                          // Add image button - always visible
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: isUploadingImage || kIsWeb
                                  ? null
                                  : () async {
                                      setState(() {
                                        isUploadingImage = true;
                                      });
                                      try {
                                        // Pick multiple images at once
                                        final pickedFiles = await ImagePicker()
                                            .pickMultiImage();

                                        if (pickedFiles.isNotEmpty) {
                                          // Upload all selected images
                                          int uploadedCount = 0;
                                          for (final pickedFile
                                              in pickedFiles) {
                                            try {
                                              // Upload to Firebase Storage
                                              final storageRef = FirebaseStorage
                                                  .instance
                                                  .ref()
                                                  .child(
                                                      'accomplishment_images/${DateTime.now().millisecondsSinceEpoch}_${uploadedCount}.jpg');
                                              await storageRef.putFile(
                                                  File(pickedFile.path));
                                              final downloadUrl =
                                                  await storageRef
                                                      .getDownloadURL();
                                              setState(() {
                                                imageUrls.add(downloadUrl);
                                              });
                                              uploadedCount++;
                                            } catch (uploadError) {
                                              debugPrint(
                                                  'Error uploading image $uploadedCount: $uploadError');
                                              // Continue with other images even if one fails
                                            }
                                          }

                                          setState(() {
                                            isUploadingImage = false;
                                          });

                                          if (context.mounted &&
                                              uploadedCount > 0) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Text(uploadedCount ==
                                                        pickedFiles.length
                                                    ? 'Successfully uploaded $uploadedCount image${uploadedCount == 1 ? '' : 's'}'
                                                    : 'Uploaded $uploadedCount of ${pickedFiles.length} images'),
                                                duration:
                                                    const Duration(seconds: 3),
                                              ),
                                            );
                                          }
                                        } else {
                                          setState(() {
                                            isUploadingImage = false;
                                          });
                                        }
                                      } catch (e) {
                                        setState(() {
                                          isUploadingImage = false;
                                        });
                                        if (context.mounted) {
                                          final loc =
                                              AppLocalizations.of(context)!;
                                          String errorMessage =
                                              loc.errorUploadingImages(e);
                                          if (e
                                                  .toString()
                                                  .contains('not authorized') ||
                                              e
                                                  .toString()
                                                  .contains('permission') ||
                                              e
                                                  .toString()
                                                  .contains('unauthorized')) {
                                            errorMessage =
                                                loc.notAuthorizedUploadImages;
                                          }
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(errorMessage),
                                              duration:
                                                  const Duration(seconds: 5),
                                            ),
                                          );
                                        }
                                      }
                                    },
                              icon: isUploadingImage
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : const Icon(Icons.add_photo_alternate),
                              label: Text(
                                isUploadingImage
                                    ? 'Uploading...'
                                    : kIsWeb
                                        ? 'Image upload requires mobile app'
                                        : 'Add Images',
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: urlController,
                        decoration: const InputDecoration(
                          labelText: 'Link URL',
                          hintText: 'Optional external link',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: displayOrderController,
                        decoration: const InputDecoration(
                          labelText: 'Display Order',
                          hintText: '0 = first, higher = later',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ), // Close SingleChildScrollView
              ), // Close SizedBox
              actions: [
                if (isEditing)
                  TextButton(
                    onPressed: isSaving || isUploadingImage
                        ? null
                        : () async {
                            // Delete accomplishment
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(loc.deleteAccomplishment),
                                content: const Text(
                                    'Are you sure you want to delete this accomplishment?'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(loc.cancel),
                                  ),
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          Theme.of(context).colorScheme.error,
                                    ),
                                    child: Text(loc.delete),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && mounted) {
                              await accomplishment.delete();
                              setState(() {
                                _accomplishments.removeWhere(
                                    (a) => a.id == accomplishment.id);
                              });
                              if (mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: Text(loc.delete),
                  ),
                TextButton(
                  onPressed: isSaving || isUploadingImage
                      ? null
                      : () => Navigator.pop(context),
                  child: Text(loc.cancel),
                ),
                TextButton(
                  onPressed: isSaving || isUploadingImage
                      ? null
                      : () async {
                          final title = titleController.text.trim();
                          if (title.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(loc.titleIsRequired)),
                            );
                            return;
                          }

                          // Start saving
                          setState(() {
                            isSaving = true;
                          });

                          try {
                            final year =
                                int.tryParse(yearController.text.trim());
                            final displayOrder = int.tryParse(
                                    displayOrderController.text.trim()) ??
                                0;

                            // Debug output
                            debugPrint('=== Saving Accomplishment ===');
                            debugPrint('Title: $title');
                            debugPrint('ImageUrls: $imageUrls');
                            debugPrint('ImageUrls count: ${imageUrls.length}');

                            final newAccomplishment = TeamAccomplishment(
                              id: accomplishment?.id ??
                                  DateTime.now().millisecondsSinceEpoch,
                              teamId: _team!.id,
                              title: title,
                              description:
                                  descriptionController.text.trim().isEmpty
                                      ? null
                                      : descriptionController.text.trim(),
                              imageUrls: imageUrls,
                              url: urlController.text.trim().isEmpty
                                  ? null
                                  : urlController.text.trim(),
                              year: year,
                              displayOrder: displayOrder,
                            );

                            debugPrint(
                                'Accomplishment imageUrls: ${newAccomplishment.imageUrls}');
                            debugPrint(
                                'Accomplishment toMap: ${newAccomplishment.toMap()}');

                            await newAccomplishment.save();

                            // Update parent widget state (not dialog state)
                            if (mounted) {
                              this.setState(() {
                                if (isEditing) {
                                  final index = _accomplishments.indexWhere(
                                      (a) => a.id == accomplishment.id);
                                  if (index != -1) {
                                    _accomplishments[index] = newAccomplishment;
                                  }
                                } else {
                                  _accomplishments.add(newAccomplishment);
                                }
                                // Re-sort accomplishments
                                _accomplishments.sort((a, b) {
                                  final orderCompare =
                                      a.displayOrder.compareTo(b.displayOrder);
                                  if (orderCompare != 0) return orderCompare;
                                  if (a.year != null && b.year != null) {
                                    final yearCompare =
                                        b.year!.compareTo(a.year!);
                                    if (yearCompare != 0) return yearCompare;
                                  }
                                  return a.title.compareTo(b.title);
                                });
                              });
                              Navigator.pop(context);
                            }
                          } catch (e) {
                            setState(() {
                              isSaving = false;
                            });
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content:
                                      Text('Error saving: ${e.toString()}'),
                                  duration: const Duration(seconds: 5),
                                ),
                              );
                            }
                          }
                        },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSaving) ...[
                        const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Text(isSaving
                          ? loc.saving
                          : (isEditing ? loc.save : loc.add)),
                    ],
                  ),
                ),
              ],
            ), // Close AlertDialog
          ), // Close PopScope
        ); // Close StatefulBuilder builder
      }, // Close builder function
    ); // Close showDialog
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

  Future<void> _showEditSeasonNameDialog(Season season) async {
    final loc = AppLocalizations.of(context)!;
    final nameController = TextEditingController(text: season.name);

    // Capture context-dependent values before async gap
    final dialogContext = context;

    final result = await showDialog<bool>(
      context: dialogContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(loc.editSeasonName),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(
              labelText: loc.seasonName,
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(loc.cancelButton),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text(loc.seasonNameRequired)),
                  );
                  return;
                }
                Navigator.of(dialogContext).pop(true);
              },
              child: Text(loc.save),
            ),
          ],
        );
      },
    );

    if (result == true) {
      final newName = nameController.text.trim();
      if (newName.isNotEmpty && newName != season.name) {
        try {
          // Update season name in database
          await DatabaseService.instance.update(
            'Seasons',
            {'name': newName},
            key: season.id.toString(),
          );

          // Update local season object
          setState(() {
            // Find and update the season in the local list
            final index = _seasons.indexWhere((s) => s.id == season.id);
            if (index != -1) {
              _seasons[index] = Season(
                id: season.id,
                name: newName,
                teamId: season.teamId,
                logoUrl: season.logoUrl,
                isFromImport: season.isFromImport,
              )..team = season.team;
            }
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(loc.seasonNameUpdated)),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${loc.errorMessage}: ${e.toString()}'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        }
      }
    }

    // Dispose controller after dialog animation completes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      nameController.dispose();
    });
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
    final loc = AppLocalizations.of(context)!;
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
                            tooltip: loc.revokeAccess,
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
