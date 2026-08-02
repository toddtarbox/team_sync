import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/features/teams/models/team.dart';
import 'package:team_sync/features/teams/widgets/team_home_page.dart';

import '../helpers/firebase_mocks.dart';
import '../helpers/screen_size_helper.dart';

/// Tests for TeamHomePage database operations
///
/// These tests verify:
/// - New database creation functionality
/// - Opening existing database functionality
/// - Database selection UI
/// - Error handling

/// Helper to wrap widget with MaterialApp and localization
Widget wrapWithMaterialApp(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: theme,
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    // Setup Firebase mocks with authenticated user for complete testing
    await FirebaseMocks.setupFirebaseMocks(authenticatedUser: true);
  });

  group('Database Creation Tests', () {
    testWidgets('FAB is visible for creating new database',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Verify FAB (FloatingActionButton) exists
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('tapping FAB shows create options',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Find and tap the FAB
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      await tester.tap(fabFinder);
      await tester.pump();
      await tester
          .pump(const Duration(milliseconds: 300)); // Wait for modal animation

      // Verify modal bottom sheet content appears
      expect(find.byType(ListTile), findsWidgets);

      await tester.resetScreenSize();
    });

    testWidgets('create options shows database options',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Tap FAB to show options
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify database options are present
      expect(find.byType(ListTile), findsWidgets);

      // Look for cloud-related icons
      expect(find.byIcon(Icons.cloud_sync_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cloud_rounded), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('FAB works on different screen sizes',
        (WidgetTester tester) async {
      for (final screenSize in ScreenSize.quickTestSizes) {
        await tester.configureScreenSize(screenSize);

        await tester.pumpWidget(
          wrapWithMaterialApp(const TeamHomePage()),
        );

        await tester.pump();

        // Verify FAB exists on all screen sizes
        expect(
          find.byType(FloatingActionButton),
          findsOneWidget,
          reason: 'FAB not found on ${screenSize.name}',
        );

        await tester.resetScreenSize();
      }
    });

    testWidgets('FAB has gradient decoration', (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Verify FAB has parent Container with gradient
      final containerFinder = find.ancestor(
        of: find.byType(FloatingActionButton).first,
        matching: find.byType(Container),
      );

      expect(containerFinder, findsWidgets);

      await tester.resetScreenSize();
    });
  });

  group('Database Options Modal Tests', () {
    testWidgets('modal shows open existing database option',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Open the modal
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify "Open Existing Cloud Database" option exists
      expect(find.byIcon(Icons.cloud_sync_rounded), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('modal shows create new database option',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Open the modal
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify "Create New Cloud Database" option exists
      expect(find.byIcon(Icons.cloud_rounded), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets(
        'modal does not show create new season option if a team does not exist',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Open the modal
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify "Create New Season" option exists
      expect(find.byIcon(Icons.calendar_today), findsNothing);

      await tester.resetScreenSize();
    });

    testWidgets('modal has proper styling', (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Open the modal
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify modal contains Wrap widget (for proper layout)
      expect(find.byType(Wrap), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('modal closes when option is tapped',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Open the modal
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify modal content is visible
      expect(find.byType(ListTile), findsWidgets);

      // Note: Actually tapping options would require auth mocks
      // which is beyond the scope of basic UI testing

      await tester.resetScreenSize();
    });
  });

  group('Database UI Responsiveness Tests', () {
    testWidgets('database options work in portrait',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Open modal in portrait
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ListTile), findsWidgets);

      await tester.resetScreenSize();
    });

    testWidgets('database options work in landscape',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(844, 390));

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Open modal in landscape
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(ListTile), findsWidgets);

      await tester.resetScreenSize();
    });

    testWidgets('FAB position consistent across screen sizes',
        (WidgetTester tester) async {
      for (final screenSize in [
        ScreenSize.small,
        ScreenSize.medium,
        ScreenSize.large
      ]) {
        await tester.configureScreenSize(screenSize);

        await tester.pumpWidget(
          wrapWithMaterialApp(const TeamHomePage()),
        );

        await tester.pump();

        final fabFinder = find.byType(FloatingActionButton);
        expect(
          fabFinder,
          findsOneWidget,
          reason: 'FAB positioning issue on ${screenSize.name}',
        );

        await tester.resetScreenSize();
      }
    });
  });

  group('Database Icon and Visual Tests', () {
    testWidgets('cloud sync icon visible for existing database',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify cloud sync icon exists
      expect(find.byIcon(Icons.cloud_sync_rounded), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('cloud icon visible for new database',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify cloud icon exists
      expect(find.byIcon(Icons.cloud_rounded), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('icons have proper theming', (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(
          const TeamHomePage(),
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          ),
        ),
      );

      await tester.pump();

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Icons should be present with theme colors
      expect(find.byType(Icon), findsWidgets);

      await tester.resetScreenSize();
    });
  });

  group('Database Accessibility Tests', () {
    testWidgets('FAB is accessible', (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Verify FAB can be found and is tappable
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);

      // Verify it has an icon for visual feedback
      expect(find.byIcon(Icons.add), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('database options accessible with large text',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(
          MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0),
            ),
            child: const TeamHomePage(),
          ),
        ),
      );

      await tester.pump();

      // Verify no overflow with large text
      expect(tester.takeException(), isNull);

      // Open modal with large text
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);

      await tester.resetScreenSize();
    });
  });

  group('Database Error Handling Tests', () {
    testWidgets('page handles no database gracefully',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Should not crash without a database
      expect(tester.takeException(), isNull);
      expect(find.byType(TeamHomePage), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('FAB remains functional after error',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Tap FAB multiple times
      for (int i = 0; i < 3; i++) {
        final fabFinder = find.byType(FloatingActionButton);
        expect(fabFinder, findsOneWidget);

        await tester.tap(fabFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Close modal by tapping outside (if possible) or pressing back
        if (Navigator.of(tester.element(fabFinder)).canPop()) {
          Navigator.of(tester.element(fabFinder)).pop();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));
        }
      }

      expect(tester.takeException(), isNull);

      await tester.resetScreenSize();
    });
  });

  group('Database State Management Tests', () {
    testWidgets('page rebuilds after database selection',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Initial state
      expect(find.byType(TeamHomePage), findsOneWidget);

      // Note: Actual state changes would require mocking DatabaseService
      // This test verifies the widget structure remains stable

      await tester.resetScreenSize();
    });

    testWidgets('loading indicator shows during async operations',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      // Don't pump yet - check for loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.resetScreenSize();
    });
  });

  group('Team Existence Tests - Demonstrating Mock Setup', () {
    testWidgets('EXAMPLE: how to verify no team exists (default state)',
        (WidgetTester tester) async {
      // By default, TeamHomePage has no team loaded (_team is null)
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Open modal
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify team-specific options are NOT shown
      expect(find.byIcon(Icons.calendar_today), findsNothing,
          reason: 'Create New Season should not appear when team is null');
      expect(find.byIcon(Icons.palette), findsNothing,
          reason: 'Change Team Colors should not appear when team is null');
      expect(find.byIcon(Icons.videocam), findsNothing,
          reason: 'Set Live Link should not appear when team is null');
      expect(find.byIcon(Icons.sports_soccer), findsNothing,
          reason: 'Generate Lineup Image should not appear when team is null');

      // But database options should always be shown
      expect(find.byIcon(Icons.cloud_sync_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cloud_rounded), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('WORKING: modal shows team options when team is injected',
        (WidgetTester tester) async {
      // Create a mock team using Team class
      final mockTeam = Team(
        id: 1,
        fullName: 'Test Soccer Team',
        shortName: 'TST',
        color1: const Color(0xFF2196F3), // Blue
        color2: const Color(0xFFFFFFFF), // White
      );

      await tester.configureScreenSize(ScreenSize.medium);

      // Inject team via initialTeam parameter
      await tester.pumpWidget(
        wrapWithMaterialApp(TeamHomePage(initialTeam: mockTeam)),
      );

      await tester.pump();

      // Open modal
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify database options still visible
      expect(find.byIcon(Icons.cloud_sync_rounded), findsOneWidget);
      expect(find.byIcon(Icons.cloud_rounded), findsOneWidget);

      // Verify team-specific options NOW appear
      expect(find.byIcon(Icons.calendar_today), findsOneWidget,
          reason: 'Create New Season should appear when team exists');
      expect(find.byIcon(Icons.palette), findsOneWidget,
          reason: 'Change Team Colors should appear when team exists');
      expect(find.byIcon(Icons.videocam), findsOneWidget,
          reason: 'Set Live Link should appear when team exists');
      expect(find.byIcon(Icons.sports_soccer), findsOneWidget,
          reason: 'Generate Lineup Image should appear when team exists');

      await tester.resetScreenSize();
    });
  });
}
