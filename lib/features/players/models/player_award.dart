import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:team_sync/features/seasons/models/season.dart';
import 'package:team_sync/core/services/database_service.dart';

/// Award or recognition for a player
class PlayerAward {
  final int id;
  final int playerId;
  final int seasonId;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? url;

  PlayerAward({
    required this.id,
    required this.playerId,
    required this.seasonId,
    required this.title,
    this.description,
    this.imageUrl,
    this.url,
  });

  factory PlayerAward.fromMap(Map<String, dynamic> map) {
    return PlayerAward(
      id: map['id'],
      playerId: map['playerId'],
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
      'playerId': playerId,
      'seasonId': seasonId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'url': url,
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
    // On web, we CANNOT save without PIN authentication
    if (kIsWeb) {
      throw Exception(
          'Cannot save PlayerAward on web without PIN authentication. '
          'Use saveWithPin(pin) method instead. '
          'Awards can only be managed on web through the player profile page with PIN entry, '
          'or on mobile with proper authentication.');
    }

    await DatabaseService.instance.insert(
      'PlayerAwards',
      toMap(),
      key: id.toString(),
    );
  }

  /// Save award using PIN authentication (web only)
  Future<void> saveWithPin(String pin) async {
    if (!kIsWeb) {
      return save();
    }

    try {
      final dbService = DatabaseService.instance;
      final dbPath = dbService.fullDatabasePath;

      if (dbPath.isEmpty) {
        throw Exception('No database path available');
      }

      final callable = FirebaseFunctions.instance.httpsCallable(
        'updatePlayerWithPin',
      );

      final requestData = {
        'databasePath': dbPath,
        'playerId': playerId,
        'seasonId': seasonId,
        'pin': pin,
        'table': 'PlayerAwards',
        'updates': {
          'id': id,
          'title': title,
          'description': description,
          'imageUrl': imageUrl,
          'url': url,
        },
      };

      final result = await callable.call<Map<String, dynamic>>(requestData);

      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Update failed');
      }
    } catch (e) {
      throw Exception('Failed to save award: $e');
    }
  }

  Future<void> delete() async {
    await DatabaseService.instance.delete(
      'PlayerAwards',
      key: id.toString(),
    );
  }

  /// Delete award using PIN authentication (web only)
  Future<void> deleteWithPin(String pin) async {
    if (!kIsWeb) {
      return delete();
    }

    try {
      final dbService = DatabaseService.instance;
      final dbPath = dbService.fullDatabasePath;

      if (dbPath.isEmpty) {
        throw Exception('No database path available');
      }

      final callable = FirebaseFunctions.instance.httpsCallable(
        'updatePlayerWithPin',
      );

      final requestData = {
        'databasePath': dbPath,
        'playerId': playerId,
        'seasonId': seasonId,
        'pin': pin,
        'table': 'PlayerAwards',
        'operation': 'delete',
        'updates': {
          'id': id,
        },
      };

      final result = await callable.call<Map<String, dynamic>>(requestData);

      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Delete failed');
      }
    } catch (e) {
      throw Exception('Failed to delete award: $e');
    }
  }
}
