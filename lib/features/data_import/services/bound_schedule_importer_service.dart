import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:team_sync/features/data_import/models/import_models.dart';

/// Parser for Bound (gobound.com) schedule pages
/// Fetches HTML from the provided URL and extracts game data
class BoundScheduleImporterService {
  final http.Client _client;

  BoundScheduleImporterService({http.Client? client})
      : _client = client ?? http.Client();

  /// Fetch and parse schedule from a Bound URL
  Future<List<ImportRow>> parseSchedule({
    required String url,
    required int seasonId,
    required int homeTeamId,
    String? seasonYear,
  }) async {
    final rows = <ImportRow>[];
    int rowNumber = 0;

    try {
      final uri = Uri.parse(url);
      final response = await _client.get(
        uri,
        headers: {
          'User-Agent':
              'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
          'Accept':
              'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        },
      );
      debugPrint('Fetching schedule from: $url');
      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode != 200) {
        throw Exception(
            'Failed to load schedule. Status: ${response.statusCode}');
      }

      final document = parse(response.body);

      // Analysis of Bound Schedule Page Structure:
      // Most dependable structure is the table rows within the schedule table.
      // We will iterate through all <tr> elements in the document.

      final tableRows = document.querySelectorAll('tr');
      final uniqueOpponents = <String>{};

      for (final row in tableRows) {
        final cells = row.querySelectorAll('td');
        // We expect columns: Date, Opponent(s), Result, Caption, Location
        // So we need at least 4 text columns (ignoring Location if it's the 5th)
        if (cells.length < 4) {
          continue;
        }

        // --- Column 0: Date ---
        final dateText = cells[0].text.trim();
        // Minimal regex: \d{1,2}/\d{1,2}/\d{2,4}
        final textDatePattern = RegExp(r'^(\d{1,2})/(\d{1,2})/(\d{2,4})$');
        final dateMatch = textDatePattern.firstMatch(dateText);

        DateTime? gameDate;
        if (dateMatch != null) {
          try {
            final m = int.parse(dateMatch.group(1)!);
            final d = int.parse(dateMatch.group(2)!);
            var y = int.parse(dateMatch.group(3)!);

            // Handle 2-digit year
            if (y < 100) {
              y += 2000;
            }
            gameDate = DateTime(y, m, d);
          } catch (_) {
            // Failed to parse date parts
          }
        }

        if (gameDate == null) {
          // If we can't parse the date column, this probably isn't a valid game row
          continue;
        }

        // --- Column 4: Caption ---
        // Check for Scrimmage before processing further
        final captionText = cells[4].text.trim();
        if (captionText.toLowerCase().contains('scrimmage')) {
          debugPrint('Skipping Scrimmage row: $dateText');
          continue;
        }

        // --- Column 1: Opponent(s) ---
        final opponentText = cells[1].text.trim();
        if (opponentText.toLowerCase().contains('scrimmage')) {
          debugPrint('Skipping Scrimmage row: $dateText');
          continue;
        }

        String opponentName = 'Unknown Opponent';
        bool isHome = true;

        if (opponentText.contains('@')) {
          isHome = false;
          opponentName = opponentText.replaceAll('@', '').trim();
        } else if (opponentText.contains('vs')) {
          isHome = true;
          opponentName = opponentText.replaceAll('vs', '').trim();
        } else {
          // If neither, assume Home but take the text? Or maybe it is neutral?
          // Defaulting to isHome=true and cleaning text logic from before strings
          // Assuming "Name" implies home (or standard convention).
          // Previous logic had fallback checks.
          opponentName = opponentText;
        }

        // Clean up opponent name
        opponentName = opponentName.replaceAll(RegExp(r'\s+'), ' ');

        // Track unique opponents
        if (opponentName.isNotEmpty && opponentName != 'Unknown Opponent') {
          uniqueOpponents.add(opponentName);
        }

        // --- Column 2: Result ---
        final resultText = cells[2].text.trim();
        int? homeScore;
        int? awayScore;
        String status = '0'; // Not Started

        if (resultText.startsWith('W') || resultText.startsWith('L')) {
          status = '9'; // Final
          final parts = resultText.split(' ');
          if (parts.length > 1) {
            // "W 57-46"
            final scores = parts[1].split('-');
            if (scores.length == 2) {
              final s1 = int.tryParse(scores[0]);
              final s2 = int.tryParse(scores[1]);
              if (s1 != null && s2 != null) {
                final maxScore = s1 > s2 ? s1 : s2;
                final minScore = s1 < s2 ? s1 : s2;

                int ourScore;
                int opponentScore;

                if (resultText.startsWith('W')) {
                  ourScore = maxScore;
                  opponentScore = minScore;
                } else {
                  // Assume L
                  ourScore = minScore;
                  opponentScore = maxScore;
                }

                if (isHome) {
                  homeScore = ourScore;
                  awayScore = opponentScore;
                } else {
                  homeScore = opponentScore;
                  awayScore = ourScore;
                }
              }
            }
          }
        } else {
          // Likely a time, e.g. "7:00 PM"
          // status remains '0'
        }

        rowNumber++;
        rows.add(ImportRow(
          rowNumber: rowNumber,
          data: {
            'seasonId': seasonId,
            'homeTeamId': isHome ? homeTeamId : null,
            'awayTeamId': isHome ? null : homeTeamId,
            'opponentName': opponentName,
            'homeTeamScore': homeScore,
            'awayTeamScore': awayScore,
            'date': gameDate.toIso8601String(),
            'gameStatus': status,
            'isHome': isHome,
          },
          entityType: 'Game',
        ));
        debugPrint(
            '  -> Added Game: $opponentName on ${gameDate.toIso8601String()}');
      }

      // Add Team rows for unique opponents found
      // We process these BEFORE games in the consumer mostly, but here we just append or prepend
      // Let's prepend them so they appear first in list if iterated
      final teamRows = <ImportRow>[];
      for (final opponent in uniqueOpponents) {
        rowNumber++;
        teamRows.add(ImportRow(
          rowNumber: rowNumber,
          data: {
            'name': opponent,
            'fullName': opponent,
            'shortName': opponent, // Required field
            'isPlaceholder': true,
          },
          entityType: 'Team',
        ));
        debugPrint('  -> Added Opponent Team: $opponent');
      }

      // Merge: Teams first, then Games
      rows.insertAll(0, teamRows);
    } catch (e) {
      debugPrint('Error parsing schedule: $e');
      rethrow;
    }

    return rows;
  }
}
