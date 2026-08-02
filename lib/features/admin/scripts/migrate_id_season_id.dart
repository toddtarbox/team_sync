import 'package:flutter/material.dart';

import 'package:team_sync/core/services/database_service.dart';

Future<void> migrateIdSeasonId() async {
  debugPrint('Starting migration for id_seasonId...');

  try {
    // 1. Fetch all players
    // We have to use the generic query because we want ALL players to check for missing keys
    // Note: This might be slow on large datasets, but it's a one-time migration.
    final allPlayersMap = await DatabaseService.instance.query('Players');

    int updatedCount = 0;
    int skippedCount = 0;
    int errorCount = 0;

    for (final playerMap in allPlayersMap) {
      try {
        final String? key = playerMap['_key']?.toString();
        if (key == null) {
          debugPrint('Skipping player with no key: ${playerMap['id']}');
          skippedCount++;
          continue;
        }

        // Check if id_seasonId already exists and is correct
        final currentIdSeasonId = playerMap['id_seasonId'];
        final id = playerMap['id'];
        final seasonId = playerMap['seasonId'];

        if (id == null || seasonId == null) {
          debugPrint(
              'Skipping invalid player record (missing id or seasonId): $key');
          skippedCount++;
          continue;
        }

        final expectedIdSeasonId = '${id}_$seasonId';

        if (currentIdSeasonId != expectedIdSeasonId) {
          // Needs update
          await DatabaseService.instance.update(
            'Players',
            {'id_seasonId': expectedIdSeasonId},
            key: key,
          );
          updatedCount++;
          if (updatedCount % 10 == 0) {
            debugPrint('Migrated $updatedCount players...');
          }
        } else {
          skippedCount++;
        }
      } catch (e) {
        debugPrint('Error migrating player record: $e');
        errorCount++;
      }
    }

    debugPrint('Migration complete!');
    debugPrint('Updated: $updatedCount');
    debugPrint('Skipped (already correct/invalid): $skippedCount');
    debugPrint('Errors: $errorCount');
  } catch (e) {
    debugPrint('Fatal error during migration: $e');
  }
}
