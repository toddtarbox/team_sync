import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:team_sync/services/database_service.dart';

class Player {
  final int id;
  final int teamId;
  final int seasonId;
  String firstName;
  String lastName;
  int number;
  String? profileImage;
  String? actionPhoto; // Action photo for baseball-style player cards
  String? editPin; // 4-digit PIN for player self-editing on web

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
      this.profileImage,
      this.actionPhoto,
      this.editPin});

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
        profileImage: map['profileImage'],
        actionPhoto: map['actionPhoto'],
        editPin: map['editPin']);
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

  static Future<Player?> singleFromIdSeasonId(int id, int seasonId) async {
    final results = await DatabaseService.instance
        .query('Players', orderByChild: 'id', equalTo: id);
    final filtered = results.where((r) => r['seasonId'] == seasonId).toList();
    if (filtered.isEmpty) {
      return null;
    }

    return Player.fromMap(filtered.first);
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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'teamId': teamId,
      'seasonId': seasonId,
      'firstName': firstName,
      'lastName': lastName,
      'number': number,
      'profileImage': profileImage,
      'actionPhoto': actionPhoto,
      'editPin': editPin,
    };
  }

  Future<void> save() async {
    // Find the database key for this player
    final candidates = await DatabaseService.instance
        .query('Players', orderByChild: 'id', equalTo: id);
    for (final c in candidates) {
      if (c['seasonId'] == seasonId) {
        final k = c['_key']?.toString();
        if (k != null) {
          await DatabaseService.instance.update(
            'Players',
            toMap(),
            key: k,
          );
          return;
        }
      }
    }
  }

  /// Save player profile using PIN authentication (web only)
  /// This uses a Cloud Function to bypass authentication requirements
  Future<void> saveWithPin(String pin) async {
    if (!kIsWeb) {
      // On mobile, use regular save
      return save();
    }

    try {
      // Get the full database path from DatabaseService
      final dbPath = DatabaseService.instance.fullDatabasePath;
      if (dbPath.isEmpty) {
        throw Exception('No database path available');
      }

      // Call Cloud Function
      final callable = FirebaseFunctions.instance.httpsCallable(
        'updatePlayerWithPin',
      );

      final result = await callable.call<Map<String, dynamic>>({
        'databasePath': dbPath,
        'playerId': id,
        'seasonId': seasonId,
        'pin': pin,
        'updates': {
          'profileImage': profileImage,
          'actionPhoto': actionPhoto,
          'firstName': firstName,
          'lastName': lastName,
          'number': number,
          if (editPin != null) 'editPin': editPin,
        },
      });

      if (result.data['success'] != true) {
        throw Exception(result.data['message'] ?? 'Update failed');
      }
    } catch (e) {
      throw Exception('Failed to update player profile: $e');
    }
  }

  /// Regenerate PIN when exiting edit mode (web only)
  /// Returns the new PIN to display to the user
  static Future<String?> regeneratePin(
      int playerId, int seasonId, String currentPin) async {
    if (!kIsWeb) {
      return null; // No PIN regeneration on mobile
    }

    try {
      // Get the full database path from DatabaseService
      final dbPath = DatabaseService.instance.fullDatabasePath;
      if (dbPath.isEmpty) {
        throw Exception('No database path available');
      }

      // Call Cloud Function
      final callable = FirebaseFunctions.instance.httpsCallable(
        'regeneratePlayerPin',
      );

      final result = await callable.call<Map<String, dynamic>>({
        'databasePath': dbPath,
        'playerId': playerId,
        'seasonId': seasonId,
        'currentPin': currentPin,
      });

      if (result.data['success'] != true) {
        throw Exception('Failed to regenerate PIN');
      }

      return result.data['newPin'] as String?;
    } catch (e) {
      throw Exception('Failed to regenerate PIN: $e');
    }
  }
}
