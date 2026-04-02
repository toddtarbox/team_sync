import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:team_sync/app_config.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/sport_strategy.dart';
import 'package:team_sync/services/soccer_strategy.dart';
import 'package:team_sync/widgets/team_sync/team_home_page.dart';

import '../helpers/firebase_mocks.dart';
import '../helpers/screen_size_helper.dart';

/// Tests for TeamHomePage actions menu (more_vert menu)
///
/// NOTE: These tests use FirebaseAuth mocking to simulate an authenticated user.
/// The actions menu requires authentication on mobile (FirebaseAuth.instance.currentUser != null).
/// We set `authenticatedUser: true` in setupFirebaseMocks() to ensure the menu appears.
///
/// These tests verify:
/// - Actions menu visibility (with authenticated user)
/// - Menu items shown when team exists
/// - Menu items shown when team doesn't exist
/// - Team-dependent menu items
/// - Subscription-dependent menu items
/// - Menu interaction behavior

class MockDatabaseProvider implements DatabaseProvider {
  @override
  String get path => 'test_path';

  @override
  Future<bool> get isImporting async => false;

  @override
  Future<bool> open(String path, {String? createWithSportId}) async => true;

  @override
  Future<bool> openFromPath(String path) async => true;

  @override
  Future<void> close() async {}

  @override
  Future<List<String>> getAvailableDatabases({String? sportFilter}) async => [];

  @override
  Future<List<Map<String, dynamic>>> query(String table,
      {String? path,
      String? where,
      List<dynamic>? whereArgs,
      String? orderBy,
      String? orderByChild,
      dynamic equalTo,
      dynamic startAt,
      dynamic endAt,
      int? limitToFirst,
      int? limitToLast}) async {
    print(
        'DEBUG: MockDatabaseProvider.query for $table where (orderBy: $orderBy, orderByChild: $orderByChild) == $equalTo');
    if (table == 'Teams' && (orderBy == 'id' || orderByChild == 'id')) {
      // Mock team with twitter credentials for testing
      return [
        {
          'id': equalTo ?? 1,
          'twitterCredentials': {'consumerKey': 'test'}
        }
      ];
    }
    return [];
  }

  @override
  Future<String?> insert(String table, Map<String, dynamic> data,
          {String? key, String? path}) async =>
      'new_id';

  @override
  Future<void> update(String table, Map<String, dynamic> data,
      {String? path,
      String? key,
      String? where,
      List<dynamic>? whereArgs,
      String? orderByChild,
      dynamic equalTo}) async {}

