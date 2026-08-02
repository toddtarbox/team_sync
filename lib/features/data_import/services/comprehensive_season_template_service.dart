import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Service for generating comprehensive season import templates
class ComprehensiveSeasonTemplateService {
  /// Generate blank comprehensive season template
  Uint8List generateTemplate({
    String seasonName = 'Season Name',
    int samplePlayerCount = 3,
    int sampleOpponentCount = 3,
    int sampleGameCount = 2,
  }) {
    final buffer = StringBuffer();

    // Header comment
    buffer.writeln('# Complete Season Import Template');
    buffer.writeln('# Format: Tab-delimited with section headers');
    buffer.writeln('# Replace example data with your actual data');
    buffer.writeln('# Delete this comment block before importing');
    buffer.writeln();

    // Season section
    buffer.writeln('[SEASON]');
    buffer.writeln('name\tyear\tlogoUrl');
    buffer.writeln('$seasonName\t2024\t');
    buffer.writeln();

    // Roster section
    buffer.writeln('[ROSTER]');
    buffer.writeln('number\tfirstName\tlastName\tposition\tgrade');
    for (int i = 1; i <= samplePlayerCount; i++) {
      buffer.writeln('$i\tPlayer$i\tLastName$i\tM\tJR');
    }
    buffer.writeln();

    // Opponents section
    buffer.writeln('[OPPONENTS]');
    buffer.writeln('fullName\tshortName\tcity\tstate');
    for (int i = 1; i <= sampleOpponentCount; i++) {
      buffer.writeln('Opponent Team $i\tOpp$i\tCity$i\tIA');
    }
    buffer.writeln();

    // Schedule section
    buffer.writeln('[SCHEDULE]');
    buffer.writeln(
        'gameRef\tdate\tlocation\topponent\thomeScore\tawayScore\tstatus');
    for (int i = 1; i <= sampleGameCount; i++) {
      final opponent =
          i <= sampleOpponentCount ? 'Opponent Team $i' : 'Opponent Team 1';
      final location = i % 2 == 1 ? 'HOME' : 'AWAY';
      buffer.writeln(
          'G$i\t2024-03-${i.toString().padLeft(2, '0')}\t$location\t$opponent\t3\t1\tFinal');
    }
    buffer.writeln();

    // Game events section
    buffer.writeln('[GAME]');
    buffer.writeln(
        'gameRef\tplayerNumber\teventType\teventMinute\teventPeriod\teventData');
    buffer.writeln('# Example: Goal with assist');
    buffer.writeln('G1\t1\tShot\t23\t1\t0');
    buffer.writeln('G1\t2\tAssist\t23\t1\t0');
    buffer.writeln('# Example: Another goal');
    buffer.writeln('G1\t3\tShot\t45\t2\t0');
    buffer.writeln('G1\t1\tAssist\t45\t2\t0');
    buffer.writeln();

    // Footer comments
    buffer.writeln('# Event Type Reference:');
    buffer.writeln(
        '# Shot: eventData 0=goal, 1=saved, 2=post, 3=off target, 4=blocked');
    buffer.writeln('# Assist: eventData always 0');
    buffer.writeln('# Card: eventData 0=yellow, 1=second yellow, 2=red');
    buffer.writeln('# PenaltyKick: eventData 0=goal, 1=saved, 2=missed');
    buffer.writeln('# Save, Foul, Offsides: eventData always 0');
    buffer.writeln();
    buffer.writeln('# Notes:');
    buffer.writeln('# - Use TAB character between columns (not spaces)');
    buffer.writeln('# - gameRef must be unique per game');
    buffer.writeln('# - playerNumber must match a player in ROSTER section');
    buffer.writeln('# - opponent must match a team in OPPONENTS section');
    buffer.writeln('# - Date format: YYYY-MM-DD');
    buffer.writeln('# - location: HOME or AWAY');

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  /// Generate template with example data (full working example)
  Uint8List generateExampleTemplate() {
    final buffer = StringBuffer();

    buffer.writeln('# Complete Season Import - Example');
    buffer.writeln('# This is a working example you can test with');
    buffer.writeln();

    buffer.writeln('[SEASON]');
    buffer.writeln('name\tyear\tlogoUrl');
    buffer.writeln('2024 Spring Season\t2024\t');
    buffer.writeln();

    buffer.writeln('[ROSTER]');
    buffer.writeln('number\tfirstName\tlastName\tposition\tgrade');
    buffer.writeln('1\tJohn\tSmith\tGK\tSR');
    buffer.writeln('7\tMike\tJohnson\tF\tJR');
    buffer.writeln('10\tSarah\tWilliams\tM\tSO');
    buffer.writeln('15\tChris\tDavis\tD\tFR');
    buffer.writeln();

    buffer.writeln('[OPPONENTS]');
    buffer.writeln('fullName\tshortName\tcity\tstate');
    buffer.writeln('Central High School\tCentral\tDowntown\tIA');
    buffer.writeln('Westside Academy\tWestside\tWestville\tIA');
    buffer.writeln('North Valley United\tNorth Valley\tNorthtown\tIA');
    buffer.writeln();

    buffer.writeln('[SCHEDULE]');
    buffer.writeln(
        'gameRef\tdate\tlocation\topponent\thomeScore\tawayScore\tstatus');
    buffer.writeln('G1\t2024-03-15\tHOME\tCentral High School\t3\t1\tFinal');
    buffer.writeln('G2\t2024-03-22\tAWAY\tWestside Academy\t2\t2\tFinal');
    buffer.writeln('G3\t2024-03-29\tHOME\tNorth Valley United\t4\t0\tFinal');
    buffer.writeln();

    buffer.writeln('[GAME]');
    buffer.writeln(
        'gameRef\tplayerNumber\teventType\teventMinute\teventPeriod\teventData');
    buffer.writeln('G1\t7\tShot\t15\t1\t0');
    buffer.writeln('G1\t10\tAssist\t15\t1\t0');
    buffer.writeln('G1\t7\tShot\t32\t2\t0');
    buffer.writeln('G1\t7\tShot\t78\t2\t0');
    buffer.writeln('G1\t10\tAssist\t78\t2\t0');
    buffer.writeln('G2\t10\tShot\t25\t1\t0');
    buffer.writeln('G2\t7\tAssist\t25\t1\t0');
    buffer.writeln('G2\t7\tShot\t65\t2\t0');
    buffer.writeln('G3\t7\tShot\t12\t1\t0');
    buffer.writeln('G3\t10\tShot\t28\t1\t0');
    buffer.writeln('G3\t7\tAssist\t28\t1\t0');
    buffer.writeln('G3\t10\tShot\t55\t2\t0');
    buffer.writeln('G3\t7\tShot\t82\t2\t0');
    buffer.writeln('G3\t15\tAssist\t82\t2\t0');

    return Uint8List.fromList(utf8.encode(buffer.toString()));
  }

  /// Download template (web/mobile)
  Future<void> downloadTemplate({
    required String fileName,
    bool includeExamples = false,
  }) async {
    try {
      final bytes =
          includeExamples ? generateExampleTemplate() : generateTemplate();

      if (kIsWeb) {
        await _downloadWebFile(bytes, fileName);
      } else {
        await _saveMobileFile(bytes, fileName);
      }

      debugPrint('Template downloaded: $fileName');
    } catch (e, stackTrace) {
      debugPrint('Error downloading template: $e\n$stackTrace');
      rethrow;
    }
  }

  Future<void> _downloadWebFile(Uint8List bytes, String fileName) async {
    debugPrint('Web download not yet implemented: $fileName');
    // TODO: Implement web download
  }

  Future<void> _saveMobileFile(Uint8List bytes, String fileName) async {
    debugPrint('Mobile save not yet implemented: $fileName');
    // TODO: Implement mobile file save
  }
}
