import 'dart:collection';
import 'dart:core';

import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/stat_leaders.dart';

enum LeaderCategory {
  goals,
  ownGoalsEarned,
  penaltyKickGoals,
  penaltyKicksTaken,
  assists,
  shots,
  shotsOnGoal,
  shotsOffPost,
  saves,
  offsides,
  corners,
  fouls,
  yellows,
  secondYellowReds,
  reds
}

class SeasonStats implements StatLeaders {
  final int teamId;
  final int seasonId;

  SeasonStats({required this.teamId, required this.seasonId});

  final HashMap<int, int> _playerShots = HashMap<int, int>();
  final HashMap<int, int> _playerShotsOnGoal = HashMap<int, int>();
  final HashMap<int, int> _playerShotsOffPost = HashMap<int, int>();
  final HashMap<int, int> _playerGoals = HashMap<int, int>();
  final HashMap<int, int> _playerPenaltyKickGoals = HashMap<int, int>();
  final HashMap<int, int> _playerPenaltyKicksTaken = HashMap<int, int>();
  final HashMap<int, int> _playerAssists = HashMap<int, int>();
  final HashMap<int, int> _playerOffsides = HashMap<int, int>();
  final HashMap<int, int> _playerSaves = HashMap<int, int>();
  final HashMap<int, int> _playerFouls = HashMap<int, int>();
  final HashMap<int, int> _playerYellows = HashMap<int, int>();
  final HashMap<int, int> _playerSecondYellowReds = HashMap<int, int>();
  final HashMap<int, int> _playerReds = HashMap<int, int>();

  int _teamShots = 0;
  int _teamShotsOnGoal = 0;
  int _teamShotsOffPost = 0;
  int _teamSaves = 0;
  int _teamGoals = 0;
  int _teamOwnGoalsEarned = 0;
  int _teamPenaltyKickGoals = 0;
  int _teamPenaltyKickTaken = 0;
  int _teamAssists = 0;
  int _teamOffsides = 0;
  int _teamCorners = 0;
  int _teamFouls = 0;
  int _teamYellows = 0;
  int _teamSecondYellowReds = 0;
  int _teamReds = 0;

  int _opponentShots = 0;
  int _opponentShotsOnGoal = 0;
  int _opponentShotsOffPost = 0;
  int _opponentSaves = 0;
  int _opponentGoals = 0;
  int _opponentOwnGoalsEarned = 0;
  int _opponentPenaltyKickGoals = 0;
  int _opponentPenaltyKickTaken = 0;
  int _opponentAssists = 0;
  int _opponentOffsides = 0;
  int _opponentCorners = 0;
  int _opponentFouls = 0;
  int _opponentYellows = 0;
  int _opponentSecondYellowReds = 0;
  int _opponentReds = 0;

