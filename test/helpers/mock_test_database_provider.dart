import 'package:sqflite/sqflite.dart';
import 'package:team_sync/core/services/database_service.dart';

/// Mock DatabaseService provider for testing
///
/// This allows you to control whether a team exists in the database
/// for testing different scenarios.
class MockTestDatabaseProvider extends DatabaseProvider {
  final Map<String, List<Map<String, dynamic>>> _mockData = {};
  bool _isOpen = false;

  /// Set mock team data
  void setMockTeam(Map<String, dynamic>? teamData) {
    if (teamData != null) {
      _mockData['Teams'] = [teamData];
    } else {
      _mockData['Teams'] = [];
    }
  }

  /// Set mock seasons data
  void setMockSeasons(List<Map<String, dynamic>> seasons) {
    _mockData['Seasons'] = seasons;
  }

  /// Clear all mock data
  void clearMockData() {
    _mockData.clear();
  }

  @override
  Future<bool> open(String path, {String? createWithSportId}) async {
    _isOpen = true;
    return true;
  }

  @override
  Future<bool> openFromPath(String path) async {
    _isOpen = true;
    return true;
  }

  @override
  String get path => _isOpen ? 'mock_database.db' : '';

  @override
  Future<bool> get isImporting => Future.value(false);

  @override
  Future<void> close() async {
    _isOpen = false;
    _mockData.clear();
  }

  @override
  Future<List<String>> getAvailableDatabases({String? sportFilter}) async {
    return ['mock_db_1', 'mock_db_2'];
  }

  @override
  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? path,
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    String? orderByChild,
    dynamic equalTo,
    dynamic startAt,
    dynamic endAt,
    int? limitToFirst,
    int? limitToLast,
  }) async {
    final data = _mockData[table] ?? [];

    // Apply filtering if needed
    if (orderByChild != null && equalTo != null) {
      return data.where((item) => item[orderByChild] == equalTo).toList();
    }

    if (where != null && whereArgs != null) {
      // Simple where clause handling
      return data;
    }

    return data;
  }

  @override
  Future<String?> insert(
    String table,
    Map<String, dynamic> data, {
    ConflictAlgorithm? conflictAlgorithm,
    String? key,
    String? path,
  }) async {
    if (!_mockData.containsKey(table)) {
      _mockData[table] = [];
    }
    _mockData[table]!.add(data);
    return key ?? 'mock_key_${_mockData[table]!.length}';
  }

  @override
  Future<void> update(
    String table,
    Map<String, dynamic> data, {
    String? path,
    String? key,
    String? where,
    List<dynamic>? whereArgs,
    String? orderByChild,
    dynamic equalTo,
  }) async {
    // Mock update - no-op for now
  }

  @override
  Future<void> delete(
    String table, {
    String? path,
    String? key,
    String? where,
    List<dynamic>? whereArgs,
    String? orderByChild,
    dynamic equalTo,
  }) async {
    if (key != null && _mockData.containsKey(table)) {
      _mockData[table]!.removeWhere((item) => item['id']?.toString() == key);
    }
  }
}
