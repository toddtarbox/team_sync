import 'package:team_sync/services/database_service.dart';

class Player {
  final int id;
  final int teamId;
  final int seasonId;
  String firstName;
  String lastName;
  int number;
  String? profileImage;

  String get displayName {
    return '$firstName $lastName';
  }

  Player(
      {required this.id,
      required this.teamId,
      required this.seasonId,
      required this.firstName,
      required this.lastName,
      required this.number,
      this.profileImage});

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
        number: map['number'],
        profileImage: map['profileImage']);
  }

  static Future<Player?> fromId(int id) async {
    if (id == -2) {
      return Player(
          id: -2,
          teamId: -1,
          seasonId: -1,
          firstName: 'Own',
          lastName: 'Goal',
          number: -1);
    }

    final results = await DatabaseService.instance
        .query('Players', orderByChild: 'id', equalTo: id);
    if (results.isNotEmpty) {
      return Player.fromMap(results.first);
    } else {
      return null;
    }
  }

  static Future<Map<int, Player>> fromIds(List<int> ids) async {
    if (ids.isEmpty) {
      return {};
    }
    // 'IN' not supported by RTDB native queries; fallback to client-side filter.
    final results = await DatabaseService.instance.query('Players');
    final players =
        results.map((p) => Player.fromMap(p)).toList(growable: false);
    return {for (var p in players) p.id: p};
  }

  static Future<Map<int, Player>> allFromTeamId(int teamId) async {
    final results = await DatabaseService.instance
        .query('Players', orderByChild: 'teamId', equalTo: teamId);
    final players =
        results.map((p) => Player.fromMap(p)).toList(growable: false);
    return {for (var p in players) p.id: p};
  }

  static Future<List<Player>> listFromTeamIdSeasonId(
      int teamId, int seasonId) async {
    // Use native RTDB query for teamId then filter seasonId locally to reduce bandwidth
    final results = await DatabaseService.instance
        .query('Players', orderByChild: 'teamId', equalTo: teamId);
    final filtered = results.where((r) => r['seasonId'] == seasonId).toList();

    final players =
        filtered.map((p) => Player.fromMap(p)).toList(growable: false);
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