  factory SeasonStats.fromMap(
      int teamId, int seasonId, List<Map<String, dynamic>> map) {
    final stats = SeasonStats(teamId: teamId, seasonId: seasonId);

    stats._opponentShots = map
        .where((m) => m['teamId'] != teamId && m['eventType'] == 'Shot')
        .length;
    stats._opponentShotsOnGoal = map
        .where((m) =>
            m['teamId'] != teamId &&
            m['eventType'] == 'Shot' &&
            m['eventData'] != null &&
            (m['eventData'] == ShotResult.goal.index ||
                m['eventData'] == ShotResult.onTargetSave.index))
        .length;
    stats._opponentShotsOffPost = map
        .where((m) =>
            m['teamId'] != teamId &&
            m['eventType'] == 'Shot' &&
            m['eventData'] != null &&
            m['eventData'] == ShotResult.offTargetPost.index)
        .length;
    stats._opponentGoals = map
        .where((m) =>
            m['teamId'] != teamId &&
            (m['eventType'] == 'Shot' || m['eventType'] == 'PenaltyKick') &&
            m['eventData'] != null &&
            m['eventData'] == ShotResult.goal.index)
        .length;
    stats._opponentPenaltyKickGoals = map
        .where((m) =>
            m['teamId'] != teamId &&
            m['eventType'] == 'PenaltyKick' &&
            m['eventData'] != null &&
            m['eventData'] == ShotResult.goal.index)
        .length;
    stats._opponentPenaltyKickTaken = map
        .where((m) => m['teamId'] != teamId && m['eventType'] == 'PenaltyKick')
        .length;
    stats._opponentSaves = map
        .where((m) =>
            m['teamId'] == teamId &&
            m['eventType'] == 'Shot' &&
            m['eventData'] != null &&
            m['eventData'] == ShotResult.onTargetSave.index)
        .length;
    stats._opponentAssists = map
        .where((m) => m['teamId'] != teamId && m['eventType'] == 'Assist')
        .length;
    stats._opponentOffsides = map
        .where((m) => m['teamId'] != teamId && m['eventType'] == 'Offsides')
        .length;
    stats._opponentCorners = map
        .where((m) => m['teamId'] != teamId && m['eventType'] == 'Corner')
        .length;
    stats._opponentFouls = map
        .where((m) => m['teamId'] != teamId && m['eventType'] == 'Foul')
        .length;
    stats._opponentYellows = map
        .where((m) =>
            m['teamId'] != teamId &&
            m['eventType'] == 'Card' &&
            m['eventData'] != null &&
            m['eventData'] == 0)
        .length;
    stats._opponentSecondYellowReds = map
        .where((m) =>
            m['teamId'] != teamId &&
            m['eventType'] == 'Card' &&
            m['eventData'] != null &&
            m['eventData'] == 2)
        .length;
    stats._opponentReds = map
        .where((m) =>
            m['teamId'] != teamId &&
            m['eventType'] == 'Card' &&
            m['eventData'] != null &&
            m['eventData'] == 1)
        .length;

    stats._teamShots = map
        .where((m) => m['teamId'] == teamId && m['eventType'] == 'Shot')
        .length;
    stats._teamShotsOnGoal = map
        .where((m) =>
            m['teamId'] == teamId &&
            m['eventType'] == 'Shot' &&
            m['eventData'] != null &&
            (m['eventData'] == ShotResult.goal.index ||
                m['eventData'] == ShotResult.onTargetSave.index))
        .length;
    stats._teamShotsOffPost = map
        .where((m) =>
            m['teamId'] == teamId &&
            m['eventType'] == 'Shot' &&
            m['eventData'] != null &&
            m['eventData'] == ShotResult.offTargetPost.index)
        .length;
    stats._teamGoals = map
        .where((m) =>
            m['teamId'] == teamId &&
            m['playerId'] != null &&
            m['playerId'] != -1 &&
            (m['eventType'] == 'Shot' || m['eventType'] == 'PenaltyKick') &&
            m['eventData'] != null &&
            m['eventData'] == ShotResult.goal.index)
        .length;
    stats._teamOwnGoalsEarned = map
        .where((m) =>
            m['teamId'] == teamId &&
            m['playerId'] != null &&
            m['playerId'] == -2 &&
            m['eventType'] == 'Shot' &&
            m['eventData'] != null &&
            m['eventData'] == ShotResult.goal.index)
        .length;
    stats._teamPenaltyKickGoals = map
        .where((m) =>
            m['teamId'] == teamId &&
            m['eventType'] == 'PenaltyKick' &&
            m['eventData'] != null &&
            m['eventData'] == ShotResult.goal.index)
        .length;
    stats._teamPenaltyKickTaken = map
        .where((m) => m['teamId'] == teamId && m['eventType'] == 'PenaltyKick')
        .length;
    stats._teamSaves = map
        .where((m) =>
            m['teamId'] != teamId &&
            m['eventType'] == 'Shot' &&
            m['eventData'] != null &&
            m['eventData'] == ShotResult.onTargetSave.index)
        .length;
    stats._teamAssists = map
        .where((m) => m['teamId'] == teamId && m['eventType'] == 'Assist')
        .length;
    stats._teamOffsides = map
        .where((m) => m['teamId'] == teamId && m['eventType'] == 'Offsides')
        .length;
    stats._teamCorners = map
        .where((m) => m['teamId'] == teamId && m['eventType'] == 'Corner')
        .length;
    stats._teamFouls = map
        .where((m) => m['teamId'] == teamId && m['eventType'] == 'Foul')
        .length;
    stats._teamYellows = map
        .where((m) =>
            m['teamId'] == teamId &&
            m['eventType'] == 'Card' &&
            m['eventData'] != null &&
            m['eventData'] == 0)
        .length;
    stats._teamSecondYellowReds = map
        .where((m) =>
            m['teamId'] == teamId &&
            m['eventType'] == 'Card' &&
            m['eventData'] != null &&
            m['eventData'] == 2)
        .length;
    stats._teamReds = map
        .where((m) =>
            m['teamId'] == teamId &&
            m['eventType'] == 'Card' &&
            m['eventData'] != null &&
            m['eventData'] == 1)
        .length;

    for (final event in map) {
      final playerId = event['playerId'] as int?;
      if (playerId == null) continue;

      switch (event['eventType']) {
        case 'Shot':
          final eventData = event['eventData'] as int?;
          if (eventData == ShotResult.goal.index) {
            stats._playerGoals
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
            stats._playerShotsOnGoal
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          }

          if (eventData == ShotResult.onTargetSave.index) {
            stats._playerShotsOnGoal
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          }

          if (eventData == ShotResult.offTargetPost.index) {
            stats._playerShotsOffPost
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          }

          stats._playerShots
              .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          break;

        case 'PenaltyKick':
          final eventData = event['eventData'] as int?;
          if (eventData == ShotResult.goal.index) {
            stats._playerGoals
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
            stats._playerPenaltyKickGoals
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
            stats._playerPenaltyKicksTaken
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          }
          break;

        case 'Assist':
          stats._playerAssists
              .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          break;

        case 'Offsides':
          stats._playerOffsides
              .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          break;

        case 'Card':
          final eventData = event['eventData'] as int?;
          switch (eventData) {
            case 0:
              stats._playerYellows
                  .update(playerId, (value) => value + 1, ifAbsent: () => 1);
              break;

            case 1:
              stats._playerReds
                  .update(playerId, (value) => value + 1, ifAbsent: () => 1);
              break;

            case 2:
              stats._playerSecondYellowReds
                  .update(playerId, (value) => value + 1, ifAbsent: () => 1);
              break;
          }
          break;

        case 'Foul':
          stats._playerFouls
              .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          break;

        case 'Save':
          stats._playerSaves
              .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          break;
      }
    }
    return stats;
  }

