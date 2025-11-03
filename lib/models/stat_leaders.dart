import 'dart:collection';

import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season_stats.dart';

abstract class StatLeaders {
  Future<HashMap<Player, int>> getStatPlayers(LeaderCategory category);
}
