import 'package:team_sync/features/players/models/player.dart';

class CareerStatEntry {
  final Player player;
  final int value;
  final String? displayValue;

  CareerStatEntry(
      {required this.player, required this.value, this.displayValue});
}
