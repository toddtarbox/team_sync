import 'dart:ui' as ui;

import 'package:carousel_slider/carousel_slider.dart';
import 'package:change_case/change_case.dart';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/player_award.dart';
import 'package:team_sync/models/player_highlight.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/season_stats.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/sport_strategy.dart';
import 'package:team_sync/widgets/breadcrumbs.dart';
import 'package:team_sync/widgets/common/skeleton_container.dart';
import 'package:team_sync/widgets/common/tappable_image.dart';
import 'package:team_sync/widgets/highlight_reel_player.dart';
import 'package:team_sync/widgets/pin_entry_dialog.dart';
import 'package:team_sync/widgets/player_card_generator.dart';
import 'package:team_sync/widgets/player_image_gallery.dart';
import 'package:team_sync/widgets/player_profile_editor.dart';
import 'package:team_sync/widgets/standard_appbar.dart';
import 'package:team_sync/widgets/video_thumbnail.dart';
import 'package:url_launcher/url_launcher.dart';

class PlayerProfilePage extends StatefulWidget {
  final Player player;
  final Season? currentSeason; // made nullable to support deep links

  const PlayerProfilePage({
    super.key,
    required this.player,
    this.currentSeason,
  });

  @override
  State<PlayerProfilePage> createState() => _PlayerProfilePageState();
}

class _PlayerProfilePageState extends State<PlayerProfilePage> {
  Future<List<Map<String, dynamic>>>? _allPlayerEventsFuture;
  Future<Map<Season, SeasonStats>>? _seasonStatsFuture;
  Future<List<GameEvent>>? _highlightsFuture;
  Future<List<PlayerHighlight>>? _independentHighlightsFuture;
  Future<List<PlayerAward>>? _awardsFuture;
  Future<Season?>?
      _currentSeasonFuture; // will load if widget.currentSeason is null
  Season? _loadedSeason;
  bool _showHighlights = true; // Control right panel visibility
  bool _isEditMode = false;
  String? _validatedPin; // Store the validated PIN for web saves

  @override
  void initState() {
    super.initState();

    // start loading season only if not provided
    if (widget.currentSeason == null) {
      _currentSeasonFuture = _loadSeasonForPlayer();
    } else {
      _currentSeasonFuture = Future.value(widget.currentSeason);
    }

    _allPlayerEventsFuture = _fetchAllPlayerEvents();
    _seasonStatsFuture = _loadPlayerSeasonStats();
    _highlightsFuture = _loadPlayerHighlights();
    _independentHighlightsFuture = _loadIndependentHighlights();
    _awardsFuture = _loadAwards();
  }

