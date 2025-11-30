import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:team_sync/models/import_models.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/entity_matcher_service.dart';
import 'package:team_sync/services/import_validator_service.dart';

class DataImporterService {
  final ImportValidatorService _validator = ImportValidatorService();
  final EntityMatcherService _matcher = EntityMatcherService();

  final StreamController<ImportProgress> _progressController =
      StreamController<ImportProgress>.broadcast();

  Stream<ImportProgress> get progressStream => _progressController.stream;

  bool _isCancelled = false;

  /// Cancel ongoing import
  void cancelImport() {
    _isCancelled = true;
  }

  /// Import data rows with batch processing
  Future<ImportResult> importData({
    required List<ImportRow> rows,
    required String fileName,
    required String entityType,
    ImportConfig config = const ImportConfig(),
  }) async {
    _isCancelled = false;
    final importId = DateTime.now().millisecondsSinceEpoch.toString();
    final startTime = DateTime.now();
    final userId = FirebaseAuth.instance.currentUser?.uid;

    debugPrint('Starting import: $importId for $entityType');

    int successCount = 0;
    int skippedCount = 0;
    int errorCount = 0;

    final processedRows = <ImportRow>[];

    try {
      // Process in batches
      for (int i = 0; i < rows.length; i += config.batchSize) {
        if (_isCancelled) {
          debugPrint('Import cancelled by user');
          break;
        }

        final batchEnd = (i + config.batchSize < rows.length)
            ? i + config.batchSize
            : rows.length;
        final batch = rows.sublist(i, batchEnd);

        debugPrint(
            'Processing batch ${i ~/ config.batchSize + 1}: rows $i to ${batchEnd - 1}');

        // Process batch
        final batchResults = await _processBatch(
          batch,
          entityType,
          config,
        );

        processedRows.addAll(batchResults);

        // Count results
        for (final row in batchResults) {
          switch (row.status) {
            case ImportRowStatus.success:
              successCount++;
              break;
            case ImportRowStatus.skipped:
              skippedCount++;
              break;
            case ImportRowStatus.error:
              errorCount++;
              break;
            default:
              break;
          }
        }

        // Emit progress
        _progressController.add(ImportProgress(
          table: entityType,
          processed: processedRows.length,
          total: rows.length,
          stage: 'writing',
          message: 'Processed ${processedRows.length} of ${rows.length} rows',
        ));

        // Delay between batches to avoid rate limits
        if (batchEnd < rows.length) {
          await Future.delayed(Duration(milliseconds: config.batchDelayMs));
        }
      }

      final duration = DateTime.now().difference(startTime);

      final result = ImportResult(
        importId: importId,
        timestamp: startTime,
        fileName: fileName,
        entityType: entityType,
        totalRows: rows.length,
        successCount: successCount,
        skippedCount: skippedCount,
        errorCount: errorCount,
        rows: processedRows,
        duration: duration,
        userId: userId,
      );

      // Log import to database
      if (!config.validateOnly) {
        await _logImport(result);
      }

      _progressController.add(ImportProgress(
        table: entityType,
        processed: processedRows.length,
        total: rows.length,
        stage: _isCancelled ? 'cancelled' : 'done',
        message:
            'Import completed: $successCount success, $errorCount errors, $skippedCount skipped',
      ));

      debugPrint(
          'Import completed: $importId - Success: $successCount, Errors: $errorCount, Skipped: $skippedCount');

      // Log details of skipped rows
      if (skippedCount > 0) {
        debugPrint('=== Skipped Rows Summary ===');
        final skippedRows = processedRows
            .where((r) => r.status == ImportRowStatus.skipped)
            .toList();
        for (final row in skippedRows) {
          final errorMessages =
              row.errors.map((e) => '${e.field}: ${e.message}').join(', ');
          debugPrint(
              '  Row ${row.rowNumber} (${row.entityType}): $errorMessages');
        }
        debugPrint('=== End Skipped Rows ===');
      }

      return result;
    } catch (e, stackTrace) {
      debugPrint('Import error: $e\n$stackTrace');
      _progressController.add(ImportProgress(
        table: entityType,
        processed: processedRows.length,
        total: rows.length,
        stage: 'error',
        message: 'Import failed: $e',
      ));
      rethrow;
    }
  }

