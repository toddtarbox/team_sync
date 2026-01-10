import 'dart:collection';

import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/stat_leaders.dart';

class BestSeasonStat {
  final Player player;
  final Season season;
  final int value;

  BestSeasonStat(
      {required this.player, required this.season, required this.value});
}

class BestSeasonStats implements StatLeaders {
  final HashMap<String, BestSeasonStat> _bestStats =
      HashMap<String, BestSeasonStat>();

  void setBestStat(String category, Player player, Season season, int value) {
    _bestStats[category] =
        BestSeasonStat(player: player, season: season, value: value);
  }

  BestSeasonStat? getBestStat(String category) {
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
}
