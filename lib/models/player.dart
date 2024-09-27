import 'package:sqflite/sqflite.dart';

class Player {
  final int id;
  final int teamId;
  final int seasonId;
  String firstName;
  String lastName;
  int number;

  String get displayName {
    return '$firstName $lastName';
  }

  Player(
      {required this.id,
      required this.teamId,
      required this.seasonId,
      required this.firstName,
      required this.lastName,
      required this.number});

  static initial({required int teamId, required int seasonId}) {
    return Player(
        id: -1,
        teamId: teamId,
        seasonId: seasonId,
        firstName: '',
        lastName: '',
        number: 0);
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
        id: map['id'],
        teamId: map['teamId'],
        seasonId: map['seasonId'],
        firstName: map['firstName'],
        lastName: map['lastName'],
        number: map['number']);
  }

  static Future<Player?> fromId(Database db, int id) async {
    final results = await db.query('Players', where: 'id=?', whereArgs: [id]);
    if (results.isNotEmpty) {
      return Player.fromMap(results.first);
    } else {
      return null;
    }
  }

  static Future<List<Player>> listFromTeamIdSeasonId(
      Database db, int teamId, int seasonId) async {
    final results = await db.query('Players',
        where: 'teamId=? AND seasonId=?', whereArgs: [teamId, seasonId]);

    final players =
        results.map((p) => Player.fromMap(p)).toList(growable: false);
    players.sort((a, b) => a.displayName.compareTo(b.displayName));

    return players;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is Player) {
      return id == other.id;
    }

    return false;
  }
}
