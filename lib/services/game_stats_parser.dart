import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:team_sync/models/import_models.dart';

/// Parser for game statistics files in the format shown in import_examples
/// Format: Tab-delimited with columns like:
/// #   Athlete	AST	G	PTS	SHT	SOG	SOG%	S%	PKM	PKA	YC
class GameStatsParser {
  /// Parse game stats file into GameEvent import rows
  ///
  /// This parser handles the specific format from game stat sheets:
  /// - Player number and name in first column (e.g., "1, Collin McBRIDE, SR")
  /// - Stats columns: AST (assists), G (goals), SHT (shots), SOG (shots on goal), etc.
  /// - Tab-delimited format
  Future<List<ImportRow>> parseGameStats({
    required Uint8List fileBytes,
    required int gameId,
    required int teamId,
    required int seasonId,
  }) async {
    try {
      // Decode bytes to string
      final content = utf8.decode(fileBytes);
      final lines = content.split('\n');

      if (lines.isEmpty) {
        throw Exception('File is empty');
      }

      final rows = <ImportRow>[];
      int rowNumber = 1;

      // Parse header to identify columns
      final headerLine = lines.first.trim();
      final headers = headerLine.split('\t').map((h) => h.trim()).toList();

      // Find column indices for stats we'll import
      final astIdx = _findColumnIndex(headers, ['ast', 'assist']);
      final goalsIdx = _findColumnIndex(headers, ['g', 'goals']);
      final pkmIdx =
          _findColumnIndex(headers, ['pkm', 'pk made', 'penalty kick made']);
      final pkaIdx = _findColumnIndex(
          headers, ['pka', 'pk attempted', 'penalty kick attempted']);
      final ycIdx = _findColumnIndex(headers, ['yc', 'yellow card']);

      // Parse data rows (skip header)
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final cells = line.split('\t').map((c) => c.trim()).toList();
        if (cells.length <= 1) continue;

        rowNumber++;

        // Parse player info from first column: "1, Collin McBRIDE, SR"
        final playerInfo = _parsePlayerInfo(cells[0]);
        if (playerInfo == null) {
          debugPrint('Could not parse player info from: ${cells[0]}');
          continue;
        }

        final playerId = playerInfo['number'] as int;
        final firstName = playerInfo['firstName'] as String;
        final lastName = playerInfo['lastName'] as String;

        // Create events for each stat
        final events = <Map<String, dynamic>>[];

        // Goals (Shot events with result = goal)
        final goals = _parseInt(cells, goalsIdx);
        for (int g = 0; g < goals; g++) {
          events.add({
            'eventType': 'Shot',
            'eventData': 0, // ShotResult.goal
            'playerId': playerId,
          });
        }

        // Assists
        final assists = _parseInt(cells, astIdx);
        for (int a = 0; a < assists; a++) {
          events.add({
            'eventType': 'Assist',
            'eventData': 0,
            'playerId': playerId,
          });
        }

        // Penalty kicks
        final pkMade = _parseInt(cells, pkmIdx);
        final pkAttempted = _parseInt(cells, pkaIdx);
        for (int p = 0; p < pkAttempted; p++) {
          events.add({
            'eventType': 'PenaltyKick',
            'eventData': p < pkMade ? 0 : 1, // 0 = goal, 1 = saved
            'playerId': playerId,
          });
        }

        // Yellow cards
        final yellowCards = _parseInt(cells, ycIdx);
        for (int y = 0; y < yellowCards; y++) {
          events.add({
            'eventType': 'Card',
            'eventData': 0, // Yellow card
            'playerId': playerId,
          });
        }

        // Create ImportRow for each event
        for (int e = 0; e < events.length; e++) {
          final eventData = events[e];
          rows.add(ImportRow(
            rowNumber: rowNumber,
            data: {
              'gameId': gameId,
              'teamId': teamId,
              'seasonId': seasonId,
              'playerId': eventData['playerId'],
              'playerFirstName': firstName, // For matching
              'playerLastName': lastName, // For matching
              'playerNumber': playerId, // For matching
              'eventType': eventData['eventType'],
              'eventData': eventData['eventData'],
              'eventMinute': 0, // Unknown from stats sheet
              'eventPeriod': 1, // Default to first half
              'eventUrls': '',
            },
            entityType: 'GameEvent',
          ));
        }
      }

      debugPrint('Parsed ${rows.length} game events from stats file');
      return rows;
    } catch (e, stackTrace) {
      debugPrint('Error parsing game stats: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Parse player info from format: "1, Collin McBRIDE, SR"
  Map<String, dynamic>? _parsePlayerInfo(String athleteCell) {
    try {
      // Split by comma
      final parts = athleteCell.split(',').map((p) => p.trim()).toList();
      if (parts.length < 2) return null;

      // First part is number
      final number = int.tryParse(parts[0]);
      if (number == null) return null;

      // Second part is name (may be "LASTNAME" or "First Last")
      final namePart = parts[1];
      final nameParts = namePart.split(' ');

      String firstName;
      String lastName;

      if (nameParts.length == 1) {
        // Single name, treat as last name
        firstName = '';
        lastName = _capitalizeProperCase(nameParts[0]);
      } else {
        // First and last name
        firstName = _capitalizeProperCase(nameParts[0]);
        lastName = _capitalizeProperCase(nameParts.sublist(1).join(' '));
      }

      return {
        'number': number,
        'firstName': firstName,
        'lastName': lastName,
      };
    } catch (e) {
      debugPrint('Error parsing player info: $e');
      return null;
    }
  }

  /// Convert name to proper case (e.g., "McBRIDE" -> "McBride")
  String _capitalizeProperCase(String name) {
    if (name.isEmpty) return name;

    // Handle names with apostrophes or hyphens
    final parts = name.split(RegExp(r"[\s'-]"));
    final capitalized = parts.map((part) {
      if (part.isEmpty) return part;

      // Special case for Mc/Mac names
      if (part.toLowerCase().startsWith('mc') && part.length > 2) {
        return 'Mc${part[2].toUpperCase()}${part.substring(3).toLowerCase()}';
      }
      if (part.toLowerCase().startsWith('mac') && part.length > 3) {
        return 'Mac${part[3].toUpperCase()}${part.substring(4).toLowerCase()}';
      }

      // Standard capitalization
      return part[0].toUpperCase() + part.substring(1).toLowerCase();
    }).toList();

    // Rejoin with original separators
    String result = capitalized[0];
    int partIndex = 1;
    for (int i = 0; i < name.length && partIndex < capitalized.length; i++) {
      if (name[i] == ' ' || name[i] == '-' || name[i] == "'") {
        result += name[i] + capitalized[partIndex];
        partIndex++;
      }
    }

    return result;
  }

  /// Find column index by trying multiple possible names
  int _findColumnIndex(List<String> headers, List<String> possibleNames) {
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase().trim();
      for (final name in possibleNames) {
        if (header.contains(name.toLowerCase())) {
          return i;
        }
      }
    }
    return -1;
  }

  /// Parse integer from cell, return 0 if not found or invalid
  int _parseInt(List<String> cells, int index) {
    if (index < 0 || index >= cells.length) return 0;
    return int.tryParse(cells[index]) ?? 0;
  }
}
