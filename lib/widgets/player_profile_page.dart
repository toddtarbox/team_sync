import 'dart:io';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:change_case/change_case.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/player_award.dart';
import 'package:team_sync/models/player_highlight.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/season_stats.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/breadcrumbs.dart';
import 'package:team_sync/widgets/pin_entry_dialog.dart';
import 'package:team_sync/widgets/player_card_generator.dart';
import 'package:team_sync/widgets/player_profile_editor.dart';
import 'package:team_sync/widgets/responsive_player_avatar.dart';
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
  Future<Map<Season, SeasonStats>>? _seasonStatsFuture;
  Future<List<GameEvent>>? _highlightsFuture;
  Future<List<PlayerHighlight>>? _independentHighlightsFuture;
  Future<List<PlayerAward>>? _awardsFuture;
  Future<Season?>?
      _currentSeasonFuture; // will load if widget.currentSeason is null
  Season? _loadedSeason;
  bool _showHighlights = true;
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
      print('Error loading season for player: $e');
      return null;
    }
  }

  void _refreshHighlights() {
    setState(() {
      _highlightsFuture = _loadPlayerHighlights();
      _independentHighlightsFuture = _loadIndependentHighlights();
    });
  }

  Future<Map<Season, SeasonStats>> _loadPlayerSeasonStats() async {
    try {
      final Map<Season, SeasonStats> seasonStatsMap = {};

      // Get all players with the same ID (across different seasons)
      final playerRecords = await DatabaseService.instance
          .query('Players', orderByChild: 'id', equalTo: widget.player.id);

      // Get unique season IDs
      final seasonIds =
          playerRecords.map((p) => p['seasonId'] as int).toSet().toList();

      // Load each season and its stats
      for (final seasonId in seasonIds) {
        // Get season info
        final seasonResults = await DatabaseService.instance
            .query('Seasons', orderByChild: 'id', equalTo: seasonId);

        if (seasonResults.isEmpty) continue;

        final season = Season.fromMap(seasonResults.first);
        await season.load();

        // Get stats for this season
        final stats = await season.getStats();
        if (stats != null) {
          seasonStatsMap[season] = stats;
        }
      }

      return seasonStatsMap;
    } catch (e) {
      print('Error loading player season stats: $e');
      rethrow; // Re-throw to show error in UI
    }
  }

  Future<List<GameEvent>> _loadPlayerHighlights() async {
    try {
      // Get all events for this player across all seasons
      final events = await DatabaseService.instance
          .query('Events', orderByChild: 'playerId', equalTo: widget.player.id);

      // Filter to only events with URLs
      final eventsWithUrls = await Future.wait(
        events
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
      print('Error loading player highlights: $e');
      return [];
    }
  }

  Future<List<PlayerHighlight>> _loadIndependentHighlights() async {
    try {
      return await PlayerHighlight.listFromPlayerId(widget.player.id);
    } catch (e) {
      print('Error loading independent highlights: $e');
      return [];
    }
  }

  Future<List<PlayerAward>> _loadAwards() async {
    try {
      return await PlayerAward.listFromPlayerId(widget.player.id);
    } catch (e) {
      print('Error loading awards: $e');
      return [];
    }
  }

  Future<Map<LeaderCategory, int>> _getPlayerStats(
      SeasonStats stats, int playerId) async {
    final Map<LeaderCategory, int> playerStats = {};

    for (final category in LeaderCategory.values) {
      if (category == LeaderCategory.ownGoalsEarned) {
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

  Future<Map<LeaderCategory, int>> _getCareerStats(
      Map<Season, SeasonStats> seasonStats) async {
    final Map<LeaderCategory, int> careerStats = {};

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
            body: const Center(child: CircularProgressIndicator()),
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
            actions: [
              // Edit Profile button (web only)
              if (kIsWeb && !_isEditMode)
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: loc.editProfile,
                  onPressed: () => _showPinDialog(),
                ),
              // Generate Player Card button (Pro feature)
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
              // Toggle highlights button
              if (!_isEditMode)
                LayoutBuilder(
                  builder: (context, constraints) {
                    // On small screens, open modal dialog
                    // On large screens, toggle inline panel
                    return IconButton(
                      icon: Icon(_showHighlights
                          ? Icons.video_library
                          : Icons.video_library_outlined),
                      tooltip: _showHighlights
                          ? loc.hideHighlights
                          : loc.showHighlights,
                      onPressed: () {
                        // Get screen width from MediaQuery
                        final screenWidth = MediaQuery.of(context).size.width;

                        if (screenWidth < 900) {
                          // Small screen - show modal dialog
                          _showHighlightsModal();
                        } else {
                          // Large screen - toggle inline panel
                          setState(() {
                            _showHighlights = !_showHighlights;
                          });
                        }
                      },
                    );
                  },
                ),
            ],
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
                        ? const Center(child: CircularProgressIndicator())
                        : FutureBuilder<Map<Season, SeasonStats>>(
                            future: _seasonStatsFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }

                              if (snapshot.hasError) {
                                return Center(
                                  child: Text(loc.errorLoadingPlayerStats(
                                      snapshot.error?.toString() ?? '',
                                      snapshot.stackTrace?.toString() ?? '')),
                                );
                              }

                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return Center(
                                    child: Text(loc.noStatsAvailable));
                              }

                              final seasonStats = snapshot.data!;
                              final seasons = seasonStats.keys.toList()
                                ..sort((a, b) => b.name
                                    .compareTo(a.name)); // Most recent first

                              // Build main content
                              final mainContent = ListView(
                                children: [
                                  // Player header with avatar and basic info
                                  _buildPlayerHeader(),

                                  const Divider(thickness: 2),

                                  // Career Stats Section
                                  _buildCareerStats(seasonStats),

                                  const Divider(thickness: 2),

                                  // Stats for each season
                                  ...seasons.map((season) => _buildSeasonStats(
                                        season,
                                        seasonStats[season]!,
                                        currentSeason,
                                      )),
                                ],
                              );

                              // Responsive layout
                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  final isWideScreen =
                                      constraints.maxWidth > 900;

                                  if (isWideScreen && _showHighlights) {
                                    // Two-column layout for wide screens
                                    return Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Main content (left side)
                                        Expanded(
                                          flex: 2,
                                          child: mainContent,
                                        ),

                                        // Highlights panel (right side)
                                        Container(
                                          width: 400,
                                          decoration: BoxDecoration(
                                            border: Border(
                                              left: BorderSide(
                                                color: Theme.of(context)
                                                    .dividerColor,
                                                width: 1,
                                              ),
                                            ),
                                          ),
                                          child: _buildHighlightsPanel(),
                                        ),
                                      ],
                                    );
                                  } else {
                                    // Single column layout for smaller screens
                                    // Highlights shown in modal dialog (opened via button)
                                    return mainContent;
                                  }
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
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
        child: Container(
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
          // Avatar
          ResponsivePlayerAvatar(player: widget.player),

          const SizedBox(height: 16),

          // Player name
          Text(
            widget.player.displayName,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          // Jersey number
          Text(
            '#${widget.player.number}',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),

          // Generate Player Card button (mobile only)
          if (!kIsWeb && _loadedSeason?.team != null) ...[
            const SizedBox(height: 20),
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

  Widget _buildSeasonStats(
      Season season, SeasonStats stats, Season? currentSeason) {
    return FutureBuilder<Map<LeaderCategory, int>>(
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
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ExpansionTile(
            initiallyExpanded:
                currentSeason != null && season.id == currentSeason.id,
            title: Text(
              season.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: nonZeroStats.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key.name.toSentenceCase().toTitleCase(),
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            entry.value.toString(),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildCareerStats(Map<Season, SeasonStats> seasonStats) {
    final loc = AppLocalizations.of(context)!;
    return FutureBuilder<Map<LeaderCategory, int>>(
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

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: Theme.of(context).colorScheme.primaryContainer,
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Text(
              loc.careerStatsTitle,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: nonZeroStats.map((entry) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entry.key.name.toSentenceCase().toTitleCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            entry.value.toString(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
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
          return const Center(child: CircularProgressIndicator());
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

        // For right panel (large screens), use two carousel sections
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
          height: 280,
          child: items.length == 1
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: items.first,
                )
              : CarouselSlider(
                  options: CarouselOptions(
                    height: 280,
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

  Widget _buildAwardsCarouselPage(List<PlayerAward> awards) {
    final loc = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 4,
      child: Column(
        children: [
          // Awards header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.emoji_events, size: 28),
                const SizedBox(width: 12),
                Text(
                  loc.awards,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${awards.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Awards list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12.0),
              itemCount: awards.length,
              itemBuilder: (context, index) {
                return _buildAwardCard(awards[index], compact: true);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlightCarouselItem(GameEvent event) {
    final loc = AppLocalizations.of(context)!;
    final urls = event.eventUrls
            ?.split(',')
            .map((u) => u.trim())
            .where((u) => u.isNotEmpty)
            .toList() ??
        [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Event icon and info
            Row(
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.game.displayName(event.team.id),
                        style: const TextStyle(fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${event.game.date.month}/${event.game.date.day}/${event.game.date.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Video thumbnail - larger for carousel
            if (urls.isNotEmpty) ...[
              Expanded(
                child: Center(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final maxWidth = constraints.maxWidth;
                      final thumbWidth =
                          maxWidth > 500 ? 400.0 : maxWidth * 0.9;
                      final thumbHeight = thumbWidth * 9 / 16;
                      return VideoThumbnail(
                        urls.first,
                        width: thumbWidth,
                        height: thumbHeight,
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Video buttons
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: urls.asMap().entries.map((entry) {
                  final index = entry.key;
                  final url = entry.value;
                  return ElevatedButton.icon(
                    onPressed: () => _launchUrl(url),
                    icon: const Icon(Icons.play_circle_outline, size: 20),
                    label: Text(
                      urls.length > 1
                          ? '${loc.videoLabel} ${index + 1}'
                          : loc.watchLabel,
                      style: const TextStyle(fontSize: 15),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIndependentHighlightCarouselItem(PlayerHighlight highlight) {
    final loc = AppLocalizations.of(context)!;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title and info
            Row(
              children: [
                const Icon(Icons.video_library, size: 40),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        highlight.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (highlight.description != null &&
                          highlight.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          highlight.description!,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${highlight.date.month}/${highlight.date.day}/${highlight.date.year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Video thumbnail - larger for carousel
            Expanded(
              child: Center(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final maxWidth = constraints.maxWidth;
                    final thumbWidth = maxWidth > 500 ? 400.0 : maxWidth * 0.9;
                    final thumbHeight = thumbWidth * 9 / 16;
                    return VideoThumbnail(
                      highlight.videoUrl,
                      width: thumbWidth,
                      height: thumbHeight,
                    );
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Watch button
            Center(
              child: SizedBox(
                width: 200,
                child: ElevatedButton.icon(
                  onPressed: () => _launchUrl(highlight.videoUrl),
                  icon: const Icon(Icons.play_circle_outline, size: 20),
                  label: Text(
                    loc.watchLabel,
                    style: const TextStyle(fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build award card for carousel (compact, focused view)
  Widget _buildAwardCarouselCard(PlayerAward award) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      elevation: 3,
      child: InkWell(
        onTap: () => _showPlayerAwardDetailsDialog(award),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Award image/icon
              if (award.imageUrl != null && award.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    award.imageUrl!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.emoji_events,
                        size: 80,
                        color: Colors.amber),
                  ),
                )
              else
                const Icon(Icons.emoji_events, size: 80, color: Colors.amber),

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
              if (award.description != null && award.description!.isNotEmpty)
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

              const Spacer(),

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
              Expanded(
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

  Widget _buildAwardCard(PlayerAward award, {bool compact = false}) {
    return Card(
      margin: EdgeInsets.only(bottom: compact ? 4 : 8),
      elevation: 2,
      child: ListTile(
        leading: award.imageUrl != null
            ? CircleAvatar(
                radius: 20,
                backgroundImage: NetworkImage(award.imageUrl!),
              )
            : const CircleAvatar(
                radius: 20,
                child: Icon(Icons.emoji_events, size: 20),
              ),
        title: Text(
          award.title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (award.description != null && award.description!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  award.description!,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: FutureBuilder<String>(
                future: award.getSeasonName(),
                builder: (context, snapshot) {
                  return Text(
                    snapshot.data ?? 'Season ${award.seasonId}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[600],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        trailing: (!kIsWeb || (_isEditMode && _validatedPin != null))
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () => _showAddAwardDialog(award: award),
                    tooltip: AppLocalizations.of(context)!.edit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _deleteAward(award),
                    tooltip: AppLocalizations.of(context)!.delete,
                  ),
                ],
              )
            : null,
        onTap: () => _showPlayerAwardDetailsDialog(award),
      ),
    );
  }

  Widget _buildHighlightItem(GameEvent event) {
    final loc = AppLocalizations.of(context)!;
    final urls = event.eventUrls
            ?.split(',')
            .map((u) => u.trim())
            .where((u) => u.isNotEmpty)
            .toList() ??
        [];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Event info
            Row(
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
                          fontSize: 15,
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
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Video links - use responsive layout
            if (urls.isNotEmpty) ...[
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final useColumnLayout = constraints.maxWidth < 350;

                  if (useColumnLayout) {
                    // Stack vertically for narrow screens
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        VideoThumbnail(
                          urls.first,
                          width: constraints.maxWidth - 24,
                          height: (constraints.maxWidth - 24) * 9 / 16,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: urls.asMap().entries.map((entry) {
                            final index = entry.key;
                            final url = entry.value;
                            return ElevatedButton.icon(
                              onPressed: () => _launchUrl(url),
                              icon: const Icon(Icons.play_circle_outline,
                                  size: 18),
                              label: Text(
                                urls.length > 1
                                    ? '${loc.videoLabel} ${index + 1}'
                                    : loc.watchLabel,
                                style: const TextStyle(fontSize: 13),
                              ),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    );
                  } else {
                    // Row layout for wider screens
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        VideoThumbnail(urls.first, width: 140, height: 79),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: urls.asMap().entries.map((entry) {
                              final index = entry.key;
                              final url = entry.value;
                              return ElevatedButton.icon(
                                onPressed: () => _launchUrl(url),
                                icon: const Icon(Icons.play_circle_outline,
                                    size: 18),
                                label: Text(
                                  urls.length > 1
                                      ? '${loc.videoLabel} ${index + 1}'
                                      : loc.watchLabel,
                                  style: const TextStyle(fontSize: 13),
                                ),
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      ],
                    );
                  }
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIndependentHighlightItem(PlayerHighlight highlight) {
    final loc = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.video_library, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        highlight.title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
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
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit/Delete buttons (mobile only)
                if (!kIsWeb) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 20),
                    onPressed: () =>
                        _showAddHighlightDialog(highlight: highlight),
                    tooltip: loc.edit,
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 20),
                    onPressed: () => _deleteHighlight(highlight),
                    tooltip: loc.delete,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final useColumnLayout = constraints.maxWidth < 350;

                if (useColumnLayout) {
                  // Stack vertically for narrow screens
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      VideoThumbnail(
                        highlight.videoUrl,
                        width: constraints.maxWidth - 24,
                        height: (constraints.maxWidth - 24) * 9 / 16,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _launchUrl(highlight.videoUrl),
                          icon: const Icon(Icons.play_circle_outline, size: 18),
                          label: Text(loc.watchLabel,
                              style: const TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  );
                } else {
                  // Row layout for wider screens
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      VideoThumbnail(highlight.videoUrl,
                          width: 140, height: 79),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _launchUrl(highlight.videoUrl),
                          icon: const Icon(Icons.play_circle_outline, size: 18),
                          label: Text(loc.watchLabel,
                              style: const TextStyle(fontSize: 13)),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      )
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final loc = AppLocalizations.of(context)!;
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.couldNotOpenUrl(urlString))),
        );
      }
    }
  }

  void _showAddHighlightDialog({PlayerHighlight? highlight}) {
    final loc = AppLocalizations.of(context)!;
    final isEdit = highlight != null;
    final titleController = TextEditingController(text: highlight?.title ?? '');
    final descriptionController =
        TextEditingController(text: highlight?.description ?? '');
    final urlController =
        TextEditingController(text: highlight?.videoUrl ?? '');
    DateTime selectedDate = highlight?.date ?? DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? loc.editHighlight : loc.addHighlightDialogTitle),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: loc.labelTitleRequired,
                    hintText: loc.hintTitleExample,
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: loc.labelDescription,
                    hintText: loc.hintDescriptionOptional,
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: loc.labelVideoUrlRequired,
                    hintText: loc.hintVideoUrl,
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc.labelDate),
                  subtitle: Text(
                    '${selectedDate.month}/${selectedDate.day}/${selectedDate.year}',
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() {
                        selectedDate = picked;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancelButton),
            ),
            FilledButton(
              onPressed: () {
                final title = titleController.text.trim();
                final url = urlController.text.trim();

                if (title.isEmpty || url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.titleUrlRequired),
                    ),
                  );
                  return;
                }

                _saveHighlight(
                  id: highlight?.id ?? DateTime.now().millisecondsSinceEpoch,
                  title: title,
                  description: descriptionController.text.trim(),
                  url: url,
                  date: selectedDate,
                );

                Navigator.pop(context);
              },
              child: Text(isEdit ? loc.updateButton : loc.addButton),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveHighlight({
    required int id,
    required String title,
    String? description,
    required String url,
    required DateTime date,
  }) async {
    final loc = AppLocalizations.of(context)!;
    try {
      final highlight = PlayerHighlight(
        id: id,
        playerId: widget.player.id,
        title: title,
        description: description?.isEmpty == true ? null : description,
        videoUrl: url,
        date: date,
      );

      await highlight.save();
      _refreshHighlights();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.highlightSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.errorSavingHighlight(e.toString()))),
        );
      }
    }
  }

  Future<void> _deleteHighlight(PlayerHighlight highlight) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc.deleteHighlightTitle),
        content: Text(loc.deleteHighlightConfirm(highlight.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await highlight.delete();
        _refreshHighlights();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.highlightDeleted)),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(loc.errorDeletingHighlight(e.toString()))),
          );
        }
      }
    }
  }

  void _showAddAwardDialog({PlayerAward? award}) async {
    final loc = AppLocalizations.of(context)!;
    final isEdit = award != null;
    final titleController = TextEditingController(text: award?.title ?? '');
    final descriptionController =
        TextEditingController(text: award?.description ?? '');
    final urlController = TextEditingController(text: award?.url ?? '');
    String? imageUrl = award?.imageUrl;
    bool isUploadingImage = false;

    // Load available seasons for this player's team
    final seasons = await Season.fromTeamId(widget.player.teamId);

    // Find the season by ID if editing
    Season? selectedSeason;
    if (award != null && seasons.isNotEmpty) {
      selectedSeason = seasons.firstWhere(
        (s) => s.id == award.seasonId,
        orElse: () => seasons.first,
      );
    } else if (seasons.isNotEmpty) {
      selectedSeason = seasons.first;
    }

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEdit ? 'Edit Award' : 'Add Award'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Award Title *',
                    hintText: 'e.g., MVP, All-Star, Top Scorer',
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Optional details',
                  ),
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL',
                    hintText: 'Optional link (e.g., article, photo)',
                    prefixIcon: Icon(Icons.link),
                  ),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 16),
                // Image upload section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Award Image',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    if (imageUrl != null && imageUrl!.isNotEmpty)
                      Stack(
                        children: [
                          Container(
                            width: 200,
                            height: 200,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                imageUrl!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                setState(() {
                                  imageUrl = null;
                                });
                              },
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: (isUploadingImage || kIsWeb)
                            ? null
                            : () async {
                                setState(() {
                                  isUploadingImage = true;
                                });
                                try {
                                  final pickedFile = await ImagePicker()
                                      .pickImage(source: ImageSource.gallery);
                                  if (pickedFile != null) {
                                    // Upload to Firebase Storage
                                    final storageRef = FirebaseStorage.instance
                                        .ref()
                                        .child(
                                            'award_images/${DateTime.now().millisecondsSinceEpoch}.jpg');
                                    await storageRef
                                        .putFile(File(pickedFile.path));
                                    final downloadUrl =
                                        await storageRef.getDownloadURL();
                                    setState(() {
                                      imageUrl = downloadUrl;
                                      isUploadingImage = false;
                                    });
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
                                    String errorMessage =
                                        'Error uploading image';
                                    if (e
                                            .toString()
                                            .contains('not authorized') ||
                                        e.toString().contains('permission') ||
                                        e.toString().contains('unauthorized')) {
                                      errorMessage =
                                          'Not authorized to upload images. Please sign in on mobile to add images.';
                                    } else {
                                      errorMessage =
                                          'Error uploading image: ${e.toString()}';
                                    }
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(errorMessage),
                                        duration: const Duration(seconds: 5),
                                      ),
                                    );
                                  }
                                }
                              },
                        icon: isUploadingImage
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.image),
                        label: Text(
                          isUploadingImage
                              ? 'Uploading...'
                              : kIsWeb
                                  ? 'Image upload requires mobile app'
                                  : 'Pick Image',
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                // Season selector
                DropdownButtonFormField<Season>(
                  initialValue: selectedSeason,
                  decoration: InputDecoration(
                    labelText: loc.season,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.calendar_month),
                  ),
                  items: seasons.map((season) {
                    return DropdownMenuItem(
                      value: season,
                      child: Text(season.name),
                    );
                  }).toList(),
                  onChanged: (season) {
                    setState(() {
                      selectedSeason = season;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(loc.cancelButton),
            ),
            FilledButton(
              onPressed: isUploadingImage
                  ? null
                  : () {
                      final title = titleController.text.trim();

                      if (title.isEmpty || selectedSeason == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content:
                                Text('Award title and season are required'),
                          ),
                        );
                        return;
                      }

                      _saveAward(
                        id: award?.id ?? DateTime.now().millisecondsSinceEpoch,
                        title: title,
                        description: descriptionController.text.trim(),
                        seasonId: selectedSeason!.id,
                        url: urlController.text.trim(),
                        imageUrl: imageUrl,
                      );

                      Navigator.pop(context);
                    },
              child: Text(isEdit ? loc.updateButton : loc.addButton),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAward({
    required int id,
    required String title,
    String? description,
    required int seasonId,
    String? url,
    String? imageUrl,
  }) async {
    try {
      final award = PlayerAward(
        id: id,
        playerId: widget.player.id,
        seasonId: seasonId,
        title: title,
        description: description?.isEmpty == true ? null : description,
        imageUrl: imageUrl?.isEmpty == true ? null : imageUrl,
        url: url?.isEmpty == true ? null : url,
      );

      // Use saveWithPin on web if PIN is available, otherwise use regular save
      if (kIsWeb && _validatedPin != null) {
        await award.saveWithPin(_validatedPin!);
      } else {
        await award.save();
      }

      _loadAwards(); // Refresh awards list

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Award saved successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving award: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteAward(PlayerAward award) async {
    final loc = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Award'),
        content: Text('Delete "${award.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(loc.cancelButton),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await award.delete();
        _loadAwards(); // Refresh awards list

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Award deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting award: ${e.toString()}')),
          );
        }
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
                    final uri = Uri.parse(award.url!);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    } else {
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
}
