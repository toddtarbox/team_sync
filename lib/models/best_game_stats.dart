import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/season_stats.dart';
import 'package:team_sync/services/database_service.dart';

class BestGameStat {
  final Player player;
  final Game game;
  final Season season;
  final int value;

  BestGameStat(
      {required this.player,
      required this.game,
      required this.season,
      required this.value});

  Map<String, dynamic> toMap(int teamId, LeaderCategory category) {
    return {
      'id': '${teamId}_${category.index}',
      'teamId': teamId,
      'category': category.index,
      'playerId': player.id,
      'gameId': game.id,
      'seasonId': season.id,
      'value': value,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Future<BestGameStat?> fromMap(Map<String, dynamic> map) async {
    try {
      final playerId = map['playerId'] as int?;
      final gameId = map['gameId'] as int?;
      final seasonId = map['seasonId'] as int?;
      final value = map['value'] as int?;

      if (playerId == null ||
          gameId == null ||
          seasonId == null ||
          value == null) {
        return null;
      }

      final player = await Player.fromId(playerId);
      final game = await Game.fromId(gameId);

      if (player == null || game == null) {
        return null;
      }

      // Get the season from the list of seasons for the team
      final seasons = await Season.fromTeamId(map['teamId'] as int);
      final season = seasons.where((s) => s.id == seasonId).firstOrNull;

      if (season == null) {
        return null;
      }

      return BestGameStat(
        player: player,
        game: game,
        season: season,
        value: value,
      );
    } catch (e) {
      return null;
    }
  }
}

class BestGameStats {
  final Map<LeaderCategory, BestGameStat> _bestStats = {};

  void setBestStat(LeaderCategory category, Player player, Game game,
      Season season, int value) {
    _bestStats[category] =
        BestGameStat(player: player, game: game, season: season, value: value);
  }

  BestGameStat? getBestStat(LeaderCategory category) {
    return _bestStats[category];
  }

  Iterable<LeaderCategory> get categories => _bestStats.keys;

  /// Save all best game stats to the database
  Future<void> saveToDatabase(int teamId) async {
    for (final entry in _bestStats.entries) {
      final category = entry.key;
      final stat = entry.value;
      final data = stat.toMap(teamId, category);
      await DatabaseService.instance.insert('BestGameStats', data);
    }
  }

  /// Load best game stats from the database for a team
  static Future<BestGameStats> loadFromDatabase(int teamId) async {
    final bestStats = BestGameStats();
    try {
      final results = await DatabaseService.instance
          .query('BestGameStats', orderByChild: 'teamId', equalTo: teamId);

      for (final map in results) {
        final categoryIndex = map['category'] as int?;
        if (categoryIndex == null ||
            categoryIndex < 0 ||
            categoryIndex >= LeaderCategory.values.length) {
          continue;
        }

        final category = LeaderCategory.values[categoryIndex];
        final stat = await BestGameStat.fromMap(map);

        if (stat != null) {
          bestStats.setBestStat(
            category,
            stat.player,
            stat.game,
            stat.season,
            stat.value,
          );
        }
      }
    } catch (e) {
      // If table doesn't exist or there's an error, return empty stats
    }
    return bestStats;
  }

  /// Check if we have cached stats
  bool get hasCachedStats => _bestStats.isNotEmpty;
}
