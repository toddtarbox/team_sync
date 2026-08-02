import 'package:flutter/material.dart';
import 'package:team_sync/app_config.dart';
import 'package:team_sync/features/seasons/models/career_stats.dart';
import 'package:team_sync/features/game_events/models/game_event.dart';
import 'package:team_sync/features/seasons/models/season_stats.dart';
import 'package:team_sync/features/sports/services/sport_strategy.dart';

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
  String get webUrl => 'https://team-sync-basketball.web.app';

  @override
  AppConfig get appConfig => AppConfig.basketball;

  @override
  List<String> get leaderCategories => [
        'points',
        '3_pointers',
        '3_point_percentage',
        '2_pointers',
        '2_point_percentage',
        'free_throws',
        'free_throw_percentage',
        'rebounds',
        'off_rebounds',
        'def_rebounds',
        'assists',
        'steals',
        'blocks',
        'turnovers',
        'fouls',
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
    } else if (event.eventType == 'Miss') {
      final shotType =
          event.eventData == 3 ? '3PT' : (event.eventData == 2 ? 'FG' : 'FT');
      if (event.player != null) {
        return 'Miss $shotType - ${event.player!.displayName}';
      }
      return 'Miss $shotType - ${event.team.shortName}';
    } else if (event.eventType == 'Period') {
      return (event as Period).display;
    }

    return event.eventType;
  }

  @override
  String getEventImageAsset(GameEvent event) {
    // Define basketball assets later
    return 'assets/images/pngs/empty.png';
  }

  @override
  bool isGoalEvent(GameEvent event) {
    // Both 'Point' events and soccer-style 'Shot' goals contribute to the score
    return event.eventType == 'Point' ||
        (event.eventType == 'Shot' && event.eventData == 0);
  }

  @override
  int getEventValue(GameEvent event) {
    if (event.eventType == 'Point') {
      return event.eventData;
    }
    if (event.eventType == 'Shot' && event.eventData == 0) {
      return 1;
    }
    return 0;
  }

  @override
  String get scoreCategory => 'points';

  @override
  String get gameTerminology => 'Game';

  @override
  String get gameReportTerminology => 'Game Report';

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
          final data = event['eventData'];
          int pointValue = 1;
          if (data is num) {
            pointValue = data.toInt();
          } else if (data is String) {
            pointValue = int.tryParse(data) ?? 0;
          } else {
            pointValue = 0;
          }
          // Add breakdown stats
          if (pointValue == 3) {
            _incrementStat(stats, '3_pointers', isTeam, event['playerId'], 1);
          } else if (pointValue == 2) {
            _incrementStat(stats, '2_pointers', isTeam, event['playerId'], 1);
          } else if (pointValue == 1) {
            _incrementStat(stats, 'free_throws', isTeam, event['playerId'], 1);
          }
          break;
        case 'Miss':
          // Track missed shots for percentages
          final missType = event['eventData']; // 3=3PT, 2=FG, 1=FT
          if (missType == 3) {
            _incrementStat(
                stats, '3_pointers_missed', isTeam, event['playerId'], 1);
          } else if (missType == 2) {
            _incrementStat(
                stats, '2_pointers_missed', isTeam, event['playerId'], 1);
          } else if (missType == 1) {
            _incrementStat(
                stats, 'free_throws_missed', isTeam, event['playerId'], 1);
          }
          break;
        case 'Shot':
          // Fallback: treat soccer-style shot goals as 1 point in basketball stats
          if (event['eventData'] == 0) {
            category = 'points';
            value = 1;
          }
          break;
        case 'Rebound':
          category = 'rebounds';
          // Add breakdown stats
          final reboundType = event['eventData'];
          if (reboundType == 2) {
            _incrementStat(stats, 'off_rebounds', isTeam, event['playerId'], 1);
          } else if (reboundType == 3) {
            _incrementStat(stats, 'def_rebounds', isTeam, event['playerId'], 1);
          }
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

    return _calculatePercentages(stats);
  }

  SeasonStats _calculatePercentages(SeasonStats stats) {
    _calculateCategoryPercentage(
        stats, '3_pointers', '3_pointers_missed', '3_point_percentage');
    _calculateCategoryPercentage(
        stats, '2_pointers', '2_pointers_missed', '2_point_percentage');
    _calculateCategoryPercentage(
        stats, 'free_throws', 'free_throws_missed', 'free_throw_percentage');
    return stats;
  }

  void _calculateCategoryPercentage(SeasonStats stats, String madeKey,
      String missedKey, String percentageKey) {
    // Team
    final teamMade = stats.teamStats[madeKey] ?? 0;
    final teamMissed = stats.teamStats[missedKey] ?? 0;
    final teamAttempts = teamMade + teamMissed;
    if (teamAttempts > 0) {
      stats.teamStats[percentageKey] =
          ((teamMade / teamAttempts) * 100).round();
    }

    // Opponent
    final opponentMade = stats.opponentStats[madeKey] ?? 0;
    final opponentMissed = stats.opponentStats[missedKey] ?? 0;
    final opponentAttempts = opponentMade + opponentMissed;
    if (opponentAttempts > 0) {
      stats.opponentStats[percentageKey] =
          ((opponentMade / opponentAttempts) * 100).round();
    }

    // Players
    final playerMadeMap = stats.playerStats[madeKey] ?? {};
    final playerMissedMap = stats.playerStats[missedKey] ?? {};

    // Union of players who have either made or missed
    final allPlayerIds = {...playerMadeMap.keys, ...playerMissedMap.keys};

    for (final playerId in allPlayerIds) {
      final made = playerMadeMap[playerId] ?? 0;
      final missed = playerMissedMap[playerId] ?? 0;
      final attempts = made + missed;

      if (attempts > 0) {
        _incrementStatMap(stats.playerStats, percentageKey, playerId,
            ((made / attempts) * 100).round());
      }
    }
  }

  void _incrementStat(SeasonStats stats, String category, bool isTeam,
      dynamic playerIdObj, int value) {
    // Update Team/Opponent totals
    if (isTeam) {
      stats.teamStats.update(category, (v) => v + value, ifAbsent: () => value);
    } else {
      stats.opponentStats
          .update(category, (v) => v + value, ifAbsent: () => value);
    }

    // Player Stats
    final playerId = playerIdObj as int?;
    if (playerId != null && playerId != -1) {
      _incrementPlayerStat(stats, category, playerId, value);
    }
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
          final data = event['eventData'];
          int pointValue = 1;
          if (data is num) {
            pointValue = data.toInt();
          } else if (data is String) {
            pointValue = int.tryParse(data) ?? 0;
          } else {
            pointValue = 0;
          }
          value = pointValue;

          // Add breakdown stats
          if (pointValue == 3) {
            _incrementStatMap(stats.playerStats, '3_pointers', playerId, 1);
          } else if (pointValue == 2) {
            _incrementStatMap(stats.playerStats, '2_pointers', playerId, 1);
          } else if (pointValue == 1) {
            _incrementStatMap(stats.playerStats, 'free_throws', playerId, 1);
          }
          break;
        case 'Miss':
          final missType = event['eventData'];
          if (missType == 3) {
            _incrementStatMap(
                stats.playerStats, '3_pointers_missed', playerId, 1);
          } else if (missType == 2) {
            _incrementStatMap(
                stats.playerStats, '2_pointers_missed', playerId, 1);
          } else if (missType == 1) {
            _incrementStatMap(
                stats.playerStats, 'free_throws_missed', playerId, 1);
          }
          break;
        case 'Shot':
          // Fallback: treat soccer-style shot goals as 1 point in basketball stats
          if (event['eventData'] == 0) {
            category = 'points';
            value = 1;
          }
          break;
        case 'Rebound':
          category = 'rebounds';
          // Add breakdown stats
          final reboundType = event['eventData'];
          if (reboundType == 2) {
            _incrementStatMap(stats.playerStats, 'off_rebounds', playerId, 1);
          } else if (reboundType == 3) {
            _incrementStatMap(stats.playerStats, 'def_rebounds', playerId, 1);
          }
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
    return _calculateCareerPercentages(stats);
  }

  CareerStats _calculateCareerPercentages(CareerStats stats) {
    _calculateCareerCategoryPercentage(
        stats, '3_pointers', '3_pointers_missed', '3_point_percentage');
    _calculateCareerCategoryPercentage(
        stats, '2_pointers', '2_pointers_missed', '2_point_percentage');
    _calculateCareerCategoryPercentage(
        stats, 'free_throws', 'free_throws_missed', 'free_throw_percentage');
    return stats;
  }

  void _calculateCareerCategoryPercentage(CareerStats stats, String madeKey,
      String missedKey, String percentageKey) {
    final playerMadeMap = stats.playerStats[madeKey] ?? {};
    final playerMissedMap = stats.playerStats[missedKey] ?? {};

    final allPlayerIds = {...playerMadeMap.keys, ...playerMissedMap.keys};

    for (final playerId in allPlayerIds) {
      final made = playerMadeMap[playerId] ?? 0;
      final missed = playerMissedMap[playerId] ?? 0;
      final attempts = made + missed;

      if (attempts > 0) {
        _incrementStatMap(stats.playerStats, percentageKey, playerId,
            ((made / attempts) * 100).round());
      }
    }
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
