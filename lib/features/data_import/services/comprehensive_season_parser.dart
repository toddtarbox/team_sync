import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:team_sync/features/data_import/models/import_models.dart';
import 'package:team_sync/core/utils/date_parser.dart';

/// Parser for comprehensive season import files
///
/// This format allows importing an entire season in one file:
/// - Season information
/// - Team rosters (players)
/// - Game schedule with opponents
/// - Game results and statistics per player
///
/// Format: Multi-section tab-delimited file with section headers
class ComprehensiveSeasonParser {
  // Store game metadata for event linking
  String? _gameSeasonName;
  String? _gameDate;
  String? _gameOpponent;
  String? _gameLocation;

  /// Parse comprehensive season file into multiple entity ImportRow lists
  Future<ComprehensiveSeasonImport> parseSeasonFile({
    required Uint8List fileBytes,
    required int homeTeamId,
  }) async {
    try {
      final content = utf8.decode(fileBytes);
      final lines = content.split('\n').map((l) => l.trim()).toList();

      final result = ComprehensiveSeasonImport(
        homeTeamId: homeTeamId,
      );

      String currentSection = '';
      List<String> sectionHeaders = [];
      int rowNumber = 0;
      bool isFirstLineAfterSection = false;

      for (final line in lines) {
        rowNumber++;
        if (line.isEmpty) continue;

        // Check for section headers
        if (line.startsWith('[') && line.endsWith(']')) {
          currentSection = line.substring(1, line.length - 1).toUpperCase();
          sectionHeaders = []; // Clear headers for new section
          isFirstLineAfterSection = true;
          debugPrint('Found section: $currentSection');
          continue;
        }

        // Skip comment lines
        if (line.startsWith('#')) continue;

        // Use proper CSV parsing to handle quoted fields
        List<String> cells;
        try {
          final parsed = const CsvToListConverter().convert(line);
          if (parsed.isEmpty) continue;
          cells = parsed[0].map((c) => c.toString().trim()).toList();
        } catch (e) {
          debugPrint('Error parsing CSV line $rowNumber: $e');
          continue;
        }

        // First non-comment line after section header is the column headers
        if (isFirstLineAfterSection && currentSection.isNotEmpty) {
          sectionHeaders = cells
              .map((h) => h.trim())
              .toList(); // Trim whitespace from headers
          isFirstLineAfterSection = false;
          debugPrint('  Headers: ${sectionHeaders.join(", ")}');
          continue;
        }

        // Parse data rows based on current section
        debugPrint('Processing row $rowNumber in section: "$currentSection"');

        switch (currentSection) {
          case 'SEASON':
            _parseSeasonSection(cells, sectionHeaders, rowNumber, result);
            break;

          case 'ROSTER':
            _parseRosterSection(cells, sectionHeaders, rowNumber, result);
            break;

          case 'OPPONENTS':
            _parseOpponentsSection(cells, sectionHeaders, rowNumber, result);
            break;

          case 'SCHEDULE':
            _parseScheduleSection(cells, sectionHeaders, rowNumber, result);
            break;

          case 'GAME':
            _parseGameSection(cells, sectionHeaders, rowNumber, result);
            break;

          case 'GAME EVENTS':
            _parseGameEventsSection(cells, sectionHeaders, rowNumber, result);
            break;

          case 'GOALKEEPING':
            _parseGoalkeepingSection(cells, sectionHeaders, rowNumber, result);
            break;

          default:
            debugPrint('Unknown section: "$currentSection"');
            break;
        }
      }

      debugPrint('Parse complete: ${result.seasonRows.length} season(s), '
          '${result.playerRows.length} player(s), '
          '${result.opponentRows.length} opponent(s), '
          '${result.gameRows.length} game(s), '
          '${result.eventRows.length} event(s)');

      return result;
    } catch (e, stackTrace) {
      debugPrint('Error parsing comprehensive season file: $e\n$stackTrace');
      rethrow;
    }
  }

