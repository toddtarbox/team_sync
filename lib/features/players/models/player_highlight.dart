import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:team_sync/core/services/database_service.dart';

/// Independent highlight not tied to a game event
class PlayerHighlight {
  final int id;
  final int playerId;
  final String title;
  final String? description;
  final String videoUrl;
  final DateTime date;

  PlayerHighlight({
    required this.id,
    required this.playerId,
    required this.title,
    this.description,
    required this.videoUrl,
    required this.date,
  });

  factory PlayerHighlight.fromMap(Map<String, dynamic> map) {
    // Handle both ISO8601 string and millisecondsSinceEpoch formats
    DateTime date;
    final dateValue = map['date'];

    try {
      if (dateValue is int) {
        // Handle millisecondsSinceEpoch (from Cloud Function saves)
        date = DateTime.fromMillisecondsSinceEpoch(dateValue);
      } else if (dateValue is String) {
        // Handle ISO8601 string (from direct database saves)
        date = DateTime.parse(dateValue);
      } else {
        // Fallback to current date if format is unexpected
        print(
            'Warning: Unexpected date format for highlight ${map['id']}: $dateValue (${dateValue.runtimeType})');
        date = DateTime.now();
      }
    } catch (e) {
      print(
          'Error parsing date for highlight ${map['id']}: $e, value: $dateValue (${dateValue.runtimeType})');
      // Fallback to current date if parsing fails
      date = DateTime.now();
    }

    return PlayerHighlight(
      id: map['id'],
      playerId: map['playerId'],
      title: map['title'],
      description: map['description'],
      videoUrl: map['videoUrl'],
      date: date,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playerId': playerId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'date': date.toIso8601String(),
    };
  }

  static Future<List<PlayerHighlight>> listFromPlayerId(int playerId) async {
    final results = await DatabaseService.instance
        .query('PlayerHighlights', orderByChild: 'playerId', equalTo: playerId);
    final highlights = results.map((h) => PlayerHighlight.fromMap(h)).toList();
    highlights.sort((a, b) => b.date.compareTo(a.date)); // Most recent first
    return highlights;
  }

  Future<void> save() async {
    // On web, highlights must be saved via PIN authentication
    if (kIsWeb) {
      throw Exception('Direct save not allowed on web. '
          'Highlights can only be managed on web through the player profile page with PIN entry, '
          'or on mobile with proper authentication.');
    }

    await DatabaseService.instance.insert(
      'PlayerHighlights',
      toMap(),
      key: id.toString(),
    );
  }

  /// Save highlight using PIN authentication (web only)
  Future<void> saveWithPin(String pin, int seasonId) async {
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
        'table': 'PlayerHighlights',
        'updates': {
          'id': id,
          'title': title,
          'description': description,
          'videoUrl': videoUrl,
          'date': date.millisecondsSinceEpoch,
        },
      };

      final result = await callable.call<Map<String, dynamic>>(requestData);

      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Update failed');
      }
    } catch (e) {
      throw Exception('Failed to save highlight: $e');
    }
  }

  Future<void> delete() async {
    // On web, highlights must be deleted via PIN authentication
    if (kIsWeb) {
      throw Exception('Direct delete not allowed on web. '
          'Highlights can only be managed on web through the player profile page with PIN entry, '
          'or on mobile with proper authentication.');
    }

    await DatabaseService.instance.delete(
      'PlayerHighlights',
      key: id.toString(),
    );
  }

  /// Delete highlight using PIN authentication (web only)
  Future<void> deleteWithPin(String pin, int seasonId) async {
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
        'table': 'PlayerHighlights',
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
      throw Exception('Failed to delete highlight: $e');
    }
  }
}
