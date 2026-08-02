import 'package:team_sync/features/players/models/player.dart';
import 'package:team_sync/features/seasons/models/season.dart';

class SeasonStat {
  final Player player;
  final Season season;
  final int value;

  final String? displayValue;

  SeasonStat(
      {required this.player,
      required this.season,
      required this.value,
      this.displayValue});
}
