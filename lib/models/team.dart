import 'package:equatable/equatable.dart';
import 'package:sqflite/sqflite.dart';
import 'package:team_sync/models/career_stats.dart';
import 'package:team_sync/models/game.dart';

class Team extends Equatable {
  final int id;
  final String fullName;
  final String shortName;

  const Team(
      {required this.id, required this.fullName, required this.shortName});

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

  Future<CareerStats?> getCareerStats(Database db, int teamId) async {
    try {
      final results =
          await db.query('Events', where: 'teamId=?', whereArgs: [teamId]);
      return CareerStats.fromMap(id, results);
    } catch (ex) {
      return null;
    }
  }

  Future<List<Game>> getGameHistory(Database db, int teamId) async {
    try {
      return Game.listFromTeamId(db, teamId);
    } catch (ex) {
      return [];
    }
  }

  @override
  List<Object?> get props => [id];
}
