import 'package:html/parser.dart' show parse;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:team_sync/models/import_models.dart';

/// Parser for Bound (gobound.com) single game stats
/// Fetches HTML from the provided URL and extracts player game stats as Events
class BoundGameStatsImporterService {
  final http.Client _client;

  BoundGameStatsImporterService({http.Client? client})
      : _client = client ?? http.Client();

  /// Parse game stats from a Bound URL into GameEvents
  Future<List<ImportRow>> parseGameStats({
    required String url,
    required int gameId,
    required int teamId,
    required int seasonId,
  }) async {
    final rows = <ImportRow>[];
    int rowNumber = 0;

    try {
      // Ensure we are hitting the /stats endpoint
      Uri uri = Uri.parse(url);
      if (!uri.path.endsWith('/stats')) {
        uri = uri.replace(path: '${uri.path}/stats');
      }

      debugPrint('Fetching game stats from: $uri');

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
            'Failed to load game stats. Status: ${response.statusCode}');
      }

      final document = parse(response.body);

      // Look for stats table. Bound often puts box scores in tables.
      // Strategy: Find table with headers like "PTS", "REB", "AST".
      final tables = document.querySelectorAll('table');

      for (final table in tables) {
        // Check headers
        final trs = table.querySelectorAll('tr');
        if (trs.isEmpty) continue;

        // Header mapping
        Map<String, int> colMap = {};
        bool isStatsTable = false;

        // Find header row (could be theead or just first tr)
        var headerRow = table.querySelector('thead tr');
        headerRow ??= trs.first;

        final cells = headerRow.querySelectorAll('th');
        // fallback to td if th missing
        final headerCells =
            cells.isNotEmpty ? cells : headerRow.querySelectorAll('td');

        for (int i = 0; i < headerCells.length; i++) {
          final text = headerCells[i].text.trim().toUpperCase();
          colMap[text] = i;
          // Check for key stats columns to identify valid table
          if (text == 'PTS' ||
              text == 'REB' ||
              text == 'RBD' ||
              text == 'AST' ||
              text == 'OR' ||
              text == 'ORB' ||
              text == 'DR' ||
              text == 'DRB' ||
              text == 'OFF' ||
              text == 'DEF' ||
              text == 'FGM' ||
              text == 'FG' ||
              text == 'FGA' ||
              text == 'FGMA' ||
              text == '3PM' ||
              text == '3FG' ||
              text == '3PA' ||
              text == '3PT' ||
              text == '3PMA' ||
              text == 'FTM' ||
              text == 'FT' ||
              text == 'FTA' ||
              text == 'FTMA') {
            isStatsTable = true;
          }
        }

        if (!isStatsTable) continue;

        // Parse rows
        for (final tr in trs) {
          final tds = tr.querySelectorAll('td');
          if (tds.length < colMap.length) continue;

          // Identify Player Name (usually first column or "Athlete")
          String name = '';
          int? number;

          // Try to find name column
          int nameIdx = 0;
          if (colMap.containsKey('ATHLETE')) {
            nameIdx = colMap['ATHLETE']!;
          } else if (colMap.containsKey('PLAYER')) {
            nameIdx = colMap['PLAYER']!;
          } else if (colMap.containsKey('NAME')) {
            nameIdx = colMap['NAME']!;
          }

          // Helper to clean name "23 Jordan Smith" -> 23, Jordan Smith
          String rawName = tds[nameIdx].text.trim();
          if (rawName.toUpperCase() == 'TEAM' ||
              rawName.toUpperCase() == 'TOTALS') {
            continue;
          }
          if (colMap.containsKey('ATHLETE') &&
              rawName.toUpperCase() == 'ATHLETE') {
            continue; // Header row
          }

          // Parse number and name
          // 1. "23 Jordan Smith" or "23 Jordan Smith SO" or "23, Smith, Jordan"
          var match = RegExp(r'^(\d+)[,\s]+(.*)').firstMatch(rawName);

          if (match != null) {
            number = int.tryParse(match.group(1)!);
            String tempName = match.group(2)!.trim();
            // Remove common grade suffixes if they exist at the end
            // e.g. "Mekai Weilage SO" -> "Mekai Weilage"
            final gradeSuffixes = [' SR', ' JR', ' SO', ' FR', ' 8', ' 7'];
            for (final suffix in gradeSuffixes) {
              if (tempName.toUpperCase().endsWith(suffix)) {
                tempName = tempName
                    .substring(0, tempName.length - suffix.length)
                    .trim();
                break;
              }
            }
            // Clean up name by removing trailing commas/spaces
            while (tempName.endsWith(',') || tempName.endsWith(' ')) {
              tempName = tempName.substring(0, tempName.length - 1).trim();
            }

            name = tempName;
          } else if (rawName.contains(',')) {
            // 2. "2, Name" or "2, Name, Class"
            final parts = rawName.split(',');
            if (parts.isNotEmpty) {
              final firstPart = parts[0].trim();
              if (RegExp(r'^\d+$').hasMatch(firstPart)) {
                number = int.parse(firstPart);
                if (parts.length > 1) {
                  name = parts[1].trim();
                  // No need to strip from comma format usually as class is separate part
                }
              } else {
                name = rawName;
              }
            }
          } else {
            name = rawName;
            // Try stripping from raw name too if no number found
            final gradeSuffixes = [' SR', ' JR', ' SO', ' FR', ' 8', ' 7'];
            for (final suffix in gradeSuffixes) {
              if (name.toUpperCase().endsWith(suffix)) {
                name = name.substring(0, name.length - suffix.length).trim();
                break;
              }
            }
          }

          if (name.isEmpty) continue;

          // Helpers to extract stat values
          String getRawStat(String key) {
            if (!colMap.containsKey(key)) return '';
            return tds[colMap[key]!].text.trim();
          }

          int getStat(String key) {
            final txt = getRawStat(key);
            if (txt.isEmpty) return 0;

            // Handle "M-A" or "M/A" format (e.g. "5-10" or "7/19")
            if (txt.contains('-') || txt.contains('/')) {
              final delimiter = txt.contains('-') ? '-' : '/';
              final parts = txt.split(delimiter);
              return int.tryParse(parts[0].trim()) ?? 0;
            }
            return int.tryParse(txt) ?? 0;
          }

          int getAttempts(String key, int makes) {
            final txt = getRawStat(key);
            if (txt.isEmpty) return makes;

            // Handle "M-A" or "M/A" format (e.g. "5-10" or "7/19")
            if (txt.contains('-') || txt.contains('/')) {
              final delimiter = txt.contains('-') ? '-' : '/';
              final parts = txt.split(delimiter);
              if (parts.length > 1) {
                return int.tryParse(parts[1].trim()) ?? makes;
              }
            }

            // Handle separate attempts column if it was passed a different key
            return int.tryParse(txt) ?? makes;
          }

          // Extract Stats and create Events
          // Basketball: PTS, REB, AST, STL, BLK, TO, PF
          final pts = getStat('PTS');
          // Bound uses RBD for Total Rebounds often, or REB, or TR
          int reb = 0;
          if (colMap.containsKey('RBD')) {
            reb = getStat('RBD');
          } else if (colMap.containsKey('REB')) {
            reb = getStat('REB');
          } else if (colMap.containsKey('TR')) {
            reb = getStat('TR');
          }

          final ast = getStat('AST');
          final stl = getStat('STL');
          final blk = getStat('BLK');
          final to = getStat('TO');
          final pf = getStat('PF') > 0 ? getStat('PF') : getStat('FL');

          void addEvent(String type, int value, [int? dataValue]) {
            if (value > 0) {
              rowNumber++;
              if (type == 'Point' && dataValue == null) {
                // Standard bulk points event (value = total points)
                rows.add(_createEventRow(rowNumber, gameId, teamId, seasonId,
                    name, number, type, value));
              } else {
                // Create multiple events
                for (int i = 0; i < value; i++) {
                  rowNumber++;
                  rows.add(_createEventRow(rowNumber, gameId, teamId, seasonId,
                      name, number, type, dataValue ?? 1));
                }
              }
            }
          }

          // Scoring Breakdown Logic
          // Makes
          final threePM = getStat('3PMA') > 0
              ? getStat('3PMA')
              : (getStat('3PM') > 0
                  ? getStat('3PM')
                  : (getStat('3FG') > 0 ? getStat('3FG') : getStat('3PT')));
          final fgm = getStat('FGMA') > 0
              ? getStat('FGMA')
              : (getStat('FGM') > 0 ? getStat('FGM') : getStat('FG'));
          final ftm = getStat('FTMA') > 0
              ? getStat('FTMA')
              : (getStat('FTM') > 0 ? getStat('FTM') : getStat('FT'));

          // Attempts
          int threePA = 0;
          if (colMap.containsKey('3PMA')) {
            threePA = getAttempts('3PMA', threePM);
          } else if (colMap.containsKey('3PA')) {
            threePA = getStat('3PA');
          } else if (colMap.containsKey('3PTA')) {
            threePA = getStat('3PTA');
          } else if (colMap.containsKey('3FGA')) {
            threePA = getStat('3FGA');
          } else {
            // Check for M-A in 3PT/3FG column
            threePA = getAttempts('3PT', threePM);
            if (threePA == threePM) threePA = getAttempts('3FG', threePM);
            if (threePA == threePM) threePA = getAttempts('3PM', threePM);
          }

          int fga = 0;
          if (colMap.containsKey('FGMA')) {
            fga = getAttempts('FGMA', fgm);
          } else if (colMap.containsKey('FGA')) {
            fga = getStat('FGA');
          } else {
            // Check for M-A in FG/FGM column
            fga = getAttempts('FG', fgm);
            if (fga == fgm) fga = getAttempts('FGM', fgm);
          }

          int fta = 0;
          if (colMap.containsKey('FTMA')) {
            fta = getAttempts('FTMA', ftm);
          } else if (colMap.containsKey('FTA')) {
            fta = getStat('FTA');
          } else {
            // Check for M-A in FT/FTM column
            fta = getAttempts('FT', ftm);
            if (fta == ftm) fta = getAttempts('FTM', ftm);
          }

          // Derived Stats
          final twoPM = (fgm > threePM) ? fgm - threePM : 0;
          final twoPA = (fga > threePA) ? fga - threePA : twoPM;

          // Add specific scoring events
          // 3 Pointers
          if (threePM > 0) addEvent('Point', threePM, 3);
          int threeMiss = threePA - threePM;
          if (threeMiss > 0) addEvent('Miss', threeMiss, 3);

          // 2 Pointers
          if (twoPM > 0) addEvent('Point', twoPM, 2);
          int twoMiss = twoPA - twoPM;
          if (twoMiss > 0) addEvent('Miss', twoMiss, 2);

          // Free Throws
          if (ftm > 0) addEvent('Point', ftm, 1);
          int ftMiss = fta - ftm;
          if (ftMiss > 0) addEvent('Miss', ftMiss, 1);

          // Add remainder points if total PTS > detailed points
          final detailedPoints = (threePM * 3) + (twoPM * 2) + (ftm * 1);
          if (pts > detailedPoints) {
            rows.add(_createEventRow(rowNumber, gameId, teamId, seasonId, name,
                number, 'Point', pts - detailedPoints));
          } else if (detailedPoints == 0 && pts > 0) {
            // Fallback to bulk points if no detailed makes found
            addEvent('Point', pts);
          }

          // Rebounds Logic
          // Try to get split stats first
          final offReb = getStat('ORB') > 0
              ? getStat('ORB')
              : (getStat('OR') > 0 ? getStat('OR') : getStat('OFF'));
          final defReb = getStat('DRB') > 0
              ? getStat('DRB')
              : (getStat('DR') > 0 ? getStat('DR') : getStat('DEF'));

          if (offReb > 0 || defReb > 0) {
            // Add specific rebound types
            // Use eventData=2 for Offensive, eventData=3 for Defensive
            addEvent('Rebound', offReb, 2);
            addEvent('Rebound', defReb, 3);

            // If total REB > sum, add remainder as generic
            if (reb > (offReb + defReb)) {
              addEvent('Rebound', reb - (offReb + defReb), 1);
            }
          } else {
            // Fallback to generic rebounds only
            addEvent('Rebound', reb, 1);
          }

          addEvent('Assist', ast);
          addEvent('Steal', stl);
          addEvent('Block', blk);
          addEvent('Turnover', to);
          addEvent('Foul', pf);
        }
      }
    } catch (e) {
      debugPrint('Error parsing game stats: $e');
      rethrow;
    }

    return rows;
  }

  ImportRow _createEventRow(int rowNumber, int gameId, int teamId, int seasonId,
      String name, int? number, String eventType, int eventData) {
    // Split name into first and last for matcher
    String firstName = '';
    String lastName = '';

    if (name.contains(',')) {
      final parts = name.split(',');
      if (parts.length > 1 && parts[1].trim().isNotEmpty) {
        lastName = parts[0].trim();
        firstName = parts[1].trim();
      } else {
        // Just a trailing comma, treat as first last?
        final cleanedName = name.replaceAll(',', '').trim();
        final nameParts = cleanedName.split(' ');
        if (nameParts.length > 1) {
          firstName = nameParts.first;
          lastName = nameParts.sublist(1).join(' ');
        } else {
          firstName = cleanedName;
        }
      }
    } else {
      final nameParts = name.trim().split(' ');
      if (nameParts.length > 1) {
        firstName = nameParts.first;
        lastName = nameParts.sublist(1).join(' ');
      } else {
        firstName = name;
      }
    }

    return ImportRow(
      rowNumber: rowNumber,
      data: {
        'gameId': gameId,
        'teamId': teamId,
        'seasonId': seasonId,
        'name': name, // For resolution fallback / logging
        'firstName': firstName,
        'lastName': lastName,
        'jerseyNumber': number, // Helper for resolution
        'eventType': eventType,
        'eventData': eventData,
        'eventMinute': 0,
        'eventPeriod': 1,
        'eventUrls': '',
        'index': rowNumber, // maintain order
      },
      entityType: 'GameEvent',
    );
  }
}
