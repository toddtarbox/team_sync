import 'dart:collection';
import 'dart:core';

import 'package:sqflite/sqflite.dart';
import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season_stats.dart';

class CareerStats {
  final int teamId;

  CareerStats({required this.teamId});

  final HashMap<int, int> _playerGoals = HashMap<int, int>();
  final HashMap<int, int> _playerPenaltyKickGoals = HashMap<int, int>();
  final HashMap<int, int> _playerPenaltyKicksTaken = HashMap<int, int>();
  final HashMap<int, int> _playerAssists = HashMap<int, int>();
  final HashMap<int, int> _playerShots = HashMap<int, int>();
  final HashMap<int, int> _playerShotsOnGoal = HashMap<int, int>();
  final HashMap<int, int> _playerShotsOffPost = HashMap<int, int>();
  final HashMap<int, int> _playerSaves = HashMap<int, int>();
  final HashMap<int, int> _playerOffsides = HashMap<int, int>();
  final HashMap<int, int> _playerFouls = HashMap<int, int>();
  final HashMap<int, int> _playerYellows = HashMap<int, int>();
  final HashMap<int, int> _playerSecondYellows = HashMap<int, int>();
  final HashMap<int, int> _playerReds = HashMap<int, int>();

  factory CareerStats.fromMap(int teamId, List<Map<String, dynamic>> map) {
    final stats = CareerStats(teamId: teamId);

    for (final event in map) {
      switch (event['eventType']) {
        case 'Shot':
          stats._playerShots.update(event['playerId'], (value) => value + 1,
              ifAbsent: () => 1);

          if (event['eventData'] == ShotResult.goal.index) {
            stats._playerGoals.update(event['playerId'], (value) => value + 1,
                ifAbsent: () => 1);
          } else if (event['eventData'] == ShotResult.onTargetSave.index) {
            stats._playerShotsOnGoal.update(
                event['playerId'], (value) => value + 1,
                ifAbsent: () => 1);
          } else if (event['eventData'] == ShotResult.offTargetPost.index) {
            stats._playerShotsOffPost.update(
                event['playerId'], (value) => value + 1,
                ifAbsent: () => 1);
          }
          break;

        case 'PenaltyKick':
          if (event['eventData'] == ShotResult.goal.index) {
            stats._playerGoals.update(event['playerId'], (value) => value + 1,
                ifAbsent: () => 1);
            stats._playerPenaltyKickGoals.update(
                event['playerId'], (value) => value + 1,
                ifAbsent: () => 1);
            stats._playerPenaltyKicksTaken.update(
                event['playerId'], (value) => value + 1,
                ifAbsent: () => 1);
          }
          break;

        case 'Assist':
          stats._playerAssists.update(event['playerId'], (value) => value + 1,
              ifAbsent: () => 1);
          break;

        case 'Save':
          stats._playerSaves.update(event['playerId'], (value) => value + 1,
              ifAbsent: () => 1);
          break;

        case 'Offsides':
          stats._playerOffsides.update(event['playerId'], (value) => value + 1,
              ifAbsent: () => 1);
          break;

        case 'Foul':
          stats._playerFouls.update(event['playerId'], (value) => value + 1,
              ifAbsent: () => 1);
          break;

        case 'Card':
          if (event['eventData'] == 0) {
            stats._playerYellows.update(event['playerId'], (value) => value + 1,
                ifAbsent: () => 1);
          } else if (event['eventData'] == 1) {
            stats._playerSecondYellows.update(
                event['playerId'], (value) => value + 1,
                ifAbsent: () => 1);
          } else if (event['eventData'] == 2) {
            stats._playerReds.update(event['playerId'], (value) => value + 1,
                ifAbsent: () => 1);
          }
          break;
      }
    }
    return stats;
  }

  Future<HashMap<Player, int>> getStatPlayers(
      Database db, LeaderCategory category) async {
    HashMap<int, int>? sourceTable;
    final HashMap<Player, int> players = HashMap<Player, int>();

    switch (category) {
      case LeaderCategory.goals:
        sourceTable = _playerGoals;
        break;

      case LeaderCategory.penaltyKickGoals:
        sourceTable = _playerPenaltyKickGoals;
        break;

      case LeaderCategory.penaltyKicksTaken:
        sourceTable = _playerPenaltyKicksTaken;
        break;

      case LeaderCategory.assists:
        sourceTable = _playerAssists;
        break;

      case LeaderCategory.shots:
        sourceTable = _playerShots;
        break;

      case LeaderCategory.shotsOnGoal:
        sourceTable = _playerShotsOnGoal;
        break;

      case LeaderCategory.shotsOffPost:
        sourceTable = _playerShotsOffPost;
        break;

      case LeaderCategory.saves:
        sourceTable = _playerSaves;
        break;

      case LeaderCategory.offsides:
        sourceTable = _playerOffsides;
        break;

      case LeaderCategory.fouls:
        sourceTable = _playerFouls;
        break;

      case LeaderCategory.yellows:
        sourceTable = _playerYellows;
        break;

      case LeaderCategory.secondYellowReds:
        sourceTable = _playerSecondYellows;
        break;

      case LeaderCategory.reds:
        sourceTable = _playerReds;
        break;

      default:
        break;
    }

    if (sourceTable == null) return players;

    for (int playerId in sourceTable.keys) {
      if (playerId != -1) {
        Player? player = await Player.fromId(db, playerId);
        if (player != null) {
          players[player] = sourceTable[playerId] ?? 0;
        }
      }
    }

    return players;
  }
}