  void _parseSeasonSection(List<String> cells, List<String> headers,
      int rowNumber, ComprehensiveSeasonImport result) {
    if (headers.isEmpty) {
      // This is the header row
      return;
    }

    final data = <String, dynamic>{};
    for (int i = 0; i < cells.length && i < headers.length; i++) {
      if (cells[i].isNotEmpty) {
        data[headers[i]] = cells[i];
      }
    }

    if (data.isNotEmpty) {
      data['teamId'] = result.homeTeamId;
      result.seasonRows.add(ImportRow(
        rowNumber: rowNumber,
        data: data,
        entityType: 'Season',
      ));
    }
  }

  void _parseRosterSection(List<String> cells, List<String> headers,
      int rowNumber, ComprehensiveSeasonImport result) {
    if (headers.isEmpty) return;

    debugPrint('Parsing ROSTER row $rowNumber: ${cells.join(" | ")}');

    final data = <String, dynamic>{};
    for (int i = 0; i < cells.length && i < headers.length; i++) {
      if (cells[i].isNotEmpty) {
        data[headers[i]] = _parseValue(cells[i]);
      }
    }

    debugPrint('  Parsed data: $data');

    if (data.isNotEmpty) {
      data['teamId'] = result.homeTeamId;
      // seasonId will be set after season is created
      result.playerRows.add(ImportRow(
        rowNumber: rowNumber,
        data: data,
        entityType: 'Player',
      ));
    }
  }

  void _parseOpponentsSection(List<String> cells, List<String> headers,
      int rowNumber, ComprehensiveSeasonImport result) {
    if (headers.isEmpty) return;

    final data = <String, dynamic>{};
    for (int i = 0; i < cells.length && i < headers.length; i++) {
      if (cells[i].isNotEmpty) {
        data[headers[i]] = cells[i];
      }
    }

    if (data.isNotEmpty) {
      result.opponentRows.add(ImportRow(
        rowNumber: rowNumber,
        data: data,
        entityType: 'Team',
      ));
    }
  }

  void _parseScheduleSection(List<String> cells, List<String> headers,
      int rowNumber, ComprehensiveSeasonImport result) {
    if (headers.isEmpty) return;

    final data = <String, dynamic>{};
    for (int i = 0; i < cells.length && i < headers.length; i++) {
      if (cells[i].isNotEmpty) {
        data[headers[i]] = _parseValue(cells[i]);
      }
    }

    if (data.isNotEmpty) {
      // Map schedule fields to Game entity fields
      final location = data['location']?.toString().toUpperCase();

      // Set homeTeamId and awayTeamId based on location
      if (location == 'HOME') {
        // Home game: homeTeamId = our team, awayTeamId = opponent (will be resolved later)
        data['homeTeamId'] = result.homeTeamId;
        data['opponentName'] = data['opponent']; // Store for later resolution
        data.remove('opponent');

        // Scores are already in correct order for home games
        // CSV: homeScore = our score, awayScore = opponent score
        if (data['homeScore'] != null) {
          data['homeTeamScore'] = data['homeScore'];
          data.remove('homeScore');
        }
        if (data['awayScore'] != null) {
          data['awayTeamScore'] = data['awayScore'];
          data.remove('awayScore');
        }
      } else if (location == 'AWAY') {
        // Away game: homeTeamId = opponent (will be resolved later), awayTeamId = our team
        data['awayTeamId'] = result.homeTeamId;
        data['opponentName'] = data['opponent']; // Store for later resolution
        data.remove('opponent');

        // SWAP scores for away games
        // CSV has: homeScore = our score, awayScore = opponent score
        // But we need: homeTeamScore = opponent score, awayTeamScore = our score
        if (data['homeScore'] != null && data['awayScore'] != null) {
          data['homeTeamScore'] =
              data['awayScore']; // Opponent's score goes to home
          data['awayTeamScore'] = data['homeScore']; // Our score goes to away
          data.remove('homeScore');
          data.remove('awayScore');
        }
      }

      // Map status to gameStatus
      if (data['status'] != null) {
        // Convert status string to GameStatus code
        final status = data['status'].toString().toLowerCase();
        String gameStatusCode;

        if (status.contains('final') && status.contains('pk')) {
          gameStatusCode = '11'; // gameFinalPKs
        } else if (status.contains('final') && status.contains('ot')) {
          gameStatusCode = '10'; // gameFinalOT
        } else if (status.contains('final')) {
          gameStatusCode = '9'; // gameFinal
        } else {
          gameStatusCode = '0'; // notStarted (default)
        }

        data['gameStatus'] = gameStatusCode;
        data.remove('status');
      }

      // Will need seasonId set after season creation
      result.gameRows.add(ImportRow(
        rowNumber: rowNumber,
        data: data,
        entityType: 'Game',
      ));
    }
  }

