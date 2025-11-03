import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/season_stats.dart';

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
}
