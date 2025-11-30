import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
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
    // Add null safety checks for required integer fields
    final id = map['id'];
    final teamId = map['teamId'];
    final seasonId = map['seasonId'];
    final number = map['number'];

    if (id == null) {
      throw Exception('Player map missing required field: id');
    }
    if (teamId == null) {
      throw Exception('Player map missing required field: teamId');
    }
    if (seasonId == null) {
      throw Exception('Player map missing required field: seasonId');
    }

    return Player(
        id: id is int ? id : int.parse(id.toString()),
        teamId: teamId is int ? teamId : int.parse(teamId.toString()),
        seasonId: seasonId is int ? seasonId : int.parse(seasonId.toString()),
        firstName: map['firstName'] ?? '',
        lastName: map['lastName'] ?? '',
        number: number != null
            ? (number is int ? number : int.parse(number.toString()))
            : 0,
        profileImage: map['profileImage'],
        actionPhoto: map['actionPhoto'],
        editPin:
            null); // Never load PIN from database - validation is server-side only
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

    try {
      final results = await DatabaseService.instance
          .query('Players', orderByChild: 'id', equalTo: id);
      if (results.isNotEmpty) {
        return Player.fromMap(results.first);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint('Error loading player with id=$id: $e');
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

    // Map with error handling to skip corrupt records
    final players = <Player>[];
    for (var playerMap in filtered) {
      try {
        players.add(Player.fromMap(playerMap));
      } catch (e) {
        debugPrint('Skipping corrupt player record in season $seasonId: $e');
        // Continue to next player instead of crashing
      }
    }

    players.sort((a, b) => a.displayName.compareTo(b.displayName));
    return players;
  }

  static Future<Player?> singleFromIdSeasonId(int id, int seasonId) async {
    try {
      final results = await DatabaseService.instance
          .query('Players', orderByChild: 'id', equalTo: id);
      final filtered = results.where((r) => r['seasonId'] == seasonId).toList();
      if (filtered.isEmpty) {
        return null;
      }

      return Player.fromMap(filtered.first);
    } catch (e) {
      debugPrint('Error loading player with id=$id, seasonId=$seasonId: $e');
      return null;
    }
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

  /// Find the latest available profile or action photo for this player across all seasons
  /// Returns a map with 'profileImage' and 'actionPhoto' keys
  /// Uses images from most recent season where they exist
  Future<Map<String, String?>> findLatestAvailableImages() async {
    // If current player has images, return them
    if ((profileImage != null && profileImage!.isNotEmpty) ||
        (actionPhoto != null && actionPhoto!.isNotEmpty)) {
      return {
        'profileImage': profileImage,
        'actionPhoto': actionPhoto,
      };
    }

    // Query all instances of this player across all seasons for this team
    final results = await DatabaseService.instance
        .query('Players', orderByChild: 'id', equalTo: id);

    // Filter to same team and convert to Player objects
    final allPlayerInstances = results
        .where((r) => r['teamId'] == teamId)
        .map((r) => Player.fromMap(r))
        .toList();

    // Sort by seasonId descending (most recent first)
    allPlayerInstances.sort((a, b) => b.seasonId.compareTo(a.seasonId));

    // Find the most recent images
    String? latestProfileImage;
    String? latestActionPhoto;

    for (final playerInstance in allPlayerInstances) {
      // Get profile image from most recent season that has it
      if (latestProfileImage == null &&
          playerInstance.profileImage != null &&
          playerInstance.profileImage!.isNotEmpty) {
        latestProfileImage = playerInstance.profileImage;
      }

      // Get action photo from most recent season that has it
      if (latestActionPhoto == null &&
          playerInstance.actionPhoto != null &&
          playerInstance.actionPhoto!.isNotEmpty) {
        latestActionPhoto = playerInstance.actionPhoto;
      }

      // If we found both, we can stop
      if (latestProfileImage != null && latestActionPhoto != null) {
        break;
      }
    }

    return {
      'profileImage': latestProfileImage,
      'actionPhoto': latestActionPhoto,
    };
  }
}
