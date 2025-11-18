import 'package:change_case/change_case.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/player_highlight.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/season_stats.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/breadcrumbs.dart';
import 'package:team_sync/widgets/common_page_header.dart';
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
  Future<Season?>?
      _currentSeasonFuture; // will load if widget.currentSeason is null
  Season? _loadedSeason;
  bool _showHighlights = true;

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
              // Toggle highlights button
              IconButton(
                icon: Icon(_showHighlights
                    ? Icons.video_library
                    : Icons.video_library_outlined),
                tooltip:
                    _showHighlights ? loc.hideHighlights : loc.showHighlights,
                onPressed: () {
                  setState(() {
                    _showHighlights = !_showHighlights;
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              if (currentSeason?.team != null) ...[
                CommonPageHeader(team: currentSeason!.team),
                Breadcrumbs(
                  items: buildTeamBreadcrumbs(
                    databaseId: DatabaseService.instance.publicShareId ?? '',
                    teamName: currentSeason.team.fullName,
                    seasonName: currentSeason.name,
                    seasonId: currentSeason.id,
                    playerName: widget.player.displayName,
                    playerId: widget.player.id,
                  ),
                ),
              ],
              Expanded(
                child: _seasonStatsFuture == null
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
                            return Center(child: Text(loc.noStatsAvailable));
                          }

                          final seasonStats = snapshot.data!;
                          final seasons = seasonStats.keys.toList()
                            ..sort((a, b) =>
                                b.name.compareTo(a.name)); // Most recent first

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
                              final isWideScreen = constraints.maxWidth > 900;

                              if (isWideScreen && _showHighlights) {
                                // Two-column layout for wide screens
                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                            color:
                                                Theme.of(context).dividerColor,
                                            width: 1,
                                          ),
                                        ),
                                      ),
                                      child: _buildHighlightsPanel(),
                                    ),
                                  ],
                                );
                              } else {
                                // Single column layout for narrow screens or when highlights hidden
                                return Column(
                                  children: [
                                    Expanded(child: mainContent),
                                    if (_showHighlights) ...[
                                      const Divider(thickness: 2),
                                      SizedBox(
                                        height: 300,
                                        child: _buildHighlightsPanel(),
                                      ),
                                    ],
                                  ],
                                );
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
        final totalCount =
            gameEventHighlights.length + independentHighlights.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                    loc.highlights,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$totalCount',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Add button (mobile only)
                  if (!kIsWeb) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _showAddHighlightDialog(),
                      tooltip: loc.addHighlight,
                    ),
                  ],
                ],
              ),
            ),

            // Highlights list
            Expanded(
              child: totalCount == 0
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          loc.noHighlightsAvailable,
                          style:
                              const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(8.0),
                      children: [
                        // Independent highlights first
                        ...independentHighlights.map((highlight) =>
                            _buildIndependentHighlightItem(highlight)),
                        // Then game event highlights
                        ...gameEventHighlights
                            .map((event) => _buildHighlightItem(event)),
                      ],
                    ),
            ),
          ],
        );
      },
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
      margin: const EdgeInsets.symmetric(vertical: 8.0),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.game.displayName(event.team.id),
                        style: const TextStyle(fontSize: 14),
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

            // Video links
            if (urls.isNotEmpty) ...[
              const SizedBox(height: 12),
              // Row with thumbnail and buttons
              Row(
                children: [
                  VideoThumbnail(urls.first, width: 160, height: 90),
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
                          icon: const Icon(Icons.play_circle_outline, size: 18),
                          label: Text(urls.length > 1
                              ? '${loc.videoLabel} ${index + 1}'
                              : loc.watchLabel),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        );
                      }).toList(),
                    ),
                  )
                ],
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
      margin: const EdgeInsets.symmetric(vertical: 8.0),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (highlight.description != null &&
                          highlight.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          highlight.description!,
                          style: const TextStyle(fontSize: 14),
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
            Row(
              children: [
                VideoThumbnail(highlight.videoUrl, width: 160, height: 90),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _launchUrl(highlight.videoUrl),
                    icon: const Icon(Icons.play_circle_outline, size: 18),
                    label: Text(loc.watchLabel),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                  ),
                )
              ],
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
}
