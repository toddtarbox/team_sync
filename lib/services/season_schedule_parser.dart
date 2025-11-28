import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:team_sync/models/import_models.dart';

/// Parser for season schedule files in the Bound format
/// Format: Tab-delimited with columns:
/// Date    Opponent    Result
/// 4/1/11  vs Des Moines East  L 0-1
class SeasonScheduleParser {
  /// Parse season schedule file into Game import rows
  ///
  /// This parser handles the Bound season schedule format:
  /// - Date in M/D/YY format
  /// - Opponent with "vs" (home) or "@" (away) prefix
  /// - Result with W/L and score (e.g., "W 3-1", "L 0-1")
  Future<List<ImportRow>> parseSchedule({
    required Uint8List fileBytes,
    required int seasonId,
    required int homeTeamId,
    String? seasonYear, // e.g., "2011" - will be used if date year is ambiguous
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

      // Parse header to verify format
      final headerLine = lines.first.trim();
      final headers = headerLine.split('\t').map((h) => h.trim()).toList();

      // Find column indices
      final dateIdx = _findColumnIndex(headers, ['date']);
      final opponentIdx = _findColumnIndex(headers, ['opponent']);
      final resultIdx = _findColumnIndex(headers, ['result']);

      if (dateIdx < 0 || opponentIdx < 0 || resultIdx < 0) {
        throw Exception(
            'Invalid format. Expected columns: Date, Opponent, Result');
      }

      // Parse data rows (skip header)
      for (int i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;

        final cells = line.split('\t').map((c) => c.trim()).toList();
        if (cells.length < 3) continue;

        rowNumber++;

        try {
          // Parse date
          final dateStr = cells[dateIdx];
          final date = _parseDate(dateStr, seasonYear);
          if (date == null) {
            debugPrint('Could not parse date: $dateStr');
            continue;
          }

          // Parse opponent and determine home/away
          final opponentStr = cells[opponentIdx];
          final gameLocation = _parseOpponent(opponentStr);
          final opponentName = gameLocation['opponentName'] as String;
          final isHome = gameLocation['isHome'] as bool;

          // Parse result
          final resultStr = cells[resultIdx];
          final result = _parseResult(resultStr);
          if (result == null) {
            debugPrint('Could not parse result: $resultStr');
            continue;
          }

          final isWin = result['isWin'] as bool;
          final homeScore = result['homeScore'] as int;
          final awayScore = result['awayScore'] as int;

          // Create import row
          rows.add(ImportRow(
            rowNumber: rowNumber,
            data: {
              'seasonId': seasonId,
              'homeTeamId':
                  isHome ? homeTeamId : null, // Will need opponent team ID
              'awayTeamId': isHome ? null : homeTeamId,
              'homeTeamScore': homeScore,
              'awayTeamScore': awayScore,
              'date': date.toIso8601String(),
              'gameStatus': '9', // Final
              'description':
                  '', // Could add tournament/playoff info if available
              'gameLinks': '',
              // Additional fields for matching
              'opponentName': opponentName,
              'isHome': isHome,
              'isWin': isWin,
            },
            entityType: 'Game',
          ));
        } catch (e) {
          debugPrint('Error parsing row $rowNumber: $e');
          continue;
        }
      }

      debugPrint('Parsed ${rows.length} games from season schedule');
      return rows;
    } catch (e, stackTrace) {
      debugPrint('Error parsing season schedule: $e\n$stackTrace');
      rethrow;
    }
  }

