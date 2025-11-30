import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:team_sync/models/import_models.dart';

class ErrorCsvExporterService {
  /// Generate error CSV with original data and error details
  Uint8List generateErrorCsv(List<ImportRow> errorRows) {
    if (errorRows.isEmpty) {
      throw Exception('No error rows to export');
    }

    // Collect all unique field names from error rows
    final Set<String> fieldNames = {};
    for (final row in errorRows) {
      fieldNames.addAll(row.data.keys);
    }

    // Build header row
    final headers = [
      'Row Number',
      'Status',
      'Errors',
      'Suggested Fixes',
      ...fieldNames.toList()..sort(),
    ];

    // Build data rows
    final List<List<dynamic>> csvData = [headers];

    for (final row in errorRows) {
      final errorMessages =
          row.errors.map((e) => '${e.field}: ${e.message}').join('; ');
      final suggestedFixes = row.errors
          .where((e) => e.suggestedFix != null)
          .map((e) => '${e.field}: ${e.suggestedFix}')
          .join('; ');

      final rowData = [
        row.rowNumber,
        row.status.name,
        errorMessages,
        suggestedFixes.isEmpty ? '' : suggestedFixes,
      ];

      // Add data fields in same order as headers
      for (final fieldName in fieldNames.toList()..sort()) {
        rowData.add(row.data[fieldName]?.toString() ?? '');
      }

      csvData.add(rowData);
    }

    // Convert to CSV string
    final csvString = const ListToCsvConverter().convert(csvData);

    // Convert to bytes
    return Uint8List.fromList(utf8.encode(csvString));
  }

  /// Generate summary CSV with import statistics
  Uint8List generateSummaryCsv(ImportResult result) {
    final csvData = [
      ['Import Summary'],
      ['Import ID', result.importId],
      ['Timestamp', result.timestamp.toIso8601String()],
      ['File Name', result.fileName],
      ['Entity Type', result.entityType],
      ['Total Rows', result.totalRows],
      ['Successful', result.successCount],
      ['Skipped', result.skippedCount],
      ['Errors', result.errorCount],
      ['Duration', '${result.duration.inSeconds}s'],
      [],
      ['Row Status Summary'],
      ['Row Number', 'Status', 'Message'],
    ];

    for (final row in result.rows) {
      final message = row.errors.isNotEmpty
          ? row.errors.map((e) => '${e.field}: ${e.message}').join('; ')
          : (row.status == ImportRowStatus.success ? 'Success' : '');

      csvData.add([
        row.rowNumber,
        row.status.name,
        message,
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    return Uint8List.fromList(utf8.encode(csvString));
  }

  /// Save error CSV to file (web download or mobile file system)
  Future<void> downloadErrorCsv({
    required List<ImportRow> errorRows,
    required String fileName,
  }) async {
    try {
      final csvBytes = generateErrorCsv(errorRows);

      if (kIsWeb) {
        // Web download
        await _downloadWebFile(csvBytes, fileName);
      } else {
        // Mobile/desktop file save
        await _saveMobileFile(csvBytes, fileName);
      }

      debugPrint('Error CSV exported: $fileName');
    } catch (e, stackTrace) {
      debugPrint('Error exporting CSV: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Save summary CSV to file
  Future<void> downloadSummaryCsv({
    required ImportResult result,
    required String fileName,
  }) async {
    try {
      final csvBytes = generateSummaryCsv(result);

      if (kIsWeb) {
        await _downloadWebFile(csvBytes, fileName);
      } else {
        await _saveMobileFile(csvBytes, fileName);
      }

      debugPrint('Summary CSV exported: $fileName');
    } catch (e, stackTrace) {
      debugPrint('Error exporting summary CSV: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> _downloadWebFile(Uint8List bytes, String fileName) async {
    // This will be implemented using web-specific code
    // For now, just log
    debugPrint('Web download not yet implemented: $fileName');
  }

  Future<void> _saveMobileFile(Uint8List bytes, String fileName) async {
    // This will be implemented using path_provider and file system
    // For now, just log
    debugPrint('Mobile save not yet implemented: $fileName');
  }
}
