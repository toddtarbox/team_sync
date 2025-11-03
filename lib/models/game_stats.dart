import 'dart:collection';

import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season_stats.dart';
import 'package:team_sync/models/stat_leaders.dart';

class GameStats implements StatLeaders {
  @override
  Future<HashMap<Player, int>> getStatPlayers(LeaderCategory category) async {
    return HashMap<Player, int>();
  }
}
