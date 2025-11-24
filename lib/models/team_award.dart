import 'package:team_sync/models/season.dart';
import 'package:team_sync/services/database_service.dart';

/// Award or recognition for a team (e.g., Tournament Winner, Championship)
class TeamAward {
  final int id;
  final int teamId;
  final int seasonId;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? url;

  TeamAward({
    required this.id,
    required this.teamId,
    required this.seasonId,
    required this.title,
    this.description,
    this.imageUrl,
    this.url,
  });

  factory TeamAward.fromMap(Map<String, dynamic> map) {
    return TeamAward(
      id: map['id'],
      teamId: map['teamId'],
      seasonId: map['seasonId'],
      title: map['title'],
      description: map['description'],
      imageUrl: map['imageUrl'],
      url: map['url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamId': teamId,
      'seasonId': seasonId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'url': url,
    };
  }

  static Future<List<TeamAward>> listFromSeasonId(int seasonId) async {
    final results = await DatabaseService.instance
        .query('TeamAwards', orderByChild: 'seasonId', equalTo: seasonId);
    final awards = results.map((a) => TeamAward.fromMap(a)).toList();

    // Sort by title
    awards.sort((a, b) => a.title.compareTo(b.title));

    return awards;
  }

  static Future<List<TeamAward>> listFromTeamId(int teamId) async {
    final results = await DatabaseService.instance
        .query('TeamAwards', orderByChild: 'teamId', equalTo: teamId);
    final awards = results.map((a) => TeamAward.fromMap(a)).toList();

    // Sort by season ID (most recent first), then by title
    awards.sort((a, b) {
      final seasonCompare = b.seasonId.compareTo(a.seasonId);
      if (seasonCompare != 0) return seasonCompare;
      return a.title.compareTo(b.title);
    });

    return awards;
  }

  /// Helper to get season name for display
  Future<String> getSeasonName() async {
    try {
      final seasonResults = await DatabaseService.instance
          .query('Seasons', orderByChild: 'id', equalTo: seasonId);
      if (seasonResults.isNotEmpty) {
        final season = Season.fromMap(seasonResults.first);
        return season.name;
      }
    } catch (e) {
      // Season not found
    }
    return 'Season $seasonId';
  }

  Future<void> save() async {
    await DatabaseService.instance.insert(
      'TeamAwards',
      toMap(),
      key: id.toString(),
    );
  }

  Future<void> delete() async {
    await DatabaseService.instance.delete(
      'TeamAwards',
      key: id.toString(),
    );
  }
}
