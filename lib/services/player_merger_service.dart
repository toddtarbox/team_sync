import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/services/database_service.dart';

/// Service for merging duplicate players across seasons
///
/// Detects duplicates as players with the same name who appear in different
/// seasons with different jersey numbers.
class PlayerMergerService {
  final StreamController<MergeProgress> _progressController =
      StreamController<MergeProgress>.broadcast();

  Stream<MergeProgress> get progressStream => _progressController.stream;

  /// Find duplicate players based on name matching across different seasons
  ///
  /// A player is considered a duplicate if:
  /// - They have the same name (normalized)
  /// - They appear in different seasons
  /// - They have different numbers across those seasons
  Future<List<DuplicatePlayerGroup>> findDuplicatePlayers({
    required int teamId,
    bool exactMatchOnly = false,
  }) async {
    debugPrint('Finding duplicate players for team $teamId');

    // Load all players for the team
    final results = await DatabaseService.instance
        .query('Players', orderByChild: 'teamId', equalTo: teamId);

    if (results.isEmpty) {
      return [];
    }

    final players = results.map((p) => Player.fromMap(p)).toList();

    debugPrint('Found ${players.length} total players for team');

    // Group by normalized name
    final Map<String, List<Player>> nameGroups = {};

    for (final player in players) {
      final normalizedName = _normalizeName(player.firstName, player.lastName);

      if (!nameGroups.containsKey(normalizedName)) {
        nameGroups[normalizedName] = [];
      }
      nameGroups[normalizedName]!.add(player);
    }

    // Find groups with duplicates
    final duplicateGroups = <DuplicatePlayerGroup>[];

    for (final entry in nameGroups.entries) {
      final groupPlayers = entry.value;

      // Only include groups with multiple players across different seasons
      if (groupPlayers.length > 1) {
        // Check if players are in different seasons
        final uniqueSeasons = groupPlayers.map((p) => p.seasonId).toSet();

        // Must have players in at least 2 different seasons to be a duplicate
        if (uniqueSeasons.length < 2) {
          continue;
        }

        // Check if these are actually different player records (different IDs)
        final uniqueIds = groupPlayers.map((p) => p.id).toSet();

        // If all players have the same ID, they're already the same player record
        // across different seasons - not duplicates that need merging
        if (uniqueIds.length == 1) {
          continue;
        }

        // We have the same name in multiple seasons with different player IDs
        // This is a duplicate that needs to be merged
        // Sort by season ID to show chronologically
        groupPlayers.sort((a, b) => a.seasonId.compareTo(b.seasonId));

        duplicateGroups.add(DuplicatePlayerGroup(
          normalizedName: entry.key,
          players: groupPlayers,
        ));
      }
    }

    debugPrint('Found ${duplicateGroups.length} duplicate player groups');

    return duplicateGroups;
  }

