import 'package:flutter/material.dart';
import 'package:team_sync/app_config.dart';
import 'package:team_sync/models/career_stats.dart';
import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/season_stats.dart';
import 'package:team_sync/services/sport_strategy.dart';

class SoccerStrategy implements SportStrategy {
  @override
  String get appTitle => 'TeamSync - Soccer';

  @override
  Color get primaryColor => Colors.green;

  @override
  String get appIconAsset => 'assets/images/pngs/soccer_icon_no_background.png';

  @override
  IconData get sportIcon => Icons.sports_soccer;

  @override
  String get sportId => 'soccer';

  @override
  String get webUrl => 'https://team-sync-soccer.web.app';

  @override
  AppConfig get appConfig => AppConfig.soccer;

  @override
  List<String> get leaderCategories => [
        'goals',
        'assists',
        'saves',
        'shots',
        'shotsOnGoal',
        'fouls',
        'yellows',
        'reds'
      ];

  @override
  String formatEventDisplay(GameEvent event) {
    // Logic from GameEvent.display
    if (event.eventType == 'Shot') {
      final shot = event as Shot;
      if (event.player != null) {
        if (shot.result == ShotResult.goal) {
          return 'Goal';
        }
        return 'Shot - ${shot.result.display}';
      }
      if (shot.result == ShotResult.goal) {
        return 'Goal';
      }
      return 'Shot - ${shot.result.display}';
    } else if (event.eventType == 'Assist') {
      return event.player != null
          ? 'Assist: ${event.player!.displayName}'
          : 'Assist';
    } else if (event.eventType == 'Save') {
      return event.player != null
          ? 'Save by ${event.player!.displayName}'
          : 'Save by ${event.team.shortName}';
    } else if (event.eventType == 'PenaltyKick') {
      final pk = event as PenaltyKick;
      if (event.player != null) {
        return '${pk.result.display} - ${event.player!.displayName} (PK)';
      }
      return '${pk.result.display} - ${event.team.shortName} (PK)';
    } else if (event.eventType == 'Corner') {
      final corner = event as Corner;
      return 'Corner kick for ${event.team.shortName} ${corner.result == CornerResult.none ? '' : ' - ${corner.result.display}'}';
    } else if (event.eventType == 'Foul') {
      return event.player != null
          ? 'Foul by ${event.player!.displayName}'
          : 'Foul by ${event.team.shortName}';
    } else if (event.eventType == 'Offsides') {
      return event.player != null
          ? 'Offsides on ${event.player!.displayName}'
          : 'Offsides on ${event.team.shortName}';
    } else if (event.eventType == 'Card') {
      return event.player != null
          ? 'Card by ${event.player!.displayName}'
          : 'Card for ${event.team.shortName}';
    } else if (event.eventType == 'Period') {
      return (event as Period)
          .display; // Period logic is fairly generic but has soccer terms
    }

    return event.eventType;
  }

  @override
  String getEventImageAsset(GameEvent event) {
    if (event is Shot) {
      switch (event.result) {
        case ShotResult.goal:
          return 'assets/images/pngs/goal.png';
        case ShotResult.onTargetSave:
          return 'assets/images/pngs/saved.png';
        case ShotResult.offTargetPost:
          return 'assets/images/pngs/offpost.png';
        case ShotResult.offTarget:
          return 'assets/images/pngs/offtarget.png';
        case ShotResult.onTargetBlock:
          return 'assets/images/pngs/blocked.png';
        case ShotResult.notInitialized:
          return 'assets/images/pngs/empty.png';
      }
    } else if (event is PenaltyKick) {
      switch (event.result) {
        case ShotResult.goal:
          return 'assets/images/pngs/goal.png';

        case ShotResult.onTargetSave:
          return 'assets/images/pngs/saved.png';

        case ShotResult.offTargetPost:
          return 'assets/images/pngs/offpost.png';

        case ShotResult.offTarget:
          return 'assets/images/pngs/offtarget.png';

        case ShotResult.onTargetBlock:
          return 'assets/images/pngs/blocked.png';

        case ShotResult.notInitialized:
          return 'assets/images/pngs/empty.png';
      }
    } else if (event is GameCard) {
      if (event.eventData == 0) {
        return 'assets/images/pngs/yellow.png';
      } else if (event.eventData == 1) {
        return 'assets/images/pngs/second_yellow_red.png';
      } else {
        return 'assets/images/pngs/red.png';
      }
    }

    return 'assets/images/pngs/empty.png';
  }

