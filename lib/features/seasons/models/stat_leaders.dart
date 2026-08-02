import 'dart:collection';

import 'package:team_sync/features/players/models/player.dart';

abstract class StatLeaders {
  Future<HashMap<Player, int>> getStatPlayers(String category);
}
