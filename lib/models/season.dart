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
  bool? isFromImport;

  late Team team;
  List<Game> games = [];
  List<Player> players = [];
  List<Team> teams = [];

  Season(
      {required this.id,
      required this.name,
      required this.teamId,
      this.logoUrl,
      this.isFromImport});

  factory Season.fromMap(Map<dynamic, dynamic> map) {
    // Add null safety checks for required integer fields
    final id = map['id'];
    final teamId = map['teamId'];

    if (id == null) {
      throw Exception('Season map missing required field: id');
    }
    if (teamId == null) {
      throw Exception('Season map missing required field: teamId');
    }

    return Season(
        id: id is int ? id : int.parse(id.toString()),
        name: map['name'] ?? 'Unnamed Season',
        teamId: teamId is int ? teamId : int.parse(teamId.toString()),
        logoUrl: map['logoUrl'],
        isFromImport: map['isFromImport']);
  }

  static Future<List<Season>> fromTeamId(int teamId) async {
    final results = await DatabaseService.instance
        .query('Seasons', orderByChild: 'teamId', equalTo: teamId);
    final seasons = results.map((s) => Season.fromMap(s)).toList();
    // Sort by name in descending order (most recent first)
    seasons.sort((a, b) => b.name.compareTo(a.name));
    return seasons;
  }

  Future<void> load() async {
    team = await Team.fromId(teamId);
    games = await Game.listFromSeasonId(id);
    players = await Player.listFromTeamIdSeasonId(team.id, id);
    teams = await Team.listFromSeasonId(id);
    teams.sort((a, b) => a.fullName.compareTo(b.fullName));
  }

  Future<SeasonStats?> getStats() async {
    try {
      final results = await DatabaseService.instance
          .query('Events', orderByChild: 'seasonId', equalTo: id);

      // Filter out events from scrimmage games
      final seasonGames = await Game.listFromSeasonId(id);
      final scrimmageGameIds =
          seasonGames.where((g) => g.isScrimmage).map((g) => g.id).toSet();

      final filteredResults = results
          .where((event) => !scrimmageGameIds.contains(event['gameId']))
          .toList();

      return SeasonStats.fromMap(teamId, id, filteredResults);
    } catch (ex) {
      return null;
    }
  }
}
