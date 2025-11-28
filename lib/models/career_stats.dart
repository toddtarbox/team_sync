import 'dart:collection';
import 'dart:core';

import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season_stats.dart';
import 'package:team_sync/models/stat_leaders.dart';
import 'package:team_sync/services/database_service.dart';

class CareerStats implements StatLeaders {
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
      final playerId = event['playerId'] as int?;
      if (playerId == null) continue;

      switch (event['eventType']) {
        case 'Shot':
          stats._playerShots
              .update(playerId, (value) => value + 1, ifAbsent: () => 1);

          final eventData = event['eventData'] as int?;
          if (eventData == ShotResult.goal.index) {
            stats._playerGoals
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          } else if (eventData == ShotResult.onTargetSave.index) {
            stats._playerShotsOnGoal
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          } else if (eventData == ShotResult.offTargetPost.index) {
            stats._playerShotsOffPost
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          }
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

        case 'Save':
          stats._playerSaves
              .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          break;

        case 'Offsides':
          stats._playerOffsides
              .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          break;

        case 'Foul':
          stats._playerFouls
              .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          break;

        case 'Card':
          final eventData = event['eventData'] as int?;
          if (eventData == 0) {
            stats._playerYellows
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          } else if (eventData == 1) {
            stats._playerSecondYellows
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          } else if (eventData == 2) {
            stats._playerReds
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          }
          break;
      }
    }
    return stats;
  }

  @override
  Future<HashMap<Player, int>> getStatPlayers(LeaderCategory category) async {
    HashMap<int, int>? sourceTable;
    final HashMap<Player, int> playerStats = HashMap<Player, int>();

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

    if (sourceTable == null) return playerStats;

    final playerIds =
        sourceTable.keys.where((id) => id != -1).toList(growable: false);

    print(
        'CareerStats.getStatPlayers: Processing ${playerIds.length} player IDs for team $teamId');

    // Query all players for this team from the database
    final allPlayerResults = await DatabaseService.instance
        .query('Players', orderByChild: 'teamId', equalTo: teamId);
    final allPlayers = allPlayerResults.map((p) => Player.fromMap(p)).toList();

    print(
        'CareerStats.getStatPlayers: Found ${allPlayers.length} total players for team $teamId');

    // Filter to only players with IDs we care about
    final relevantPlayers =
        allPlayers.where((p) => playerIds.contains(p.id)).toList();

    print(
        'CareerStats.getStatPlayers: Filtered to ${relevantPlayers.length} relevant players');

    // Group players by ID and pick the one from the most recent season
    // This prevents duplicates when the same player appears in multiple seasons
    final uniquePlayers = <int, Player>{};
    for (final player in relevantPlayers) {
      final existingPlayer = uniquePlayers[player.id];
      if (existingPlayer == null || player.seasonId > existingPlayer.seasonId) {
        if (existingPlayer != null) {
          print(
              'CareerStats.getStatPlayers: Replacing player ${player.displayName} (ID: ${player.id}) - old season: ${existingPlayer.seasonId}, new season: ${player.seasonId}');
        }
        uniquePlayers[player.id] = player;
      }
    }

    print(
        'CareerStats.getStatPlayers: Created ${uniquePlayers.length} unique players');

    // Build the result map with unique players
    for (int playerId in playerIds) {
      final player = uniquePlayers[playerId];
      if (player != null) {
        playerStats[player] = sourceTable[playerId] ?? 0;
        print(
            'CareerStats.getStatPlayers: Added ${player.displayName} (ID: ${player.id}, Season: ${player.seasonId}) with ${sourceTable[playerId]} stats');
      }
    }

    print(
        'CareerStats.getStatPlayers: Final playerStats has ${playerStats.length} entries');
    print(
        'CareerStats.getStatPlayers: HashMap keys: ${playerStats.keys.map((p) => '${p.displayName} (ID: ${p.id}, Season: ${p.seasonId})').join(', ')}');

    return playerStats;
  }
}