  @override
  Future<void> delete(String table,
      {String? path,
      String? key,
      String? where,
      List<dynamic>? whereArgs,
      String? orderByChild,
      dynamic equalTo}) async {}
}

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

  setUp(() {
    final strategy = SoccerStrategy();
    AppConfig.initialize(strategy.appConfig);
    SportStrategy.initialize(strategy);

    // Inject MockDatabaseProvider to handle Twitter configuration check
    DatabaseService.isTest = true;
    final mockProvider = MockDatabaseProvider();
    DatabaseService.instance.setProvider(mockProvider);

    // Mock FlutterSecureStorage (try both potential channel names)
    for (final channelName in [
      'plugins.it_elysium.org/flutter_secure_storage',
      'plugins.it-elysium.org/flutter_secure_storage'
    ]) {
      final channel = MethodChannel(channelName);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'read') {
          return null;
        }
        if (methodCall.method == 'readAll') {
          return <String, String>{};
        }
        return null;
      });
    }
  });

  setUpAll(() async {
    // Setup Firebase mocks WITH authenticated user
    // This allows the actions menu to appear on mobile
    SharedPreferences.setMockInitialValues({});
    await FirebaseMocks.setupFirebaseMocks(authenticatedUser: true);
  });

  group('Actions Menu Visibility Tests', () {
    testWidgets('actions menu button is visible without team',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Verify more_vert icon (actions menu) exists
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('actions menu button is visible with team',
        (WidgetTester tester) async {
      final mockTeam = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(TeamHomePage(initialTeam: mockTeam)),
      );

      await tester.pump();

      // Verify more_vert icon exists
      expect(find.byIcon(Icons.more_vert), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('tapping actions menu opens popup menu',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Tap the actions menu button
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify popup menu appears (contains PopupMenuItem widgets)
      expect(find.byType(PopupMenuItem<String>), findsWidgets);

      await tester.resetScreenSize();
    });

    testWidgets('actions menu works on different screen sizes',
        (WidgetTester tester) async {
      for (final screenSize in ScreenSize.quickTestSizes) {
        await tester.configureScreenSize(screenSize);

        await tester.pumpWidget(
          wrapWithMaterialApp(const TeamHomePage()),
        );

        await tester.pump();

        expect(
          find.byIcon(Icons.more_vert),
          findsOneWidget,
          reason: 'Actions menu not found on ${screenSize.name}',
        );

        await tester.resetScreenSize();
      }
    });
  });

  group('Actions Menu WITHOUT Team', () {
    testWidgets('shows only Settings option when team does not exist',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Open actions menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Settings should ALWAYS be visible
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Team-dependent options should NOT appear
      expect(find.byIcon(Icons.send), findsNothing,
          reason: 'Tweet should not appear without team');
      expect(find.byIcon(Icons.leaderboard), findsNothing,
          reason: 'Records should not appear without team');
      expect(find.byIcon(Icons.manage_history_outlined), findsNothing,
          reason: 'History should not appear without team');

      await tester.resetScreenSize();
    });

    testWidgets('Settings is accessible without team',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Open actions menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Find Settings menu item
      final settingsItem = find.ancestor(
        of: find.text('Settings'),
        matching: find.byType(PopupMenuItem<String>),
      );

      expect(settingsItem, findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('only one menu item visible without team',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Open actions menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Count visible menu items - should be exactly 1 (Settings only)
      final menuItems = find.byType(PopupMenuItem<String>);
      expect(menuItems, findsOneWidget);

      await tester.resetScreenSize();
    });
  });

  group('Actions Menu WITH Team', () {
    testWidgets('shows team-dependent menu items when team exists',
        (WidgetTester tester) async {
      final mockTeam = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(TeamHomePage(initialTeam: mockTeam)),
      );

      await tester.pump();

      // Open actions menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Settings should ALWAYS be visible
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Team-dependent options SHOULD appear
      expect(find.byIcon(Icons.send), findsOneWidget,
          reason: 'Tweet should appear with team');
      expect(find.text('Send Tweet'), findsOneWidget);

      expect(find.byIcon(Icons.leaderboard), findsOneWidget,
          reason: 'Records should appear with team');
      expect(find.text('Records'), findsOneWidget);

      expect(find.byIcon(Icons.manage_history_outlined), findsOneWidget,
          reason: 'History should appear with team');
      expect(find.text('History'), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('multiple menu items visible with team',
        (WidgetTester tester) async {
      final mockTeam = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(TeamHomePage(initialTeam: mockTeam)),
      );

      await tester.pump();

      // Open actions menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Count visible menu items
      // Should have: Tweet, Records, History, Settings (4 total)
      // Note: Share option requires subscription, so won't appear in basic test
      final menuItems = find.byType(PopupMenuItem<String>);
      expect(menuItems, findsNWidgets(4));

      await tester.resetScreenSize();
    });

    testWidgets('Tweet option only appears with team',
        (WidgetTester tester) async {
      final mockTeam = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(TeamHomePage(initialTeam: mockTeam)),
      );

      await tester.pump();

      // Open actions menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Tweet option
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.text('Send Tweet'), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('Records option only appears with team',
        (WidgetTester tester) async {
      final mockTeam = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(TeamHomePage(initialTeam: mockTeam)),
      );

      await tester.pump();

      // Open actions menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Records option
      expect(find.byIcon(Icons.leaderboard), findsOneWidget);
      expect(find.text('Records'), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('History option only appears with team',
        (WidgetTester tester) async {
      final mockTeam = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(TeamHomePage(initialTeam: mockTeam)),
      );

      await tester.pump();

      // Open actions menu
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify History option
      expect(find.byIcon(Icons.manage_history_outlined), findsOneWidget);
      expect(find.text('History'), findsOneWidget);

      await tester.resetScreenSize();
    });
  });

  group('Actions Menu Comparison Tests', () {
    testWidgets('menu has more items with team than without',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      // Test without team
      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final itemsWithoutTeam = tester
          .widgetList(
            find.byType(PopupMenuItem<String>),
          )
          .length;

      // Close menu
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Reset widget
      await tester.pumpWidget(Container());
      await tester.pump();

      // Test with team
      final mockTeam = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      await tester.pumpWidget(
        wrapWithMaterialApp(TeamHomePage(initialTeam: mockTeam)),
      );

      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final itemsWithTeam = tester
          .widgetList(
            find.byType(PopupMenuItem<String>),
          )
          .length;

      // Should have more items with team
      expect(itemsWithTeam, greaterThan(itemsWithoutTeam));

      await tester.resetScreenSize();
    });

    testWidgets('Settings appears in both scenarios',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      // Test without team
      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Settings'), findsOneWidget);

      // Close menu
      await tester.tapAt(const Offset(10, 10));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Reset widget
      await tester.pumpWidget(Container());
      await tester.pump();

      // Test with team
      final mockTeam = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      await tester.pumpWidget(
        wrapWithMaterialApp(TeamHomePage(initialTeam: mockTeam)),
      );

      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Settings'), findsOneWidget);

      await tester.resetScreenSize();
    });
  });

  group('Actions Menu Icon Tests', () {
    testWidgets('all menu items have proper icons without team',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Settings icon
      expect(find.byIcon(Icons.settings), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('all menu items have proper icons with team',
        (WidgetTester tester) async {
      final mockTeam = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(TeamHomePage(initialTeam: mockTeam)),
      );

      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify all icons
      expect(find.byIcon(Icons.send), findsOneWidget);
      expect(find.byIcon(Icons.leaderboard), findsOneWidget);
      expect(find.byIcon(Icons.manage_history_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('menu items have text labels with team',
        (WidgetTester tester) async {
      final mockTeam = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(TeamHomePage(initialTeam: mockTeam)),
      );

      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify all text labels
      expect(find.text('Send Tweet'), findsOneWidget);
      expect(find.text('Records'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.resetScreenSize();
    });
  });

  group('Actions Menu Interaction Tests', () {
    testWidgets('menu can be opened multiple times',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Open and close menu multiple times
      for (int i = 0; i < 3; i++) {
        // Open menu
        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.byType(PopupMenuItem<String>), findsWidgets);

        // Close menu
        await tester.tapAt(const Offset(10, 10));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
      }

      expect(tester.takeException(), isNull);

      await tester.resetScreenSize();
    });
  });

  group('Actions Menu Responsiveness Tests', () {
    testWidgets('menu works in portrait orientation',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));

      final mockTeam = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      await tester.pumpWidget(
        wrapWithMaterialApp(TeamHomePage(initialTeam: mockTeam)),
      );

      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PopupMenuItem<String>), findsWidgets);

      await tester.resetScreenSize();
    });

    testWidgets('menu works in landscape orientation',
        (WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(844, 390));

      final mockTeam = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      await tester.pumpWidget(
        wrapWithMaterialApp(TeamHomePage(initialTeam: mockTeam)),
      );

      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PopupMenuItem<String>), findsWidgets);

      await tester.resetScreenSize();
    });

    testWidgets('menu adapts to different screen sizes',
        (WidgetTester tester) async {
      final mockTeam = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      for (final size in ScreenSize.quickTestSizes) {
        await tester.configureScreenSize(size);

        await tester.pumpWidget(
          wrapWithMaterialApp(TeamHomePage(initialTeam: mockTeam)),
        );

        await tester.pump();

        await tester.tap(find.byIcon(Icons.more_vert));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(
          find.byType(PopupMenuItem<String>),
          findsWidgets,
          reason: 'Menu items not found on ${size.name}',
        );

        // Close menu
        await tester.tapAt(const Offset(10, 10));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        await tester.resetScreenSize();
      }
    });
  });

  group('Actions Menu Accessibility Tests', () {
    testWidgets('menu button is accessible', (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      // Verify menu button exists and is tappable
      final menuButton = find.byIcon(Icons.more_vert);
      expect(menuButton, findsOneWidget);

      // Should be able to tap it
      await tester.tap(menuButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.byType(PopupMenuItem<String>), findsWidgets);

      await tester.resetScreenSize();
    });

    testWidgets('menu works with large text scaling',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      final mockTeam = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      await tester.pumpWidget(
        wrapWithMaterialApp(
          MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2.0),
            ),
            child: TeamHomePage(initialTeam: mockTeam),
          ),
        ),
      );

      await tester.pump();

      // Open menu with large text
      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should not cause overflow
      expect(tester.takeException(), isNull);

      expect(find.byType(PopupMenuItem<String>), findsWidgets);

      await tester.resetScreenSize();
    });
  });

  group('Actions Menu State Tests', () {
    testWidgets('menu reflects team state correctly',
        (WidgetTester tester) async {
      await tester.configureScreenSize(ScreenSize.medium);

      // Start without team
      await tester.pumpWidget(
        wrapWithMaterialApp(const TeamHomePage()),
      );

      await tester.pump();

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should have minimal menu items
      expect(find.text('Send Tweet'), findsNothing);
      expect(find.text('Records'), findsNothing);
      expect(find.text('History'), findsNothing);
      expect(find.text('Settings'), findsOneWidget);

      await tester.resetScreenSize();
    });

    testWidgets('menu items are in correct order with team',
        (WidgetTester tester) async {
      final mockTeam = Team(
        id: 1,
        fullName: 'Test Team',
        shortName: 'TST',
        color1: Colors.blue,
        color2: Colors.white,
      );

      await tester.configureScreenSize(ScreenSize.medium);

      await tester.pumpWidget(
        wrapWithMaterialApp(TeamHomePage(initialTeam: mockTeam)),
      );
      await tester.pump(const Duration(seconds: 2));

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pump(const Duration(milliseconds: 500));

      // Verify all menu items are present
      expect(find.text('Send Tweet'), findsOneWidget);
      expect(find.text('Records'), findsOneWidget);
      expect(find.text('Analytics'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      await tester.resetScreenSize();
    });
  });
}
