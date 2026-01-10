import 'dart:collection';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/stat_leaders.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/sport_strategy.dart';

class CareerStats implements StatLeaders {
  final int teamId;
  final Map<String, Map<int, int>> playerStats = {};

  CareerStats({required this.teamId});

  static Future<CareerStats> fromMap(
      int teamId, List<Map<String, dynamic>> map) {
    return SportStrategy.current.createCareerStats(teamId, map);
  }

  @override
  Future<HashMap<Player, int>> getStatPlayers(String category) async {
    final HashMap<Player, int> stats = HashMap<Player, int>();
    final sourceTable = playerStats[category];

    if (sourceTable == null) return stats;

    final playerIds =
        sourceTable.keys.where((id) => id != -1).toList(growable: false);

    final allPlayerResults = await DatabaseService.instance
        .query('Players', orderByChild: 'teamId', equalTo: teamId);
    final allPlayers = allPlayerResults.map((p) => Player.fromMap(p)).toList();

    final relevantPlayers =
        allPlayers.where((p) => playerIds.contains(p.id)).toList();

    final uniquePlayers = <int, Player>{};
    for (final player in relevantPlayers) {
      final existingPlayer = uniquePlayers[player.id];
      // For career stats, we generally want the latest instance of the player
      if (existingPlayer == null || player.seasonId > existingPlayer.seasonId) {
        uniquePlayers[player.id] = player;
      }
    }

    for (int playerId in playerIds) {
      final player = uniquePlayers[playerId];
      if (player != null) {
        stats[player] = sourceTable[playerId] ?? 0;
      }
    }

    return stats;
  }
}