  @override
  bool isGoalEvent(GameEvent event) {
    return (event.eventType == 'Shot' || event.eventType == 'PenaltyKick') &&
        event.eventData == 0; // 0 is ShotResult.goal.index
  }

  @override
  SeasonStats createSeasonStats(
      int teamId, int seasonId, List<Map<String, dynamic>> events) {
    final stats = SeasonStats(teamId: teamId, seasonId: seasonId);

    // Opponent Stats
    stats.opponentStats['shots'] = events
        .where((m) => m['teamId'] != teamId && m['eventType'] == 'Shot')
        .length;
    stats.opponentStats['shotsOnGoal'] = events
        .where((m) =>
            m['teamId'] != teamId &&
            m['eventType'] == 'Shot' &&
            m['eventData'] != null &&
            (m['eventData'] == ShotResult.goal.index ||
                m['eventData'] == ShotResult.onTargetSave.index))
        .length;
    stats.opponentStats['shotsOffPost'] = events
        .where((m) =>
            m['teamId'] != teamId &&
            m['eventType'] == 'Shot' &&
            m['eventData'] != null &&
            m['eventData'] == ShotResult.offTargetPost.index)
        .length;
    stats.opponentStats['goals'] = events
        .where((m) =>
            m['teamId'] != teamId &&
            (m['eventType'] == 'Shot' || m['eventType'] == 'PenaltyKick') &&
            m['eventData'] != null &&
            m['eventData'] == ShotResult.goal.index)
        .length;
    stats.opponentStats['penaltyKickGoals'] = events
        .where((m) =>
            m['teamId'] != teamId &&
            m['eventType'] == 'PenaltyKick' &&
            m['eventData'] != null &&
            m['eventData'] == ShotResult.goal.index)
        .length;
    stats.opponentStats['penaltyKicksTaken'] = events
        .where((m) => m['teamId'] != teamId && m['eventType'] == 'PenaltyKick')
        .length;
    stats.opponentStats['saves'] = events
        .where((m) =>
            m['teamId'] == teamId &&
            m['eventType'] == 'Shot' &&
            m['eventData'] != null &&
            m['eventData'] == ShotResult.onTargetSave.index)
        .length;
    stats.opponentStats['assists'] = events
        .where((m) => m['teamId'] != teamId && m['eventType'] == 'Assist')
        .length;
    stats.opponentStats['offsides'] = events
        .where((m) => m['teamId'] != teamId && m['eventType'] == 'Offsides')
        .length;
    stats.opponentStats['corners'] = events
        .where((m) => m['teamId'] != teamId && m['eventType'] == 'Corner')
        .length;
    stats.opponentStats['fouls'] = events
        .where((m) => m['teamId'] != teamId && m['eventType'] == 'Foul')
        .length;
    stats.opponentStats['yellows'] = events
        .where((m) =>
            m['teamId'] != teamId &&
            m['eventType'] == 'Card' &&
            m['eventData'] != null &&
            m['eventData'] == 0)
        .length;
    stats.opponentStats['secondYellowReds'] = events
        .where((m) =>
            m['teamId'] != teamId &&
            m['eventType'] == 'Card' &&
            m['eventData'] != null &&
            m['eventData'] == 2)
        .length;
    stats.opponentStats['reds'] = events
        .where((m) =>
            m['teamId'] != teamId &&
            m['eventType'] == 'Card' &&
            m['eventData'] != null &&
            m['eventData'] == 1)
        .length;

    // Team Stats
    stats.teamStats['shots'] = events
        .where((m) => m['teamId'] == teamId && m['eventType'] == 'Shot')
        .length;
    stats.teamStats['shotsOnGoal'] = events
        .where((m) =>
            m['teamId'] == teamId &&
            m['eventType'] == 'Shot' &&
            m['eventData'] != null &&
            (m['eventData'] == ShotResult.goal.index ||
                m['eventData'] == ShotResult.onTargetSave.index))
        .length;
    stats.teamStats['shotsOffPost'] = events
        .where((m) =>
            m['teamId'] == teamId &&
            m['eventType'] == 'Shot' &&
            m['eventData'] != null &&
            m['eventData'] == ShotResult.offTargetPost.index)
        .length;
    stats.teamStats['goals'] = events
        .where((m) =>
            m['teamId'] == teamId &&
            m['playerId'] != null &&
            m['playerId'] != -1 &&
            (m['eventType'] == 'Shot' || m['eventType'] == 'PenaltyKick') &&
            m['eventData'] != null &&
            m['eventData'] == ShotResult.goal.index)
        .length;
    stats.teamStats['ownGoalsEarned'] = events
        .where((m) =>
            m['teamId'] == teamId &&
            m['playerId'] != null &&
            m['playerId'] == -2 &&
            m['eventType'] == 'Shot' &&
            m['eventData'] != null &&
            m['eventData'] == ShotResult.goal.index)
        .length;
    stats.teamStats['penaltyKickGoals'] = events
        .where((m) =>
            m['teamId'] == teamId &&
            m['eventType'] == 'PenaltyKick' &&
            m['eventData'] != null &&
            m['eventData'] == ShotResult.goal.index)
        .length;
    stats.teamStats['penaltyKicksTaken'] = events
        .where((m) => m['teamId'] == teamId && m['eventType'] == 'PenaltyKick')
        .length;
    stats.teamStats['saves'] = events
        .where((m) =>
            m['teamId'] != teamId &&
            m['eventType'] == 'Shot' &&
            m['eventData'] != null &&
            m['eventData'] == ShotResult.onTargetSave.index)
        .length;
    stats.teamStats['assists'] = events
        .where((m) => m['teamId'] == teamId && m['eventType'] == 'Assist')
        .length;
    stats.teamStats['offsides'] = events
        .where((m) => m['teamId'] == teamId && m['eventType'] == 'Offsides')
        .length;
    stats.teamStats['corners'] = events
        .where((m) => m['teamId'] == teamId && m['eventType'] == 'Corner')
        .length;
    stats.teamStats['fouls'] = events
        .where((m) => m['teamId'] == teamId && m['eventType'] == 'Foul')
        .length;
    stats.teamStats['yellows'] = events
        .where((m) =>
            m['teamId'] == teamId &&
            m['eventType'] == 'Card' &&
            m['eventData'] != null &&
            m['eventData'] == 0)
        .length;
    stats.teamStats['secondYellowReds'] = events
        .where((m) =>
            m['teamId'] == teamId &&
            m['eventType'] == 'Card' &&
            m['eventData'] != null &&
            m['eventData'] == 2)
        .length;
    stats.teamStats['reds'] = events
        .where((m) =>
            m['teamId'] == teamId &&
            m['eventType'] == 'Card' &&
            m['eventData'] != null &&
            m['eventData'] == 1)
        .length;

    // Player Stats
    for (final event in events) {
      final playerId = event['playerId'] as int?;
      if (playerId == null) continue;

      switch (event['eventType']) {
        case 'Shot':
          final eventData = event['eventData'] as int?;
          if (eventData == ShotResult.goal.index) {
            _incrementPlayerStat(stats, 'goals', playerId);
            _incrementPlayerStat(stats, 'shotsOnGoal', playerId);
          }

          if (eventData == ShotResult.onTargetSave.index) {
            _incrementPlayerStat(stats, 'shotsOnGoal', playerId);
          }

          if (eventData == ShotResult.offTargetPost.index) {
            _incrementPlayerStat(stats, 'shotsOffPost', playerId);
          }

          _incrementPlayerStat(stats, 'shots', playerId);
          break;

        case 'PenaltyKick':
          final eventData = event['eventData'] as int?;
          if (eventData == ShotResult.goal.index) {
            _incrementPlayerStat(stats, 'goals', playerId);
            _incrementPlayerStat(stats, 'penaltyKickGoals', playerId);
            _incrementPlayerStat(stats, 'penaltyKicksTaken', playerId);
          }
          break;

        case 'Assist':
          _incrementPlayerStat(stats, 'assists', playerId);
          break;

        case 'Offsides':
          _incrementPlayerStat(stats, 'offsides', playerId);
          break;

        case 'Card':
          final eventData = event['eventData'] as int?;
          switch (eventData) {
            case 0:
              _incrementPlayerStat(stats, 'yellows', playerId);
              break;

            case 1:
              _incrementPlayerStat(stats, 'reds', playerId);
              break;

            case 2:
              _incrementPlayerStat(stats, 'secondYellowReds', playerId);
              break;
          }
          break;

        case 'Foul':
          _incrementPlayerStat(stats, 'fouls', playerId);
          break;

        case 'Save':
          _incrementPlayerStat(stats, 'saves', playerId);
          break;
      }
    }
    return stats;
  }