  Future<Season?> _loadSeasonForPlayer() async {
    try {
      final results = await DatabaseService.instance.query('Seasons',
          orderByChild: 'id', equalTo: widget.player.seasonId);
      if (results.isEmpty) return null;
      final season = Season.fromMap(results.first);
      await season.load();
      _loadedSeason = season;
      return season;
    } catch (e) {
      debugPrint('Error loading season for player: $e');
      return null;
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAllPlayerEvents() async {
    try {
      // Get all events for this player across all seasons
      // Using indexed query on 'playerId' which implies fetching all events for a single player
      final events = await DatabaseService.instance
          .query('Events', orderByChild: 'playerId', equalTo: widget.player.id);

      // Cast to expected type
      return events.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (e) {
      debugPrint('Error loading all player events: $e');
      return [];
    }
  }

  Future<Map<Season, SeasonStats>> _loadPlayerSeasonStats() async {
    final Map<Season, SeasonStats> seasonStatsMap = {};
    try {
      // Use the pre-fetched events for this player
      final allEvents = await _allPlayerEventsFuture;
      if (allEvents == null || allEvents.isEmpty) return {};

      // Filter out events from scrimmage games
      final gameIds = allEvents
          .map((e) => e['gameId'] as int?)
          .where((id) => id != null)
          .cast<int>()
          .toSet();
      final Set<int> scrimmageGameIds = {};

      for (final gameId in gameIds) {
        final gameData = await DatabaseService.instance
            .query('Games', orderByChild: 'id', equalTo: gameId);
        if (gameData.isNotEmpty) {
          final map = gameData.first;
          final isScrimmage = map['isScrimmage'] == 1 ||
              map['isScrimmage'] == true ||
              map['isScrimmage'] == 'true';
          if (isScrimmage) {
            scrimmageGameIds.add(gameId);
          }
        }
      }

      final filteredEvents = allEvents
          .where((e) => !scrimmageGameIds.contains(e['gameId'] as int?))
          .toList();

      // Group events by seasonId
      final eventsBySeason = <int, List<Map<String, dynamic>>>{};
      for (final event in filteredEvents) {
        final seasonId = event['seasonId'] as int?;
        if (seasonId != null) {
          if (!eventsBySeason.containsKey(seasonId)) {
            eventsBySeason[seasonId] = [];
          }
          eventsBySeason[seasonId]!.add(event);
        }
      }

      // Load each season and create SeasonStats from the subset of events
      for (final seasonId in eventsBySeason.keys) {
        final seasonEvents = eventsBySeason[seasonId]!;

        // Get season info (efficient lookup by ID)
        final seasonResults = await DatabaseService.instance
            .query('Seasons', orderByChild: 'id', equalTo: seasonId);

        if (seasonResults.isEmpty) {
          continue;
        }

        final season = Season.fromMap(seasonResults.first);
        await season.load();

        // Create SeasonStats using ONLY this player's events for this season.
        // This is safe because PlayerProfilePage only displays stats for this specific player,
        // so we don't need the full team's event history to calculate rank.
        final stats =
            SeasonStats.fromMap(season.teamId, season.id, seasonEvents);

        seasonStatsMap[season] = stats;
      }

      return seasonStatsMap;
    } catch (e, stack) {
      debugPrint('Error loading player season stats: $e\n$stack');
      rethrow; // Re-throw to show error in UI
    }
  }

  Future<List<GameEvent>> _loadPlayerHighlights() async {
    try {
      // Use the pre-fetched events
      final allEvents = await _allPlayerEventsFuture;
      if (allEvents == null) return [];

      // Filter to only events with URLs
      final eventsWithUrls = await Future.wait(
        allEvents
            .where((e) =>
                e['eventUrls'] != null && e['eventUrls'].toString().isNotEmpty)
            .map((e) async => await GameEvent.fromMap(e))
            .toList(growable: false),
      );

      // Remove nulls and sort by date (most recent first)
      final validEvents = eventsWithUrls.whereType<GameEvent>().toList();
      validEvents.sort((a, b) => b.game.date.compareTo(a.game.date));

      return validEvents;
    } catch (e) {
      debugPrint('Error loading player highlights: $e');
      return [];
    }
  }

  Future<List<PlayerHighlight>> _loadIndependentHighlights() async {
    try {
      return await PlayerHighlight.listFromPlayerId(widget.player.id);
    } catch (e) {
      debugPrint('Error loading independent highlights: $e');
      return [];
    }
  }

  Future<List<PlayerAward>> _loadAwards() async {
    try {
      return await PlayerAward.listFromPlayerId(widget.player.id);
    } catch (e) {
      debugPrint('Error loading awards: $e');
      return [];
    }
  }

  Future<Map<String, int>> _getPlayerStats(
      SeasonStats stats, int playerId) async {
    final Map<String, int> playerStats = {};

    for (final category in SportStrategy.current.leaderCategories) {
      if (category == 'ownGoalsEarned') {
        continue;
      }

      final statPlayers = await stats.getStatPlayers(category);

      // Find the player in the stats
      for (final entry in statPlayers.entries) {
        if (entry.key.id == playerId) {
          playerStats[category] = entry.value;
          break;
        }
      }
    }

    return playerStats;
  }

  Future<Map<String, int>> _getCareerStats(
      Map<Season, SeasonStats> seasonStats) async {
    final Map<String, int> careerStats = {};

    // Aggregate stats across all seasons
    for (final stats in seasonStats.values) {
      final playerStats = await _getPlayerStats(stats, widget.player.id);

      for (final entry in playerStats.entries) {
        careerStats[entry.key] = (careerStats[entry.key] ?? 0) + entry.value;
      }
    }

    return careerStats;
  }

  Future<void> _showPinDialog() async {
    if (!kIsWeb) {
      setState(() {
        _isEditMode = true;
      });
      return;
    }

    final pin = await showDialog<String>(
      context: context,
      builder: (context) => PinEntryDialog(player: widget.player),
    );

    if (pin != null && pin.isNotEmpty) {
      setState(() {
        _isEditMode = true;
        _validatedPin = pin; // Store the validated PIN
      });
    }
  }

  void _exitEditMode() async {
    // Regenerate PIN silently when exiting edit mode (web only)
    // The new PIN will only be visible to coaches on mobile
    if (_validatedPin != null) {
      try {
        await Player.regeneratePin(
          widget.player.id,
          widget.player.seasonId,
          _validatedPin!,
        );
        // PIN regenerated successfully - now reload player to get the new PIN
        await _reloadPlayerData();
      } catch (e) {
        // Log error but don't block exit
        debugPrint('Failed to regenerate PIN: $e');
      }
    }

    setState(() {
      _isEditMode = false;
      _validatedPin = null; // Clear the PIN
      // Reload data to show any changes
      _seasonStatsFuture = _loadPlayerSeasonStats();
      _highlightsFuture = _loadPlayerHighlights();
      _independentHighlightsFuture = _loadIndependentHighlights();
      _awardsFuture = _loadAwards();
    });
  }

  /// Reload player data from database to get updated PIN
  Future<void> _reloadPlayerData() async {
    try {
      final results = await DatabaseService.instance.query(
        'Players',
        orderByChild: 'id',
        equalTo: widget.player.id,
      );

      if (results.isNotEmpty) {
        // Find the player with matching seasonId
        for (final result in results) {
          final player = Player.fromMap(result);
          if (player.seasonId == widget.player.seasonId) {
            // Update the widget's player object with the new PIN
            widget.player.editPin = player.editPin;
            debugPrint('Player PIN reloaded: ${player.editPin}');
            break;
          }
        }
      }
    } catch (e) {
      debugPrint('Error reloading player data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    // Build a FutureBuilder to ensure we have a season (team) available for the app bar
    return FutureBuilder<Season?>(
      future: _currentSeasonFuture,
      builder: (context, seasonSnapshot) {
        // While loading the season, show a simple scaffold with a spinner
        if (seasonSnapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: buildStandardAppBar(
              context: context,
              team: null,
              title: Text(widget.player.displayName,
                  style: const TextStyle(
                      fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            body: _buildProfileSkeleton(context),
          );
        }

        final Season? currentSeason =
            seasonSnapshot.data ?? widget.currentSeason ?? _loadedSeason;

        return Scaffold(
          appBar: buildStandardAppBar(
            context: context,
            team: currentSeason?.team,
            title: Text(
              widget.player.displayName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            actions: _buildAppBarActions(context, currentSeason),
          ),
          body: Column(
            children: [
              if (currentSeason?.team != null) ...[
                Breadcrumbs(
                  items: buildTeamBreadcrumbs(
                    databaseId: DatabaseService.instance.publicShareId ?? '',
                    teamName: currentSeason!.team.fullName,
                    seasonName: currentSeason.name,
                    seasonId: currentSeason.id,
                    playerName: widget.player.displayName,
                    playerId: widget.player.id,
                  ),
                ),
              ],
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideScreen = constraints.maxWidth > 900;

                    // Build the avatar header section
                    final avatarSection = _buildHeroHeader(currentSeason);

                    // Two-column layout with right panel extending full height
                    if (isWideScreen && _showHighlights) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Left column: avatar + content
                          Expanded(
                            flex: 2,
                            child: Column(
                              children: [
                                avatarSection,
                                Expanded(
                                  child: _isEditMode
                                      ? ListView(
                                          children: [
                                            PlayerProfileEditor(
                                              player: widget.player,
                                              onExitEditMode: _exitEditMode,
                                              pin: _validatedPin,
                                            ),
                                          ],
                                        )
                                      : _seasonStatsFuture == null
                                          ? Center(child: _buildStatsSkeleton())
                                          : FutureBuilder<
                                              Map<Season, SeasonStats>>(
                                              future: _seasonStatsFuture,
                                              builder: (context, snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return Center(
                                                      child:
                                                          _buildStatsSkeleton());
                                                }

                                                if (snapshot.hasError) {
                                                  return Center(
                                                    child: Text(loc
                                                        .errorLoadingPlayerStats(
                                                            snapshot.error
                                                                    ?.toString() ??
                                                                '',
                                                            snapshot.stackTrace
                                                                    ?.toString() ??
                                                                '')),
                                                  );
                                                }

                                                if (!snapshot.hasData ||
                                                    snapshot.data!.isEmpty) {
                                                  return Center(
                                                      child: Text(loc
                                                          .noStatsAvailable));
                                                }

                                                final seasonStats =
                                                    snapshot.data!;
                                                final seasons = seasonStats.keys
                                                    .toList()
                                                  ..sort((a, b) {
                                                    if (currentSeason != null) {
                                                      if (a.id ==
                                                          currentSeason.id) {
                                                        return -1;
                                                      }
                                                      if (b.id ==
                                                          currentSeason.id) {
                                                        return 1;
                                                      }
                                                    }
                                                    return b.name
                                                        .compareTo(a.name);
                                                  });

                                                return ListView(
                                                  children: [
                                                    _buildPlayerHeader(),
                                                    const Divider(thickness: 2),
                                                    _buildCareerStats(
                                                        seasonStats),
                                                    const Divider(thickness: 2),
                                                    ...seasons.map((season) =>
                                                        _buildSeasonStats(
                                                          season,
                                                          seasonStats[season]!,
                                                          currentSeason,
                                                        )),
                                                  ],
                                                );
                                              },
                                            ),
                                ),
                              ],
                            ),
                          ),
                          // Right column: full-height highlights panel
                          SizedBox(
                            width: 400,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.surface,
                                border: Border(
                                  left: BorderSide(
                                    color: Theme.of(context).dividerColor,
                                    width: 1,
                                  ),
                                ),
                              ),
                              child: _buildHighlightsPanel(),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Single column layout (narrow screen or panel hidden)
                      return Column(
                        children: [
                          avatarSection,
                          Expanded(
                            child: _isEditMode
                                ? ListView(
                                    children: [
                                      PlayerProfileEditor(
                                        player: widget.player,
                                        onExitEditMode: _exitEditMode,
                                        pin: _validatedPin,
                                      ),
                                    ],
                                  )
                                : _seasonStatsFuture == null
                                    ? Center(child: _buildStatsSkeleton())
                                    : FutureBuilder<Map<Season, SeasonStats>>(
                                        future: _seasonStatsFuture,
                                        builder: (context, snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return Center(
                                                child: _buildStatsSkeleton());
                                          }

                                          if (snapshot.hasError) {
                                            return Center(
                                              child: Text(
                                                  loc.errorLoadingPlayerStats(
                                                      snapshot.error
                                                              ?.toString() ??
                                                          '',
                                                      snapshot.stackTrace
                                                              ?.toString() ??
                                                          '')),
                                            );
                                          }

                                          if (!snapshot.hasData ||
                                              snapshot.data!.isEmpty) {
                                            return Center(
                                                child:
                                                    Text(loc.noStatsAvailable));
                                          }

                                          final seasonStats = snapshot.data!;
                                          final seasons = seasonStats.keys
                                              .toList()
                                            ..sort((a, b) {
                                              if (currentSeason != null) {
                                                if (a.id == currentSeason.id) {
                                                  return -1;
                                                }
                                                if (b.id == currentSeason.id) {
                                                  return 1;
                                                }
                                              }
                                              return b.name.compareTo(a.name);
                                            });

                                          return ListView(
                                            children: [
                                              _buildPlayerHeader(),
                                              const Divider(thickness: 2),
                                              _buildCareerStats(seasonStats),
                                              const Divider(thickness: 2),
                                              ...seasons.map(
                                                  (season) => _buildSeasonStats(
                                                        season,
                                                        seasonStats[season]!,
                                                        currentSeason,
                                                      )),
                                            ],
                                          );
                                        },
                                      ),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Launch the fullscreen highlight reel player
  void _launchHighlightReel() async {
    // Load all awards, game event highlights, and independent highlights
    final results = await Future.wait([
      _awardsFuture ?? Future.value(<PlayerAward>[]),
      _highlightsFuture ?? Future.value(<GameEvent>[]),
      _independentHighlightsFuture ?? Future.value(<PlayerHighlight>[]),
    ]);

    final awards = results[0] as List<PlayerAward>;
    final gameEventHighlights = results[1] as List<GameEvent>;
    final independentHighlights = results[2] as List<PlayerHighlight>;

    if (!mounted) return;

    // Convert GameEvent highlights to PlayerHighlight format for the reel
    final List<PlayerHighlight> allHighlights = [
      ...independentHighlights,
      ...gameEventHighlights.map((event) {
        // Extract first video URL from the event
        final urls = event.eventUrls
                ?.split(',')
                .map((u) => u.trim())
                .where((u) => u.isNotEmpty)
                .toList() ??
            [];

        return PlayerHighlight(
          id: event.id,
          playerId: widget.player.id,
          title: event.display,
          description:
              '${event.game.displayName(event.team.id)} - ${event.game.date.month}/${event.game.date.day}/${event.game.date.year}',
          videoUrl: urls.isNotEmpty ? urls.first : '',
          date: event.game.date,
        );
      }).where(
          (h) => h.videoUrl.isNotEmpty), // Only include if video URL exists
    ];

    // Check if there's any content to show
    if (awards.isEmpty && allHighlights.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No awards or highlights available'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Navigate to fullscreen highlight reel
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HighlightReelPlayer(
          awards: awards,
          highlights: allHighlights,
          playerName: widget.player.displayName,
        ),
      ),
    );
  }

  /// Show highlights and awards in a modal dialog with carousels (for small screens)
  void _showHighlightsModal() async {
    final loc = AppLocalizations.of(context)!;

    // Load the data
    final results = await Future.wait([
      _highlightsFuture ?? Future.value(<GameEvent>[]),
      _independentHighlightsFuture ?? Future.value(<PlayerHighlight>[]),
      _awardsFuture ?? Future.value(<PlayerAward>[]),
    ]);

    final gameEventHighlights = results[0] as List<GameEvent>;
    final independentHighlights = results[1] as List<PlayerHighlight>;
    final awards = results[2] as List<PlayerAward>;

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(28),
                    topRight: Radius.circular(28),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.video_library, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      '${loc.highlights} & ${loc.awards}',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Content with two carousel sections
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    // Awards Section with Carousel
                    if (awards.isNotEmpty) ...[
                      _buildCarouselSection(
                        title: loc.awards,
                        icon: Icons.emoji_events,
                        count: awards.length,
                        items: awards
                            .map((award) => _buildAwardCarouselCard(award))
                            .toList(),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Highlights Section with Carousel
                    if (gameEventHighlights.isNotEmpty ||
                        independentHighlights.isNotEmpty) ...[
                      _buildCarouselSection(
                        title: loc.highlights,
                        icon: Icons.video_library,
                        count: gameEventHighlights.length +
                            independentHighlights.length,
                        items: [
                          ...independentHighlights.map(
                              (h) => _buildIndependentHighlightCarouselCard(h)),
                          ...gameEventHighlights
                              .map((e) => _buildGameEventCarouselCard(e)),
                        ],
                      ),
                    ],

                    // Empty state
                    if (awards.isEmpty &&
                        gameEventHighlights.isEmpty &&
                        independentHighlights.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            loc.noHighlightsAvailable,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroHeader(Season? season) {
    // If we have an action photo, use it as background
    // Otherwise use a gradient based on team colors if available
    final String? actionPhoto = widget.player.actionPhoto;
    final hasActionPhoto = actionPhoto != null && actionPhoto.isNotEmpty;

    return Container(
      height: 320,
      margin: const EdgeInsets.only(bottom: 24),
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            if (hasActionPhoto)
              Positioned.fill(
                child: Image.network(
                  actionPhoto,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _buildFallbackBackground(season),
                ),
              )
            else
              _buildFallbackBackground(season),

            // Blur/Darken Overlay
            if (hasActionPhoto)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(
                      sigmaX: 10.0, sigmaY: 10.0), // Blur effect
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.4), // Darken effect
                  ),
                ),
              ),

            // Content
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Avatar
                Hero(
                  tag: 'player_avatar_${widget.player.id}',
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: PlayerImageGallery(
                      player: widget.player,
                      size: 140,
                      useLatestImages: true,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Name and Number
                Text(
                  widget.player.displayName,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(0, 2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    widget.player.displayNumbers,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            // QR Code Button (Top Right)
            if (season != null)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.qr_code_2, color: Colors.white),
                    onPressed: () => _showQRCodeDialog(season),
                    tooltip: 'Show QR Code',
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFallbackBackground(Season? season) {
    // Determine gradient colors
    Color color1 = Theme.of(context).colorScheme.primary;
    Color color2 = Theme.of(context).colorScheme.primaryContainer;

    if (season != null) {
      color1 = season.team.color1;
      // We don't have color2 on team usually, let's just use a darker shade or complementary
      color2 =
          Color.lerp(season.team.color1, Colors.black, 0.4) ?? Colors.black;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color1, color2],
        ),
      ),
    );
  }

  /// Build a carousel section with title and items
  Widget _buildCarouselSection({
    required String title,
    required IconData icon,
    required int count,
    required List<Widget> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Carousel
        SizedBox(
          height: 300,
          child: items.length == 1
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: items.first,
                )
              : CarouselSlider(
                  options: CarouselOptions(
                    height: 300,
                    viewportFraction: 0.85,
                    enlargeCenterPage: true,
                    enableInfiniteScroll: items.length > 1,
                    autoPlay: false,
                  ),
                  items: items,
                ),
        ),

        // Swipe hint for multiple items
        if (items.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.swipe, size: 14, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(
                    'Swipe to browse ($count items)',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPlayerHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Generate Player Card button (mobile only)
          if (!kIsWeb && _loadedSeason?.team != null) ...[
            FutureBuilder<Season?>(
              future: _currentSeasonFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data?.team == null) {
                  return const SizedBox.shrink();
                }

                final team = snapshot.data!.team;

                return ElevatedButton.icon(
                  onPressed: () async {
                    await PlayerCardGenerator.showPlayerCardDialog(
                      context,
                      team: team,
                      player: widget.player,
                    );
                  },
                  icon: const Icon(Icons.stars, size: 20),
                  label: const Text('Generate Player Card'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: team.color1,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // Generate the web URL for this player
  String _getPlayerWebUrl(Season season) {
    final databaseId = DatabaseService.instance.publicShareId ?? '';
    // Use Firebase hosting URL as base - this can be customized
    final baseUrl = SportStrategy.current.webUrl;
    // Use global player route (not season-specific)
    return '$baseUrl/#/team/$databaseId/player/${widget.player.id}';
  }

  // Show QR code dialog
  void _showQRCodeDialog(Season season) {
    final loc = AppLocalizations.of(context)!;
    final playerUrl = _getPlayerWebUrl(season);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.qr_code_2, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(loc.playerProfileQRCode),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Large QR Code
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
              ),
              child: SizedBox(
                width: 280,
                height: 280,
                child: RepaintBoundary(
                  child: QrImageView(
                    data: playerUrl,
                    version: QrVersions.auto,
                    size: 280,
                    backgroundColor: Colors.white,
                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                    semanticsLabel: 'QR code for ${widget.player.displayName}',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Player info
            Text(
              widget.player.displayName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              widget.player.displayNumbers,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            // URL display
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                playerUrl,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loc.scanQRCodeToViewProfile,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.close),
          ),
          TextButton.icon(
            onPressed: () async {
              // Share the URL
              final loc = AppLocalizations.of(context)!;
              try {
                await SharePlus.instance.share(
                  ShareParams(
                    text: playerUrl,
                    subject: loc.playerProfileLink(widget.player.displayName),
                  ),
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(loc.errorSharingLink)),
                  );
                }
              }
            },
            icon: const Icon(Icons.share),
            label: Text(loc.share),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonStats(
      Season season, SeasonStats stats, Season? currentSeason) {
    return FutureBuilder<Map<String, int>>(
      future: _getPlayerStats(stats, widget.player.id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final playerStats = snapshot.data!;
        // Filter out stats that are 0
        final nonZeroStats =
            playerStats.entries.where((entry) => entry.value > 0).toList();

        if (nonZeroStats.isEmpty) {
          return const SizedBox.shrink();
        }

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant)),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            initiallyExpanded:
                currentSeason != null && season.id == currentSeason.id,
            shape: const Border(), // Remove default borders
            title: Text(
              season.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: nonZeroStats.map((entry) {
                    return _buildStatCard(
                      label: _getStatLabel(entry.key),
                      value: entry.value.toString(),
                      icon: _getStatIcon(entry.key),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    IconData? icon,
    bool isHighlighted = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? colorScheme.primaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: isHighlighted
            ? Border.all(color: colorScheme.primary, width: 1)
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 20,
              color:
                  isHighlighted ? colorScheme.primary : colorScheme.secondary,
            ),
            const SizedBox(height: 4),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isHighlighted
                  ? colorScheme.onPrimaryContainer
                  : colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isHighlighted
                  ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                  : colorScheme.onSurfaceVariant,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  String _getStatLabel(String category) {
    switch (category) {
      case 'penaltyKickGoals':
        return 'PK Goals';
      case 'penaltyKicksTaken':
        return 'PKs Taken';
      case 'shotsOnGoal':
        return 'SOG';
      default:
        return category.toSentenceCase().toTitleCase();
    }
  }

  IconData _getStatIcon(String category) {
    switch (category) {
      case 'goals':
        return Icons.sports_soccer;
      case 'assists':
        return Icons.handshake; // best approximation for assist
      default:
        return Icons.analytics;
    }
  }

  Widget _buildCareerStats(Map<Season, SeasonStats> seasonStats) {
    final loc = AppLocalizations.of(context)!;
    return FutureBuilder<Map<String, int>>(
      future: _getCareerStats(seasonStats),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }

        final careerStats = snapshot.data!;
        // Filter out stats that are 0
        final nonZeroStats =
            careerStats.entries.where((entry) => entry.value > 0).toList();

        if (nonZeroStats.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.surface,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ExpansionTile(
            initiallyExpanded: true,
            shape: const Border(),
            title: Row(
              children: [
                Icon(Icons.emoji_events,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                Text(
                  loc.careerStatsTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: nonZeroStats.map((entry) {
                    return _buildStatCard(
                      label: _getStatLabel(entry.key),
                      value: entry.value.toString(),
                      icon: _getStatIcon(entry.key),
                      isHighlighted: true,
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHighlightsPanel() {
    final loc = AppLocalizations.of(context)!;
    return FutureBuilder<List<dynamic>>(
      future: Future.wait([
        _highlightsFuture ?? Future.value(<GameEvent>[]),
        _independentHighlightsFuture ?? Future.value(<PlayerHighlight>[]),
        _awardsFuture ?? Future.value(<PlayerAward>[]),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildHighlightsSkeleton();
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                  loc.errorLoadingHighlights(snapshot.error?.toString() ?? '')),
            ),
          );
        }

        final gameEventHighlights =
            (snapshot.data?[0] as List<GameEvent>?) ?? [];
        final independentHighlights =
            (snapshot.data?[1] as List<PlayerHighlight>?) ?? [];
        final awards = (snapshot.data?[2] as List<PlayerAward>?) ?? [];
        final totalHighlights =
            gameEventHighlights.length + independentHighlights.length;

        // For right panel (large screens), use column layout that fills height
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Header
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.video_library, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '${loc.highlights} & ${loc.awards}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable content with two carousel sections
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                children: [
                  // Awards Section with Carousel
                  if (awards.isNotEmpty) ...[
                    _buildPanelCarouselSection(
                      title: loc.awards,
                      icon: Icons.emoji_events,
                      count: awards.length,
                      items: awards
                          .map((award) => _buildAwardCarouselCard(award))
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Highlights Section with Carousel
                  if (totalHighlights > 0) ...[
                    _buildPanelCarouselSection(
                      title: loc.highlights,
                      icon: Icons.video_library,
                      count: totalHighlights,
                      items: [
                        ...independentHighlights.map(
                            (h) => _buildIndependentHighlightCarouselCard(h)),
                        ...gameEventHighlights
                            .map((e) => _buildGameEventCarouselCard(e)),
                      ],
                    ),
                  ],

                  // Empty state
                  if (awards.isEmpty && totalHighlights == 0)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          loc.noHighlightsAvailable,
                          style:
                              const TextStyle(fontSize: 15, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Build a carousel section for the right panel
  Widget _buildPanelCarouselSection({
    required String title,
    required IconData icon,
    required int count,
    required List<Widget> items,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              Icon(icon, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Carousel
        SizedBox(
          height: 420,
          child: items.length == 1
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: items.first,
                )
              : CarouselSlider(
                  options: CarouselOptions(
                    height: 420,
                    viewportFraction: 0.90,
                    enlargeCenterPage: true,
                    enableInfiniteScroll: items.length > 1,
                    autoPlay: false,
                  ),
                  items: items,
                ),
        ),

        // Swipe hint for multiple items
        if (items.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Center(
              child: Text(
                'Swipe · $count items',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Build award card for carousel (compact, focused view)
  Widget _buildAwardCarouselCard(PlayerAward award) {
    // Use award image if available, otherwise fall back to player's best image
    final displayImage = (award.imageUrl != null && award.imageUrl!.isNotEmpty)
        ? award.imageUrl!
        : widget.player.displayImageForStats;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      elevation: 3,
      child: InkWell(
        onTap: () => _showPlayerAwardDetailsDialog(award),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: SizedBox(
              width: 250, // Constraint width to ensure wrapping works
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Award image/icon - use player image as fallback
                  if (displayImage != null)
                    TappableImage.network(
                      imageUrl: displayImage,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(12),
                      heroTag: 'player_award_${widget.player.id}_${award.id}',
                      errorWidget: const Icon(Icons.emoji_events,
                          size: 80, color: Colors.amber),
                    )
                  else
                    const Icon(Icons.emoji_events,
                        size: 80, color: Colors.amber),

                  const SizedBox(height: 16),

                  // Award title
                  Text(
                    award.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: 8),

                  // Description
                  if (award.description != null &&
                      award.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(
                        award.description!,
                        style: const TextStyle(fontSize: 14),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                  const SizedBox(
                      height: 16), // Replaced spacer with fixed spacing

                  // Season info
                  FutureBuilder<String>(
                    future: award.getSeasonName(),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? 'Season ${award.seasonId}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[600],
                        ),
                      );
                    },
                  ),

                  // URL button if available
                  if (award.url != null && award.url!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => _launchUrl(award.url!),
                      icon: const Icon(Icons.link, size: 16),
                      label: const Text('Learn More'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build game event highlight card for carousel
  Widget _buildGameEventCarouselCard(GameEvent event) {
    final loc = AppLocalizations.of(context)!;
    final urls = event.eventUrls
            ?.split(',')
            .map((u) => u.trim())
            .where((u) => u.isNotEmpty)
            .toList() ??
        [];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: SizedBox(
            width: 280, // Slightly wider for video
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Event info
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    event.image,
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.display,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            event.game.displayName(event.team.id),
                            style: const TextStyle(fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${event.game.date.month}/${event.game.date.day}/${event.game.date.year}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Video thumbnail
                if (urls.isNotEmpty) ...[
                  // Using fixed height container for video
                  SizedBox(
                    height: 150,
                    child: Center(
                      child: VideoThumbnail(
                        urls.first,
                        width: 250,
                        height: 140,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Video buttons
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: urls.asMap().entries.map((entry) {
                      final index = entry.key;
                      final url = entry.value;
                      return ElevatedButton.icon(
                        onPressed: () => _launchUrl(url),
                        icon: const Icon(Icons.play_circle_outline, size: 18),
                        label: Text(
                          urls.length > 1
                              ? '${loc.videoLabel} ${index + 1}'
                              : loc.watchLabel,
                          style: const TextStyle(fontSize: 13),
                        ),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build independent highlight card for carousel
  Widget _buildIndependentHighlightCarouselCard(PlayerHighlight highlight) {
    final loc = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Title and info
            Row(
              children: [
                const Icon(Icons.video_library, size: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        highlight.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (highlight.description != null &&
                          highlight.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          highlight.description!,
                          style: const TextStyle(fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${highlight.date.month}/${highlight.date.day}/${highlight.date.year}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Video thumbnail
            Expanded(
              child: Center(
                child: VideoThumbnail(
                  highlight.videoUrl,
                  width: 250,
                  height: 140,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Watch button
            SizedBox(
              width: 180,
              child: ElevatedButton.icon(
                onPressed: () => _launchUrl(highlight.videoUrl),
                icon: const Icon(Icons.play_circle_outline, size: 18),
                label: Text(
                  loc.watchLabel,
                  style: const TextStyle(fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final loc = AppLocalizations.of(context)!;
    final uri = Uri.parse(urlString);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.couldNotOpenUrl(urlString))),
        );
      }
    }
  }

  void _showPlayerAwardDetailsDialog(PlayerAward award) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.emoji_events, color: Colors.amber, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                award.title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Award Image
              if (award.imageUrl != null && award.imageUrl!.isNotEmpty) ...[
                Center(
                  child: Container(
                    constraints: const BoxConstraints(
                      maxWidth: 400,
                      maxHeight: 400,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        award.imageUrl!,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(Icons.broken_image, size: 48),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Season Name
              FutureBuilder<String>(
                future: award.getSeasonName(),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Season',
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          snapshot.data!,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Description
              if (award.description != null &&
                  award.description!.isNotEmpty) ...[
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  award.description!,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
              ],

              // URL Link
              if (award.url != null && award.url!.isNotEmpty) ...[
                Text(
                  'Link',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    try {
                      final uri = Uri.parse(award.url!);
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } catch (e) {
                      debugPrint('Could not launch URL: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Could not open URL: ${award.url}'),
                          ),
                        );
                      }
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.link, color: Colors.blue.shade700, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            award.url!,
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              decoration: TextDecoration.underline,
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Icon(Icons.open_in_new,
                            color: Colors.blue.shade700, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSkeleton(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: SkeletonContainer.rectangular(
          width: 150,
          height: 24,
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      SkeletonContainer.circular(
                        size: 160,
                      ),
                      const SizedBox(height: 24),
                      SkeletonContainer.rectangular(
                        width: 200,
                        height: 32,
                      ),
                      const SizedBox(height: 8),
                      SkeletonContainer.rectangular(
                        width: 60,
                        height: 24,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: List.generate(5, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: SkeletonContainer.rectangular(
                          height: 60,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 8,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        return Row(
          children: [
            SkeletonContainer.rectangular(width: 80, height: 16),
            const Spacer(),
            SkeletonContainer.rectangular(width: 40, height: 16),
            const SizedBox(width: 16),
            SkeletonContainer.rectangular(width: 40, height: 16),
          ],
        );
      },
    );
  }

  Widget _buildHighlightsSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.0,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return SkeletonContainer.rectangular(
          height: double.infinity,
          borderRadius: BorderRadius.circular(8),
        );
      },
    );
  }

  List<Widget> _buildAppBarActions(
      BuildContext context, Season? currentSeason) {
    if (_isEditMode) return [];

    final loc = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return [
        PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'edit':
                _showPinDialog();
                break;
              case 'card':
                if (currentSeason?.team != null) {
                  await PlayerCardGenerator.showPlayerCardDialog(
                    context,
                    team: currentSeason!.team,
                    player: widget.player,
                  );
                }
                break;
              case 'highlight_reel':
                _launchHighlightReel();
                break;
              case 'show_highlights':
                _showHighlightsModal();
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return [
              PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    const Icon(Icons.edit),
                    const SizedBox(width: 8),
                    Text(loc.editProfile),
                  ],
                ),
              ),
              if (currentSeason?.team != null)
                const PopupMenuItem(
                  value: 'card',
                  child: Row(
                    children: [
                      Icon(Icons.stars),
                      SizedBox(width: 8),
                      Text('Generate Player Card'),
                    ],
                  ),
                ),
              const PopupMenuItem(
                value: 'highlight_reel',
                child: Row(
                  children: [
                    Icon(Icons.movie),
                    SizedBox(width: 8),
                    Text('Play Highlight Reel'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'show_highlights',
                child: Row(
                  children: [
                    const Icon(Icons.video_library),
                    const SizedBox(width: 8),
                    Text(loc.showHighlights),
                  ],
                ),
              ),
            ];
          },
        ),
      ];
    }

    return [
      IconButton(
        icon: const Icon(Icons.edit),
        tooltip: loc.editProfile,
        onPressed: () => _showPinDialog(),
      ),
      if (currentSeason?.team != null)
        IconButton(
          icon: const Icon(Icons.stars),
          tooltip: 'Generate Player Card',
          onPressed: () async {
            await PlayerCardGenerator.showPlayerCardDialog(
              context,
              team: currentSeason!.team,
              player: widget.player,
            );
          },
        ),
      IconButton(
        icon: const Icon(Icons.movie),
        tooltip: 'Play Highlight Reel',
        onPressed: () => _launchHighlightReel(),
      ),
      if (screenWidth < 900)
        IconButton(
          icon: const Icon(Icons.video_library),
          tooltip: loc.showHighlights,
          onPressed: () => _showHighlightsModal(),
        )
      else
        IconButton(
          icon: Icon(
            _showHighlights
                ? Icons.video_library
                : Icons.video_library_outlined,
          ),
          tooltip: _showHighlights ? loc.hideHighlights : loc.showHighlights,
          onPressed: () {
            setState(() {
              _showHighlights = !_showHighlights;
            });
          },
        ),
    ];
  }
}
