import 'package:sqflite/sqflite.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/team.dart';

class Season {
  final int id;
  final String name;
  final int teamId;

  late Team team;
  List<Game> games = [];
  List<Player> players = [];
  List<Team> teams = [];

  Season({required this.id, required this.name, required this.teamId});

  factory Season.fromMap(Map<dynamic, dynamic> map) {
    return Season(id: map['id'], name: map['name'], teamId: map['teamId']);
  }

  Future<void> load(Database db) async {
    team = await Team.fromId(db, teamId);
    games = await Game.listFromSeasonId(db, id);
    players = await Player.listFromTeamIdSeasonId(db, team.id, id);

    final teamResults = await db.query('Teams');
    teams = teamResults.map((g) => Team.fromMap(g)).toList(growable: false);
    teams.sort((a, b) => a.fullName.compareTo(b.fullName));
  }
}
