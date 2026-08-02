import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/features/teams/widgets/team_home_page.dart';

import '../helpers/firebase_mocks.dart';
import '../helpers/mock_helpers.dart';
import '../helpers/screen_size_helper.dart';

/// Tests for TeamHomePage with Season data
///
/// These tests verify that the TeamHomePage renders correctly and
/// demonstrate how to create mock season data for testing.

/// Helper to wrap widget with MaterialApp and localization
Widget wrapWithMaterialApp(Widget child) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await FirebaseMocks.setupFirebaseMocks(authenticatedUser: true);
  });

  group('TeamHomePage Season Tests', () {
    testWidgets('renders without crashing', (WidgetTester tester) async {
      // Act: Render the widget
      await tester.configureScreenSize(ScreenSize.medium);
      await tester.pumpWidget(
        wrapWithMaterialApp(TeamHomePage()),
      );

      // Initial pump
      await tester.pump();

      // Assert: Verify widget rendered
      expect(find.byType(TeamHomePage), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.resetScreenSize();
    });

    testWidgets('renders on different screen sizes',
        (WidgetTester tester) async {
      // Test on multiple screen sizes
      for (final screenSize in ScreenSize.quickTestSizes) {
        await tester.configureScreenSize(screenSize);

        await tester.pumpWidget(
          wrapWithMaterialApp(TeamHomePage()),
        );

        await tester.pump();

        expect(
          find.byType(TeamHomePage),
          findsOneWidget,
          reason: 'Failed on ${screenSize.name}',
        );
        expect(
          tester.takeException(),
          isNull,
          reason: 'Error on ${screenSize.name}',
        );

        await tester.resetScreenSize();
      }
    });

    testWidgets('renders in portrait and landscape',
        (WidgetTester tester) async {
      // Test portrait
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(
        wrapWithMaterialApp(TeamHomePage()),
      );
      await tester.pump();

      expect(find.byType(TeamHomePage), findsOneWidget);
      expect(tester.takeException(), isNull);

      // Test landscape
      await tester.binding.setSurfaceSize(const Size(844, 390));
      await tester.pump();

      expect(find.byType(TeamHomePage), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.resetScreenSize();
    });

    testWidgets('handles text scaling', (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      for (final textScale in [0.8, 1.0, 1.5, 2.0]) {
        await tester.pumpWidget(
          wrapWithMaterialApp(
            MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
              child: const TeamHomePage(),
            ),
          ),
        );

        await tester.pump();

        expect(
          tester.takeException(),
          isNull,
          reason: 'Failed at text scale $textScale',
        );
      }

      await tester.resetScreenSize();
    });
  });

  group('Season Mock Data Creation Tests', () {
    test('creates single season mock data', () {
      // Create a season
      final season = MockHelpers.createMockSeasonMap(
        id: 1,
        name: '2024 Fall Season',
        teamId: 1,
      );

      // Verify structure
      expect(season['id'], equals(1));
      expect(season['name'], equals('2024 Fall Season'));
      expect(season['teamId'], equals(1));
    });

    test('creates multiple seasons', () {
      // Create multiple seasons
      final seasons = MockHelpers.createMockSeasons(3, teamId: 1);

      // Verify
      expect(seasons.length, equals(3));
      expect(seasons[0]['id'], equals(1));
      expect(seasons[1]['id'], equals(2));
      expect(seasons[2]['id'], equals(3));
      expect(seasons.every((s) => s['teamId'] == 1), isTrue);
    });

    test('creates season with custom properties', () {
      // Create custom season
      final season = MockHelpers.createMockSeasonMap(
        id: 5,
        name: 'Custom Season',
        teamId: 10,
        logoUrl: 'https://example.com/logo.png',
      );

      // Verify custom properties
      expect(season['id'], equals(5));
      expect(season['name'], equals('Custom Season'));
      expect(season['teamId'], equals(10));
      expect(season['logoUrl'], equals('https://example.com/logo.png'));
    });

    test('creates team mock data', () {
      // Create team
      final team = MockHelpers.createMockTeamMap(
        id: 1,
        fullName: 'Test Soccer Team',
        shortName: 'TST',
      );

      // Verify
      expect(team['id'], equals(1));
      expect(team['fullName'], equals('Test Soccer Team'));
      expect(team['shortName'], equals('TST'));
    });

    test('creates player mock data', () {
      // Create players
      final players = MockHelpers.createMockPlayers(5, teamId: 1, seasonId: 1);

      // Verify
      expect(players.length, equals(5));
      expect(players[0]['teamId'], equals(1));
      expect(players[0]['seasonId'], equals(1));
      expect(players[0]['number'], equals(1));
      expect(players[4]['number'], equals(5));
    });

    test('creates game mock data', () {
      // Create games
      final games = MockHelpers.createMockGames(
        3,
        seasonId: 1,
        homeTeamId: 1,
        awayTeamId: 2,
      );

      // Verify
      expect(games.length, equals(3));
      expect(games[0]['seasonId'], equals(1));
      expect(games[0]['homeTeamId'], equals(1));
      expect(games[0]['awayTeamId'], equals(2));
    });

    test('creates complete season data structure', () {
      // Create complete season with related data
      final team = MockHelpers.createMockTeamMap(id: 1);
      final season = MockHelpers.createMockSeasonMap(id: 1, teamId: 1);
      final players = MockHelpers.createMockPlayers(11, teamId: 1, seasonId: 1);
      final games = MockHelpers.createMockGames(
        5,
        seasonId: 1,
        homeTeamId: 1,
        awayTeamId: 2,
      );

      // Verify data structure relationships
      expect(team['id'], equals(season['teamId']));
      expect(players.every((p) => p['seasonId'] == season['id']), isTrue);
      expect(games.every((g) => g['seasonId'] == season['id']), isTrue);
      expect(players.length, equals(11));
      expect(games.length, equals(5));
    });

    test('creates season data for multiple years', () {
      // Create seasons for multiple years
      final seasons = [
        MockHelpers.createMockSeasonMap(id: 1, name: '2022 Season', teamId: 1),
        MockHelpers.createMockSeasonMap(id: 2, name: '2023 Season', teamId: 1),
        MockHelpers.createMockSeasonMap(id: 3, name: '2024 Season', teamId: 1),
      ];

      // Verify chronological data
      expect(seasons.length, equals(3));
      expect(seasons[0]['name'], contains('2022'));
      expect(seasons[1]['name'], contains('2023'));
      expect(seasons[2]['name'], contains('2024'));
    });
  });
}