  int get teamCorners => _teamCorners;
  int get opponentCorners => _opponentCorners;

  int teamStat(LeaderCategory category) {
    switch (category) {
      case LeaderCategory.goals:
        return _teamGoals;
      case LeaderCategory.ownGoalsEarned:
        return _teamOwnGoalsEarned;
      case LeaderCategory.shots:
        return _teamShots;
      case LeaderCategory.shotsOnGoal:
        return _teamShotsOnGoal;
      case LeaderCategory.shotsOffPost:
        return _teamShotsOffPost;
      case LeaderCategory.assists:
        return _teamAssists;
      case LeaderCategory.saves:
        return _teamSaves;
      case LeaderCategory.offsides:
        return _teamOffsides;
      case LeaderCategory.corners:
        return _teamCorners;
      case LeaderCategory.fouls:
        return _teamFouls;
      case LeaderCategory.yellows:
        return _teamYellows;
      case LeaderCategory.secondYellowReds:
        return _teamSecondYellowReds;
      case LeaderCategory.reds:
        return _teamReds;
      case LeaderCategory.penaltyKickGoals:
        return _teamPenaltyKickGoals;
      case LeaderCategory.penaltyKicksTaken:
        return _teamPenaltyKickTaken;
    }
  }

  int opponentStat(LeaderCategory category) {
    switch (category) {
      case LeaderCategory.goals:
        return _opponentGoals;
      case LeaderCategory.ownGoalsEarned:
        return _opponentOwnGoalsEarned;
      case LeaderCategory.shots:
        return _opponentShots;
      case LeaderCategory.shotsOnGoal:
        return _opponentShotsOnGoal;
      case LeaderCategory.shotsOffPost:
        return _opponentShotsOffPost;
      case LeaderCategory.assists:
        return _opponentAssists;
      case LeaderCategory.saves:
        return _opponentSaves;
      case LeaderCategory.offsides:
        return _opponentOffsides;
      case LeaderCategory.corners:
        return _opponentCorners;
      case LeaderCategory.fouls:
        return _opponentFouls;
      case LeaderCategory.yellows:
        return _opponentYellows;
      case LeaderCategory.secondYellowReds:
        return _opponentSecondYellowReds;
      case LeaderCategory.reds:
        return _opponentReds;
      case LeaderCategory.penaltyKickGoals:
        return _opponentPenaltyKickGoals;
      case LeaderCategory.penaltyKicksTaken:
        return _opponentPenaltyKickTaken;
    }
  }

  @override
  Future<HashMap<Player, int>> getStatPlayers(LeaderCategory category) async {
    HashMap<int, int> sourceTable;
    final HashMap<Player, int> players = HashMap<Player, int>();

    switch (category) {
      case LeaderCategory.assists:
        sourceTable = _playerAssists;
        break;

      case LeaderCategory.fouls:
        sourceTable = _playerFouls;
        break;

      case LeaderCategory.goals:
        sourceTable = _playerGoals;
        break;

      case LeaderCategory.ownGoalsEarned:
        sourceTable = _playerGoals;
        break;

      case LeaderCategory.offsides:
        sourceTable = _playerOffsides;
        break;

      case LeaderCategory.corners:
        // Corners are team stats, not player stats
        return players;

      case LeaderCategory.reds:
        sourceTable = _playerReds;
        break;

      case LeaderCategory.saves:
        sourceTable = _playerSaves;
        break;

      case LeaderCategory.shots:
        sourceTable = _playerShots;
        break;

      case LeaderCategory.shotsOffPost:
        sourceTable = _playerShotsOffPost;
        break;

      case LeaderCategory.shotsOnGoal:
        sourceTable = _playerShotsOnGoal;
        break;

      case LeaderCategory.yellows:
        sourceTable = _playerYellows;
        break;

      case LeaderCategory.secondYellowReds:
        sourceTable = _playerSecondYellowReds;
        break;

      case LeaderCategory.penaltyKickGoals:
        sourceTable = _playerPenaltyKickGoals;
        break;

      case LeaderCategory.penaltyKicksTaken:
        sourceTable = _playerPenaltyKicksTaken;
        break;
    }

    for (int playerId in sourceTable.keys) {
      if (playerId != -1) {
        // Use singleFromIdSeasonId to get the player for this specific season
        Player? player = await Player.singleFromIdSeasonId(playerId, seasonId);
        if (player != null) {
          players[player] = sourceTable[playerId] ?? 0;
        }
      }
    }

    return players;
  }
}
