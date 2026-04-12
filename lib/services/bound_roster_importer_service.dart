import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:team_sync/models/import_models.dart';

/// Parser for Bound (gobound.com) roster pages
/// Fetches HTML from the provided URL and extracts player data
class BoundRosterImporterService {
  final http.Client _client;

  BoundRosterImporterService({http.Client? client})
      : _client = client ?? http.Client();

  /// Parse roster from a Bound URL into ImportRows
  Future<List<ImportRow>> parseRoster({
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
        throw Exception(
            'Failed to load roster. Status: ${response.statusCode}');
      }

      final document = parse(response.body);

      // Select the main table (often just 'table')
      // Based on research:
      // Row: <tr><td>#</td><td>Name</td><td>Year</td><td>Pos</td><td>Ht</td></tr>
      final tables = document.querySelectorAll('table');
      if (tables.isEmpty) return rows;

      // Usually the first table is the roster
      final table = tables.first;
      final trs = table.querySelectorAll('tr');

      // Detect indices from header
      int numberIdx = 0;
      int nameIdx = 1;
      int yearIdx = 2;
      int posIdx = 3;
      int heightIdx = 4;

      if (trs.isNotEmpty) {
        final headerRow = trs.first;
        // Check for TH first, then TD
        var headerCells = headerRow.querySelectorAll('th');
        if (headerCells.isEmpty) {
          headerCells = headerRow.querySelectorAll('td');
        }

        if (headerCells.isNotEmpty) {
          for (int i = 0; i < headerCells.length; i++) {
            final text = headerCells[i].text.toLowerCase().trim();
            if (text.contains('name')) nameIdx = i;
            if (text.contains('#') || text.contains('number')) numberIdx = i;
            if (text.contains('year') || text.contains('grade')) yearIdx = i;
            if (text.contains('pos')) posIdx = i;
            if (text.contains('ht') || text.contains('height')) heightIdx = i;
          }
        }
      }

      for (final tr in trs) {
        final tds = tr.querySelectorAll('td');
        if (tds.length < 4) {
          continue; // Expect at least 4 cols (Num, Name, Year, Pos)
        }

        // Helper to get safely
        String getCol(int idx) {
          if (idx < 0 || idx >= tds.length) return '';
          return tds[idx].text.trim();
        }

        // Check if header row (skip if number column is '#')
        if (getCol(numberIdx).startsWith('#') ||
            getCol(nameIdx).toLowerCase() == 'name') {
          continue;
        }

        // Parse fields
        // Allow fallback if number is missing/invalid, as names are critical
        int? number = int.tryParse(getCol(numberIdx));
        // If number parsing failed, check if it's because it's empty or invalid
        // If the row clearly has a name, we might want to keep it?
        // For now, let's treat number as 0 if missing, unless user wants strict skipping.
        // Re-reading user request: "no players are being imported" -> likely strict skipping is the bug.
        // We'll default to 0 if parsing fails but name exists.
        if (number == null) {
          final rawNum = getCol(numberIdx);
          if (rawNum.isEmpty || rawNum == '-') {
            number = 0;
          } else {
            // It might be a header row that slipped through or garbage data
            // But if we have a valid name, we should probably try to import it.
            number = 0;
          }
        }

        // Name might have extra whitespace or newlines
        final rawNameStr = getCol(nameIdx).replaceAll(RegExp(r'\s+'), ' ');
        if (rawNameStr.isEmpty || rawNameStr.toLowerCase() == 'name') continue;

        String firstName = '';
        String lastName = '';

        if (rawNameStr.contains(',')) {
          final parts = rawNameStr.split(',');
          if (parts.length > 1 && parts[1].trim().isNotEmpty) {
            lastName = parts[0].trim();
            firstName = parts[1].trim();
          } else {
            // Just a trailing comma, treat as first last
            final cleanedName = rawNameStr.replaceAll(',', '').trim();
            final parts = cleanedName.split(' ');
            firstName = parts.first;
            lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
          }
        } else {
          final parts = rawNameStr.split(' ');
          firstName = parts.first;
          lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        }

        final year = getCol(yearIdx);
        final position = getCol(posIdx);
        final height = getCol(heightIdx);

        rowNumber++;
        rows.add(ImportRow(
          rowNumber: rowNumber,
          data: {
            'teamId': teamId,
            'seasonId': seasonId,
            'number': number,
            'firstName': firstName,
            'lastName': lastName,
            'name': rawNameStr,
            'classYear': year,
            'position': position,
            'height': height,
            'email': '',
            'phone': '',
          },
          entityType: 'Player',
        ));
      }
    } catch (e) {
      debugPrint('Error parsing roster HTML: $e');
      rethrow;
    }

    return rows;
  }
}