  @override
  Future<CareerStats> createCareerStats(
      int teamId, List<Map<String, dynamic>> events) async {
    final stats = CareerStats(teamId: teamId);

    for (final event in events) {
      final playerId = event['playerId'] as int?;
      if (playerId == null) continue;

      switch (event['eventType']) {
        case 'Shot':
          final eventData = event['eventData'] as int?;
          if (eventData == ShotResult.goal.index) {
            _incrementStatMap(stats.playerStats, 'goals', playerId);
          } else if (eventData == ShotResult.onTargetSave.index) {
            _incrementStatMap(stats.playerStats, 'shotsOnGoal', playerId);
          } else if (eventData == ShotResult.offTargetPost.index) {
            _incrementStatMap(stats.playerStats, 'shotsOffPost', playerId);
          }
          _incrementStatMap(stats.playerStats, 'shots', playerId);
          break;

        case 'PenaltyKick':
          final eventData = event['eventData'] as int?;
          if (eventData == ShotResult.goal.index) {
            _incrementStatMap(stats.playerStats, 'goals', playerId);
            _incrementStatMap(stats.playerStats, 'penaltyKickGoals', playerId);
            _incrementStatMap(stats.playerStats, 'penaltyKicksTaken', playerId);
          }
          break;

        case 'Assist':
          _incrementStatMap(stats.playerStats, 'assists', playerId);
          break;

        case 'Save':
          _incrementStatMap(stats.playerStats, 'saves', playerId);
          break;

        case 'Offsides':
          _incrementStatMap(stats.playerStats, 'offsides', playerId);
          break;

        case 'Foul':
          _incrementStatMap(stats.playerStats, 'fouls', playerId);
          break;

        case 'Card':
          final eventData = event['eventData'] as int?;
          if (eventData == 0) {
            _incrementStatMap(stats.playerStats, 'yellows', playerId);
          } else if (eventData == 1) {
            _incrementStatMap(stats.playerStats, 'reds', playerId);
          } else if (eventData == 2) {
            _incrementStatMap(stats.playerStats, 'secondYellowReds', playerId);
          }
          break;
      }
    }
    return stats;
  }

  void _incrementStatMap(
      Map<String, Map<int, int>> stats, String category, int playerId) {
    stats.putIfAbsent(category, () => {});
    stats[category]!.update(playerId, (v) => v + 1, ifAbsent: () => 1);
  }

  void _incrementPlayerStat(SeasonStats stats, String category, int playerId) {
    _incrementStatMap(stats.playerStats, category, playerId);
  }
}
