---
description: Run the migration to add id_seasonId to all players
---

1. Create a migration script file `lib/scripts/migrate_id_season_id.dart` with the following content:
```dart
import 'package:flutter/material.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/services/database_service.dart';

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
             debugPrint('Skipping invalid player record (missing id or seasonId): $key');
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
```

2. Register this script in your main app or a temporary button to execute it. 
   For example, you can add a temporary button in `SeasonPage`'s `build` method (only for admin/debug):

```dart
// Temporary migration button
ElevatedButton(
  onPressed: () async {
    await migrateIdSeasonId();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Migration started, check logs')),
    );
  },
  child: const Text('Run Migration'),
)
```

**Instruction:** 
To run this, simply create the file and call the function from anywhere in the connected app (e.g. from a button or `initState`).
