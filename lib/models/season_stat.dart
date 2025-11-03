import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';

class SeasonStat {
  final Player player;
  final Season season;
  final int value;

  SeasonStat({required this.player, required this.season, required this.value});
}
