import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:team_sync/models/import_models.dart';

/// Parser for Bound (gobound.com) stats pages
/// Fetches HTML from the provided URL and extracts player stats
class BoundStatsImporterService {
  final http.Client _client;

  BoundStatsImporterService({http.Client? client})
      : _client = client ?? http.Client();

  /// Parse stats from a Bound URL
  Future<List<ImportRow>> parseStats({
    required String url,
    required int teamId,
    required int seasonId,
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

      if (response.statusCode != 200) {
        throw Exception('Failed to load stats. Status: ${response.statusCode}');
      }

      final document = parse(response.body);

      // Select the responsive table
      final table = document.querySelector('.table-responsive table');
      if (table == null) return rows;

      final trs = table.querySelectorAll('tr');

      // Dynamic Column Mapping
      Map<String, int> colMap = {};

      // Find header row
      for (final tr in trs) {
        final tds = tr.querySelectorAll('td');
        if (tds.isEmpty) continue;

        // If first col is 'Athlete', this is header
        if (tds[0].text.trim().toLowerCase().startsWith('athlete')) {
          for (int i = 0; i < tds.length; i++) {
            // Clean header (remove newlines, trim)
            colMap[tds[i].text.trim().toUpperCase()] = i;
          }
          break;
        }
      }

      for (final tr in trs) {
        final tds = tr.querySelectorAll('td');
        if (tds.isEmpty) continue;
        if (tds.length < colMap.length) continue;

        // Col 0: Athlete "2, Bryce Nelson, FR"
        final col0 = tds[0].text.trim();

        // Skip headers or empty
        if (col0.toLowerCase().startsWith('athlete') || col0.isEmpty) continue;

        // Parse Athlete Info
        final parts = col0.split(',');
        if (parts.isEmpty) continue;

        int? number;
        String name = '';
        String year = '';

        if (parts.isNotEmpty) {
          // Remove hidden elements if present (like in tests)
          // But here we just take text.
          // In HTML parsing, tds[0].text gets all text including hidden span '2'.
          // Real implementation: clean string.
          String rawNum = parts[0].trim();
          // Remove duplicates if text separation failed (e.g. "22" instead of "2")
          // Heuristic: take only the first distinct number if repeated?
          // Actually, let's trust the browser's/parser's text extraction for now or use regex.
          final match = RegExp(r'^(\d+)').firstMatch(rawNum);
          if (match != null) {
            number = int.tryParse(match.group(1)!);
          }
        }
        if (parts.length > 1) {
          name = parts[1].trim();
        }
        if (parts.length > 2) {
          year = parts[2].trim();
        }

        if (name.isEmpty || name.toLowerCase() == 'team') continue;

        // Helper to get int val from mapped column
        int getStat(String key) {
          if (!colMap.containsKey(key)) return 0;
          int idx = colMap[key]!;
          if (idx >= tds.length) return 0;
          return int.tryParse(tds[idx].text.trim()) ?? 0;
        }

        rowNumber++;
        rows.add(ImportRow(
          rowNumber: rowNumber,
          data: {
            'teamId': teamId,
            'seasonId': seasonId,
            'jerseyNumber': number,
            'name': name,
            'classYear': year,
            // Generic / Mixed Stats
            'GP': getStat('GP'),
            'GS': getStat('GS'),
            // Basketball
            'PTS': getStat('PTS'),
            'ORB': getStat('ORB'),
            'DRB': getStat('DRB'),
            'AST': getStat('AST'),
            'STL': getStat('STL'),
            'BLK': getStat('BLK'),
            'TO': getStat('TO'),
            'PF': getStat('FL'), // Bound uses FL for fouls
            // Soccer
            'Goals': getStat('G'),
            'Shots': getStat('SHT'),
            'SOG': getStat('SOG'),
            'Saves': getStat('SV'),
            'GoalsAgainst': getStat('GA'),
            'Minutes': getStat('MIN'),
            'YellowCards': getStat('YC'),
            'RedCards': getStat('RC'),
          },
          entityType: 'PlayerStats',
        ));
      }
    } catch (e) {
      debugPrint('Error parsing stats HTML: $e');
      rethrow;
    }

    return rows;
  }
}
