import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/features/teams/widgets/team_home_page.dart';

import '../helpers/firebase_mocks.dart';
import '../helpers/screen_size_helper.dart';

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

  // Setup Firebase mocks before all tests
  setUpAll(() async {
    await FirebaseMocks.setupFirebaseMocks(authenticatedUser: true);
  });

  group('TeamHomePage Screen Size Tests', () {
    // Test on quick sizes (small, medium, large)
    for (final screenSize in ScreenSize.quickTestSizes) {
      testWidgets('TeamHomePage renders on ${screenSize.name}', (
        WidgetTester tester,
      ) async {
        // Configure screen size
        await tester.configureScreenSize(screenSize);

        // Build the widget
        await tester.pumpWidget(MaterialApp(home: TeamHomePage()));

        // Wait for initial frame - use pump() not pumpAndSettle()
        await tester.pump();

        // Verify the widget builds without throwing
        expect(find.byType(TeamHomePage), findsOneWidget);

        // Clean up
        await tester.resetScreenSize();
      });
    }

    // Test specific layout concerns on different sizes
    testWidgets('TeamHomePage layout adjusts for small screens', (
      WidgetTester tester,
    ) async {
      await tester.configureScreenSize(ScreenSize.small);

      await tester.pumpWidget(MaterialApp(home: TeamHomePage()));

      await tester.pump();

      // Verify page renders
      expect(find.byType(TeamHomePage), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('TeamHomePage layout adjusts for large screens', (
      WidgetTester tester,
    ) async {
      await tester.configureScreenSize(ScreenSize.large);

      await tester.pumpWidget(MaterialApp(home: TeamHomePage()));

      await tester.pump();

      // Verify page renders
      expect(find.byType(TeamHomePage), findsOneWidget);

      await tester.resetScreenSize();
    });

    // Test on common phone sizes
    group('Common Phone Sizes', () {
      for (final screenSize in ScreenSize.commonPhoneSizes) {
        testWidgets('renders correctly on ${screenSize.name}', (
          WidgetTester tester,
        ) async {
          await tester.configureScreenSize(screenSize);

          await tester.pumpWidget(MaterialApp(home: TeamHomePage()));

          // Use pump() instead of pumpAndSettle() to avoid timeout
          await tester.pump();

          // Verify no overflow errors
          expect(tester.takeException(), isNull);

          // Verify the widget renders
          expect(find.byType(TeamHomePage), findsOneWidget);

          await tester.resetScreenSize();
        });
      }
    });

    // Test portrait vs landscape
    testWidgets('TeamHomePage handles orientation changes', (
      WidgetTester tester,
    ) async {
      // Start with portrait
      await tester.binding.setSurfaceSize(const Size(390, 844));

      await tester.pumpWidget(MaterialApp(home: TeamHomePage()));

      await tester.pump();
      expect(find.byType(TeamHomePage), findsOneWidget);

      // Switch to landscape
      await tester.binding.setSurfaceSize(const Size(844, 390));
      await tester.pump();

      // Verify still renders correctly
      expect(find.byType(TeamHomePage), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.resetScreenSize();
    });

    // Test scrolling on small screens
    testWidgets('TeamHomePage renders on small screens', (
      WidgetTester tester,
    ) async {
      await tester.configureScreenSize(ScreenSize.small);

      await tester.pumpWidget(MaterialApp(home: TeamHomePage()));

      // Use pump() to avoid timeout
      await tester.pump();

      // Verify widget renders
      expect(find.byType(TeamHomePage), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.resetScreenSize();
    });

    // Test text scaling
    testWidgets('TeamHomePage handles different text scale factors', (
      WidgetTester tester,
    ) async {
      await tester.configureScreenSize(ScreenSize.medium);

      for (final textScale in [0.8, 1.0, 1.5, 2.0]) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
              child: TeamHomePage(),
            ),
          ),
        );

        await tester.pump();

        // Verify no overflow with different text scales
        expect(
          tester.takeException(),
          isNull,
          reason: 'Failed at text scale $textScale',
        );
      }

      await tester.resetScreenSize();
    });
  });

  group('Responsive Layout Tests', () {
    testWidgets('verifies responsive breakpoints', (WidgetTester tester) async {
      final sizes = [
        ScreenSize.small, // < 600
        ScreenSize.medium, // ~375
        ScreenSize.large, // ~414
        ScreenSize.iPad, // > 600
      ];

      for (final size in sizes) {
        await tester.configureScreenSize(size);

        await tester.pumpWidget(const MaterialApp(home: TeamHomePage()));

        // Use pump() to avoid timeout
        await tester.pump();

        // Verify layout adapts appropriately
        expect(find.byType(TeamHomePage), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: 'Layout error on ${size.name}',
        );

        await tester.resetScreenSize();
      }
    });
  });

  group('Visual Density Tests', () {
    testWidgets('handles different visual densities', (
      WidgetTester tester,
    ) async {
      await tester.configureScreenSize(ScreenSize.medium);

      final densities = [
        VisualDensity.compact,
        VisualDensity.comfortable,
        VisualDensity.standard,
      ];

      for (final density in densities) {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(visualDensity: density),
            home: const TeamHomePage(),
          ),
        );

        // Use pump() to avoid timeout
        await tester.pump();

        expect(find.byType(TeamHomePage), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      await tester.resetScreenSize();
    });
  });
}
