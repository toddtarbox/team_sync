import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:team_sync/features/data_import/models/import_models.dart';
import 'package:team_sync/core/utils/date_parser.dart';

class CsvParserService {
  /// Parse CSV file bytes into ImportRow objects
  Future<List<ImportRow>> parseCsv({
    required Uint8List fileBytes,
    required String entityType,
    Map<String, String>? columnMapping,
    String fieldDelimiter = ',',
    String textDelimiter = '"',
    String? eol,
  }) async {
    try {
      // Decode bytes to string
      final csvString = utf8.decode(fileBytes);

      debugPrint('Using delimiter: COMMA');

      // Parse CSV
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(
        csvString,
        fieldDelimiter: fieldDelimiter,
        textDelimiter: textDelimiter,
        eol: eol,
      );

      if (csvData.isEmpty) {
        throw Exception('CSV file is empty');
      }

      // Extract headers from first row
      final headers = csvData.first.map((h) => h.toString().trim()).toList();

      // Apply column mapping if provided
      final mappedHeaders = _applyColumnMapping(headers, columnMapping);

      // Parse data rows
      final List<ImportRow> rows = [];
      for (int i = 1; i < csvData.length; i++) {
        final rowData = csvData[i];
        if (_isEmptyRow(rowData)) continue;

        final Map<String, dynamic> data = {};
        for (int j = 0; j < rowData.length && j < mappedHeaders.length; j++) {
          final header = mappedHeaders[j];
          final value = _parseValue(rowData[j]);
          if (value != null) {
            data[header] = value;
          }
        }

        rows.add(ImportRow(
          rowNumber: i,
          data: data,
          entityType: entityType,
        ));
      }

      debugPrint('Parsed ${rows.length} rows from CSV');
      return rows;
    } catch (e, stackTrace) {
      debugPrint('Error parsing CSV: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Apply column mapping to headers
  List<String> _applyColumnMapping(
    List<String> headers,
    Map<String, String>? columnMapping,
  ) {
    if (columnMapping == null || columnMapping.isEmpty) {
      return headers;
    }

    return headers.map((header) {
      return columnMapping[header] ?? header;
    }).toList();
  }

  /// Check if a row is empty
  bool _isEmptyRow(List<dynamic> row) {
    return row.every((cell) => cell == null || cell.toString().trim().isEmpty);
  }

  /// Parse individual cell value
  dynamic _parseValue(dynamic value) {
    if (value == null) return null;

    final stringValue = value.toString().trim();
    if (stringValue.isEmpty) return null;

    // Try to parse as number
    final numValue = num.tryParse(stringValue);
    if (numValue != null) return numValue;

    // Try to parse as boolean
    if (stringValue.toLowerCase() == 'true') return true;
    if (stringValue.toLowerCase() == 'false') return false;

    // Try to parse as date
    final dateValue = DateParser.parseToIso8601(stringValue);
    if (dateValue != null) return dateValue;

    return stringValue;
  }

  /// Auto-detect column mappings based on common patterns
  Map<String, String> detectColumnMapping(
      List<String> headers, String entityType) {
    final Map<String, String> mapping = {};

    for (final header in headers) {
      final normalized = header.toLowerCase().trim();
      final mapped = _getMappedColumn(normalized, entityType);
      if (mapped != null) {
        mapping[header] = mapped;
      }
    }

    return mapping;
  }

  String? _getMappedColumn(String normalized, String entityType) {
    switch (entityType) {
      case 'Team':
        if (normalized.contains('full') && normalized.contains('name')) {
          return 'fullName';
        }
        if (normalized.contains('short') && normalized.contains('name')) {
          return 'shortName';
        }
        if (normalized == 'name' || normalized == 'team name') {
          return 'fullName';
        }
        break;

      case 'Player':
        if (normalized.contains('first') && normalized.contains('name')) {
          return 'firstName';
        }
        if (normalized.contains('last') && normalized.contains('name')) {
          return 'lastName';
        }
        if (normalized == 'number' || normalized == 'jersey') {
          return 'number';
        }
        break;

      case 'Game':
        if (normalized.contains('home') && normalized.contains('team')) {
          return 'homeTeamId';
        }
        if (normalized.contains('away') && normalized.contains('team')) {
          return 'awayTeamId';
        }
        if (normalized.contains('date')) {
          return 'date';
        }
        if (normalized.contains('home') && normalized.contains('score')) {
          return 'homeTeamScore';
        }
        if (normalized.contains('away') && normalized.contains('score')) {
          return 'awayTeamScore';
        }
        break;

      case 'Season':
        if (normalized == 'name' || normalized == 'season name') {
          return 'name';
        }
        if (normalized.contains('team')) {
          return 'teamId';
        }
        break;

      case 'GameEvent':
        if (normalized.contains('player')) {
          return 'playerId';
        }
        if (normalized.contains('team')) {
          return 'teamId';
        }
        if (normalized.contains('game')) {
          return 'gameId';
        }
        if (normalized.contains('minute')) {
          return 'eventMinute';
        }
        if (normalized.contains('type')) {
          return 'eventType';
        }
        break;
    }

    return null;
  }
}
