import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/season_page.dart';
import 'package:team_sync/widgets/season_record.dart';

import '../helpers/firebase_mocks.dart';
import '../helpers/mock_helpers.dart';

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
      List? whereArgs,
      String? orderBy,
      String? orderByChild,
      dynamic equalTo,
      dynamic startAt,
      dynamic endAt,
      int? limitToFirst,
      int? limitToLast}) async {
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
      List? whereArgs,
      String? orderByChild,
      dynamic equalTo}) async {}

  @override
  Future<void> delete(String table,
      {String? path,
      String? key,
      String? where,
      List? whereArgs,
      String? orderByChild,
      dynamic equalTo}) async {}
}

class TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}

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
    DatabaseService.isTest = true;
    await FirebaseMocks.setupFirebaseMocks(authenticatedUser: true);
    HttpOverrides.global = TestHttpOverrides();
    // Inject MockDatabaseProvider
    DatabaseService.instance.setProvider(MockDatabaseProvider());
  });

  group('SeasonPage Header Tests', () {
    late Season seasonWithImage;
    late Season seasonWithoutImage;
    late Team team;

    setUp(() {
      final teamMap = MockHelpers.createMockTeamMap(id: 1);
      team = Team.fromMap(teamMap);

      final seasonMapWithImage = MockHelpers.createMockSeasonMap(
          id: 1, teamId: 1, logoUrl: 'https://example.com/logo.png');
      seasonWithImage = Season.fromMap(seasonMapWithImage)..team = team;

      final seasonMapWithoutImage =
          MockHelpers.createMockSeasonMap(id: 2, teamId: 1);
      seasonWithoutImage = Season.fromMap(seasonMapWithoutImage)..team = team;
    });

    testWidgets('shows image header when logoUrl is present',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
            wrapWithMaterialApp(SeasonPage(season: seasonWithImage)));
        await tester.pump(Duration.zero);
      });
      await tester.pumpAndSettle();

      final containerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          if (decoration.image is DecorationImage) {
            final imageProvider = decoration.image!.image;
            if (imageProvider is NetworkImage) {
              return imageProvider.url == 'https://example.com/logo.png';
            }
          }
        }
        return false;
      });

      expect(containerFinder, findsOneWidget);
      expect(find.byType(SeasonRecord), findsOneWidget);
    },
        skip:
            true); // Missing Firebase Database mock plugin implementation causing crashes

    testWidgets('shows standard header when logoUrl is missing',
        (WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.pumpWidget(
            wrapWithMaterialApp(SeasonPage(season: seasonWithoutImage)));
        await tester.pump(Duration.zero);
      });
      await tester.pumpAndSettle();

      final containerFinder = find.byWidgetPredicate((widget) {
        if (widget is Container && widget.decoration is BoxDecoration) {
          final decoration = widget.decoration as BoxDecoration;
          if (decoration.image is DecorationImage) {
            return true;
          }
        }
        return false;
      });

      expect(containerFinder, findsNothing);
      expect(find.byType(SeasonRecord), findsOneWidget);
    },
        skip:
            true); // Missing Firebase Database mock plugin implementation causing crashes
  });
}