  /// Process a single batch of rows
  Future<List<ImportRow>> _processBatch(
    List<ImportRow> batch,
    String entityType,
    ImportConfig config,
  ) async {
    final results = <ImportRow>[];

    for (final row in batch) {
      if (_isCancelled) break;

      try {
        // Step 1: Validate
        final errors = await _validator.validateRow(row);
        if (errors.isNotEmpty) {
          // Log detailed skip reason
          debugPrint(
              'Skipping row ${row.rowNumber} (${row.entityType}): ${errors.map((e) => '${e.field}: ${e.message}').join(', ')}');

          results.add(row.copyWith(
            status: config.skipOnError
                ? ImportRowStatus.skipped
                : ImportRowStatus.error,
            errors: errors,
          ));
          continue;
        }

        // Step 2: Match existing entities (if needed)
        EntityMatch? match;
        if (entityType == 'Team') {
          match = await _matcher.matchTeam(row.data);
        } else if (entityType == 'Player') {
          final teamId = row.data['teamId'];
          final seasonId = row.data['seasonId'];
          if (teamId != null && seasonId != null) {
            match = await _matcher.matchPlayer(row.data, teamId, seasonId);
          }
        } else if (entityType == 'Season') {
          final teamId = row.data['teamId'];
          if (teamId != null) {
            match = await _matcher.matchSeason(row.data, teamId);
          }
        }

        // Step 3: Import (if not validate-only mode)
        if (!config.validateOnly) {
          await _importRow(row, entityType, match);
        }

        results.add(row.copyWith(
          status: ImportRowStatus.success,
          match: match,
        ));
      } catch (e, stackTrace) {
        debugPrint('Error processing row ${row.rowNumber}: $e\n$stackTrace');
        results.add(row.copyWith(
          status: config.skipOnError
              ? ImportRowStatus.skipped
              : ImportRowStatus.error,
          errors: [
            ValidationError(
              field: 'system',
              message: 'Import error: $e',
            ),
          ],
        ));
      }
    }

    return results;
  }

  /// Import a single row to database
  Future<void> _importRow(
    ImportRow row,
    String entityType,
    EntityMatch? match,
  ) async {
    final data = Map<String, dynamic>.from(row.data);

    // Add isFromImport flag
    data['isFromImport'] = true;

    // Special handling for Players found in different seasons
    final isPlayerInDifferentSeason = entityType == 'Player' &&
        match != null &&
        match.matchType == MatchType.fuzzy &&
        match.existingData?['foundInDifferentSeason'] == true;

    // If entity exists and should be updated (EXACT match in same season/context)
    if (match != null && match.isExactMatch && match.existingId != null) {
      data['id'] = match.existingId;
      row.data['id'] = match.existingId; // Update original row data
      // Update existing record
      await DatabaseService.instance.update(
        _getTableName(entityType),
        data,
        orderByChild: 'id',
        equalTo: match.existingId,
      );
    } else if (isPlayerInDifferentSeason) {
      // Player exists in another season - reuse player ID but create new season record
      // This ensures the same person has the same player ID across seasons
      data['id'] = match.existingId;
      row.data['id'] = match.existingId;

      debugPrint(
          'Creating new season record for existing player ID ${match.existingId} '
          '(${data['firstName']} ${data['lastName']}) in season ${data['seasonId']}');

      // Insert new record for this season (same player ID, different season)
      await DatabaseService.instance.insert(
        _getTableName(entityType),
        data,
      );
    } else {
      // Generate new ID if not provided
      if (data['id'] == null) {
        data['id'] = await _generateNextId(entityType);
        row.data['id'] =
            data['id']; // Update original row data with generated ID
      }

      // Ensure required default values (only if not already set)
      // Don't override existing scores, even if they are 0
      if (!data.containsKey('homeTeamScore')) {
        data['homeTeamScore'] = 0;
      }
      if (!data.containsKey('awayTeamScore')) {
        data['awayTeamScore'] = 0;
      }
      data.putIfAbsent('gameStatus', () => '0');

      // Insert new record
      await DatabaseService.instance.insert(
        _getTableName(entityType),
        data,
      );
    }
  }

  /// Generate next available ID for entity type
  Future<int> _generateNextId(String entityType) async {
    try {
      final results =
          await DatabaseService.instance.query(_getTableName(entityType));
      if (results.isEmpty) return 1;

      int maxId = 0;
      for (final record in results) {
        final id = record['id'];
        if (id is int && id > maxId) {
          maxId = id;
        }
      }

      return maxId + 1;
    } catch (e) {
      debugPrint('Error generating ID for $entityType: $e');
      return DateTime.now().millisecondsSinceEpoch % 1000000; // Fallback
    }
  }

  /// Log import to database
  Future<void> _logImport(ImportResult result) async {
    try {
      await DatabaseService.instance.insert(
        '_imports',
        result.toMap(),
      );
      debugPrint('Import logged: ${result.importId}');
    } catch (e, stackTrace) {
      debugPrint('Error logging import: $e\n$stackTrace');
    }
  }

  /// Get table name for entity type
  String _getTableName(String entityType) {
    switch (entityType) {
      case 'Team':
        return 'Teams';
      case 'Season':
        return 'Seasons';
      case 'Player':
        return 'Players';
      case 'Game':
        return 'Games';
      case 'GameEvent':
        return 'Events';
      default:
        throw Exception('Unknown entity type: $entityType');
    }
  }

  void dispose() {
    _progressController.close();
  }
}
