import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season_stats.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';

class Season {
  final int id;
  final String name;
  final int teamId;
  String? logoUrl;

  late Team team;
  List<Game> games = [];
  List<Player> players = [];
  List<Team> teams = [];

  Season(
      {required this.id,
      required this.name,
      required this.teamId,
      this.logoUrl});

  factory Season.fromMap(Map<dynamic, dynamic> map) {
    return Season(
        id: map['id'],
        name: map['name'],
        teamId: map['teamId'],
        logoUrl: map['logoUrl']);
  }

  static Future<List<Season>> fromTeamId(int teamId) async {
    final results = await DatabaseService.instance
        .query('Seasons', orderByChild: 'teamId', equalTo: teamId);
    final seasons = results.map((s) => Season.fromMap(s)).toList();
    // Sort by id in descending order (most recent first)
    seasons.sort((a, b) => b.id.compareTo(a.id));
    return seasons;
  }

  Future<void> load() async {
    team = await Team.fromId(teamId);
    games = await Game.listFromSeasonId(id);
    players = await Player.listFromTeamIdSeasonId(team.id, id);

    final teamResults = await DatabaseService.instance.query('Teams');
    teams = teamResults.map((g) => Team.fromMap(g)).toList(growable: false);
    teams.sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  Future<SeasonStats?> getStats() async {
    try {
      final results = await DatabaseService.instance
          .query('Events', orderByChild: 'seasonId', equalTo: id);
      return SeasonStats.fromMap(teamId, id, results);
    } catch (ex) {
      return null;
    }
  }
}
