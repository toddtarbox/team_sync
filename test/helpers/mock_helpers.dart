import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Mock data helpers for testing
class MockHelpers {
  /// Create a mock Season for testing
  static Map<String, dynamic> createMockSeasonMap({
    int? id,
    String? name,
    int teamId = 1,
    String? logoUrl,
  }) {
    return {
      'id': id ?? 1,
      'name': name ?? 'Test Season ${id ?? 1}',
      'teamId': teamId,
      'logoUrl': logoUrl,
    };
  }

  /// Create a mock Team for testing
  static Map<String, dynamic> createMockTeamMap({
    int? id,
    String? fullName,
    String? shortName,
    int? color1,
    int? color2,
    String? logoUrl,
  }) {
    return {
      'id': id ?? 1,
      'fullName': fullName ?? 'Test Team ${id ?? 1}',
      'shortName': shortName ?? 'Test ${id ?? 1}',
      'color1': color1 ?? 0xFF2196F3, // Blue
      'color2': color2 ?? 0xFFFFFFFF, // White
      'logoUrl': logoUrl,
    };
  }

  /// Create a mock Player for testing
  static Map<String, dynamic> createMockPlayerMap({
    int? id,
    int teamId = 1,
    int seasonId = 1,
    String? firstName,
    String? lastName,
    int? number,
  }) {
    return {
      'id': id ?? 1,
      'teamId': teamId,
      'seasonId': seasonId,
      'firstName': firstName ?? 'Player',
      'lastName': lastName ?? '${id ?? 1}',
      'number': number ?? (id ?? 1),
    };
  }

  /// Create a mock Game for testing
  static Map<String, dynamic> createMockGameMap({
    int? id,
    int seasonId = 1,
    int homeTeamId = 1,
    int awayTeamId = 2,
    int homeTeamScore = 0,
    int awayTeamScore = 0,
    DateTime? date,
    String? description,
  }) {
    return {
      'id': id ?? 1,
      'seasonId': seasonId,
      'homeTeamId': homeTeamId,
      'awayTeamId': awayTeamId,
      'homeTeamScore': homeTeamScore,
      'awayTeamScore': awayTeamScore,
      'date': (date ?? DateTime.now()).millisecondsSinceEpoch,
      'description': description,
      'gameStatus': 'scheduled',
    };
  }

  /// Create multiple mock seasons
  static List<Map<String, dynamic>> createMockSeasons(int count,
      {int teamId = 1}) {
    return List.generate(
      count,
      (index) => createMockSeasonMap(
        id: index + 1,
        name: '${DateTime.now().year - count + index + 1} Season',
        teamId: teamId,
      ),
    );
  }

  /// Create multiple mock players
  static List<Map<String, dynamic>> createMockPlayers(
    int count, {
    int teamId = 1,
    int seasonId = 1,
  }) {
    return List.generate(
      count,
      (index) => createMockPlayerMap(
        id: index + 1,
        teamId: teamId,
        seasonId: seasonId,
        firstName: 'Player',
        lastName: '${index + 1}',
        number: index + 1,
      ),
    );
  }

  /// Create multiple mock games
  static List<Map<String, dynamic>> createMockGames(
    int count, {
    int seasonId = 1,
    int homeTeamId = 1,
    int awayTeamId = 2,
  }) {
    return List.generate(
      count,
      (index) => createMockGameMap(
        id: index + 1,
        seasonId: seasonId,
        homeTeamId: homeTeamId,
        awayTeamId: awayTeamId,
        date: DateTime.now().add(Duration(days: index * 7)),
        description: 'Game ${index + 1}',
      ),
    );
  }
}

/// TestBinding configuration for widget tests
class TestBindingConfiguration {
  /// Setup common test bindings
  static void setup() {
    TestWidgetsFlutterBinding.ensureInitialized();
  }

  /// Setup with custom screen size
  static Future<void> setupWithScreenSize(Size size) async {
    setup();
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    await binding.setSurfaceSize(size);
  }
}
