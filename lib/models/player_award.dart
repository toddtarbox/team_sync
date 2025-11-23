import 'package:team_sync/models/season.dart';
import 'package:team_sync/services/database_service.dart';

/// Award or recognition for a player
class PlayerAward {
  final int id;
  final int playerId;
  final int seasonId;
  final String title;
  final String? description;
  final String? imageUrl;

  PlayerAward({
    required this.id,
    required this.playerId,
    required this.seasonId,
    required this.title,
    this.description,
    this.imageUrl,
  });

  factory PlayerAward.fromMap(Map<String, dynamic> map) {
    return PlayerAward(
      id: map['id'],
      playerId: map['playerId'],
      seasonId: map['seasonId'],
      title: map['title'],
      description: map['description'],
      imageUrl: map['imageUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playerId': playerId,
      'seasonId': seasonId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  static Future<List<PlayerAward>> listFromPlayerId(int playerId) async {
    final results = await DatabaseService.instance
        .query('PlayerAwards', orderByChild: 'playerId', equalTo: playerId);
    final awards = results.map((a) => PlayerAward.fromMap(a)).toList();

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
      'PlayerAwards',
      toMap(),
      key: id.toString(),
    );
  }

  Future<void> delete() async {
    await DatabaseService.instance.delete(
      'PlayerAwards',
      key: id.toString(),
    );
  }
}