  void _parseGameSection(List<String> cells, List<String> headers,
      int rowNumber, ComprehensiveSeasonImport result) {
    if (headers.isEmpty) return;

    final data = <String, dynamic>{};
    for (int i = 0; i < cells.length && i < headers.length; i++) {
      if (cells[i].isNotEmpty) {
        data[headers[i]] = _parseValue(cells[i]);
      }
    }

    if (data.isNotEmpty) {
      // Check if this is game metadata (has seasonName) or event data (has playerNumber)
      if (data['seasonName'] != null) {
        // This is game metadata for linking events
        _gameSeasonName = data['seasonName']?.toString();
        _gameDate = data['date']?.toString();
        _gameOpponent = data['opponent']?.toString();
        _gameLocation = data['location']?.toString();

        debugPrint(
            'Game metadata: Season=$_gameSeasonName, Date=$_gameDate, Opponent=$_gameOpponent, Location=$_gameLocation');

        // Store as metadata in result
        result.gameMetadata = {
          'seasonName': _gameSeasonName,
          'date': _gameDate,
          'opponent': _gameOpponent,
          'location': _gameLocation,
        };
      } else if (data['gameRef'] != null || data['playerNumber'] != null) {
        // This is event data from old format
        result.eventRows.add(ImportRow(
          rowNumber: rowNumber,
          data: data,
          entityType: 'GameEvent',
        ));
      }
    }
  }

