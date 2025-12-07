import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:team_sync/models/import_models.dart';

class CsvTemplateService {
  /// Get template for specific entity type
  CsvTemplate getTemplate(String entityType) {
    switch (entityType) {
      case 'Team':
        return _getTeamTemplate();
      case 'Season':
        return _getSeasonTemplate();
      case 'Player':
        return _getPlayerTemplate();
      case 'Game':
        return _getGameTemplate();
      case 'GameEvent':
        return _getGameEventTemplate();
      default:
        throw Exception('Unknown entity type: $entityType');
    }
  }

  /// Generate blank CSV template with headers and example row
  Uint8List generateTemplateCsv(String entityType) {
    final template = getTemplate(entityType);

    // Header row
    final headers = template.allColumns;

    // Example row
    final exampleRow =
        headers.map((col) => template.exampleValues[col] ?? '').toList();

    final csvData = [
      ['# ${template.entityType} Import Template'],
      ['# Required columns: ${template.requiredColumns.join(", ")}'],
      ['# Optional columns: ${template.optionalColumns.join(", ")}'],
      ['#'],
      ['# Column Descriptions:'],
      ...headers
          .map((col) => ['# $col: ${template.columnDescriptions[col] ?? ""}']),
      ['#'],
      headers, // Actual header row
      exampleRow, // Example data row
    ];

    final csvString = const ListToCsvConverter().convert(csvData);
    return Uint8List.fromList(utf8.encode(csvString));
  }

  CsvTemplate _getTeamTemplate() {
    return const CsvTemplate(
      entityType: 'Team',
      requiredColumns: ['fullName', 'shortName'],
      optionalColumns: ['color1', 'color2', 'logoUrl'],
      columnDescriptions: {
        'fullName': 'Full team name (required)',
        'shortName': 'Short/abbreviated team name (required)',
        'color1': 'Primary color as hex (#RRGGBB) or ARGB integer',
        'color2': 'Secondary color as hex (#RRGGBB) or ARGB integer',
        'logoUrl': 'URL to team logo image',
      },
      exampleValues: {
        'fullName': 'Springfield Strikers',
        'shortName': 'Strikers',
        'color1': '#0000FF',
        'color2': '#FFFFFF',
        'logoUrl': 'https://example.com/logo.png',
      },
    );
  }

  CsvTemplate _getSeasonTemplate() {
    return const CsvTemplate(
      entityType: 'Season',
      requiredColumns: ['name', 'teamId'],
      optionalColumns: ['logoUrl'],
      columnDescriptions: {
        'name': 'Season name (required, e.g., "2024 Fall")',
        'teamId': 'Team ID this season belongs to (required)',
        'logoUrl': 'URL to season logo image',
      },
      exampleValues: {
        'name': '2024 Fall',
        'teamId': '1',
        'logoUrl': 'https://example.com/season-logo.png',
      },
    );
  }

  CsvTemplate _getPlayerTemplate() {
    return const CsvTemplate(
      entityType: 'Player',
      requiredColumns: [
        'firstName',
        'lastName',
        'number',
        'teamId',
        'seasonId'
      ],
      optionalColumns: ['profileImage', 'actionPhoto'],
      columnDescriptions: {
        'firstName': 'Player first name (required)',
        'lastName': 'Player last name (required)',
        'number': 'Jersey number (required)',
        'teamId': 'Team ID (required)',
        'seasonId': 'Season ID (required)',
        'profileImage': 'URL to player profile image',
        'actionPhoto': 'URL to action photo for player cards',
      },
      exampleValues: {
        'firstName': 'John',
        'lastName': 'Smith',
        'number': '10',
        'teamId': '1',
        'seasonId': '1',
        'profileImage': 'https://example.com/player.jpg',
        'actionPhoto': 'https://example.com/action.jpg',
      },
    );
  }

  CsvTemplate _getGameTemplate() {
    return const CsvTemplate(
      entityType: 'Game',
      requiredColumns: ['seasonId', 'homeTeamId', 'awayTeamId', 'date'],
      optionalColumns: [
        'homeTeamScore',
        'awayTeamScore',
        'gameStatus',
        'description',
        'gameLinks'
      ],
      columnDescriptions: {
        'seasonId': 'Season ID (required)',
        'homeTeamId': 'Home team ID (required)',
        'awayTeamId': 'Away team ID (required)',
        'date':
            'Game date in ISO8601 format: YYYY-MM-DD or YYYY-MM-DDTHH:MM:SS (required)',
        'homeTeamScore': 'Home team final score',
        'awayTeamScore': 'Away team final score',
        'gameStatus':
            'Game status: 0=Not Started, 1=1st Half, 2=Halftime, 3=2nd Half, 9=Final',
        'description': 'Game description or notes',
        'gameLinks': 'URLs to game highlights or stats',
      },
      exampleValues: {
        'seasonId': '1',
        'homeTeamId': '1',
        'awayTeamId': '2',
        'date': '2024-11-25T14:00:00',
        'homeTeamScore': '3',
        'awayTeamScore': '2',
        'gameStatus': '9',
        'description': 'Championship Game',
        'gameLinks': 'https://example.com/highlights',
      },
    );
  }

  CsvTemplate _getGameEventTemplate() {
    return const CsvTemplate(
      entityType: 'GameEvent',
      requiredColumns: [
        'gameId',
        'teamId',
        'seasonId',
        'eventType',
        'eventMinute',
        'eventPeriod',
        'eventData'
      ],
      optionalColumns: ['playerId', 'eventUrls'],
      columnDescriptions: {
        'gameId': 'Game ID (required)',
        'teamId': 'Team ID (required)',
        'seasonId': 'Season ID (required)',
        'playerId': 'Player ID (optional, depends on event type)',
        'eventType':
            'Event type: Shot, Assist, Save, PenaltyKick, Corner, Foul, Card, Offsides, Period (required)',
        'eventMinute': 'Minute of event (required)',
        'eventPeriod': 'Period: 1=1st Half, 2=2nd Half, etc. (required)',
        'eventData':
            'Event-specific data (required, meaning varies by eventType)',
        'eventUrls': 'URLs to event video/images',
      },
      exampleValues: {
        'gameId': '1',
        'teamId': '1',
        'seasonId': '1',
        'playerId': '10',
        'eventType': 'Shot',
        'eventMinute': '23',
        'eventPeriod': '1',
        'eventData': '0',
        'eventUrls': 'https://example.com/goal.mp4',
      },
    );
  }

  /// Download template CSV file
  Future<void> downloadTemplate(String entityType, String fileName) async {
    try {
      final csvBytes = generateTemplateCsv(entityType);

      if (kIsWeb) {
        await _downloadWebFile(csvBytes, fileName);
      } else {
        await _saveMobileFile(csvBytes, fileName);
      }

      debugPrint('Template downloaded: $fileName');
    } catch (e, stackTrace) {
      debugPrint('Error downloading template: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> _downloadWebFile(Uint8List bytes, String fileName) async {
    debugPrint('Web download not yet implemented: $fileName');
  }

  Future<void> _saveMobileFile(Uint8List bytes, String fileName) async {
    debugPrint('Mobile save not yet implemented: $fileName');
  }
}