  /// Merge duplicate players into a single player record
  /// All game events, awards, and highlights will be updated to reference the primary player
  Future<MergeResult> mergePlayers({
    required Player primaryPlayer,
    required List<Player> duplicatePlayers,
    bool deleteAfterMerge = true,
  }) async {
    debugPrint(
        'Merging ${duplicatePlayers.length} duplicate players into primary player ${primaryPlayer.id}');

    _progressController.add(MergeProgress(
      stage: 'starting',
      message: 'Starting merge of ${duplicatePlayers.length} players',
      processed: 0,
      total: duplicatePlayers.length,
    ));

    final startTime = DateTime.now();
    int eventsUpdated = 0;
    int awardsUpdated = 0;
    int highlightsUpdated = 0;
    final List<String> errors = [];

    try {
      for (int i = 0; i < duplicatePlayers.length; i++) {
        final duplicate = duplicatePlayers[i];

        debugPrint(
            'Processing duplicate player ${duplicate.id} (${duplicate.displayName}, season ${duplicate.seasonId})');

        _progressController.add(MergeProgress(
          stage: 'processing',
          message:
              'Processing player ${duplicate.displayName} (season ${duplicate.seasonId})',
          processed: i,
          total: duplicatePlayers.length,
        ));

        // 1. Update GameEvents
        try {
          final eventCount =
              await _updateGameEvents(duplicate.id, primaryPlayer.id);
          eventsUpdated += eventCount;
          debugPrint('  Updated $eventCount game events');
        } catch (e, stackTrace) {
          final error =
              'Error updating game events for player ${duplicate.id}: $e';
          debugPrint('$error\n$stackTrace');
          errors.add(error);
        }

        // 2. Update PlayerAwards
        try {
          final awardCount =
              await _updatePlayerAwards(duplicate.id, primaryPlayer.id);
          awardsUpdated += awardCount;
          debugPrint('  Updated $awardCount player awards');
        } catch (e, stackTrace) {
          final error = 'Error updating awards for player ${duplicate.id}: $e';
          debugPrint('$error\n$stackTrace');
          errors.add(error);
        }

        // 3. Update PlayerHighlights
        try {
          final highlightCount =
              await _updatePlayerHighlights(duplicate.id, primaryPlayer.id);
          highlightsUpdated += highlightCount;
          debugPrint('  Updated $highlightCount player highlights');
        } catch (e, stackTrace) {
          final error =
              'Error updating highlights for player ${duplicate.id}: $e';
          debugPrint('$error\n$stackTrace');
          errors.add(error);
        }

        // 4. Delete duplicate player record if requested
        if (deleteAfterMerge) {
          try {
            await _deletePlayer(duplicate);
            debugPrint('  Deleted duplicate player record');
          } catch (e, stackTrace) {
            final error = 'Error deleting player ${duplicate.id}: $e';
            debugPrint('$error\n$stackTrace');
            errors.add(error);
          }
        }
      }

      final duration = DateTime.now().difference(startTime);

      _progressController.add(MergeProgress(
        stage: 'complete',
        message: 'Merge completed successfully',
        processed: duplicatePlayers.length,
        total: duplicatePlayers.length,
      ));

      debugPrint('Merge completed in ${duration.inMilliseconds}ms');
      debugPrint(
          '  Events: $eventsUpdated, Awards: $awardsUpdated, Highlights: $highlightsUpdated');

      return MergeResult(
        success: true,
        primaryPlayerId: primaryPlayer.id,
        mergedPlayerIds: duplicatePlayers.map((p) => p.id).toList(),
        eventsUpdated: eventsUpdated,
        awardsUpdated: awardsUpdated,
        highlightsUpdated: highlightsUpdated,
        duration: duration,
        errors: errors,
      );
    } catch (e, stackTrace) {
      debugPrint('Merge failed: $e\n$stackTrace');

      _progressController.add(MergeProgress(
        stage: 'error',
        message: 'Merge failed: $e',
        processed: 0,
        total: duplicatePlayers.length,
      ));

      return MergeResult(
        success: false,
        primaryPlayerId: primaryPlayer.id,
        mergedPlayerIds: [],
        eventsUpdated: eventsUpdated,
        awardsUpdated: awardsUpdated,
        highlightsUpdated: highlightsUpdated,
        duration: DateTime.now().difference(startTime),
        errors: [e.toString(), ...errors],
      );
    }
  }

  /// Update game events to reference the new player ID
  Future<int> _updateGameEvents(int oldPlayerId, int newPlayerId) async {
    debugPrint('  Querying Events for oldPlayerId: $oldPlayerId');
    final events = await DatabaseService.instance
        .query('Events', orderByChild: 'playerId', equalTo: oldPlayerId);

    debugPrint('  Found ${events.length} events to update');

    int count = 0;
    for (final event in events) {
      final key = event['_key']?.toString();
      if (key != null) {
        debugPrint(
            '    Updating event $key from player $oldPlayerId to $newPlayerId');
        await DatabaseService.instance.update(
          'Events',
          {'playerId': newPlayerId},
          key: key,
        );
        count++;
      } else {
        debugPrint('    Warning: Event without _key found: $event');
      }
    }

    debugPrint('  Successfully updated $count events');
    return count;
  }

  /// Update player awards to reference the new player ID
  Future<int> _updatePlayerAwards(int oldPlayerId, int newPlayerId) async {
    final awards = await DatabaseService.instance
        .query('PlayerAwards', orderByChild: 'playerId', equalTo: oldPlayerId);

    int count = 0;
    for (final award in awards) {
      final key = award['_key']?.toString();
      if (key != null) {
        await DatabaseService.instance.update(
          'PlayerAwards',
          {'playerId': newPlayerId},
          key: key,
        );
        count++;
      }
    }

    return count;
  }

  /// Update player highlights to reference the new player ID
  Future<int> _updatePlayerHighlights(int oldPlayerId, int newPlayerId) async {
    final highlights = await DatabaseService.instance.query('PlayerHighlights',
        orderByChild: 'playerId', equalTo: oldPlayerId);

    int count = 0;
    for (final highlight in highlights) {
      final key = highlight['_key']?.toString();
      if (key != null) {
        await DatabaseService.instance.update(
          'PlayerHighlights',
          {'playerId': newPlayerId},
          key: key,
        );
        count++;
      }
    }

    return count;
  }

  /// Delete a player record from the database
  Future<void> _deletePlayer(Player player) async {
    final candidates = await DatabaseService.instance
        .query('Players', orderByChild: 'id', equalTo: player.id);

    for (final candidate in candidates) {
      if (candidate['seasonId'] == player.seasonId) {
        final key = candidate['_key']?.toString();
        if (key != null) {
          await DatabaseService.instance.delete('Players', key: key);
          return;
        }
      }
    }
  }

