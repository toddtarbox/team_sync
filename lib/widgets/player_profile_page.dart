import 'package:change_case/change_case.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/season_stats.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/custom_appbar.dart';

class PlayerProfilePage extends StatefulWidget {
  final Player player;
  final Season currentSeason;

  const PlayerProfilePage({
    super.key,
    required this.player,
    required this.currentSeason,
  });

  @override
  State<PlayerProfilePage> createState() => _PlayerProfilePageState();
}

class _PlayerProfilePageState extends State<PlayerProfilePage> {
  late Future<Map<Season, SeasonStats>> _seasonStatsFuture;

  @override
  void initState() {
    super.initState();
    _seasonStatsFuture = _loadPlayerSeasonStats();
  }

  Future<Map<Season, SeasonStats>> _loadPlayerSeasonStats() async {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        team: widget.currentSeason.team,
        title: Text(
          widget.player.displayName,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<Map<Season, SeasonStats>>(
        future: _seasonStatsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading player stats: ${snapshot.error}'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No stats available'));
          }

          final seasonStats = snapshot.data!;
          final seasons = seasonStats.keys.toList()
            ..sort((a, b) => b.name.compareTo(a.name)); // Most recent first

          return ListView(
            children: [
              // Player header with avatar and basic info
              _buildPlayerHeader(),

              const Divider(thickness: 2),

              // Stats for each season
              ...seasons.map((season) => _buildSeasonStats(
                    season,
                    seasonStats[season]!,
                  )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPlayerHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          // Avatar
          CircleAvatar(
            radius: 60,
            child: widget.player.profileImage != null &&
                    widget.player.profileImage!.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      widget.player.profileImage!,
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Text(
                          '${widget.player.firstName[0]}${widget.player.lastName[0]}',
                          style: const TextStyle(fontSize: 40),
                        );
                      },
                    ),
                  )
                : Text(
                    '${widget.player.firstName[0]}${widget.player.lastName[0]}',
                    style: const TextStyle(fontSize: 40),
                  ),
          ),
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

  Widget _buildSeasonStats(Season season, SeasonStats stats) {
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
            initiallyExpanded: season.id == widget.currentSeason.id,
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
}