  void _parseGameEventsSection(List<String> cells, List<String> headers,
      int rowNumber, ComprehensiveSeasonImport result) {
    if (headers.isEmpty) return;

    debugPrint('Parsing GAME EVENTS row $rowNumber: ${cells.join(" | ")}');

    final data = <String, dynamic>{};
    for (int i = 0; i < cells.length && i < headers.length; i++) {
      if (cells[i].isNotEmpty) {
        data[headers[i]] = _parseValue(cells[i]);
      }
    }

    if (data.isEmpty || data['Athlete'] == null) return;

    // Parse athlete info: "1, Collin McBRIDE, SR"
    // Remove surrounding quotes if present
    final athleteStr = data['Athlete'].toString().replaceAll('"', '').trim();
    final parts = athleteStr.split(',').map((s) => s.trim()).toList();

    if (parts.length < 2) {
      debugPrint('  Invalid athlete format: $athleteStr');
      return;
    }

    final playerNumber = int.tryParse(parts[0]);
    if (playerNumber == null) {
      debugPrint('  Invalid player number: ${parts[0]}');
      return;
    }

    debugPrint('  Player #$playerNumber:');

    // Convert statistics to game events
    // Get all stat values first
    final totalGoals = _parseIntValue(data['G']);
    final penaltyKicksMade = _parseIntValue(data['PKM']);
    final assists = _parseIntValue(data['AST']);
    final totalShots = _parseIntValue(data['SHT']);
    final shotsOnGoal = _parseIntValue(data['SOG']);

    debugPrint(
        '    Stats: G=$totalGoals, PKM=$penaltyKicksMade, AST=$assists, SHT=$totalShots, SOG=$shotsOnGoal');

    // Regular goals = total goals minus penalty kick goals
    final regularGoals = totalGoals - penaltyKicksMade;

    // Regular Goals (excluding penalty kicks)
    if (regularGoals > 0) {
      for (int i = 0; i < regularGoals; i++) {
        result.eventRows.add(ImportRow(
          rowNumber: rowNumber,
          data: {
            'playerNumber': playerNumber,
            'eventType': 'Shot',
            'eventData': 0, // ShotResult.goal.index
            'eventMinute': 0,
            'eventPeriod': 0,
          },
          entityType: 'GameEvent',
        ));
      }
      debugPrint('    Added $regularGoals regular goal event(s)');
    }

    // Assists (AST) - already retrieved at top
    if (assists > 0) {
      for (int i = 0; i < assists; i++) {
        result.eventRows.add(ImportRow(
          rowNumber: rowNumber,
          data: {
            'playerNumber': playerNumber,
            'eventType': 'Assist',
            'eventData': 0, // Assists don't have result types, use 0
            'eventMinute': 0,
            'eventPeriod': 0,
          },
          entityType: 'GameEvent',
        ));
      }
      debugPrint('    Added $assists assist event(s)');
    }

    // Shots on Goal (SOG) - these are saves by the opponent
    // Already retrieved at top: shotsOnGoal, totalGoals
    final actualGoals = totalGoals; // Use total goals for SOG calculation
    final saves = shotsOnGoal - actualGoals; // SOG includes goals
    if (saves > 0) {
      for (int i = 0; i < saves; i++) {
        result.eventRows.add(ImportRow(
          rowNumber: rowNumber,
          data: {
            'playerNumber': playerNumber,
            'eventType': 'Shot',
            'eventData':
                1, // ShotResult.onTargetSave.index (CORRECT - already 1)
            'eventMinute': 0,
            'eventPeriod': 0,
          },
          entityType: 'GameEvent',
        ));
      }
      debugPrint('    Added $saves shot (saved) event(s)');
    }

    // Shots off target (SHT - SOG)
    // Already retrieved at top: totalShots, shotsOnGoal
    final offTargetShots = totalShots - shotsOnGoal;
    if (offTargetShots > 0) {
      for (int i = 0; i < offTargetShots; i++) {
        result.eventRows.add(ImportRow(
          rowNumber: rowNumber,
          data: {
            'playerNumber': playerNumber,
            'eventType': 'Shot',
            'eventData': 3, // ShotResult.offTarget.index (3, not 0!)
            'eventMinute': 0,
            'eventPeriod': 0,
          },
          entityType: 'GameEvent',
        ));
      }
      debugPrint('    Added $offTargetShots shot (off target) event(s)');
    }

    // Yellow Cards (YC)
    final yellowCards = _parseIntValue(data['YC']);
    if (yellowCards > 0) {
      for (int i = 0; i < yellowCards; i++) {
        result.eventRows.add(ImportRow(
          rowNumber: rowNumber,
          data: {
            'playerNumber': playerNumber,
            'eventType': 'Card',
            'eventData': 0, // Yellow card
            'eventMinute': 0,
            'eventPeriod': 0,
          },
          entityType: 'GameEvent',
        ));
      }
      debugPrint('    Added $yellowCards yellow card event(s)');
    }

    // Penalty Kicks Made (PKM) - already retrieved at top
    if (penaltyKicksMade > 0) {
      for (int i = 0; i < penaltyKicksMade; i++) {
        result.eventRows.add(ImportRow(
          rowNumber: rowNumber,
          data: {
            'playerNumber': playerNumber,
            'eventType': 'PenaltyKick',
            'eventData': 0, // ShotResult.goal.index
            'eventMinute': 0,
            'eventPeriod': 0,
          },
          entityType: 'GameEvent',
        ));
      }
      debugPrint('    Added $penaltyKicksMade penalty kick goal event(s)');
    }

    // Penalty Kicks Attempted but missed (PKA - PKM)
    final penaltyKicksAttempted = _parseIntValue(data['PKA']);
    final penaltyKicksMissed = penaltyKicksAttempted - penaltyKicksMade;
    if (penaltyKicksMissed > 0) {
      for (int i = 0; i < penaltyKicksMissed; i++) {
        result.eventRows.add(ImportRow(
          rowNumber: rowNumber,
          data: {
            'playerNumber': playerNumber,
            'eventType': 'PenaltyKick',
            'eventData': 3, // ShotResult.offTarget.index (3, not 0!)
            'eventMinute': 0,
            'eventPeriod': 0,
          },
          entityType: 'GameEvent',
        ));
      }
      debugPrint(
          '    Added $penaltyKicksMissed penalty kick (missed) event(s)');
    }
  }