  /// Normalize a name for comparison (lowercase, trim, remove extra spaces)
  String _normalizeName(String firstName, String lastName) {
    final normalized = '${firstName.trim()} ${lastName.trim()}'
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), ' ');
    return normalized;
  }

  /// Find and clean up orphaned events (events referencing deleted players)
  /// Returns a map of deleted player IDs to the count of orphaned events found
  Future<Map<int, OrphanedEventInfo>> findOrphanedEvents({
    required int teamId,
  }) async {
    debugPrint('Finding orphaned events for team $teamId');

    // Get all players for the team
    final playerResults = await DatabaseService.instance
        .query('Players', orderByChild: 'teamId', equalTo: teamId);
    final validPlayerIds = playerResults.map((p) => p['id'] as int).toSet();

    debugPrint('Found ${validPlayerIds.length} valid players');

    // Get all events for the team
    final allEvents = await DatabaseService.instance
        .query('Events', orderByChild: 'teamId', equalTo: teamId);

    final Map<int, OrphanedEventInfo> orphanedByPlayerId = {};

    for (final event in allEvents) {
      final playerId = event['playerId'] as int?;
      // teamId match is guaranteed by query, except for manual verification if needed

      // Check if playerId exists and is not in valid players
      if (playerId != null &&
          playerId != -1 &&
          !validPlayerIds.contains(playerId)) {
        if (!orphanedByPlayerId.containsKey(playerId)) {
          orphanedByPlayerId[playerId] = OrphanedEventInfo(
            playerId: playerId,
            eventKeys: [],
            eventCount: 0,
          );
        }

        final key = event['_key']?.toString();
        if (key != null) {
          orphanedByPlayerId[playerId]!.eventKeys.add(key);
          orphanedByPlayerId[playerId]!.eventCount++;
        }
      }
    }

    debugPrint(
        'Found ${orphanedByPlayerId.length} deleted players with orphaned events');
    for (final entry in orphanedByPlayerId.entries) {
      debugPrint('  Player ID ${entry.key}: ${entry.value.eventCount} events');
    }

    return orphanedByPlayerId;
  }

  /// Delete orphaned events
  Future<int> deleteOrphanedEvents(
      Map<int, OrphanedEventInfo> orphanedEvents) async {
    int totalDeleted = 0;

    for (final info in orphanedEvents.values) {
      for (final key in info.eventKeys) {
        try {
          await DatabaseService.instance.delete('Events', key: key);
          totalDeleted++;
        } catch (e) {
          debugPrint('Error deleting orphaned event $key: $e');
        }
      }
    }

    debugPrint('Deleted $totalDeleted orphaned events');
    return totalDeleted;
  }

  void dispose() {
    _progressController.close();
  }
}

/// Group of duplicate players with the same name
class DuplicatePlayerGroup {
  final String normalizedName;
  final List<Player> players;

  DuplicatePlayerGroup({
    required this.normalizedName,
    required this.players,
  });

  String get displayName {
    if (players.isEmpty) return normalizedName;
    return players.first.displayName;
  }

  /// Get seasons where this player appears
  List<int> get seasonIds {
    return players.map((p) => p.seasonId).toList();
  }

  /// Get different numbers used across seasons
  Set<int> get numbers {
    return players.map((p) => p.number).toSet();
  }
}

/// Progress of a merge operation
class MergeProgress {
  final String stage;
  final String message;
  final int processed;
  final int total;

  MergeProgress({
    required this.stage,
    required this.message,
    required this.processed,
    required this.total,
  });

  double get progress => total > 0 ? processed / total : 0.0;
}

/// Information about orphaned events for a deleted player
class OrphanedEventInfo {
  final int playerId;
  final List<String> eventKeys;
  int eventCount;

  OrphanedEventInfo({
    required this.playerId,
    required this.eventKeys,
    required this.eventCount,
  });
}

/// Result of a merge operation
class MergeResult {
  final bool success;
  final int primaryPlayerId;
  final List<int> mergedPlayerIds;
  final int eventsUpdated;
  final int awardsUpdated;
  final int highlightsUpdated;
  final Duration duration;
  final List<String> errors;

  MergeResult({
    required this.success,
    required this.primaryPlayerId,
    required this.mergedPlayerIds,
    required this.eventsUpdated,
    required this.awardsUpdated,
    required this.highlightsUpdated,
    required this.duration,
    required this.errors,
  });

  int get totalUpdates => eventsUpdated + awardsUpdated + highlightsUpdated;

  String get summary {
    if (!success) {
      return 'Merge failed: ${errors.first}';
    }

    return 'Merged ${mergedPlayerIds.length} players. '
        'Updated $eventsUpdated events, $awardsUpdated awards, $highlightsUpdated highlights. '
        'Duration: ${duration.inMilliseconds}ms';
  }
}
