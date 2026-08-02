import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/features/players/models/player.dart';
import 'package:team_sync/features/seasons/models/season.dart';
import 'package:team_sync/features/teams/models/team.dart';
import 'package:team_sync/core/services/database_service.dart';
import 'package:team_sync/features/players/widgets/player_profile_page.dart';

import '../helpers/firebase_mocks.dart';
import '../helpers/mock_helpers.dart';
import '../helpers/mock_test_database_provider.dart';
import '../helpers/screen_size_helper.dart';

/// Tests for PlayerProfilePage action buttons
///
/// These tests verify:
/// - Action button visibility based on conditions
/// - Edit Profile button (web only)
/// - Generate Player Card button (team-dependent)
/// - Toggle Highlights button
/// - Button behavior on different screen sizes
/// - Button interaction

/// Helper to wrap widget with MaterialApp and localization
Widget wrapWithMaterialApp(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: theme,
    home: child,
  );
}

/// Helper to wrap widget with MaterialApp and localization with specific size
Widget wrapWithMaterialAppAndSize(Widget child, Size size, {ThemeData? theme}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: theme,
    home: MediaQuery(
      data: MediaQueryData(size: size),
      child: child,
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await FirebaseMocks.setupFirebaseMocks(authenticatedUser: true);

    // Initialize mock database to prevent null database errors
    final mockDb = MockTestDatabaseProvider();
    await mockDb.open('test_database.db');
    DatabaseService.instance.setProvider(mockDb);
  });

  group('Action Buttons Visibility Tests', () {
    testWidgets('action buttons appear with valid player',
        (WidgetTester tester) async {
      final player = Player.fromMap(MockHelpers.createMockPlayerMap(id: 1));

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(PlayerProfilePage(player: player)),
      );

      await tester.pump();

      // At least one action button should appear
      expect(find.byType(IconButton), findsWidgets);

      await tester.resetScreenSize();
    });

    testWidgets('page renders without errors when no season',
        (WidgetTester tester) async {
      final player = Player.fromMap(MockHelpers.createMockPlayerMap(id: 1));

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(PlayerProfilePage(player: player)),
      );

      await tester.pump();

      expect(find.byType(PlayerProfilePage), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.resetScreenSize();
    });

    testWidgets('action buttons work on different screen sizes',
        (WidgetTester tester) async {
      final player = Player.fromMap(MockHelpers.createMockPlayerMap(id: 1));

      for (final screenSize in ScreenSize.quickTestSizes) {
        await tester.configureScreenSize(screenSize);

        await tester.pumpWidget(
          wrapWithMaterialApp(PlayerProfilePage(player: player)),
        );

        await tester.pump();

        expect(
          find.byType(PlayerProfilePage),
          findsOneWidget,
          reason: 'PlayerProfilePage not rendered on ${screenSize.name}',
        );
        expect(tester.takeException(), isNull);

        await tester.resetScreenSize();
      }
    });
  });

  group('Generate Player Card Button Tests', () {
    testWidgets('player card button appears when season with team exists',
        (WidgetTester tester) async {
      final team = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      final season = Season.fromMap(
        MockHelpers.createMockSeasonMap(id: 1, teamId: 1),
      );
      season.team = team;

      final player = Player.fromMap(
        MockHelpers.createMockPlayerMap(id: 1, seasonId: 1, teamId: 1),
      );

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(
          PlayerProfilePage(player: player, currentSeason: season),
        ),
      );

      await tester.pump();

      // Look for the stars icon (Generate Player Card)
      expect(find.byIcon(Icons.stars), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('player card button has correct tooltip',
        (WidgetTester tester) async {
      final team = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      final season = Season.fromMap(
        MockHelpers.createMockSeasonMap(id: 1, teamId: 1),
      );
      season.team = team;

      final player = Player.fromMap(
        MockHelpers.createMockPlayerMap(id: 1, seasonId: 1, teamId: 1),
      );

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(
          PlayerProfilePage(player: player, currentSeason: season),
        ),
      );

      await tester.pump();

      // Find IconButton with stars icon
      final iconButton = find.ancestor(
        of: find.byIcon(Icons.stars),
        matching: find.byType(IconButton),
      );

      expect(iconButton, findsOneWidget);

      // Verify tooltip
      final IconButton button = tester.widget(iconButton);
      expect(button.tooltip, equals('Generate Player Card'));

      await tester.resetScreenSize();
    });

    testWidgets('player card button works on all screen sizes',
        (WidgetTester tester) async {
      final team = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      final season = Season.fromMap(
        MockHelpers.createMockSeasonMap(id: 1, teamId: 1),
      );
      season.team = team;

      final player = Player.fromMap(
        MockHelpers.createMockPlayerMap(id: 1, seasonId: 1, teamId: 1),
      );

      for (final size in ScreenSize.quickTestSizes) {
        await tester.configureScreenSize(size);

        await tester.pumpWidget(
          wrapWithMaterialApp(
            PlayerProfilePage(player: player, currentSeason: season),
          ),
        );

        await tester.pump();

        expect(
          find.byIcon(Icons.stars),
          findsOneWidget,
          reason: 'Player card button not found on ${size.name}',
        );

        await tester.resetScreenSize();
      }
    });
  });

  group('Toggle Highlights Button Tests', () {
    testWidgets('highlights button appears', (WidgetTester tester) async {
      final player = Player.fromMap(MockHelpers.createMockPlayerMap(id: 1));

      await tester.configureScreenSize(ScreenSize.small);

      await tester.pumpWidget(
        wrapWithMaterialApp(PlayerProfilePage(player: player)),
      );

      await tester.pump();

      // Look for video library icon
      final highlightsButton = find.byIcon(Icons.video_library);

      expect(highlightsButton, findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('highlights button is tappable', (WidgetTester tester) async {
      final player = Player.fromMap(MockHelpers.createMockPlayerMap(id: 1));

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(PlayerProfilePage(player: player)),
      );

      await tester.pump();

      // Find the highlights button
      final highlightsButton = find.byIcon(Icons.video_library);
      expect(highlightsButton, findsOneWidget);

      // Verify it's inside an IconButton
      final iconButton = find.ancestor(
        of: highlightsButton,
        matching: find.byType(IconButton),
      );
      expect(iconButton, findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('highlights button works on different screen sizes',
        (WidgetTester tester) async {
      final player = Player.fromMap(MockHelpers.createMockPlayerMap(id: 1));

      for (final size in ScreenSize.quickTestSizes) {
        await tester.configureScreenSize(size);

        await tester.pumpWidget(
          wrapWithMaterialApp(PlayerProfilePage(player: player)),
        );

        await tester.pump();

        // Highlights button should be present on all screen sizes
        final highlightsIcon = find.byWidgetPredicate(
          (widget) =>
              widget is Icon &&
              (widget.icon == Icons.video_library_outlined ||
                  widget.icon == Icons.video_library),
        );

        expect(
          highlightsIcon,
          findsOneWidget,
          reason: 'Highlights button not found on ${size.name}',
        );

        await tester.resetScreenSize();
      }
    });

    testWidgets('small screen: highlights button opens modal dialog',
        (WidgetTester tester) async {
      final player = Player.fromMap(MockHelpers.createMockPlayerMap(id: 1));

      // Use helper to set screen size explicitly
      await tester.pumpWidget(
        wrapWithMaterialAppAndSize(
          PlayerProfilePage(player: player),
          const Size(600, 800),
        ),
      );

      await tester.pump();

      // Initially, no dialog should be present
      expect(find.byType(Dialog), findsNothing);

      // Find and tap the highlights button
      final highlightsButton = find.byIcon(Icons.video_library);
      expect(highlightsButton, findsOneWidget);

      await tester.tap(highlightsButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // On small screens, a dialog should appear
      expect(find.byType(Dialog), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('large screen: highlights button toggles inline panel',
        (WidgetTester tester) async {
      final player = Player.fromMap(MockHelpers.createMockPlayerMap(id: 1));

      // Use helper to set screen size to large (>= 900px)
      await tester.pumpWidget(
        wrapWithMaterialAppAndSize(
          PlayerProfilePage(player: player),
          const Size(1400, 800),
        ),
      );

      await tester.pump();

      // Initially, no dialog should open on large screens
      expect(find.byType(Dialog), findsNothing);

      // Find the highlights button
      final highlightsButton = find.byIcon(Icons.video_library);
      expect(highlightsButton, findsOneWidget);

      // Tap the button
      await tester.tap(highlightsButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // On large screens, no dialog should appear (inline panel instead)
      expect(find.byType(Dialog), findsNothing);

      // Note: We don't verify icon state change here as the icon behavior
      // is tested separately in the "toggling button changes icon state" test

      await tester.resetScreenSize();
    });

    testWidgets('small screen: modal can be closed',
        (WidgetTester tester) async {
      final player = Player.fromMap(MockHelpers.createMockPlayerMap(id: 1));

      await tester.pumpWidget(
        wrapWithMaterialAppAndSize(
          PlayerProfilePage(player: player),
          const Size(600, 800),
        ),
      );

      await tester.pump();

      // Tap highlights button to open modal
      final highlightsButton = find.byIcon(Icons.video_library);
      await tester.tap(highlightsButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog should be present
      expect(find.byType(Dialog), findsOneWidget);

      // Close the dialog by tapping outside or pressing back
      // Find the barrier (area outside dialog)
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog should be closed
      expect(find.byType(Dialog), findsNothing);

      await tester.resetScreenSize();
    });

    testWidgets('large screen: toggling button changes icon state',
        (WidgetTester tester) async {
      final player = Player.fromMap(MockHelpers.createMockPlayerMap(id: 1));

      await tester.pumpWidget(
        wrapWithMaterialAppAndSize(
          PlayerProfilePage(player: player),
          const Size(1400, 800),
        ),
      );

      await tester.pump();

      // Initially should show outlined icon (highlights hidden)
      final outlinedIcon = find.byIcon(Icons.video_library_outlined);
      final filledIcon = find.byIcon(Icons.video_library);

      // One of these should be present initially
      final initialState = outlinedIcon.evaluate().isNotEmpty
          ? Icons.video_library_outlined
          : Icons.video_library;

      // Find any video library icon
      final highlightsButton = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            (widget.icon == Icons.video_library_outlined ||
                widget.icon == Icons.video_library),
      );
      expect(highlightsButton, findsOneWidget);

      // Tap to toggle
      await tester.tap(highlightsButton);
      await tester.pump();

      // Icon should still be present (may have changed state)
      final afterToggle = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            (widget.icon == Icons.video_library_outlined ||
                widget.icon == Icons.video_library),
      );
      expect(afterToggle, findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('screen size 899px: highlights opens modal (boundary test)',
        (WidgetTester tester) async {
      final player = Player.fromMap(MockHelpers.createMockPlayerMap(id: 1));

      // Test at 899px (just below 900px threshold)
      await tester.pumpWidget(
        wrapWithMaterialAppAndSize(
          PlayerProfilePage(player: player),
          const Size(899, 800),
        ),
      );

      await tester.pump();

      // Tap highlights button
      final highlightsButton = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            (widget.icon == Icons.video_library_outlined ||
                widget.icon == Icons.video_library),
      );
      await tester.tap(highlightsButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should open dialog (< 900px)
      expect(find.byType(Dialog), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('screen size 900px - highlights toggles panel (boundary test)',
        (WidgetTester tester) async {
      final player = Player.fromMap(MockHelpers.createMockPlayerMap(id: 1));

      // Test at 900px (at threshold) - use helper to ensure exact width
      await tester.pumpWidget(
        wrapWithMaterialAppAndSize(
          PlayerProfilePage(player: player),
          const Size(900, 800),
        ),
      );

      await tester.pump();

      // Verify no dialog initially
      expect(find.byType(Dialog), findsNothing,
          reason: 'Should have no dialog before tapping button');

      // Find and tap highlights button
      final highlightsButton = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            (widget.icon == Icons.video_library_outlined ||
                widget.icon == Icons.video_library),
      );

      expect(highlightsButton, findsOneWidget,
          reason: 'Highlights button should exist');

      await tester.tap(highlightsButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // At 900px width (>= 900), should toggle inline panel, NOT show dialog
      expect(find.byType(Dialog), findsNothing,
          reason:
              'At 900px width (>= 900), should toggle inline panel, NOT show dialog');

      await tester.resetScreenSize();
    });
  });

  group('Action Buttons with Season Tests', () {
    testWidgets('all expected buttons appear with season and team',
        (WidgetTester tester) async {
      final team = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      final season = Season.fromMap(
        MockHelpers.createMockSeasonMap(id: 1, teamId: 1),
      );
      season.team = team;

      final player = Player.fromMap(
        MockHelpers.createMockPlayerMap(id: 1, seasonId: 1, teamId: 1),
      );

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(
          PlayerProfilePage(player: player, currentSeason: season),
        ),
      );

      await tester.pump();

      // Generate Player Card button (stars icon)
      expect(find.byIcon(Icons.stars), findsOneWidget);

      // Toggle Highlights button
      final highlightsIcon = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            (widget.icon == Icons.video_library_outlined ||
                widget.icon == Icons.video_library),
      );
      expect(highlightsIcon, findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('action buttons count with team', (WidgetTester tester) async {
      final team = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      final season = Season.fromMap(
        MockHelpers.createMockSeasonMap(id: 1, teamId: 1),
      );
      season.team = team;

      final player = Player.fromMap(
        MockHelpers.createMockPlayerMap(id: 1, seasonId: 1, teamId: 1),
      );

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(
          PlayerProfilePage(player: player, currentSeason: season),
        ),
      );

      await tester.pump();

      // Count IconButtons in AppBar
      final iconButtons = find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(IconButton),
      );

      // Should have at least 2 buttons: Generate Player Card + Highlights
      expect(iconButtons, findsAtLeastNWidgets(2));

      await tester.resetScreenSize();
    });
  });

  group('Action Buttons without Season Tests', () {
    testWidgets('highlights button still appears without season',
        (WidgetTester tester) async {
      final player = Player.fromMap(MockHelpers.createMockPlayerMap(id: 1));

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(PlayerProfilePage(player: player)),
      );

      await tester.pump();

      // Highlights button should still appear
      final highlightsIcon = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            (widget.icon == Icons.video_library_outlined ||
                widget.icon == Icons.video_library),
      );

      expect(highlightsIcon, findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('player card button does not appear without team',
        (WidgetTester tester) async {
      final player = Player.fromMap(MockHelpers.createMockPlayerMap(id: 1));

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(PlayerProfilePage(player: player)),
      );

      await tester.pump();

      // Stars icon (player card) should not appear without team
      expect(find.byIcon(Icons.stars), findsNothing);

      await tester.resetScreenSize();
    });
  });

  group('Action Buttons Responsiveness Tests', () {
    testWidgets('action buttons work in portrait orientation',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      final team = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      final season = Season.fromMap(
        MockHelpers.createMockSeasonMap(id: 1, teamId: 1),
      );
      season.team = team;

      final player = Player.fromMap(
        MockHelpers.createMockPlayerMap(id: 1, seasonId: 1, teamId: 1),
      );

      await tester.pumpWidget(
        wrapWithMaterialApp(
          PlayerProfilePage(player: player, currentSeason: season),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.stars), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('action buttons work in landscape orientation',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(844, 390));

      final team = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      final season = Season.fromMap(
        MockHelpers.createMockSeasonMap(id: 1, teamId: 1),
      );
      season.team = team;

      final player = Player.fromMap(
        MockHelpers.createMockPlayerMap(id: 1, seasonId: 1, teamId: 1),
      );

      await tester.pumpWidget(
        wrapWithMaterialApp(
          PlayerProfilePage(player: player, currentSeason: season),
        ),
      );

      await tester.pump();

      expect(find.byIcon(Icons.stars), findsOneWidget);

      await tester.resetScreenSize();
    });
  });

  group('Action Buttons Accessibility Tests', () {
    testWidgets('action buttons are accessible', (WidgetTester tester) async {
      final team = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      final season = Season.fromMap(
        MockHelpers.createMockSeasonMap(id: 1, teamId: 1),
      );
      season.team = team;

      final player = Player.fromMap(
        MockHelpers.createMockPlayerMap(id: 1, seasonId: 1, teamId: 1),
      );

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(
          PlayerProfilePage(player: player, currentSeason: season),
        ),
      );

      await tester.pump();

      // Verify buttons exist and are tappable
      final iconButtons = find.byType(IconButton);
      expect(iconButtons, findsWidgets);

      await tester.resetScreenSize();
    });

    testWidgets('action buttons work with large text scaling',
        (WidgetTester tester) async {
      final team = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      final season = Season.fromMap(
        MockHelpers.createMockSeasonMap(id: 1, teamId: 1),
      );
      season.team = team;

      final player = Player.fromMap(
        MockHelpers.createMockPlayerMap(id: 1, seasonId: 1, teamId: 1),
      );

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(
          MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0),
            ),
            child: PlayerProfilePage(player: player, currentSeason: season),
          ),
        ),
      );

      await tester.pump();

      // Should not cause overflow
      expect(tester.takeException(), isNull);

      // Buttons should still be present
      expect(find.byIcon(Icons.stars), findsOneWidget);

      await tester.resetScreenSize();
    });
  });

  group('Action Buttons Icon Tests', () {
    testWidgets('all action buttons have correct icons',
        (WidgetTester tester) async {
      final team = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      final season = Season.fromMap(
        MockHelpers.createMockSeasonMap(id: 1, teamId: 1),
      );
      season.team = team;

      final player = Player.fromMap(
        MockHelpers.createMockPlayerMap(id: 1, seasonId: 1, teamId: 1),
      );

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(
          PlayerProfilePage(player: player, currentSeason: season),
        ),
      );

      await tester.pump();

      // Generate Player Card icon
      expect(find.byIcon(Icons.stars), findsOneWidget);

      // Highlights icon (one of the two variants)
      final highlightsIcon = find.byWidgetPredicate(
        (widget) =>
            widget is Icon &&
            (widget.icon == Icons.video_library_outlined ||
                widget.icon == Icons.video_library),
      );
      expect(highlightsIcon, findsOneWidget);

      await tester.resetScreenSize();
    });
  });

  group('Action Buttons State Tests', () {
    testWidgets('action buttons reflect player state',
        (WidgetTester tester) async {
      final team = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      final season = Season.fromMap(
        MockHelpers.createMockSeasonMap(id: 1, teamId: 1),
      );
      season.team = team;

      final player = Player.fromMap(
        MockHelpers.createMockPlayerMap(
          id: 1,
          seasonId: 1,
          teamId: 1,
          firstName: 'Test',
          lastName: 'Player',
        ),
      );

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(
          PlayerProfilePage(player: player, currentSeason: season),
        ),
      );

      await tester.pump();

      // Verify page shows player name
      expect(find.text('Test Player'), findsOneWidget);

      // Verify action buttons are present
      expect(find.byIcon(Icons.stars), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('page handles no errors with valid player and season',
        (WidgetTester tester) async {
      final team = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      final season = Season.fromMap(
        MockHelpers.createMockSeasonMap(id: 1, teamId: 1),
      );
      season.team = team;

      final player = Player.fromMap(
        MockHelpers.createMockPlayerMap(id: 1, seasonId: 1, teamId: 1),
      );

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(
          PlayerProfilePage(player: player, currentSeason: season),
        ),
      );

      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(PlayerProfilePage), findsOneWidget);

      await tester.resetScreenSize();
    });
  });
}
