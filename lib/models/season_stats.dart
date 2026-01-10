import 'dart:collection';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/stat_leaders.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/sport_strategy.dart';

class SeasonStats implements StatLeaders {
  final int teamId;
  final int seasonId;

  final Map<String, int> teamStats = {};
  final Map<String, int> opponentStats = {};
  final Map<String, Map<int, int>> playerStats = {};

  SeasonStats({required this.teamId, required this.seasonId});

  // Factory delegates to Strategy
  static SeasonStats fromMap(
      int teamId, int seasonId, List<Map<String, dynamic>> map) {
    return SportStrategy.current.createSeasonStats(teamId, seasonId, map);
  }

  // Getters for Soccer compatibility - mapping to string keys
  int get teamGoals => teamStats['goals'] ?? 0;
  int get teamOwnGoalsEarned => teamStats['ownGoalsEarned'] ?? 0;
  int get teamPenaltyKickGoals => teamStats['penaltyKickGoals'] ?? 0;
  int get teamPenaltyKickTaken => teamStats['penaltyKicksTaken'] ?? 0;
  int get teamAssists => teamStats['assists'] ?? 0;
  int get teamShots => teamStats['shots'] ?? 0;
  int get teamShotsOnGoal => teamStats['shotsOnGoal'] ?? 0;
  int get teamShotsOffPost => teamStats['shotsOffPost'] ?? 0;
  int get teamSaves => teamStats['saves'] ?? 0;
  int get teamOffsides => teamStats['offsides'] ?? 0;
  int get teamCorners => teamStats['corners'] ?? 0;
  int get teamFouls => teamStats['fouls'] ?? 0;
  int get teamYellows => teamStats['yellows'] ?? 0;
  int get teamSecondYellowReds => teamStats['secondYellowReds'] ?? 0;
  int get teamReds => teamStats['reds'] ?? 0;

  int get opponentGoals => opponentStats['goals'] ?? 0;
  int get opponentOwnGoalsEarned => opponentStats['ownGoalsEarned'] ?? 0;
  int get opponentPenaltyKickGoals => opponentStats['penaltyKickGoals'] ?? 0;
  int get opponentPenaltyKickTaken => opponentStats['penaltyKicksTaken'] ?? 0;
  int get opponentAssists => opponentStats['assists'] ?? 0;
  int get opponentShots => opponentStats['shots'] ?? 0;
  int get opponentShotsOnGoal => opponentStats['shotsOnGoal'] ?? 0;
  int get opponentShotsOffPost => opponentStats['shotsOffPost'] ?? 0;
  int get opponentSaves => opponentStats['saves'] ?? 0;
  int get opponentOffsides => opponentStats['offsides'] ?? 0;
  int get opponentCorners => opponentStats['corners'] ?? 0;
  int get opponentFouls => opponentStats['fouls'] ?? 0;
  int get opponentYellows => opponentStats['yellows'] ?? 0;
  int get opponentSecondYellowReds => opponentStats['secondYellowReds'] ?? 0;
  int get opponentReds => opponentStats['reds'] ?? 0;

  int teamStat(String category) {
    return teamStats[category] ?? 0;
  }

  int opponentStat(String category) {
    return opponentStats[category] ?? 0;
  }

  @override
  Future<HashMap<Player, int>> getStatPlayers(String category) async {
    final HashMap<Player, int> players = HashMap<Player, int>();
    final sourceTable = playerStats[category];

    if (sourceTable == null) return players;

    final playerIds =
        sourceTable.keys.where((id) => id != -1).toList(growable: false);

    // Query all players for this team from the database
    // Optimization: filtering by teamId to avoid fetching the entire database
    final allPlayerResults = await DatabaseService.instance
        .query('Players', orderByChild: 'teamId', equalTo: teamId);
    final allPlayers = allPlayerResults.map((p) => Player.fromMap(p)).toList();

    // Filter to only players with IDs we care about
    final relevantPlayers =
        allPlayers.where((p) => playerIds.contains(p.id)).toList();

    // Group players by ID and pick the one from the most recent season
    // This prevents duplicates when the same player appears in multiple seasons
    final uniquePlayers = <int, Player>{};
    for (final player in relevantPlayers) {
      final existingPlayer = uniquePlayers[player.id];
      if (existingPlayer == null || player.seasonId > existingPlayer.seasonId) {
        uniquePlayers[player.id] = player;
      }
    }

    // Build the result map with unique players
    for (int playerId in playerIds) {
      final player = uniquePlayers[playerId];
      if (player != null) {
        players[player] = sourceTable[playerId] ?? 0;
      }
    }

    return players;
  }
}
