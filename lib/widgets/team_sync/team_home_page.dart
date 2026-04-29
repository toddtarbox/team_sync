import 'dart:async';
import 'package:universal_io/io.dart';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/services/sport_strategy.dart';
import 'package:flutter/services.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:showcaseview/showcaseview.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/game_event.dart';

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
import 'package:team_sync/utils/game_action_helpers.dart';
import 'package:team_sync/widgets/common/award_card.dart';
import 'package:team_sync/widgets/common/skeleton_container.dart';
import 'package:team_sync/widgets/common/award_detail_dialog.dart';
import 'package:team_sync/widgets/common_page_header.dart';
import 'package:team_sync/widgets/team_summary_section.dart';

import 'package:team_sync/widgets/event_stream_widget.dart';

import 'package:team_sync/widgets/season_page.dart';
import 'package:team_sync/widgets/responsive_avatar.dart';
import 'package:team_sync/widgets/scoreboard_widget.dart';
import 'package:team_sync/widgets/season_record.dart';
import 'package:team_sync/widgets/standard_appbar.dart';
import 'package:team_sync/widgets/tweet_preview_dialog.dart';
import 'package:team_sync/widgets/video_thumbnail.dart';
import 'package:team_sync/widgets/common/hover_builder.dart';
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

class _TeamHomePageState extends State<TeamHomePage>
    with SingleTickerProviderStateMixin {
  Team? _team;
  Game? _nextUpcomingGame;
  List<Season> _seasons = [];
  List<Season> _importedSeasons = [];
  List<TeamAccomplishment> _accomplishments = [];
  Game? _currentOrLastGame;
  List<Game> _lastFiveGames = []; // For carousel when no live game
  int _currentRecentGamesCarouselPage = 0; // Track current page in carousel
  int _currentAnalyticsCarouselPage = 0; // Track current page in carousel
  Season? _currentSeason;
  late bool _isSubscribed;
  bool _isSharing = false;
  bool _isDrawerOpen =
      false; // Track drawer state for web - collapsed by default
  bool _accomplishmentsExpanded =
      false; // Track accomplishments section state - collapsed by default
  bool _recentGamesExpanded =
      false; // Track recent games section state - collapsed by default
  bool _analyticsExpanded =
      false; // Track analytics section state - collapsed by default
  bool _isLoadingImportedSeasons =
      false; // Track if imported seasons are loading
  bool _allSeasonsLoaded =
      false; // Track if all seasons (regular + imported) are fully loaded
  final _teamIdController = TextEditingController();
  final PageController _accomplishmentsPageController = PageController();
  final ScrollController _scrollController =
      ScrollController(); // Track scroll for hiding header elements
  late AnimationController _hideController;
  late Animation<double> _hideAnimation;
  late Future<bool> _loadFuture;
  Timer? _liveGameUpdateTimer;
  StreamSubscription<bool>? _subscriptionListener;
  StreamSubscription<User?>? _authListener;
  bool _isShowingSignInDialog = false;
  bool _hasTwitterConfig = false;
  Map<String, num> _asyncOverallStats = {};

  final _welcomeKey = GlobalKey();
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

    if (!DatabaseService.isTest) {
      DatabaseService.instance.setProvider(FirebaseDBProvider());
    }

    // Initialize the load future once
    _loadFuture = _load().then((success) async {
      if (success && _team != null) {
        final hasConfig =
            await TwitterService.instance.isConfigured(teamId: _team!.id);
        if (mounted) {
          setState(() {
            _hasTwitterConfig = hasConfig;
          });
        }
      }
      return success;
    });

    if (!kIsWeb) {
      _setupShowcase();
      _checkIfFirstLaunch();
    }

    // Listen to authentication status and continuously require sign-in on mobile
    if (!kIsWeb) {
      _authListener = FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (mounted && user == null) {
          // Clear active database state on logout
          try {
            await DatabaseService.instance.close();
            const storage = FlutterSecureStorage();
            await storage.delete(key: 'last_db_used');
          } catch (e) {
            debugPrint('Error clearing database after logout: $e');
          }

          if (mounted) {
            setState(() {
              _team = null;
              _seasons = [];
            });

            _ensureUserSignedIn().then((isSignedIn) {
              if (isSignedIn && mounted) {
                // Register user in lookup table now that they are signed in
                try {
                  DatabaseSharingService.instance.registerUserInLookup();
                } catch (e) {
                  debugPrint('Failed to register user in lookup: $e');
                }

                // Reload the database
                setState(() {
                  _loadFuture = _load().then((success) async {
                    if (success && _team != null) {
                      final hasConfig = await TwitterService.instance
                          .isConfigured(teamId: _team!.id);
                      if (mounted) {
                        setState(() {
                          _hasTwitterConfig = hasConfig;
                        });
                      }
                    }
                    return success;
                  });
                });
              }
            });
          }
        }
      });
    }

    _loadExpansionStates();

    // Initialize scroll hide controller
    _hideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
      value: 1.0, // Initially shown
    );
    _hideAnimation = CurvedAnimation(
      parent: _hideController,
      curve: Curves.easeInOut,
    );

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final isScrolled = _scrollController.offset > 50;

      // Drive animation controller based on scroll state
      if (isScrolled &&
          _hideController.status != AnimationStatus.reverse &&
          _hideController.status != AnimationStatus.dismissed) {
        _hideController.reverse();
      } else if (!isScrolled &&
          _hideController.status != AnimationStatus.forward &&
          _hideController.status != AnimationStatus.completed) {
        _hideController.forward();
      }
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

        final keysToShow = [_welcomeKey];
        // Only include _goProKey if it exists in the tree (user not subscribed)
        if (!_isSubscribed) {
          keysToShow.add(_goProKey);
        }
        keysToShow.add(_settingsKey);

        ShowcaseView.get().startShowCase(keysToShow);
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

  Future<void> _loadExpansionStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _accomplishmentsExpanded =
              prefs.getBool('team_accomplishments_expanded') ?? false;
          _recentGamesExpanded =
              prefs.getBool('team_recent_games_expanded') ?? false;
          _analyticsExpanded =
              prefs.getBool('team_analytics_expanded') ?? false;
        });
      }
    } catch (e) {
      // Ignore errors
    }
  }

  @override
  void dispose() {
    _subscriptionListener?.cancel();
    _authListener?.cancel();
    _liveGameUpdateTimer?.cancel();
    _accomplishmentsPageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _hideController.dispose();
    _teamIdController.dispose();
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
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(SportStrategy.current.appTitle,
              style:
                  const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ),
        actions: _buildAppBarActions(),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      body: Column(
        children: [
          if (_team != null)
            CommonPageHeader(
              team: _team!,
              onTeamUpdated: () {
                setState(() {
                  _loadFuture = _load();
                });
              },
            ),
          if (_team != null)
            _buildAnimatedVisibility(
              child: TeamSummarySection(
                team: _team!,
                onSummaryChanged: () {
                  setState(() {
                    _loadFuture = _load();
                  });
                },
              ),
            ),
          if (_team != null)
            _buildAnimatedVisibility(
              child: _buildLiveBanner(),
            ),
          // Recent highlights (web only)
          if (kIsWeb && _team != null)
            _buildAnimatedVisibility(
              child: _buildRecentHighlights(),
            ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // Replaces implicit animation with robust explicit animation
  Widget _buildAnimatedVisibility({required Widget child}) {
    return SizeTransition(
      sizeFactor: _hideAnimation,
      axisAlignment: -1.0, // Slide up/down from top
      child: FadeTransition(
        opacity: _hideAnimation,
        child: child,
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
                  await AdhocTweetDialog.show(context,
                      teamId: _team?.id, team: _team);
                  break;
                case 'share':
                  await _shareDatabase();
                  break;
                case 'records':
                  final databaseId = DatabaseService.instance.publicShareId!;
                  NavigationHelper.navigateTo(
                      context, '/team/$databaseId/records',
                      extra: _team);
                  break;
                case 'history':
                  final databaseId = DatabaseService.instance.publicShareId!;
                  NavigationHelper.navigateTo(
                      context, '/team/$databaseId/history',
                      extra: _team);
                  break;
                case 'settings':
                  final databaseId = DatabaseService.instance.publicShareId;
                  if (databaseId != null && databaseId.isNotEmpty) {
                    NavigationHelper.navigateTo(
                        context, '/team/$databaseId/settings',
                        extra: _team);
                  } else {
                    NavigationHelper.navigateTo(context, '/settings',
                        extra: _team);
                  }
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              final loc = AppLocalizations.of(context)!;
              return [
                // Tweet option - show on mobile when team exists AND twitter is configured
                if (!kIsWeb && _team != null && _hasTwitterConfig)
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
        HoverBuilder(
          builder: (context, isHovered) {
            return Transform.scale(
              scale: kIsWeb && isHovered ? 1.1 : 1.0,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                onSelected: (value) async {
                  switch (value) {
                    case 'records':
                      final databaseId =
                          DatabaseService.instance.publicShareId!;
                      NavigationHelper.navigateTo(
                          context, '/team/$databaseId/records',
                          extra: _team);
                      break;
                    case 'history':
                      final databaseId =
                          DatabaseService.instance.publicShareId!;
                      NavigationHelper.navigateTo(
                          context, '/team/$databaseId/history',
                          extra: _team);
                      break;
                    case 'settings':
                      final databaseId = DatabaseService.instance.publicShareId;
                      if (databaseId != null && databaseId.isNotEmpty) {
                        NavigationHelper.navigateTo(
                            context, '/team/$databaseId/settings',
                            extra: _team);
                      } else {
                        NavigationHelper.navigateTo(context, '/settings',
                            extra: _team);
                      }
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
            );
          },
        ),
    ];
  }

  Widget? _buildFloatingActionButton() {
    if (kIsWeb) {
      return (!_isDrawerOpen && _team != null
          ? HoverBuilder(
              builder: (context, isHovered) {
                return Transform.scale(
                  scale: isHovered && kIsWeb ? 1.1 : 1.0,
                  child: FloatingActionButton(
                    onPressed: () {
                      setState(() {
                        _isDrawerOpen = true;
                      });
                    },
                    tooltip: 'Show game details',
                    child: const Icon(Icons.event),
                  ),
                );
              },
            )
          : null);
    }

    if (_team == null) {
      return null;
    }

    // Mobile
    return Container(
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
        ));
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
              return _buildDashboardSkeleton();
            }

            // Show additional loading states
            if (_isSharing) {
              return _buildDashboardSkeleton();
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
    if (!kIsWeb && (DatabaseService.instance.path.isEmpty || _team == null)) {
      return Showcase(
          key: _welcomeKey,
          description:
              'Welcome to TeamSync! Let\'s take a look around and get you started managing your team!',
          child: _buildWelcomeView());
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

  Widget _buildSeasonsList() {
    final loc = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate responsive horizontal padding
        final screenWidth = constraints.maxWidth;
        const maxContentWidth = 1400.0;
        final horizontalPadding = screenWidth > maxContentWidth
            ? (screenWidth - maxContentWidth) / 2
            : 0.0;

        return CustomScrollView(
          key: const Key('team_home_scroll_view'),
          controller: _scrollController,
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(
                left: 16.0 + horizontalPadding,
                right: 16.0 + horizontalPadding,
                top: 16.0,
                bottom: 16.0,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // Recent Games Section (Collapsible)
                  if (_currentSeason != null && _currentOrLastGame != null) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: InkWell(
                        key: const Key('recent_games_header'),
                        onTap: () async {
                          setState(() {
                            _recentGamesExpanded = !_recentGamesExpanded;
                          });
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('team_recent_games_expanded',
                                _recentGamesExpanded);
                          } catch (e) {
                            // Ignore errors
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: HoverBuilder(
                          builder: (context, isHovered) {
                            return Transform.translate(
                              offset: isHovered && kIsWeb
                                  ? const Offset(4, 0)
                                  : Offset.zero,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      _recentGamesExpanded
                                          ? Icons.keyboard_arrow_down
                                          : Icons.keyboard_arrow_right,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons
                                          .sports_score, // Or another relevant icon
                                      size: 20,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      loc.recentGames,
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
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _recentGamesExpanded
                          ? Column(
                              children: [
                                if (_lastFiveGames.isEmpty)
                                  // Show single live or last game
                                  ScoreboardWidget(
                                    season: _currentSeason!,
                                    game: _currentOrLastGame!,
                                    teamId: _team!.id,
                                  )
                                else
                                  // Show carousel of last 5 games
                                  SizedBox(
                                    height:
                                        200, // Fixed height for the carousel
                                    child: PageView.builder(
                                      controller:
                                          PageController(viewportFraction: 0.9),
                                      itemCount: _lastFiveGames.length,
                                      onPageChanged: (index) {
                                        setState(() {
                                          _currentRecentGamesCarouselPage =
                                              index;
                                        });
                                      },
                                      itemBuilder: (context, index) {
                                        final game = _lastFiveGames[index];
                                        return Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 4.0),
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
                                // Page indicator
                                if (_lastFiveGames.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: List.generate(
                                        _lastFiveGames.length,
                                        (index) => Container(
                                          margin: const EdgeInsets.symmetric(
                                              horizontal: 4),
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: index ==
                                                    _currentRecentGamesCarouselPage
                                                ? Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .primary
                                                    .withValues(alpha: 0.3),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 24),
                  ],
                  // Analytics Section (Collapsible)
                  if (_seasons.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 8),
                      child: InkWell(
                        key: const Key('analytics_header'),
                        onTap: () async {
                          setState(() {
                            _analyticsExpanded = !_analyticsExpanded;
                          });
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool(
                                'team_analytics_expanded', _analyticsExpanded);
                          } catch (e) {
                            // Ignore errors
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: HoverBuilder(
                          builder: (context, isHovered) {
                            return Transform.translate(
                              offset: isHovered && kIsWeb
                                  ? const Offset(4, 0)
                                  : Offset.zero,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Icon(
                                      _analyticsExpanded
                                          ? Icons.keyboard_arrow_down
                                          : Icons.keyboard_arrow_right,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      Icons
                                          .analytics, // Or another relevant icon
                                      size: 20,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      loc.analytics, // Ensure 'analytics' key exists or use 'Analytics' string if strictly needed, but reusing loc is safer if key exists. Otherwise use 'Team Performance' or similar. Assuming loc.analytics exists or I'll use existing "Team Performance" string logic. Let's use "Team Analytics" string for now to be safe or check keys.
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
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _analyticsExpanded
                          ? Column(
                              children: [
                                // Analytics Carousel - Show comprehensive team statistics (or skeleton)
                                const SizedBox(height: 16),
                                if (_allSeasonsLoaded)
                                  _buildAnalyticsCarousel()
                                else
                                  _buildAnalyticsSkeleton(),
                              ],
                            )
                          : const SizedBox.shrink(),
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
                        key: const Key('accomplishments_header'),
                        onTap: () async {
                          setState(() {
                            _accomplishmentsExpanded =
                                !_accomplishmentsExpanded;
                          });
                          try {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool('team_accomplishments_expanded',
                                _accomplishmentsExpanded);
                          } catch (e) {
                            // Ignore errors
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: HoverBuilder(
                          builder: (context, isHovered) {
                            return Transform.translate(
                              offset: isHovered && kIsWeb
                                  ? const Offset(4, 0)
                                  : Offset.zero,
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
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
                                        _team?.isTeamAdmin(FirebaseAuth
                                                .instance.currentUser?.uid) ==
                                            true)
                                      IconButton(
                                        icon: const Icon(Icons.add, size: 20),
                                        onPressed: () =>
                                            _showAddAccomplishmentDialog(),
                                        tooltip: loc.addAccomplishment,
                                        constraints: const BoxConstraints(),
                                        padding: EdgeInsets.zero,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    // Show content when expanded
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: _accomplishmentsExpanded
                          ? Column(
                              children: [
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
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outlineVariant,
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
                                  else if (_team?.isTeamAdmin(FirebaseAuth
                                              .instance.currentUser?.uid) ==
                                          true &&
                                      _accomplishments.length > 1)
                                    // Mobile admin: Reorderable list
                                    ReorderableListView(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      onReorder: _onReorderAccomplishments,
                                      children: _accomplishments
                                          .map((accomplishment) => Padding(
                                                key:
                                                    ValueKey(accomplishment.id),
                                                padding: const EdgeInsets.only(
                                                    bottom: 12),
                                                child: _buildAccomplishmentCard(
                                                    accomplishment),
                                              ))
                                          .toList(),
                                    )
                                  else
                                    // Mobile non-admin or single item: Regular list
                                    ..._accomplishments
                                        .map((accomplishment) => Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 12),
                                              child: _buildAccomplishmentCard(
                                                  accomplishment),
                                            )),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                  const SizedBox(height: 24),
                  // Enhanced Overall Record Card - Only show when all seasons are loaded AND there are seasons
                  if (_allSeasonsLoaded &&
                      (_seasons.isNotEmpty || _importedSeasons.isNotEmpty))
                    InkWell(
                      onTap: () {
                        final databaseId =
                            DatabaseService.instance.publicShareId!;
                        NavigationHelper.navigateTo(
                          context,
                          '/team/$databaseId/history',
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: HoverBuilder(
                        builder: (context, isHovered) {
                          return Transform.scale(
                            scale: kIsWeb && isHovered ? 1.02 : 1.0,
                            child: Card(
                              elevation: isHovered && kIsWeb ? 8 : 4,
                              clipBehavior: Clip.antiAlias,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isHovered && kIsWeb
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.emoji_events,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
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
                                    SeasonRecord(
                                        [..._seasons, ..._importedSeasons],
                                        singleSeason: false, isOverall: true),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(3, (index) {
                                    return Container(
                                      margin: EdgeInsets.only(
                                          right: index < 2 ? 16 : 0),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .surface
                                            .withValues(alpha: 0.5),
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .outline
                                              .withValues(alpha: 0.1),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Container(
                                            width: 32,
                                            height: 14,
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.05),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  loc.loadingAllSeasons,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant
                                        .withValues(alpha: 0.7),
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
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
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
              padding:
                  EdgeInsets.symmetric(horizontal: 16.0 + horizontalPadding),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final season = _seasons[index];
                    final databaseId = DatabaseService.instance.publicShareId!;

                    return GestureDetector(
                      onTap: () {
                        NavigationHelper.navigateTo(
                            context, '/team/$databaseId/season/${season.id}',
                            extra: season);
                      },
                      child: HoverBuilder(
                        builder: (context, isHovered) {
                          return Transform.scale(
                            scale: kIsWeb && isHovered ? 1.02 : 1.0,
                            child: Card(
                              elevation: isHovered ? 6 : 3, // Elevate on hover
                              clipBehavior: Clip.antiAlias,
                              color: Theme.of(context).colorScheme.surface,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isHovered
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                  width: isHovered ? 2 : 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Header section with season name - MOVED TO TOP
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          season.team.color1
                                              .withValues(alpha: 0.15),
                                          season.team.color2
                                              .withValues(alpha: 0.10),
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (season.team.logoUrl != null &&
                                            season
                                                .team.logoUrl!.isNotEmpty) ...[
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
                                        // Edit button for admins on mobile
                                        if (!kIsWeb &&
                                            _team?.isTeamAdmin(FirebaseAuth
                                                    .instance
                                                    .currentUser
                                                    ?.uid) ==
                                                true) ...[
                                          const SizedBox(width: 8),
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit,
                                              size: 20,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .primary,
                                            ),
                                            onPressed: () =>
                                                _showEditSeasonNameDialog(
                                                    season),
                                            padding: EdgeInsets.zero,
                                            constraints: const BoxConstraints(),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Season content
                                  if (season.logoUrl != null &&
                                      season.logoUrl!.isNotEmpty)
                                    GestureDetector(
                                      onTap: () {
                                        _showSeasonPhoto(
                                            context, season.logoUrl);
                                      },
                                      child: SizedBox(
                                        height: 180,
                                        child: Stack(
                                          fit: StackFit.expand,
                                          children: [
                                            // Image
                                            Image.network(
                                              season.logoUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (context, error, stackTrace) {
                                                return Center(
                                                  child: Icon(
                                                    Icons.image_not_supported,
                                                    size: 48,
                                                    color: Theme.of(context)
                                                        .colorScheme
                                                        .outline,
                                                  ),
                                                );
                                              },
                                            ),
                                            // Gradient Overlay
                                            Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.topCenter,
                                                  end: Alignment.bottomCenter,
                                                  colors: [
                                                    Colors.transparent,
                                                    Colors.black
                                                        .withValues(alpha: 0.7),
                                                  ],
                                                  stops: const [0.5, 1.0],
                                                ),
                                              ),
                                            ),
                                            // Overlaid Record
                                            Positioned(
                                              bottom: 0,
                                              left: 0,
                                              right: 0,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(10),
                                                child: Center(
                                                  child: SeasonRecord(
                                                    [season],
                                                    isCompact: true,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                  else
                                    // Fallback: Stats section (no image)
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: SeasonRecord([season]),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
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
                  padding: EdgeInsets.only(
                    left: 20 + horizontalPadding,
                    right: 20 + horizontalPadding,
                    top: 32,
                    bottom: 8,
                  ),
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
                padding:
                    EdgeInsets.symmetric(horizontal: 16.0 + horizontalPadding),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final season = _importedSeasons[index];
                      final databaseId =
                          DatabaseService.instance.publicShareId!;

                      return GestureDetector(
                        onTap: () {
                          NavigationHelper.navigateTo(
                              context, '/team/$databaseId/season/${season.id}',
                              extra: season);
                        },
                        child: HoverBuilder(
                          builder: (context, isHovered) {
                            return Transform.scale(
                              scale: kIsWeb && isHovered ? 1.02 : 1.0,
                              child: Card(
                                elevation:
                                    isHovered ? 6 : 3, // Elevate on hover
                                clipBehavior: Clip.antiAlias,
                                color: Theme.of(context).colorScheme.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isHovered
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context)
                                            .colorScheme
                                            .primary
                                            .withValues(alpha: 0.3),
                                    width: isHovered ? 2.5 : 1.5,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // Header section with season name - MOVED TO TOP
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
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.cloud_download,
                                            size: 18,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                          const SizedBox(width: 8),
                                          if (season.team.logoUrl != null &&
                                              season.team.logoUrl!
                                                  .isNotEmpty) ...[
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
                                    // Season image banner (if available)
                                    if (season.logoUrl != null &&
                                        season.logoUrl!.isNotEmpty)
                                      GestureDetector(
                                        onTap: () {
                                          _showSeasonPhoto(
                                              context, season.logoUrl);
                                        },
                                        child: Container(
                                          height: 180,
                                          color: Colors.transparent,
                                          child: Image.network(
                                            season.logoUrl!,
                                            fit: BoxFit.contain,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Center(
                                                child: Icon(
                                                  Icons.image_not_supported,
                                                  size: 48,
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .outline,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    // Stats section
                                    Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: SeasonRecord([season]),
                                    ),
                                  ],
                                ),
                              ), // Card
                            ); // Transform return
                          },
                        ), // HoverBuilder
                      ); // GestureDetector
                    },
                    childCount: _importedSeasons.length,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildWelcomeView() {
    final loc = AppLocalizations.of(context)!;
    final isDatabaseConnected = DatabaseService.instance.path.isNotEmpty;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .primaryContainer
                    .withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDatabaseConnected
                    ? Icons.storage_rounded
                    : SportStrategy.current.sportIcon,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              isDatabaseConnected
                  ? 'Database Connected!'
                  : loc.welcomeToTeamSync,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Text(
                isDatabaseConnected
                    ? 'Your cloud database is ready. Now let\'s create your team to start tracking games and stats!'
                    : 'Manage your team like a pro. Track games, stats, and player performance all in one place.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              onPressed: () {
                if (isDatabaseConnected) {
                  _handleSelection(context, 'team');
                } else {
                  _showCreateOptions(context);
                }
              },
              icon: Icon(isDatabaseConnected
                  ? Icons.group_add_rounded
                  : Icons.add_rounded),
              label: Text(
                isDatabaseConnected ? 'Create New Team' : loc.getStarted,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {
                if (isDatabaseConnected) {
                  _showCreateOptions(context);
                } else {
                  _handleSelection(context, 'existingCloudDatabase');
                }
              },
              child: Text(
                isDatabaseConnected
                    ? 'Switch Database'
                    : loc.openExistingDatabase,
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
      ),
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
      if (kIsWeb) {
        // Ensure we are authenticated (even anonymously) before trying to load
        if (FirebaseAuth.instance.currentUser == null) {
          // Wait a brief moment ensuring auth state might still be initializing
          await Future.delayed(const Duration(milliseconds: 500));
          if (FirebaseAuth.instance.currentUser == null) {
            throw 'Authentication failed. Please refresh the page. If the issue persists, ensure Anonymous Authentication is enabled in the Firebase Console.';
          }
        }
      }

      if (widget.databaseId != null) {
        final result = await _loadFromDatabaseId();
        if (!result) {
          throw 'Unable to load team data. The link may be invalid or you do not have permission to view this team.';
        }
        return result;
      } else if (!kIsWeb && !DatabaseService.isTest) {
        final result = await _loadLocalDatabase();
        return result;
      }
      return true;
    } on FirebaseException catch (e) {
      debugPrint(
          '[TeamHomePage] Firebase Error in _load: ${e.code} - ${e.message}');
      if (e.code == 'permission-denied') {
        throw 'Access denied. The database link may be invalid, or public access is not enabled for this team.';
      }
      rethrow;
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
      try {
        // Assume team id=1 and fetch team and seasons simultaneously
        final results = await Future.wait([
          Team.fromId(1),
          Season.fromTeamId(1),
        ]);

        setState(() {
          _team = results[0] as Team;
        });

        await _loadSeasons(preloadedSeasons: results[1] as List<Season>);
      } catch (e) {
        debugPrint(
            '[TeamHomePage] Team with id=1 not found. Fetching any team...');
        final teamResult =
            await DatabaseService.instance.query('Teams', limitToFirst: 1);

        if (teamResult.isNotEmpty) {
          // Use the first team found
          final teamMap = teamResult.first;
          final team = Team.fromMap(teamMap);

          setState(() {
            _team = team;
          });

          await _loadSeasons();
        } else {
          debugPrint('[TeamHomePage] No teams found in database.');
          return false;
        }
      }
    }
    return true;
  }

  Future<bool> _loadLocalDatabase() async {
    try {
      const storage = FlutterSecureStorage();
      var lastDBUsed = await storage.read(key: 'last_db_used');

      var dbOpened = false;

      if (FirebaseAuth.instance.currentUser != null &&
          lastDBUsed != null &&
          lastDBUsed.isNotEmpty) {
        try {
          dbOpened = await DatabaseService.instance.open(lastDBUsed);
        } catch (e) {
          debugPrint('[TeamHomePage] Error opening database: $e');
        }

        if (!dbOpened) {
          try {
            final availableDBs = await DatabaseService.instance
                .getAvailableDatabases(
                    sportFilter: SportStrategy.current.sportId);
            if (!availableDBs.contains(lastDBUsed)) {
              debugPrint(
                  'Last DB $lastDBUsed not valid for sport ${SportStrategy.current.sportId}');
              if (availableDBs.isNotEmpty) {
                lastDBUsed = availableDBs.first;
                await storage.write(key: 'last_db_used', value: lastDBUsed);
              } else {
                lastDBUsed = null;
                await storage.delete(key: 'last_db_used');
              }
            }
          } catch (e) {
            debugPrint('Error validating last DB: $e');
          }
        }
      }

      if (DatabaseService.instance.path.isNotEmpty) {
        try {
          // Attempt to parallel-load Team 1 and Seasons
          final results = await Future.wait([
            Team.fromId(1),
            Season.fromTeamId(1),
          ]);
          _team = results[0] as Team;
          await _loadSeasons(preloadedSeasons: results[1] as List<Season>);
        } catch (e) {
          // Fallback if Team id 1 doesn't exist
          final teamResult = await DatabaseService.instance
              .query('Teams', limitToFirst: 1);
          if (teamResult.isNotEmpty) {
            _team = Team.fromMap(teamResult.first);
            await _loadSeasons();
          }
        }
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('[TeamHomePage] Error in _loadLocalDatabase: $e');
      debugPrint('[TeamHomePage] Stack trace: $stackTrace');
      return false;
    }
  }

  Future<void> _loadSeasons({List<Season>? preloadedSeasons}) async {
    if (_team == null) {
      return;
    }

    final teamId = _team!.id;
    final allSeasons = preloadedSeasons ?? await Season.fromTeamId(teamId);

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

    // Trigger async stats update (for percentages)
    _updateOverallStats();
  }

  /// Calculates detailed stats (e.g. percentages) asynchronously
  Future<void> _updateOverallStats() async {
    final allSeasons = [..._seasons, ..._importedSeasons];
    if (allSeasons.isEmpty) return;

    final stats = <String, num>{};

    // Calculate percentages for basketball
    if (SportStrategy.current.sportId == 'basketball') {
      int total3PM = 0;
      int total3PMissed = 0;
      int total2PM = 0;
      int total2PMissed = 0;
      int totalFTM = 0;
      int totalFTMissed = 0;

      for (final season in allSeasons) {
        // Fetch SeasonStats (this loads events which might be expensive, so we do it async)
        final sStats = await season.getStats();
        if (sStats != null) {
          total3PM += sStats.teamStat('3_pointers');
          total3PMissed += sStats.teamStat('3_pointers_missed');
          total2PM += sStats.teamStat('2_pointers');
          total2PMissed += sStats.teamStat('2_pointers_missed');
          totalFTM += sStats.teamStat('free_throws');
          totalFTMissed += sStats.teamStat('free_throws_missed');
        }
      }

      final total3PAttempts = total3PM + total3PMissed;
      if (total3PAttempts > 0) {
        stats['3_point_percentage'] =
            ((total3PM / total3PAttempts) * 100).round();
      }

      final total2PAttempts = total2PM + total2PMissed;
      if (total2PAttempts > 0) {
        stats['2_point_percentage'] =
            ((total2PM / total2PAttempts) * 100).round();
      }

      final totalFTAttempts = totalFTM + totalFTMissed;
      if (totalFTAttempts > 0) {
        stats['free_throw_percentage'] =
            ((totalFTM / totalFTAttempts) * 100).round();
      }
    }

    if (mounted) {
      setState(() {
        _asyncOverallStats = stats;
      });
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
          _loadCurrentOrLastGame();
          _updateOverallStats();
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
          _updateOverallStats();
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

  /// Build analytics carousel with multiple cards showing overall statistics
  Widget _buildAnalyticsCarousel() {
    final loc = AppLocalizations.of(context)!;
    final allSeasons = [..._seasons, ..._importedSeasons];

    // Calculate overall statistics
    final stats = _calculateOverallStats(allSeasons);
    stats.addAll(_asyncOverallStats);

    // Build items list first to get count
    final items = [
      // Goals/Points Analytics Card
      if (stats.containsKey('totalGoalsScored'))
        _buildAnalyticsCard(
          title: SportStrategy.current.sportId == 'basketball'
              ? 'Scoring Analytics'
              : loc.goalAnalytics,
          icon: SportStrategy.current.sportIcon,
          iconColor: Colors.green,
          stats: [
            _buildStatRow(
                SportStrategy.current.sportId == 'basketball'
                    ? 'Total Points'
                    : loc.totalGoalsScored,
                '${stats['totalGoalsScored']}',
                Icons.sports_score),
            _buildStatRow(
                SportStrategy.current.sportId == 'basketball'
                    ? 'Points Allowed'
                    : loc.totalGoalsConceded,
                '${stats['totalGoalsConceded']}',
                Icons.shield),
            _buildStatRow(
                SportStrategy.current.sportId == 'basketball'
                    ? 'Points Per Game'
                    : loc.avgGoalsPerGame,
                stats['avgGoalsPerGame']!.toStringAsFixed(2),
                Icons.trending_up),
            _buildStatRow(
                SportStrategy.current.sportId == 'basketball'
                    ? 'Point Diff'
                    : loc.goalDifferential,
                stats['goalDifferential']! >= 0
                    ? '+${stats['goalDifferential']}'
                    : '${stats['goalDifferential']}',
                Icons.compare_arrows),
            if (SportStrategy.current.sportId == 'basketball' &&
                stats.containsKey('2_point_percentage'))
              _buildStatRow(
                  'FG %', '${stats['2_point_percentage']}%', Icons.data_usage),
            if (SportStrategy.current.sportId == 'basketball' &&
                stats.containsKey('3_point_percentage'))
              _buildStatRow(
                  '3PT %', '${stats['3_point_percentage']}%', Icons.data_usage),
            if (SportStrategy.current.sportId == 'basketball' &&
                stats.containsKey('free_throw_percentage'))
              _buildStatRow('FT %', '${stats['free_throw_percentage']}%',
                  Icons.data_usage),
          ],
        ),
      // Win Streaks Card
      if (stats.containsKey('longestWinStreak'))
        _buildAnalyticsCard(
          title: loc.streaksRecords,
          icon: Icons.emoji_events,
          iconColor: Colors.amber,
          stats: [
            _buildStatRow(loc.longestWinStreak,
                '${stats['longestWinStreak']} ${loc.games}', Icons.trending_up),
            _buildStatRow(
                loc.longestUnbeatenStreak,
                '${stats['longestUnbeatenStreak']} ${loc.games}',
                Icons.shield_outlined),
            _buildStatRow(
                SportStrategy.current.sportId == 'basketball'
                    ? 'Most Points in Game'
                    : loc.mostGoalsInGame,
                '${stats['mostGoalsInGame']}',
                Icons.sports_score),
            _buildStatRow(loc.biggestVictory, '+${stats['biggestVictory']}',
                Icons.celebration),
          ],
        ),
      // Home vs Away Card
      if (stats.containsKey('homeWins'))
        _buildAnalyticsCard(
          title: loc.homeAwayAnalysis,
          icon: Icons.home,
          iconColor: Colors.blue,
          stats: [
            _buildStatRow(
                loc.homeRecord,
                '${stats['homeWins']}-${stats['homeDraws']}-${stats['homeLosses']}',
                Icons.home),
            _buildStatRow(
                loc.awayRecord,
                '${stats['awayWins']}-${stats['awayDraws']}-${stats['awayLosses']}',
                Icons.flight_takeoff),
            _buildStatRow(
                loc.homeWinPercentage,
                '${(stats['homeWinPct']! * 100).toStringAsFixed(0)}%',
                Icons.percent),
            _buildStatRow(
                loc.awayWinPercentage,
                '${(stats['awayWinPct']! * 100).toStringAsFixed(0)}%',
                Icons.percent),
          ],
        ),
      // Clean Sheets & Defense Card (Soccer Only)
      if (stats.containsKey('cleanSheets') &&
          SportStrategy.current.sportId != 'basketball')
        _buildAnalyticsCard(
          title: loc.defensiveStats,
          icon: Icons.shield,
          iconColor: Colors.indigo,
          stats: [
            _buildStatRow(
                loc.cleanSheets, '${stats['cleanSheets']}', Icons.block),
            _buildStatRow(
                loc.cleanSheetPercentage,
                '${(stats['cleanSheetPct']! * 100).toStringAsFixed(0)}%',
                Icons.percent),
            _buildStatRow(
                loc.avgGoalsConceded,
                stats['avgGoalsConceded']!.toStringAsFixed(2),
                Icons.shield_outlined),
            _buildStatRow(loc.shutoutsRecorded, '${stats['shutouts']}',
                Icons.verified_user),
          ],
        ),
    ];

    return Column(
      children: [
        // Analytics cards carousel
        CarouselSlider(
          options: CarouselOptions(
            height: 240,
            viewportFraction: 0.85,
            enlargeCenterPage: true,
            enableInfiniteScroll: stats.isNotEmpty,
            autoPlay: stats.length > 1,
            autoPlayInterval: const Duration(seconds: 5),
            onPageChanged: (index, reason) {
              setState(() {
                _currentAnalyticsCarouselPage = index;
              });
            },
          ),
          items: items,
        ),
        const SizedBox(height: 8),
        // Page indicators

        if (items.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: items.asMap().entries.map((entry) {
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary.withValues(
                      alpha: _currentAnalyticsCarouselPage == entry.key
                          ? 0.9
                          : 0.3),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _buildAnalyticsSkeleton() {
    return SizedBox(
      height: 240,
      child: Card(
        elevation: 0,
        margin: const EdgeInsets.symmetric(
            horizontal: 32), // Match viewportFraction roughly
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            width: 2,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // Header skeleton
              Row(
                children: [
                  SkeletonContainer.rectangular(width: 24, height: 24),
                  const SizedBox(width: 12),
                  SkeletonContainer.rectangular(width: 120, height: 16),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                  color: Theme.of(context)
                      .colorScheme
                      .outline
                      .withValues(alpha: 0.1)),
              const SizedBox(height: 12),
              // Stats rows skeleton
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(4, (index) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SkeletonContainer.rectangular(width: 80, height: 12),
                        SkeletonContainer.rectangular(width: 40, height: 12),
                      ],
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build individual analytics card
  Widget _buildAnalyticsCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Widget> stats,
  }) {
    return HoverBuilder(
      builder: (context, isHovered) {
        return Transform.scale(
          scale: isHovered && kIsWeb ? 1.02 : 1.0,
          child: InkWell(
            onTap: () {
              // Navigate to Analytics (History Versus) page
              final databaseId = DatabaseService.instance.publicShareId!;
              NavigationHelper.navigateTo(
                context,
                '/team/$databaseId/history',
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Card(
              key: const Key('analytics_card'),
              elevation: isHovered && kIsWeb ? 8 : 4,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: isHovered && kIsWeb
                      ? iconColor
                      : iconColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      iconColor.withValues(alpha: 0.1),
                      Theme.of(context).colorScheme.surface,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card header
                    Row(
                      children: [
                        Icon(icon, color: iconColor, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        // Add tap indicator icon
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: iconColor.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),
                    // Stats rows
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            for (var i = 0; i < stats.length; i++) ...[
                              stats[i],
                              if (i < stats.length - 1)
                                const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build individual stat row
  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context)
              .colorScheme
              .onSurfaceVariant
              .withValues(alpha: 0.6),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  /// Calculate overall statistics from all seasons
  /// Only includes completed games from the past
  Map<String, num> _calculateOverallStats(List<Season> seasons) {
    final stats = <String, num>{};

    if (seasons.isEmpty) return stats;

    final now = DateTime.now();
    int totalGoalsScored = 0;
    int totalGoalsConceded = 0;
    int totalGames = 0;
    int homeWins = 0, homeDraws = 0, homeLosses = 0;
    int awayWins = 0, awayDraws = 0, awayLosses = 0;
    int cleanSheets = 0;
    int shutouts = 0;
    int longestWinStreak = 0;
    int longestUnbeatenStreak = 0;
    int mostGoalsInGame = 0;
    int biggestVictory = 0;

    int currentWinStreak = 0;
    int currentUnbeatenStreak = 0;

    for (final season in seasons) {
      // Process games for detailed stats
      for (final game in season.games) {
        // Only include completed games from the past
        // GameStatus index 9+ means completed/final
        final isCompleted = game.gameStatus.index >= 9;
        final isInPast = game.date.isBefore(now);

        // Skip if game is not completed or is in the future
        if (!isCompleted || !isInPast) {
          continue;
        }

        final isHome = game.isHomeTeam(season.teamId);
        final goalsFor = isHome ? game.homeTeamScore : game.awayTeamScore;
        final goalsAgainst = isHome ? game.awayTeamScore : game.homeTeamScore;
        final goalDiff = goalsFor - goalsAgainst;

        totalGoalsScored += goalsFor;
        totalGoalsConceded += goalsAgainst;
        totalGames++;

        // Track biggest victory
        if (goalDiff > biggestVictory) {
          biggestVictory = goalDiff;
        }

        // Track most goals in a game
        if (goalsFor > mostGoalsInGame) {
          mostGoalsInGame = goalsFor;
        }

        // Track clean sheets (no goals conceded)
        if (goalsAgainst == 0) {
          cleanSheets++;
          if (goalsFor > 0) shutouts++;
        }

        // Track home/away records
        if (isHome) {
          if (goalDiff > 0) {
            homeWins++;
          } else if (goalDiff == 0)
            homeDraws++;
          else
            homeLosses++;
        } else {
          if (goalDiff > 0) {
            awayWins++;
          } else if (goalDiff == 0)
            awayDraws++;
          else
            awayLosses++;
        }

        // Track streaks
        if (goalDiff > 0) {
          currentWinStreak++;
          currentUnbeatenStreak++;
          if (currentWinStreak > longestWinStreak) {
            longestWinStreak = currentWinStreak;
          }
          if (currentUnbeatenStreak > longestUnbeatenStreak) {
            longestUnbeatenStreak = currentUnbeatenStreak;
          }
        } else if (goalDiff == 0) {
          currentWinStreak = 0;
          currentUnbeatenStreak++;
          if (currentUnbeatenStreak > longestUnbeatenStreak) {
            longestUnbeatenStreak = currentUnbeatenStreak;
          }
        } else {
          currentWinStreak = 0;
          currentUnbeatenStreak = 0;
        }
      }
    }

    // Calculate derived stats
    final homeGames = homeWins + homeDraws + homeLosses;
    final awayGames = awayWins + awayDraws + awayLosses;

    stats['totalGoalsScored'] = totalGoalsScored;
    stats['totalGoalsConceded'] = totalGoalsConceded;
    stats['avgGoalsPerGame'] =
        totalGames > 0 ? totalGoalsScored / totalGames : 0;
    stats['avgGoalsConceded'] =
        totalGames > 0 ? totalGoalsConceded / totalGames : 0;
    stats['goalDifferential'] = totalGoalsScored - totalGoalsConceded;

    stats['homeWins'] = homeWins;
    stats['homeDraws'] = homeDraws;
    stats['homeLosses'] = homeLosses;
    stats['homeWinPct'] = homeGames > 0 ? homeWins / homeGames : 0;

    stats['awayWins'] = awayWins;
    stats['awayDraws'] = awayDraws;
    stats['awayLosses'] = awayLosses;
    stats['awayWinPct'] = awayGames > 0 ? awayWins / awayGames : 0;

    stats['cleanSheets'] = cleanSheets;
    stats['shutouts'] = shutouts;
    stats['cleanSheetPct'] = totalGames > 0 ? cleanSheets / totalGames : 0;

    stats['longestWinStreak'] = longestWinStreak;
    stats['longestUnbeatenStreak'] = longestUnbeatenStreak;
    stats['mostGoalsInGame'] = mostGoalsInGame;
    stats['biggestVictory'] = biggestVictory;

    return stats;
  }

  Future<void> _loadCurrentOrLastGame() async {
    if (_team == null) return;

    try {
      // Get all games incrementally from loaded seasons
      final games = _seasons.expand((s) => s.games).toList();

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
        return game.gameStatus.index > 0;
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
        _currentRecentGamesCarouselPage = 0;
      } else {
        _currentOrLastGame = startedOrCompletedGames.first;
        // Get last 5 completed games for carousel (only completed games, status 9+)
        _lastFiveGames = startedOrCompletedGames
            .where((game) => game.gameStatus.index >= 9)
            .take(5)
            .toList();
        _currentRecentGamesCarouselPage = 0; // Reset to first page
        // Load game events for each of the last 5 games
        for (final game in _lastFiveGames) {
          await game.loadGameEvents();
        }
      }

      // Load game events for the selected game
      if (_currentOrLastGame != null) {
        await _currentOrLastGame!.loadGameEvents();
      }

      // Cancel the update timer if game is no longer live
      if (_liveGameUpdateTimer != null) {
        final isLiveGame = _currentOrLastGame != null &&
            _currentOrLastGame!.gameStatus.index > 0 &&
            _currentOrLastGame!.gameStatus.index < 9;
        if (!isLiveGame) {
          _liveGameUpdateTimer?.cancel();
          _liveGameUpdateTimer = null;
        }
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
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      return true;
    }

    if (!mounted || _isShowingSignInDialog) return false;

    _isShowingSignInDialog = true;
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
                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    } catch (e) {
                      debugPrint('Google sign-in error: $e');
                      if (context.mounted) {
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
                        if (context.mounted) {
                          Navigator.of(context).pop(true);
                        }
                      } catch (e) {
                        debugPrint('Apple sign-in error: $e');
                        if (context.mounted) {
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

    _isShowingSignInDialog = false;
    return result == true;
  }

  Widget _buildHoverableOption({
    required Widget leading,
    required Widget title,
    required VoidCallback onTap,
    Widget? subtitle,
  }) {
    return HoverBuilder(
      builder: (context, isHovered) {
        return Transform.scale(
          scale: isHovered && kIsWeb ? 1.02 : 1.0,
          child: ListTile(
            leading: leading,
            title: title,
            subtitle: subtitle,
            onTap: onTap,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            tileColor: isHovered && kIsWeb
                ? Theme.of(context)
                    .colorScheme
                    .surfaceContainerHighest
                    .withValues(alpha: 0.3)
                : null,
          ),
        );
      },
    );
  }

  Future<void> _showCreateOptions(BuildContext context) async {
    final loc = AppLocalizations.of(context)!;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext builderContext) {
        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Wrap(
            children: [
              _buildHoverableOption(
                leading: Icon(Icons.cloud_sync_rounded,
                    color: Theme.of(context).colorScheme.secondary),
                title: Text(
                    AppLocalizations.of(context)!.openExistingCloudDatabase),
                onTap: () {
                  Navigator.of(builderContext).pop();
                  _handleSelection(context, 'existingCloudDatabase');
                },
              ),
              _buildHoverableOption(
                leading: Icon(Icons.cloud_rounded,
                    color: Theme.of(context).colorScheme.secondary),
                title:
                    Text(AppLocalizations.of(context)!.createNewCloudDatabase),
                onTap: () async {
                  Navigator.of(builderContext).pop();
                  await _handleSelection(context, 'newCloudDatabase');
                },
              ),
              if (_team != null) ...[
                _buildHoverableOption(
                  leading: Icon(Icons.calendar_today,
                      color: Theme.of(context).colorScheme.secondary),
                  title: Text(AppLocalizations.of(context)!.createNewSeason),
                  onTap: () {
                    Navigator.of(builderContext).pop();
                    _handleSelection(context, 'season');
                  },
                ),
                _buildHoverableOption(
                  leading: Icon(Icons.palette,
                      color: Theme.of(context).colorScheme.secondary),
                  title: Text(loc.changeTeamColors),
                  onTap: () {
                    Navigator.of(builderContext).pop();
                    _handleSelection(context, 'teamColors');
                  },
                ),
                _buildHoverableOption(
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
                _buildHoverableOption(
                  leading: Icon(Icons.group,
                      color: Theme.of(context).colorScheme.secondary),
                  title: Text(loc.createNewTeam),
                  onTap: () {
                    Navigator.of(builderContext).pop();
                    _handleSelection(context, 'team');
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _pickCloudDatabase() async {
    // Check if user is signed in first
    if (!await _ensureUserSignedIn()) {
      return null;
    }

    if (!mounted) return null;

    // Show loading while fetching databases
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    List<String> entries = [];
    try {
      entries = await DatabaseService.instance
          .getAvailableDatabases(sportFilter: SportStrategy.current.sportId);
    } finally {
      if (mounted) {
        Navigator.of(context).pop(); // Dismiss loading
      }
    }

    if (entries.isEmpty) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: true,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(AppLocalizations.of(context)!.noCloudDatabasesFound),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      }
      return null;
    }

    if (!mounted) return null;

    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.selectACloudDatabase,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: entries.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, indent: 16, endIndent: 16),
                    itemBuilder: (context, index) {
                      final databaseName = entries[index];
                      return ListTile(
                        leading: Icon(
                          Icons.storage,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          databaseName,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(context, databaseName);
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
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
          // Allow the bottom sheet closing animation to finish
          await Future.delayed(const Duration(milliseconds: 300));

          if (mounted) {
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (BuildContext context) {
                return const PopScope(
                  canPop: false,
                  child: Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text('Opening database...'),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }

          // Small delay to ensure dialog renders
          await Future.delayed(const Duration(milliseconds: 100));

          try {
            await _openCloudDatabase(databaseName);
          } finally {
            if (mounted) {
              Navigator.of(context).pop(); // Dismiss loading indicator
            }
          }
          // The page will update automatically due to setState in _openCloudDatabase
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
        await GameActionHelpers.editLiveLink(
          context: context,
          game: _nextUpcomingGame ?? _currentOrLastGame,
          team: _team,
          onUpdate: () {
            if (mounted) setState(() {});
          },
        );
        break;
    }
  }

  Future<void> _createDatabase() async {
    // Check if user is signed in first
    if (!await _ensureUserSignedIn()) {
      return;
    }
    if (!mounted) return;

    String databaseName = '';
    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Card(
            child: Padding(
              padding: EdgeInsets.only(
                top: 50,
                left: 50,
                right: 50,
                bottom: MediaQuery.of(context).viewInsets.bottom + 50,
              ),
              child: SingleChildScrollView(
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

                                if (mounted) setState(() {});
                                if (context.mounted) Navigator.pop(context);
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
                ]),
              ),
            ),
          );
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

      await DatabaseService.instance
          .open(databaseName, createWithSportId: SportStrategy.current.sportId);

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
        isScrollControlled: true,
        builder: (context) {
          return StatefulBuilder(
              builder: (BuildContext context, StateSetter setModalState) {
            return Card(
              child: Padding(
                padding: EdgeInsets.only(
                  top: 50,
                  left: 50,
                  right: 50,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 50,
                ),
                child: SingleChildScrollView(
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
                          backgroundImage:
                              imageFile != null ? FileImage(imageFile!) : null,
                          initials: '',
                          fallbackIcon: const Icon(Icons.add_a_photo),
                        ),
                      ),
                    TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!.teamName),
                        onChanged: (name) => teamName = name),
                    TextField(
                        decoration: InputDecoration(
                            labelText:
                                AppLocalizations.of(context)!.teamShortName),
                        onChanged: (name) => teamShortName = name),
                    const SizedBox(height: 20),
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
                  ]),
                ),
              ),
            );
          });
        });
  }

  Future<void> _saveTeam(String teamName, String teamShortName,
      {Color? color1 = Colors.green,
      Color? color2 = Colors.green,
      String? logoUrl}) async {
    await DatabaseService.instance.insert('Teams', {
      'id': 1,
      'fullName': teamName,
      'shortName': teamShortName,
      'color1': color1?.toARGB32(),
      'color2': color2?.toARGB32(),
      'logoUrl': logoUrl
    });

    // Load the new team
    final teamResult = await DatabaseService.instance
        .query('Teams', orderByChild: 'id', equalTo: 1);
    if (teamResult.isNotEmpty) {
      _team = Team.fromMap(teamResult.first);
      await _loadSeasons();
      if (mounted) setState(() {});
    }
  }

  Future<void> _createSeason() async {
    late String seasonName;

    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Card(
            child: Padding(
              padding: EdgeInsets.only(
                top: 50,
                left: 50,
                right: 50,
                bottom: MediaQuery.of(context).viewInsets.bottom + 50,
              ),
              child: SingleChildScrollView(
                child: Column(children: [
                  Text(AppLocalizations.of(context)!.newSeason),
                  TextField(
                      autofocus: true,
                      decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.seasonName),
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

                                if (mounted) setState(() {});
                                if (context.mounted) Navigator.pop(context);
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
                ]),
              ),
            ),
          );
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
                Team.clearCache();
                final teamResult = await DatabaseService.instance
                    .query('Teams', orderByChild: 'id', equalTo: _team!.id);
                if (teamResult.isNotEmpty) {
                  if (mounted) {
                    setState(() {
                      _team = Team.fromMap(teamResult.first);
                    });
                  }
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
      final baseUrl = SportStrategy.current.webUrl;
      final url = '$baseUrl/team/$id';
      final databaseName = DatabaseService.instance.path;

      if (mounted) {
        setState(() {
          _isSharing = false;
        });
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
        setState(() {
          _isSharing = false;
        });
        final loc = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(loc.errorDuringShare),
            backgroundColor: Theme.of(context).colorScheme.error));
      }
      debugPrint(e.toString());
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
    await GameActionHelpers.tweetGameDay(
      context: context,
      game: _nextUpcomingGame ?? _currentOrLastGame,
      team: _team,
      onUpdate: () {
        if (mounted) setState(() {});
      },
    );
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
        _currentOrLastGame!.gameLinks!.trim().isNotEmpty) {
      try {
        final g = _currentOrLastGame!.date.toLocal();
        isLive = g.year == nowLocal.year &&
            g.month == nowLocal.month &&
            g.day == nowLocal.day &&
            _currentOrLastGame!.gameStatus.index > 0 &&
            _currentOrLastGame!.gameStatus.index < 9;
      } catch (e) {
        debugPrint('Error checking live game date: $e');
        isLive = false;
      }
    }

    // Live banner — only if the conditions above are met
    if (isLive) {
      final url = _currentOrLastGame!.gameLinks!;

      final loc = AppLocalizations.of(context)!;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HoverBuilder(
            builder: (context, isHovered) {
              return Transform.scale(
                scale: isHovered && kIsWeb ? 1.02 : 1.0,
                child: GestureDetector(
                  onTap: () async {
                    try {
                      final uri = Uri.parse(url);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: Text(loc.unableToOpenLiveLink)));
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
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
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
                                color: Colors.white,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(Icons.open_in_new, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          _buildViewScheduleLink(),
        ],
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
          _nextUpcomingGame!.gameLinks!.trim().isNotEmpty;

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

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HoverBuilder(
            builder: (context, isHovered) {
              return Transform.scale(
                scale: isHovered && kIsWeb && hasLiveLink ? 1.02 : 1.0,
                child: GestureDetector(
                  // Make banner tappable if live link exists
                  onTap: hasLiveLink
                      ? () async {
                          final url = _nextUpcomingGame!.gameLinks!;
                          try {
                            final uri = Uri.parse(url);
                            if (await canLaunchUrl(uri)) {
                              await launchUrl(uri,
                                  mode: LaunchMode.externalApplication);
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content:
                                            Text(loc.unableToOpenLiveLink)));
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(loc.unableToOpenLiveLink)));
                            }
                          }
                        }
                      : null,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 10, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [_team!.color1, _team!.color2],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        // Opponent Logo or Schedule Icon
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: ResponsiveAvatar(
                            imageUrl: _nextUpcomingGame!.isHomeTeam(_team!.id)
                                ? _nextUpcomingGame!.awayTeam.logoUrl
                                : _nextUpcomingGame!.homeTeam.logoUrl,
                            initials: (_nextUpcomingGame!.isHomeTeam(_team!.id)
                                        ? _nextUpcomingGame!.awayTeam.shortName
                                        : _nextUpcomingGame!.homeTeam.shortName)
                                    .isNotEmpty
                                ? (_nextUpcomingGame!.isHomeTeam(_team!.id)
                                    ? _nextUpcomingGame!.awayTeam.shortName
                                    : _nextUpcomingGame!.homeTeam.shortName)
                                : opponent.substring(
                                    0, min(2, opponent.length)),
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${loc.nextGamePrefix} $opponent',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
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
                        // Live Link Icon
                        if (hasLiveLink)
                          const Padding(
                            padding: EdgeInsets.only(left: 8.0),
                            child: Icon(
                              Icons.videocam,
                              color: Colors.white,
                              size: 28,
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
                ),
              );
            },
          ),
          _buildViewScheduleLink(),
        ],
      );
    }

    return _buildViewScheduleLink();
  }

  Widget _buildViewScheduleLink() {
    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 4.0),
      child: InkWell(
        onTap: () {
          if (_currentSeason != null) {
            final databaseId = DatabaseService.instance.publicShareId!;
            NavigationHelper.navigateTo(
              context,
              '/team/$databaseId/season/${_currentSeason!.id}',
              extra: {
                'season': _currentSeason!,
                'viewType': SeasonViewType.calendar
              },
            );
          }
        },
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_month,
                  size: 16,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.lightBlueAccent
                      : Theme.of(context).primaryColor),
              const SizedBox(width: 6),
              Text(
                'View Season Schedule',
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.lightBlueAccent
                      : Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows recent highlights (events with non-empty eventUrls) from the
  /// currently selected game. Visible on web only. Limits to 6 most recent
  /// events and shows buttons for each available URL on an event.
  Widget _buildRecentHighlights() {
    if (_currentOrLastGame == null || _team == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<GameEvent>>(
      future: _currentOrLastGame!
          .loadGameEvents()
          .then((_) => _currentOrLastGame!.allGameEvents),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return const SizedBox.shrink();
        }

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
                                                      'accomplishment_images/${DateTime.now().millisecondsSinceEpoch}_$uploadedCount.jpg');
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
        ); // Close StatefulBuilder
      },
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
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancelButton),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.seasonNameRequired)),
                  );
                  return;
                }
                Navigator.of(context).pop(true);
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

  Widget _buildDashboardSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Games header
          Row(
            children: [
              SkeletonContainer.rectangular(width: 24, height: 24),
              const SizedBox(width: 8),
              SkeletonContainer.rectangular(width: 120, height: 16),
            ],
          ),
          const SizedBox(height: 16),
          // Game Card Skeleton
          SkeletonContainer.rectangular(
            height: 140,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 24),
          // Team Performance Card
          SkeletonContainer.rectangular(
            height: 280,
            borderRadius: BorderRadius.circular(16),
          ),
          const SizedBox(height: 24),
          // Seasons Header
          SkeletonContainer.rectangular(width: 100, height: 16),
          const SizedBox(height: 16),
          // Season Items
          ...List.generate(
            3,
            (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: SkeletonContainer.rectangular(
                height: 80,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
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
