import 'dart:collection';

import 'package:team_sync/features/players/models/player.dart';
import 'package:team_sync/features/seasons/models/stat_leaders.dart';

class GameStats implements StatLeaders {
  @override
  Future<HashMap<Player, int>> getStatPlayers(String category) async {
    return HashMap<Player, int>();
  }
}