  /// Parse date from M/D/YY format
  DateTime? _parseDate(String dateStr, String? seasonYear) {
    try {
      // Format: 4/1/11 or 4/1/2011
      final parts = dateStr.split('/');
      if (parts.length != 3) return null;

      final month = int.tryParse(parts[0]);
      final day = int.tryParse(parts[1]);
      var year = int.tryParse(parts[2]);

      if (month == null || day == null || year == null) return null;

      // Handle 2-digit year
      if (year < 100) {
        if (seasonYear != null) {
          // Use season year as reference
          final baseYear = int.tryParse(seasonYear);
          if (baseYear != null) {
            // Determine century based on proximity
            final century = (baseYear ~/ 100) * 100;
            year = century + year;

            // If year is too far from season year, adjust
            if ((year - baseYear).abs() > 50) {
              if (year < baseYear) {
                year += 100;
              } else {
                year -= 100;
              }
            }
          }
        } else {
          // Default: assume 20th or 21st century
          if (year >= 0 && year <= 30) {
            year += 2000;
          } else {
            year += 1900;
          }
        }
      }

      return DateTime(year, month, day);
    } catch (e) {
      debugPrint('Error parsing date "$dateStr": $e');
      return null;
    }
  }

  /// Parse opponent and determine home/away
  /// Format: "vs Des Moines East" (home) or "@ Atlantic" (away)
  Map<String, dynamic> _parseOpponent(String opponentStr) {
    bool isHome = false;
    String opponentName = opponentStr;

    if (opponentStr.startsWith('vs ')) {
      isHome = true;
      opponentName = opponentStr.substring(3).trim();
    } else if (opponentStr.startsWith('@ ')) {
      isHome = false;
      opponentName = opponentStr.substring(2).trim();
    }

    return {
      'opponentName': opponentName,
      'isHome': isHome,
    };
  }

  /// Parse result and score
  /// Format: "W 3-1" or "L 0-1"
  Map<String, dynamic>? _parseResult(String resultStr) {
    try {
      final parts = resultStr.split(' ');
      if (parts.length < 2) return null;

      final result = parts[0].toUpperCase();
      final isWin = result == 'W';

      // Parse score: "3-1"
      final scoreParts = parts[1].split('-');
      if (scoreParts.length != 2) return null;

      final score1 = int.tryParse(scoreParts[0]);
      final score2 = int.tryParse(scoreParts[1]);

      if (score1 == null || score2 == null) return null;

      // If win, our score is first; if loss, opponent's score is first
      int homeScore;
      int awayScore;

      if (isWin) {
        homeScore = score1;
        awayScore = score2;
      } else {
        homeScore = score2;
        awayScore = score1;
      }

      return {
        'isWin': isWin,
        'homeScore': homeScore,
        'awayScore': awayScore,
      };
    } catch (e) {
      debugPrint('Error parsing result "$resultStr": $e');
      return null;
    }
  }

  /// Find column index by trying multiple possible names
  int _findColumnIndex(List<String> headers, List<String> possibleNames) {
    for (int i = 0; i < headers.length; i++) {
      final header = headers[i].toLowerCase().trim();
      for (final name in possibleNames) {
        if (header == name.toLowerCase() ||
            header.contains(name.toLowerCase())) {
          return i;
        }
      }
    }
    return -1;
  }
}

/// Extension to match opponent names to team IDs
class OpponentMatcher {
  /// Match opponent name to team in database
  /// Returns null if not found, or team ID if match found
  static Future<int?> matchOpponent(String opponentName) async {
    // This would query the Teams table for a match
    // For now, return null - will need to be implemented with EntityMatcherService
    return null;
  }

  /// Extract team name variations for better matching
  /// "Des Moines East" -> ["Des Moines East", "DME", "East"]
  static List<String> getNameVariations(String name) {
    final variations = <String>[name];

    // Remove common suffixes
    final cleanName =
        name.replaceAll(RegExp(r',?\s+(NE|IA|KS|MO|SD)$'), '').trim();
    if (cleanName != name) {
      variations.add(cleanName);
    }

    // Extract last part (e.g., "East" from "Des Moines East")
    final parts = cleanName.split(' ');
    if (parts.length > 1) {
      variations.add(parts.last);
    }

    // Create acronym
    if (parts.length > 1) {
      final acronym = parts.map((p) => p[0].toUpperCase()).join('');
      variations.add(acronym);
    }

    return variations;
  }
}