  void _parseGoalkeepingSection(List<String> cells, List<String> headers,
      int rowNumber, ComprehensiveSeasonImport result) {
    if (headers.isEmpty) return;

    debugPrint('Parsing GOALKEEPING row $rowNumber: ${cells.join(" | ")}');

    final data = <String, dynamic>{};
    for (int i = 0; i < cells.length && i < headers.length; i++) {
      if (cells[i].isNotEmpty) {
        data[headers[i]] = _parseValue(cells[i]);
      }
    }

    if (data.isEmpty || data['Athlete'] == null) return;

    // Parse athlete info: "12, Jake Cool, SR"
    final athleteStr = data['Athlete'].toString().replaceAll('"', '').trim();
    final parts = athleteStr.split(',').map((s) => s.trim()).toList();

    if (parts.length < 2) {
      debugPrint('  Invalid athlete format: $athleteStr');
      return;
    }

    final playerNumber = int.tryParse(parts[0]);
    if (playerNumber == null) {
      debugPrint('  Invalid player number: ${parts[0]}');
      return;
    }

    debugPrint('  Goalkeeper #$playerNumber:');

    // Get goalkeeper stats
    final saves = _parseIntValue(data['SV']);

    debugPrint('    Stats: SV=$saves');

    // Create Save events for the goalkeeper
    // Each save is an opponent shot that was saved by this goalkeeper
    if (saves > 0) {
      for (int i = 0; i < saves; i++) {
        result.eventRows.add(ImportRow(
          rowNumber: rowNumber,
          data: {
            'playerNumber': playerNumber,
            'eventType': 'Save',
            'eventData': 0, // Saves don't have result types
            'eventMinute': 0,
            'eventPeriod': 0,
          },
          entityType: 'GameEvent',
        ));
      }
      debugPrint('    Added $saves save event(s)');
    }
  }

  int _parseIntValue(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();

    // Handle percentage strings like "0.0%"
    final str = value.toString().replaceAll('%', '').trim();
    return int.tryParse(str) ?? 0;
  }

  dynamic _parseValue(String value) {
    if (value.isEmpty) return null;

    // Try number
    final numValue = num.tryParse(value);
    if (numValue != null) return numValue;

    // Try boolean
    if (value.toLowerCase() == 'true') return true;
    if (value.toLowerCase() == 'false') return false;

    // Try date
    final dateValue = DateParser.parseToIso8601(value);
    if (dateValue != null) return dateValue;

    return value;
  }
}

/// Result of parsing comprehensive season file
class ComprehensiveSeasonImport {
  final int homeTeamId;
  final List<ImportRow> seasonRows = [];
  final List<ImportRow> playerRows = [];
  final List<ImportRow> opponentRows = [];
  final List<ImportRow> gameRows = [];
  final List<ImportRow> eventRows = [];
  Map<String, dynamic>? gameMetadata;

  ComprehensiveSeasonImport({
    required this.homeTeamId,
  });

  int get totalRows =>
      seasonRows.length +
      playerRows.length +
      opponentRows.length +
      gameRows.length +
      eventRows.length;

  List<ImportRow> getAllRows() {
    return [
      ...seasonRows,
      ...opponentRows,
      ...playerRows,
      ...gameRows,
      ...eventRows,
    ];
  }
}
