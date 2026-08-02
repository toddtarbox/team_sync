import 'dart:collection';
import 'package:team_sync/features/games/models/game.dart';
import 'package:team_sync/features/players/models/player.dart';
import 'package:team_sync/features/seasons/models/season.dart';
import 'package:team_sync/features/seasons/models/stat_leaders.dart';
import 'package:team_sync/core/services/database_service.dart';

class BestGameStat {
  final Player player;
  final Game game;
  final Season season;
  final int value;

  final String? displayValue;

  BestGameStat(
      {required this.player,
      required this.game,
      required this.season,
      required this.value,
      this.displayValue});

  Map<String, dynamic> toMap(int teamId, String category) {
    return {
      'id': '${teamId}_$category',
      'teamId': teamId,
      'category': category,
      'playerId': player.id,
      'gameId': game.id,
      'seasonId': season.id,
      'value': value,
      'displayValue': displayValue,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  static Future<BestGameStat?> fromMap(Map<String, dynamic> map) async {
    try {
      final playerId = map['playerId'] as int?;
      final gameId = map['gameId'] as int?;
      final seasonId = map['seasonId'] as int?;
      final value = map['value'] as int?;
      final displayValue = map['displayValue'] as String?;

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
        displayValue: displayValue,
      );
    } catch (e) {
      return null;
    }
  }
}

class BestGameStats implements StatLeaders {
  final HashMap<String, BestGameStat> _bestStats =
      HashMap<String, BestGameStat>();

  void setBestStat(String category, Player player, Game game, Season season,
      int value, String? displayValue) {
    _bestStats[category] = BestGameStat(
        player: player,
        game: game,
        season: season,
        value: value,
        displayValue: displayValue);
  }

  BestGameStat? getBestStat(String category) {
    return _bestStats[category];
  }

  Iterable<String> get categories => _bestStats.keys;

  @override
  Future<HashMap<Player, int>> getStatPlayers(String category) async {
    final bestStat = _bestStats[category];
    if (bestStat != null) {
      return HashMap.fromEntries([MapEntry(bestStat.player, bestStat.value)]);
    }
    return HashMap<Player, int>();
  }

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
        // Handle both old int-based and new string-based categories if needed
        // For strict string refactoring, we expect String
        final category = map['category'];

        if (category is String) {
          final stat = await BestGameStat.fromMap(map);
          // Verify category is valid for current sport? Maybe not strictly required
          if (stat != null) {
            bestStats.setBestStat(
              category,
              stat.player,
              stat.game,
              stat.season,
              stat.value,
              stat.displayValue,
            );
          }
        }
      }
    } catch (e) {
      // If table doesn't exist or there's an error, return empty stats
    }
    return bestStats;
  }

  /// Check if we have cached stats
  bool get hasCachedStats => _bestStats.isNotEmpty;

  /// Clear cached best game stats from the database for a team
  static Future<void> clearCache(int teamId) async {
    try {
      final results = await DatabaseService.instance
          .query('BestGameStats', orderByChild: 'teamId', equalTo: teamId);

      for (final map in results) {
        final id = map['id'] as String?;
        if (id != null) {
          await DatabaseService.instance.delete('BestGameStats', key: id);
        }
      }
    } catch (e) {
      // If table doesn't exist or there's an error, that's fine
    }
  }
}
