import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';

class Team {
  final int id;
  final String fullName;
  final String shortName;

  Team({required this.id, required this.fullName, required this.shortName});

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
        id: map['id'], fullName: map['fullName'], shortName: map['shortName']);
  }

  static Future<Team> fromId(Database db, int id) async {
    final results = await db.query('Teams', where: 'id=?', whereArgs: [id]);
    return Team.fromMap(results.first);
  }

  static Future<List<Team>> all(Database db) async {
    final results = await db.query('Teams');
    return results.map((t) => Team.fromMap(t)).toList(growable: false);
  }
}
