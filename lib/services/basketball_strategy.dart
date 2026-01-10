import 'package:flutter/material.dart';
import 'package:team_sync/models/career_stats.dart';
import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/season_stats.dart';
import 'package:team_sync/services/sport_strategy.dart';

class BasketballStrategy implements SportStrategy {
  @override
  String get appTitle => 'TeamSync - Basketball';

  @override
  Color get primaryColor => Colors.orange;

  @override
  String get appIconAsset =>
      'assets/images/pngs/basketball_icon_no_background.png';

  @override
  IconData get sportIcon => Icons.sports_basketball;

  @override
  String get sportId => 'basketball';

  @override
  List<String> get leaderCategories => [
        'points',
        'rebounds',
        'assists',
        'steals',
        'blocks',
        'turnovers',
        'fouls'
      ];

  @override
  String formatEventDisplay(GameEvent event) {
    if (event.eventType == 'Point') {
      final points = event.eventData;
      if (event.player != null) {
        return '$points Pt - ${event.player!.displayName}';
      }
      return '$points Pt - ${event.team.shortName}';
    } else if (event.eventType == 'Rebound') {
      return event.player != null
          ? 'Rebound: ${event.player!.displayName}'
          : 'Rebound';
    } else if (event.eventType == 'Assist') {
      return event.player != null
          ? 'Assist: ${event.player!.displayName}'
          : 'Assist';
    } else if (event.eventType == 'Steal') {
      return event.player != null
          ? 'Steal: ${event.player!.displayName}'
          : 'Steal';
    } else if (event.eventType == 'Block') {
      return event.player != null
          ? 'Block: ${event.player!.displayName}'
          : 'Block';
    } else if (event.eventType == 'Turnover') {
      return event.player != null
          ? 'Turnover: ${event.player!.displayName}'
          : 'Turnover';
    } else if (event.eventType == 'Foul') {
      return event.player != null
          ? 'Foul: ${event.player!.displayName}'
          : 'Foul';
    } else if (event.eventType == 'Period') {
      return (event as Period).display;
    }

    return '${event.eventType}';
  }

  @override
  String getEventImageAsset(GameEvent event) {
    // Define basketball assets later
    return 'assets/images/pngs/empty.png';
  }

  @override
  bool isGoalEvent(GameEvent event) {
    return event.eventType == 'Point';
  }

  @override
  SeasonStats createSeasonStats(
      int teamId, int seasonId, List<Map<String, dynamic>> events) {
    final stats = SeasonStats(teamId: teamId, seasonId: seasonId);

    for (final event in events) {
      final isTeam = event['teamId'] == teamId;
      final type = event['eventType'];

      // Map event type to category key
      String? category;
      int value = 1;

      switch (type) {
        case 'Point':
          category = 'points';
          value = event['eventData'] as int? ?? 0;
          break;
        case 'Rebound':
          category = 'rebounds';
          break;
        case 'Assist':
          category = 'assists';
          break;
        case 'Steal':
          category = 'steals';
          break;
        case 'Block':
          category = 'blocks';
          break;
        case 'Turnover':
          category = 'turnovers';
          break;
        case 'Foul':
          category = 'fouls';
          break;
      }

      if (category != null) {
        // Update Team/Opponent totals
        if (isTeam) {
          stats.teamStats
              .update(category, (v) => v + value, ifAbsent: () => value);
        } else {
          stats.opponentStats
              .update(category, (v) => v + value, ifAbsent: () => value);
        }

        // Player Stats
        final playerId = event['playerId'] as int?;
        if (playerId != null && playerId != -1) {
          _incrementPlayerStat(stats, category, playerId, value);
        }
      }
    }

    return stats;
  }

  @override
  Future<CareerStats> createCareerStats(
      int teamId, List<Map<String, dynamic>> events) async {
    final stats = CareerStats(teamId: teamId);

    // Basic implementation for basketball career stats
    for (final event in events) {
      final playerId = event['playerId'] as int?;
      if (playerId == null) continue;

      final type = event['eventType'];
      // Mapping logic similar to createSeasonStats
      String? category;
      int value = 1;

      switch (type) {
        case 'Point':
          category = 'points';
          value = event['eventData'] as int? ?? 0;
          break;
        case 'Rebound':
          category = 'rebounds';
          break;
        case 'Assist':
          category = 'assists';
          break;
        case 'Steal':
          category = 'steals';
          break;
        case 'Block':
          category = 'blocks';
          break;
        case 'Turnover':
          category = 'turnovers';
          break;
        case 'Foul':
          category = 'fouls';
          break;
      }

      if (category != null) {
        _incrementStatMap(stats.playerStats, category, playerId, value);
      }
    }
    return stats;
  }

  void _incrementStatMap(Map<String, Map<int, int>> stats, String category,
      int playerId, int value) {
    stats.putIfAbsent(category, () => {});
    stats[category]!.update(playerId, (v) => v + value, ifAbsent: () => value);
  }

  void _incrementPlayerStat(
      SeasonStats stats, String category, int playerId, int value) {
    _incrementStatMap(stats.playerStats, category, playerId, value);
  }
}
