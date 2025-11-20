import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart' as fs;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:team_sync/services/database_sharing_service.dart';

/// Progress event emitted during Firestore -> RTDB import.
class ImportProgress {
  final String table; // table name (Teams, Players, ...)
  final int processed; // number processed so far
  final int total; // total to process (if known)
  final String stage; // 'reading', 'writing', 'done', 'error', 'cancelled'
  final String? message; // optional message or error

  ImportProgress({
    required this.table,
    required this.processed,
    required this.total,
    required this.stage,
    this.message,
  });
}

final StreamController<ImportProgress> _importProgressController =
    StreamController<ImportProgress>.broadcast();

Stream<ImportProgress> get importProgressStream =>
    _importProgressController.stream;

bool _importCancelled = false;

/// Request cancellation of any running import.
void cancelImport() {
  _importCancelled = true;
}

/// Clear cancellation flag and prepare to start a new import.
void startImport() {
  _importCancelled = false;
}

void _emitImportProgress(ImportProgress p) {
  try {
    _importProgressController.add(p);
  } catch (e) {
    debugPrint('Failed to emit import progress: $e');
  }
}

/// An abstract class that defines the interface for database operations.
abstract class DatabaseProvider {
  Future<bool> open(String path);
  Future<bool> openFromPath(String path);
  String get path;
  Future<bool> get isImporting;
  Future<void> close();
  Future<List<String>> getAvailableDatabases();

  /// Query rows under a path or table.
  ///
  /// Backwards-compatible: callers can still pass [table] + [where]/[whereArgs]/[orderBy]
  /// which will be handled with a client-side filter when native queries aren't possible.
  /// Preferred RTDB-style parameters: provide [path] (full RTDB path) and any of
  /// [orderByChild], [equalTo], [startAt], [endAt], [limitToFirst], [limitToLast].
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
      int? limitToLast});
  Future<String?> insert(String table, Map<String, dynamic> data,
      {ConflictAlgorithm? conflictAlgorithm, String? key, String? path});

  /// Update rows under a table or path. If [key] is provided, only that child is updated.
  /// If [orderByChild] + [equalTo] are provided, they will be used as a native RTDB query
  /// to locate children to update. Otherwise [where]/[whereArgs] fallback is used.
  Future<void> update(String table, Map<String, dynamic> data,
      {String? path,
      String? key,
      String? where,
      List<dynamic>? whereArgs,
      String? orderByChild,
      dynamic equalTo});

  /// Delete rows under a table or path. Accepts the same targeting options as [update].
  Future<void> delete(String table,
      {String? path,
      String? key,
      String? where,
      List<dynamic>? whereArgs,
      String? orderByChild,
      dynamic equalTo});
}

/// Local sqflite provider (minimal implementation used by the app).
class LocalDatabaseProvider implements DatabaseProvider {
  Database? _database;

  @override
  Future<List<String>> getAvailableDatabases() => Future.value([]);

  @override
  Future<bool> open(String path) async {
    _database = await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        db.execute(
            "create table Clubs (id integer primary key autoincrement, " +
                "name text not null, " +
                "description text, " +
                "color1 integer not null, " +
                "color2 integer not null, " +
                "logoUrl text, " +
                "createdAt integer not null);");

        db.execute(
            "create table Seasons (id integer primary key autoincrement, " +
                "name text not null, " +
                "teamId integer not null);");

        db.execute(
            "create table Teams (id integer primary key autoincrement, " +
                "fullName text not null, " +
                "shortName text not null, " +
                "color1 integer not null, " +
                "color2 integer not null, " +
                "clubId integer);");

        db.execute(
            "create table Games (id integer primary key autoincrement, " +
                "seasonId integer not null, " +
                "homeTeamId integer not null, " +
                "awayTeamId integer not null, " +
                "homeTeamScore integer not null, " +
                "awayTeamScore integer not null, " +
                "date text not null, " +
                "gameStatus text not null, " +
                "milliSecondsLeft long not null);");

        db.execute("create table Players (id integer not null, " +
            "teamId integer not null, " +
            "seasonId integer not null, " +
            "firstName string not null, " +
            "lastName string not null, " +
            "number integer not null, " +
            "profileImage text, " +
            "primary key(id, teamId, seasonId));");

        db.execute(
            "create table Events (id integer primary key autoincrement, " +
                "playerId integer not null, " +
                "teamId integer not null, " +
                "gameId integer not null, " +
                "seasonId integer not null, " +
                "eventType text not null, " +
                "eventLocation text not null, " +
                "eventMinute integer not null, " +
                "eventPeriod integer not null, " +
                "eventData integer not null, " +
                "eventTextData text);");
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // Add profileImage column to Players table
          try {
            await db
                .execute("ALTER TABLE Players ADD COLUMN profileImage text;");
          } catch (e) {
            debugPrint('Migration failed: $e');
          }
        }
      },
    );

    return true;
  }

  @override
  Future<bool> openFromPath(String path) async => await open(path);

  @override
  String get path => _database?.path ?? '';

  @override
  Future<void> close() async => await _database?.close();

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
    // Local provider (sqflite) doesn't support RTDB native queries.
    // Map arguments to a normal SQL query when possible.
    final effectiveTable = (path != null && path.isNotEmpty) ? path : table;
    return await _database!.query(effectiveTable,
        where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  @override
  Future<String?> insert(String table, Map<String, dynamic> data,
      {ConflictAlgorithm? conflictAlgorithm, String? key, String? path}) async {
    // For local DB we just insert into the table (ignore key/path)
    await _database!.insert(table, data,
        conflictAlgorithm: conflictAlgorithm ?? ConflictAlgorithm.replace);
    return null;
  }

  @override
  Future<void> update(String table, Map<String, dynamic> data,
      {String? path,
      String? key,
      String? where,
      List<dynamic>? whereArgs,
      String? orderByChild,
      dynamic equalTo}) async {
    // Map to SQL update using where/whereArgs when provided.
    final effectiveTable = (path != null && path.isNotEmpty) ? path : table;
    if (key != null) {
      await _database!
          .update(effectiveTable, data, where: 'id=?', whereArgs: [key]);
      return;
    }
    await _database!
        .update(effectiveTable, data, where: where, whereArgs: whereArgs);
  }

  @override
  Future<void> delete(String table,
      {String? path,
      String? key,
      String? where,
      List<dynamic>? whereArgs,
      String? orderByChild,
      dynamic equalTo}) async {
    final effectiveTable = (path != null && path.isNotEmpty) ? path : table;
    if (key != null) {
      await _database!.delete(effectiveTable, where: 'id=?', whereArgs: [key]);
      return;
    }
    await _database!.delete(effectiveTable, where: where, whereArgs: whereArgs);
  }

  @override
  Future<bool> get isImporting => Future.value(false);
}

/// Realtime Database provider using `firebase_database`.
class FirebaseDBProvider implements DatabaseProvider {
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  // Emits a DateTime when the currently-open database node receives a value event.
  final StreamController<DateTime?> _updateController =
      StreamController<DateTime?>.broadcast();
  Stream<DateTime?> get updateStream => _updateController.stream;

  StreamSubscription<DatabaseEvent>? _dbValueSub;

  FirebaseDBProvider() {
    // Enable offline persistence on platforms that support it (mobile/desktop).
    // Web does not support setPersistenceEnabled, so guard with kIsWeb.
    try {
      if (!kIsWeb) {
        _database.setPersistenceEnabled(true);
        // Set a reasonable cache size (10 MB) — adjust if needed.
        _database.setPersistenceCacheSizeBytes(10 * 1024 * 1024);
      }
    } catch (e) {
      debugPrint('Could not enable RTDB persistence: $e');
    }

    // Listen to connection state from RTDB special location
    try {
      if (!kIsWeb) {
        _database.ref('.info/connected').onValue.listen((event) {
          final connected = (event.snapshot.value == true);
          DatabaseService.instance._emitConnectionStateInternal(connected);
          if (connected) DatabaseService.instance._clearPendingOnReconnect();
        });
      }
    } catch (e) {
      debugPrint('Could not subscribe to connection state: $e');
    }
  }

  String _subscriptionId = '';
  String _path = '';
  int? _clubTeamId; // Track the current team ID when in club mode
  DatabaseEvent? _dbEvent;
  DataSnapshot? get dbSnapshot => _dbEvent?.snapshot;
  DataSnapshot? get dbDocumentSnapshot => dbSnapshot;

  /// Check if we're in club mode (loading from ClubTeams collection)
  bool get _isClubMode => _path.startsWith('ClubTeams/');

  /// Validate that a path is safe for Firebase Realtime Database
  /// Firebase paths cannot contain: . $ # [ ] or have empty components
  bool _isValidFirebasePath(String path) {
    if (path.isEmpty) return false;
    if (path.contains('//')) return false; // Empty path component
    if (path.contains('.')) return false;
    if (path.contains('\$')) return false;
    if (path.contains('#')) return false;
    if (path.contains('[')) return false;
    if (path.contains(']')) return false;
    return true;
  }

  /// Translate table names for club mode
  String _getTableName(String table) {
    if (!_isClubMode) return table;

    // Map TeamSync table names to ClubSync collection names
    switch (table) {
      case 'Teams':
        return 'ClubTeams';
      case 'Seasons':
        return 'ClubSeasons';
      case 'Games':
        return 'ClubGames';
      case 'Players':
        return 'ClubPlayers';
      case 'Events':
        return 'ClubEvents';
      default:
        return table;
    }
  }

  String? get publicShareId {
    final snap = dbDocumentSnapshot;
    if (snap == null || !snap.exists) return null;
    final data = snap.value as Map<dynamic, dynamic>?;
    if (data != null && data.containsKey('publicShareId')) {
      final id = data['publicShareId'];
      // Handle both String and int types
      return id?.toString();
    }
    return null;
  }

  @override
  Future<bool> get isImporting async {
    try {
      final snap = dbDocumentSnapshot;
      if (snap == null || !snap.exists) return false;
      final data = snap.value as Map<dynamic, dynamic>?;
      return (data?['isImporting'] == true);
    } catch (e) {
      return false;
    }
  }

  Future<void> set(Map<String, dynamic> map) async {
    final snap = dbDocumentSnapshot;
    if (snap == null || !snap.exists) return;
    final ref = _database.ref(snap.ref.path);
    await ref.update(map);
  }

  Future<void> _getSubscriptionId() async {
    // If already have a valid subscription ID, return early
    if (_subscriptionId.isNotEmpty) {
      return;
    }

    try {
      if (FirebaseAuth.instance.currentUser == null) {
        debugPrint('User must be signed in before accessing cloud database');
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid.isNotEmpty) {
        _subscriptionId = user.uid;
        debugPrint('Subscription ID set to: $_subscriptionId');

        // Register user in lookup table for sharing features
        if (user.email != null && !kIsWeb) {
          try {
            await DatabaseSharingService.instance.registerUserInLookup();
          } catch (e) {
            debugPrint('Failed to register user for sharing: $e');
          }
        }
      } else {
        debugPrint('Failed to get subscription ID - no user authenticated');
      }
    } catch (e, stackTrace) {
      debugPrint('Error getting subscription ID: $e');
      debugPrint('Stack trace: $stackTrace');
    }
  }

  @override
  Future<List<String>> getAvailableDatabases() async {
    await _getSubscriptionId();

    // Validate that we have a valid subscription ID
    if (_subscriptionId.isEmpty) {
      debugPrint('getAvailableDatabases: No subscription ID available');
      return [];
    }

    final dbPath = 'subscriptionIds/$_subscriptionId/databases';
    if (!_isValidFirebasePath(dbPath)) {
      debugPrint('getAvailableDatabases: Invalid path: $dbPath');
      return [];
    }

    // Get user's own databases
    final ref = _database.ref(dbPath);
    final snapshot = await ref.get();
    final ownDatabases = <String>[];
    if (snapshot.exists && snapshot.value != null) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      ownDatabases.addAll(data.keys.map((k) => k.toString()));
    }

    // Get shared databases (for Pro users only)
    final sharedDatabases = <String>[];
    try {
      final shared = await DatabaseSharingService.instance.getSharedDatabases();
      for (final sharedDb in shared) {
        // Add with prefix to distinguish from own databases
        final displayName =
            '${sharedDb['ownerEmail']} - ${sharedDb['databaseName']}';
        sharedDatabases.add(displayName);
      }
    } catch (e) {
      debugPrint('getAvailableDatabases: Error getting shared databases: $e');
    }

    return [...ownDatabases, ...sharedDatabases];
  }

  @override
  Future<bool> open(String path) async {
    await _getSubscriptionId();

    // Validate that we have a valid subscription ID
    if (_subscriptionId.isEmpty) {
      debugPrint('open: No subscription ID available for path: $path');
      return false;
    }

    _path = path;

    final dbPath = 'subscriptionIds/$_subscriptionId/databases/$_path';
    if (!_isValidFirebasePath(dbPath)) {
      debugPrint('open: Invalid Firebase path: $dbPath');
      return false;
    }

    final ref = _database.ref(dbPath);
    _dbEvent = await ref.once();
    if (_dbEvent?.snapshot.exists == false) {
      await ref.set({'version': 1});
      _dbEvent = await ref.once();
    }

    // Listen for value events on the opened database node and emit update times.
    try {
      await _dbValueSub?.cancel();
      _dbValueSub = ref.onValue.listen((ev) {
        try {
          final snap = ev.snapshot;
          if (snap.exists && snap.value != null) {
            final map = snap.value as dynamic;
            // If 'lastUpdated' exists and is a numeric server-timestamp (ms since epoch), use it.
            if (map is Map && map.containsKey('lastUpdated')) {
              final lu = map['lastUpdated'];
              if (lu is int) {
                _updateController
                    .add(DateTime.fromMillisecondsSinceEpoch(lu, isUtc: true));
                return;
              }
            }
          }
        } catch (e) {
          debugPrint(
              'updateStream: failed to read lastUpdated from snapshot: $e');
        }
        // Fall back to local observed time
        _updateController.add(DateTime.now().toUtc());
      });
    } catch (e) {
      debugPrint('Failed to subscribe to database value events: $e');
    }

    return !(await isImporting);
  }

  @override
  Future<bool> openFromPath(String path) async {
    // Validate path is not empty and doesn't contain empty components
    if (path.isEmpty) {
      debugPrint('openFromPath: Empty path provided');
      return false;
    }

    // Check for empty path components (consecutive slashes)
    if (path.contains('//')) {
      debugPrint('openFromPath: Invalid path with empty components: $path');
      return false;
    }

    final parts = path.split('/');

    // For club team paths (e.g., 'ClubTeams/123'), handle specially
    if (parts.isNotEmpty && parts[0] == 'ClubTeams') {
      _path = path; // Store full path like 'ClubTeams/123'
      _subscriptionId = ''; // No subscription ID for club teams
      _clubTeamId = parts.length > 1 ? int.tryParse(parts[1]) : null;

      // For club teams, we just need to verify the team exists
      try {
        final ref = _database.ref(path);
        final snapshot = await ref.once();
        _dbEvent = snapshot;

        if (!snapshot.snapshot.exists) {
          debugPrint('openFromPath: Club team not found at path: $path');
          return false;
        }

        // Subscribe to value events for this team
        try {
          await _dbValueSub?.cancel();
          _dbValueSub = ref.onValue.listen((ev) {
            _updateController.add(DateTime.now().toUtc());
          });
        } catch (e) {
          debugPrint('Failed to subscribe to team value events: $e');
        }

        return true;
      } catch (e, stackTrace) {
        debugPrint('openFromPath: Error opening club team path: $e');
        debugPrint('Stack trace: $stackTrace');
        return false;
      }
    }

    // For subscription-based databases, parse and validate the path
    // Expected format: subscriptionIds/{uid}/databases/{dbName}
    _path = parts.isNotEmpty ? parts.last : path;
    _subscriptionId = parts.length > 1 ? parts[1] : '';
    _clubTeamId = null; // Clear club team ID

    // Validate subscription ID is not empty for subscription-based paths
    if (_subscriptionId.isEmpty &&
        parts.isNotEmpty &&
        parts[0] == 'subscriptionIds') {
      debugPrint(
          'openFromPath: Invalid subscription path - missing subscription ID: $path');
      return false;
    }

    try {
      final ref = _database.ref(path);
      _dbEvent = await ref.once();

      if (_dbEvent?.snapshot.exists == false) {
        debugPrint('openFromPath: Database not found at path: $path');
        return false;
      }

      // Subscribe to value events for this database path
      try {
        await _dbValueSub?.cancel();
        _dbValueSub = ref.onValue.listen((ev) {
          try {
            final snap = ev.snapshot;
            if (snap.exists && snap.value != null) {
              final map = snap.value as dynamic;
              if (map is Map && map.containsKey('lastUpdated')) {
                final lu = map['lastUpdated'];
                if (lu is int) {
                  _updateController.add(
                      DateTime.fromMillisecondsSinceEpoch(lu, isUtc: true));
                  return;
                }
              }
            }
          } catch (e) {
            debugPrint(
                'updateStream: failed to read lastUpdated from snapshot: $e');
          }
          _updateController.add(DateTime.now().toUtc());
        });
      } catch (e) {
        debugPrint('Failed to subscribe to database value events: $e');
      }
    } catch (e, stackTrace) {
      debugPrint('openFromPath: Error accessing path: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }

    return !(await isImporting);
  }

  @override
  String get path => _path;

  /// Get the current subscription ID (user ID who owns the database)
  String get subscriptionId => _subscriptionId;

  @override
  Future<void> close() async {
    // Tear down any active subscriptions when provider is closed.
    await _dbValueSub?.cancel();
    // don't close _updateController here because provider may be reused; keep it open
    return;
  }

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
    final snap = dbDocumentSnapshot;
    if (snap == null || !snap.exists) return [];

    // Translate table name for club mode
    final translatedTable = _getTableName(table);

    final String nodePath = (path != null && path.isNotEmpty)
        ? path
        : (_isClubMode
            ? translatedTable // In club mode, use root-level collection
            : '${snap.ref.path}/$translatedTable'); // In subscription mode, use nested path
    final ref = _database.ref(nodePath);

    // If caller provided RTDB-style args, build a native Query
    Query? q;
    if (orderByChild != null) q = ref.orderByChild(orderByChild);
    if (orderByChild == null && orderBy != null && orderBy.trim().isNotEmpty) {
      // prefer orderByChild if provided; otherwise try to use the orderBy field
      final parts = orderBy.trim().split(RegExp(r'\s+'));
      q = ref.orderByChild(parts[0]);
    }

    if (q != null) {
      if (equalTo != null) q = q.equalTo(equalTo);
      if (startAt != null) q = q.startAt(startAt);
      if (endAt != null) q = q.endAt(endAt);
      if (limitToFirst != null) q = q.limitToFirst(limitToFirst);
      if (limitToLast != null) q = q.limitToLast(limitToLast);

      try {
        final qsnap = await q.get();
        if (!qsnap.exists || qsnap.value == null) return [];
        final val = qsnap.value;
        final List<Map<String, dynamic>> rows = [];
        if (val is List) {
          for (final e in val) {
            if (e == null) continue;
            if (e is Map) rows.add(Map<String, dynamic>.from(e));
          }
        } else if (val is Map) {
          for (final entry in val.entries) {
            final v = entry.value;
            if (v is Map) {
              // Use more robust map conversion that preserves all fields
              final m = <String, dynamic>{};
              v.forEach((key, value) {
                m[key.toString()] = value;
              });
              m['_key'] = entry.key.toString();
              rows.add(m);
            }
          }
        }

        // If caller asked for a different orderBy (SQL style), apply local sort
        if (orderBy != null && orderBy.trim().isNotEmpty) {
          final parts = orderBy.trim().split(RegExp(r'\s+'));
          final orderField = parts[0];
          final desc = parts.length > 1 && parts[1].toUpperCase() == 'DESC';

          rows.sort((a, b) {
            final av = a[orderField];
            final bv = b[orderField];
            if (av == null && bv == null) return 0;
            if (av == null) return desc ? 1 : -1;
            if (bv == null) return desc ? -1 : 1;
            if (av is num && bv is num)
              return desc ? bv.compareTo(av) : av.compareTo(bv);
            final as = av.toString();
            final bs = bv.toString();
            return desc ? bs.compareTo(as) : as.compareTo(bs);
          });
        }

        return rows;
      } catch (e, st) {
        debugPrint(
            'RTDB native query failed, falling back to full read: $e\n$st');
        // fall through
      }
    }

    // Full-read fallback: fetch entire node and apply SQL-style filters locally
    final snapshot = await ref.get();
    if (!snapshot.exists || snapshot.value == null) return [];

    final value = snapshot.value;
    final List<Map<String, dynamic>> rows = [];

    if (value is List) {
      for (final e in value) {
        if (e == null) continue;
        if (e is Map) {
          final m = <String, dynamic>{};
          e.forEach((key, value) {
            m[key.toString()] = value;
          });
          rows.add(m);
        }
      }
    } else if (value is Map) {
      for (final entry in value.entries) {
        final v = entry.value;
        if (v is Map) {
          final m = <String, dynamic>{};
          v.forEach((key, value) {
            m[key.toString()] = value;
          });
          m['_key'] = entry.key.toString();
          rows.add(m);
        }
      }
    } else {
      return [];
    }

    // Apply simple WHERE filtering: supports patterns like 'field1=? AND field2=?'
    if (where != null &&
        where.trim().isNotEmpty &&
        whereArgs != null &&
        whereArgs.isNotEmpty) {
      final fields = where.split(RegExp(r'\s+AND\s+', caseSensitive: false));
      final parsedFields = fields.map((f) {
        var field = f.trim();
        field = field.replaceAll(RegExp(r'=\s*\?'), '').trim();
        return field;
      }).toList(growable: false);

      rows.retainWhere((row) {
        for (var i = 0; i < parsedFields.length; i++) {
          final field = parsedFields[i];
          final expected = (i < whereArgs.length) ? whereArgs[i] : null;
          final actual = row.containsKey(field) ? row[field] : null;
          if (expected == null) {
            if (actual != null) return false;
          } else {
            if (actual != expected) return false;
          }
        }
        return true;
      });
    }

    // Apply orderBy if present. Supports 'field', 'field ASC', 'field DESC'
    if (orderBy != null && orderBy.trim().isNotEmpty) {
      final parts = orderBy.trim().split(RegExp(r'\s+'));
      final orderField = parts[0];
      final desc = parts.length > 1 && parts[1].toUpperCase() == 'DESC';

      rows.sort((a, b) {
        final av = a[orderField];
        final bv = b[orderField];
        if (av == null && bv == null) return 0;
        if (av == null) return desc ? 1 : -1;
        if (bv == null) return desc ? -1 : 1;
        if (av is num && bv is num)
          return desc ? bv.compareTo(av) : av.compareTo(bv);
        final as = av.toString();
        final bs = bv.toString();
        return desc ? bs.compareTo(as) : as.compareTo(bs);
      });
    }

    return rows;
  }

  @override
  Future<String?> insert(String table, Map<String, dynamic> data,
      {ConflictAlgorithm? conflictAlgorithm, String? key, String? path}) async {
    final snap = dbDocumentSnapshot;
    if (snap == null || !snap.exists) return null;

    // Translate table name for club mode
    final translatedTable = _getTableName(table);

    final nodePath = (path != null && path.isNotEmpty)
        ? path
        : (_isClubMode
            ? translatedTable // In club mode, use root-level collection
            : '${snap.ref.path}/$translatedTable'); // In subscription mode, use nested path
    final collectionRef = _database.ref(nodePath);
    if (key != null && key.isNotEmpty) {
      await collectionRef.child(key).set(data);
      return key;
    }
    final newRef = collectionRef.push();
    await newRef.set(data);
    return newRef.key;
  }

  @override
  Future<void> update(String table, Map<String, dynamic> data,
      {String? path,
      String? key,
      String? where,
      List<dynamic>? whereArgs,
      String? orderByChild,
      dynamic equalTo}) async {
    final snap = dbDocumentSnapshot;
    if (snap == null || !snap.exists) return;

    // Translate table name for club mode
    final translatedTable = _getTableName(table);

    final nodePath = (path != null && path.isNotEmpty)
        ? path
        : (_isClubMode
            ? translatedTable // In club mode, use root-level collection
            : '${snap.ref.path}/$translatedTable'); // In subscription mode, use nested path
    final collectionRef = _database.ref(nodePath);

    if (key != null && key.isNotEmpty) {
      // Try treating key as the RTDB child key first
      try {
        final childSnap = await collectionRef.child(key).get();
        if (childSnap.exists) {
          await collectionRef
              .child(key)
              .update(Map<String, dynamic>.from(data));
          return;
        }
      } catch (e) {
        // Continue to fallback below
      }

      // Fallback: caller likely passed the object's `id` field. Try to find children
      // where child.id == key (or numeric equivalent) and update them.
      dynamic parsedKey = key;
      final asInt = int.tryParse(key);
      if (asInt != null) parsedKey = asInt;
      try {
        final q = collectionRef.orderByChild('id').equalTo(parsedKey);
        final snap = await q.get();
        if (snap.exists && snap.value != null) {
          final map = snap.value as Map<dynamic, dynamic>;
          for (final entry in map.entries) {
            final childKey = entry.key.toString();
            await collectionRef
                .child(childKey)
                .update(Map<String, dynamic>.from(data));
          }
          return;
        }
      } catch (e) {
        // ignore fallback failures
      }
      return;
    }
    // If orderByChild + equalTo provided, use native query to find matching children
    if (orderByChild != null && equalTo != null) {
      final q = collectionRef.orderByChild(orderByChild).equalTo(equalTo);
      final snapshot = await q.get();
      if (!snapshot.exists || snapshot.value == null) return;
      final map = snapshot.value as Map<dynamic, dynamic>;
      for (final entry in map.entries) {
        final childKey = entry.key.toString();
        await collectionRef
            .child(childKey)
            .update(Map<String, dynamic>.from(data));
      }
      return;
    }

    // Fallback: full read + local filter using where/whereArgs
    final items = await collectionRef.get();
    if (!items.exists || items.value == null) return;
    final map = items.value as Map<dynamic, dynamic>;
    for (final entry in map.entries) {
      final childKey = entry.key.toString();
      final itemMap = entry.value as Map<dynamic, dynamic>;
      var matches = true;
      if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
        final fields = where.split(RegExp(r'\s+AND\s+', caseSensitive: false));
        int index = 0;
        for (var f in fields) {
          final field = f.replaceAll(RegExp(r'=\s*\?'), '').trim();
          final expected = whereArgs[index++];
          if (itemMap[field] != expected) {
            matches = false;
            break;
          }
        }
      }
      if (matches) {
        await collectionRef
            .child(childKey)
            .update(Map<String, dynamic>.from(data));
      }
    }
  }

  @override
  Future<void> delete(String table,
      {String? path,
      String? key,
      String? where,
      List<dynamic>? whereArgs,
      String? orderByChild,
      dynamic equalTo}) async {
    final snap = dbDocumentSnapshot;
    if (snap == null || !snap.exists) return;

    // Translate table name for club mode
    final translatedTable = _getTableName(table);

    final nodePath = (path != null && path.isNotEmpty)
        ? path
        : (_isClubMode
            ? translatedTable // In club mode, use root-level collection
            : '${snap.ref.path}/$translatedTable'); // In subscription mode, use nested path
    final collectionRef = _database.ref(nodePath);

    if (key != null && key.isNotEmpty) {
      // Try direct child key first
      try {
        final childSnap = await collectionRef.child(key).get();
        if (childSnap.exists) {
          await collectionRef.child(key).remove();
          return;
        }
      } catch (e) {
        // fall through to fallback
      }

      // Fallback: treat key as an 'id' field value and delete matching children
      dynamic parsedKey = key;
      final asInt = int.tryParse(key);
      if (asInt != null) parsedKey = asInt;
      try {
        final q = collectionRef.orderByChild('id').equalTo(parsedKey);
        final snap = await q.get();
        if (snap.exists && snap.value != null) {
          final map = snap.value as Map<dynamic, dynamic>;
          for (final entry in map.entries) {
            final childKey = entry.key.toString();
            await collectionRef.child(childKey).remove();
          }
          return;
        }
      } catch (e) {
        // ignore
      }
      return;
    }

    if (orderByChild != null && equalTo != null) {
      final q = collectionRef.orderByChild(orderByChild).equalTo(equalTo);
      final snapshot = await q.get();
      if (!snapshot.exists || snapshot.value == null) return;
      final map = snapshot.value as Map<dynamic, dynamic>;
      for (final entry in map.entries) {
        final childKey = entry.key.toString();
        await collectionRef.child(childKey).remove();
      }
      return;
    }

    // Fallback: full read + local filter
    final items = await collectionRef.get();
    if (!items.exists || items.value == null) return;
    final map = items.value as Map<dynamic, dynamic>;
    for (final entry in map.entries) {
      final childKey = entry.key.toString();
      final itemMap = entry.value as Map<dynamic, dynamic>;
      var matches = true;
      if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
        final fields = where.split(RegExp(r'\s+AND\s+', caseSensitive: false));
        int index = 0;
        for (var f in fields) {
          final field = f.replaceAll(RegExp(r'=\s*\?'), '').trim();
          final expected = whereArgs[index++];
          if (itemMap[field] != expected) {
            matches = false;
            break;
          }
        }
      }
      if (matches) {
        await collectionRef.child(childKey).remove();
      }
    }
  }

  /// Create or return a public share ID for this database.
  Future<String?> shareDatabase() async {
    // If a publicShareId already exists, return it. Otherwise generate a
    // new unique 6-digit id, write it to the database document, and return it.
    final doc = dbDocumentSnapshot;
    if (doc == null) return null;

    final data = doc.value as Map<dynamic, dynamic>?;
    if (data != null && data.containsKey('publicShareId')) {
      // Handle both String and int types from Firebase
      final id = data['publicShareId'];
      return id?.toString();
    }

    // Generate a random 6-digit id and ensure it doesn't collide with existing mapping.
    final random = Random();
    final rt = FirebaseDatabase.instance;
    String publicId = '';
    const int maxAttempts = 10;
    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      publicId = (100000 + random.nextInt(900000)).toString();
      try {
        final mapSnap = await rt.ref('shared_databases/$publicId').get();
        if (!mapSnap.exists) {
          // No mapping yet — we can use this id.
          break;
        }
      } catch (e) {
        // If we can't read the mapping path, break and attempt to use the id.
        // It's better to proceed than to block sharing completely.
        debugPrint('shareDatabase: failed to check mapping for $publicId: $e');
        break;
      }
      publicId = '';
    }

    if (publicId.isEmpty) {
      // Fallback: generate a timestamp-based id to avoid collisions.
      publicId = DateTime.now().toUtc().millisecondsSinceEpoch.toString();
    }

    // Persist the publicShareId on the database document itself. Then confirm
    // that the top-level mapping (/shared_databases/<id>) points to our
    // databasePath. If a collision is detected (mapping points elsewhere),
    // remove the written publicShareId and retry.
    final databasePath = 'subscriptionIds/$_subscriptionId/databases/$_path';
    const int verifyAttempts = 5;
    for (int verify = 0; verify < verifyAttempts; verify++) {
      try {
        await _database.ref(databasePath).update({'publicShareId': publicId});

        // Give the Cloud Function a short moment to write the top-level mapping.
        await Future.delayed(const Duration(milliseconds: 300));

        final mapSnap = await rt.ref('shared_databases/$publicId').get();
        if (!mapSnap.exists || mapSnap.value == null) {
          // mapping not present yet; retry a few times
          await Future.delayed(const Duration(milliseconds: 200));
          continue;
        }

        final mapVal = mapSnap.value;
        if (mapVal is Map && mapVal['databasePath'] == databasePath) {
          // Success: mapping points to our database
          return publicId;
        }

        // Collision detected: mapping points to a different database.
        // Clean up our tentative publicShareId and try another id.
        try {
          await _database.ref(databasePath).update({'publicShareId': null});
        } catch (e) {
          debugPrint(
              'shareDatabase: failed to clear collided publicShareId: $e');
        }
        publicId = '';
        // Fall through to outer generation loop by breaking here.
        break;
      } catch (e) {
        debugPrint(
            'shareDatabase: verification attempt failed for $publicId: $e');
        // Continue verification attempts
      }
    }

    // If verification failed or collision occurred, signal failure by returning null.
    if (publicId.isEmpty) {
      debugPrint('shareDatabase: could not obtain a unique publicShareId');
      return null;
    }
    return publicId;
  }

  /// Open a database by a public share id. Since we store `publicShareId` on the
  /// database document itself, scan the `subscriptionIds` tree to find a matching
  /// database. This is an infrequent operation so scanning is acceptable.
  Future<bool> openFromId(String id) async {
    final rt = FirebaseDatabase.instance;

    // Resolve the public id using the top-level mapping maintained by Cloud Functions:
    // /shared_databases/<id> => { databasePath }
    try {
      final mapSnap = await rt.ref('shared_databases/$id').get();
      if (mapSnap.exists && mapSnap.value != null) {
        final mapVal = mapSnap.value;
        if (mapVal is Map && mapVal['databasePath'] != null) {
          final path = mapVal['databasePath'].toString();
          return await openFromPath(path);
        }
      }
    } catch (e) {
      debugPrint('openFromId: failed to read shared_databases/$id: $e');
    }

    // If mapping is missing, return false (no scanning fallback).
    return false;
  }
}

/// Singleton service that delegates to a DatabaseProvider.
class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  late DatabaseProvider _provider;

  // Connection status stream: true = connected, false = disconnected
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();
  Stream<bool> get connectionState => _connectionController.stream;

  // Pending write operations counter
  int _pendingWrites = 0;
  final StreamController<int> _pendingController =
      StreamController<int>.broadcast();
  Stream<int> get pendingWrites => _pendingController.stream;

  // Last sync timestamp stream (null when never synced)
  DateTime? _lastSyncTime;
  final StreamController<DateTime?> _lastSyncController =
      StreamController<DateTime?>.broadcast();
  Stream<DateTime?> get lastSync => _lastSyncController.stream;

  /// Stream emitting observed database update times (useful for web read-only viewers).
  Stream<DateTime?> get databaseUpdates {
    if (_provider is FirebaseDBProvider) {
      return (_provider as FirebaseDBProvider).updateStream;
    }
    return _lastSyncController.stream;
  }

  static const String _prefsLastSyncKey = 'last_sync_time';

  Future<void> _loadLastSyncFromPrefs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final s = prefs.getString(_prefsLastSyncKey);
      if (s != null) {
        final dt = DateTime.tryParse(s);
        if (dt != null) {
          _lastSyncTime = dt;
          _emitLastSync(_lastSyncTime);
        }
      }
    } catch (e) {
      debugPrint('Failed to load last sync from prefs: $e');
    }
  }

  Future<void> _setLastSync(DateTime? t) async {
    _lastSyncTime = t;
    _emitLastSync(_lastSyncTime);
    try {
      final prefs = await SharedPreferences.getInstance();
      if (t == null) {
        await prefs.remove(_prefsLastSyncKey);
      } else {
        await prefs.setString(_prefsLastSyncKey, t.toIso8601String());
      }
    } catch (e) {
      debugPrint('Failed to persist last sync to prefs: $e');
    }
  }

  bool _connected = false;

  // keep compatibility: internal emitter is _emitConnectionStateInternal
  void _emitConnectionStateInternal(bool v) {
    _connected = v;
    _connectionController.add(v);
    if (v) {
      // on connect, update last sync time
      _setLastSync(DateTime.now());
    }
  }

  void _emitLastSync(DateTime? t) => _lastSyncController.add(t);
  void _emitPending() => _pendingController.add(_pendingWrites);
  void _incrementPending() {
    _pendingWrites++;
    _emitPending();
  }

  void _decrementPending() {
    if (_pendingWrites > 0) _pendingWrites--;
    _emitPending();
    // If we've drained pending writes and are connected, update last sync
    if (_pendingWrites == 0 && _connected) {
      _setLastSync(DateTime.now());
    }
  }

  void _clearPendingOnReconnect() {
    // When reconnected, the client will have flushed queued writes; reset counter.
    _pendingWrites = 0;
    _emitPending();
    _setLastSync(DateTime.now());
  }

  bool get isLocalDatabase => _provider is LocalDatabaseProvider;
  String? get publicShareId {
    if (_provider is FirebaseDBProvider) {
      return (_provider as FirebaseDBProvider).publicShareId;
    }
    return null;
  }

  DatabaseService._internal() {
    _provider = LocalDatabaseProvider();
    // Load persisted last-sync timestamp (non-blocking)
    _loadLastSyncFromPrefs();
  }

  void setProvider(DatabaseProvider provider) {
    _provider = provider;
  }

  Future<bool> get isImporting async => await _provider.isImporting;

  Future<void> importToCloud() async {
    if (_provider is FirebaseDBProvider || await isImporting) return;

    final cloudProvider = FirebaseDBProvider();

    final cloudDbName = _provider.path.split('/').last;
    await cloudProvider.open(cloudDbName);

    const tablesToMigrate = ['Teams', 'Seasons', 'Players', 'Games', 'Events'];

    await cloudProvider.set({'isImporting': true});

    for (final table in tablesToMigrate) {
      debugPrint('Querying table: $table');
      final dataToMigrate = await _provider.query(table);

      debugPrint('Migrating table: $table - ${dataToMigrate.length} rows');
      final rowMigrationPromises = dataToMigrate.map((row) async {
        await cloudProvider.insert(table, row);
      });
      await Future.wait(rowMigrationPromises);
    }

    await cloudProvider.set({'isImporting': false});

    await _provider.close();
    setProvider(cloudProvider);

    debugPrint('Importing complete');
  }

  /// Import from Firestore (a document path that contains collections -> tables)
  /// into the user's Realtime Database subscription area.
  Future<void> importFromFirestore(String firestorePath,
      {bool backupExisting = true}) async {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('Not authenticated');

    final firestore = fs.FirebaseFirestore.instance;
    final docRef = firestore.doc(firestorePath);
    final rt = FirebaseDatabase.instance;
    final dbName = firestorePath.split('/').last;
    final basePath =
        'subscriptionIds/$uid/databases/$dbName'.replaceAll('.db', '');

    // Mark importing so other clients know
    await rt.ref(basePath).update({'isImporting': true});

    // Known table names used by the app
    const tablesToMigrate = ['Teams', 'Seasons', 'Players', 'Games', 'Events'];

    for (final colName in tablesToMigrate) {
      fs.QuerySnapshot? snapshot;
      List<fs.QueryDocumentSnapshot> docs = const [];

      // Try 1: subcollection under the provided document path
      try {
        debugPrint(
            'importFromFirestore: trying doc subcollection $colName at $firestorePath');
        snapshot = await docRef.collection(colName).get();
        docs = snapshot.docs;
        debugPrint(
            'importFromFirestore: doc.subcollection $colName returned ${docs.length} docs');
      } catch (e, st) {
        debugPrint(
            'importFromFirestore: doc subcollection read failed for $colName: $e\n$st');
      }

      // Try 2: collection at full path ($firestorePath/$colName)
      if (docs.isEmpty) {
        try {
          final altPath = '$firestorePath/$colName';
          debugPrint('importFromFirestore: trying collection path $altPath');
          snapshot = await firestore.collection(altPath).get();
          docs = snapshot.docs;
          debugPrint(
              'importFromFirestore: collection($altPath) returned ${docs.length} docs');
        } catch (e, st) {
          debugPrint(
              'importFromFirestore: collection(path/col) read failed for $colName: $e\n$st');
        }
      }

      // Try 3: top-level collection with the name
      if (docs.isEmpty) {
        try {
          debugPrint(
              'importFromFirestore: trying top-level collection $colName');
          snapshot = await firestore.collection(colName).get();
          docs = snapshot.docs;
          debugPrint(
              'importFromFirestore: top-level collection $colName returned ${docs.length} docs');
        } catch (e, st) {
          debugPrint(
              'importFromFirestore: top-level collection read failed for $colName: $e\n$st');
        }
      }

      if (docs.isEmpty) {
        debugPrint(
            'importFromFirestore: No documents found for $colName, skipping');
        continue;
      }

      final List<MapEntry<String, dynamic>> rows = [];
      for (final d in docs) {
        try {
          rows.add(MapEntry(d.id, _firestoreValueToJson(d.data())));
        } catch (e, st) {
          debugPrint(
              'importFromFirestore: Failed to convert doc ${d.id} in $colName: $e\n$st');
        }
      }

      final rtTableRef = rt.ref('$basePath/$colName');

      // Backup existing table if requested
      if (backupExisting) {
        try {
          final existingSnap = await rtTableRef.get();
          if (existingSnap.exists && existingSnap.value != null) {
            final backupPath =
                '$basePath/_backups/${DateTime.now().toIso8601String()}/$colName';
            final backupRef = rt.ref(backupPath);
            // Write existing data as a whole backup map
            final existingMap = existingSnap.value as dynamic;
            await backupRef.set(existingMap);
            debugPrint(
                'importFromFirestore: Backed up $colName to $backupPath');
          }
        } catch (e, st) {
          debugPrint(
              'importFromFirestore: Backup failed for $colName: $e\n$st');
        }
      }

      // Write per-document to avoid overwriting unrelated nodes accidentally
      int processed = 0;
      _emitImportProgress(ImportProgress(
          table: colName, processed: 0, total: rows.length, stage: 'writing'));
      for (final entry in rows) {
        if (_importCancelled) break;
        try {
          final childRef = rtTableRef.child(entry.key);
          await childRef.set(entry.value);
          processed++;
          _emitImportProgress(ImportProgress(
              table: colName,
              processed: processed,
              total: rows.length,
              stage: 'writing'));
        } catch (e, st) {
          _emitImportProgress(ImportProgress(
              table: colName,
              processed: processed,
              total: rows.length,
              stage: 'error',
              message: e.toString()));
          debugPrint(
              'importFromFirestore: Failed to write doc ${entry.key} in $colName: $e\n$st');
        }
      }

      // Final stage
      if (_importCancelled) {
        _emitImportProgress(ImportProgress(
            table: colName,
            processed: processed,
            total: rows.length,
            stage: 'cancelled'));
        debugPrint('importFromFirestore: Import cancelled during $colName');
      } else {
        _emitImportProgress(ImportProgress(
            table: colName,
            processed: processed,
            total: rows.length,
            stage: 'done'));
        debugPrint(
            'importFromFirestore: Wrote $processed records to $basePath/$colName');
      }

      if (_importCancelled) {
        debugPrint('importFromFirestore: Import cancelled by user');
        break;
      }
    }

    // Clear importing flag
    try {
      await rt.ref(basePath).update({'isImporting': false});
    } catch (e) {
      debugPrint('importFromFirestore: could not clear isImporting flag: $e');
    }
  }

  Future<bool> open(String path) async => await _provider.open(path);

  Future<bool> openFromPath(String path) async {
    if (_provider is! FirebaseDBProvider) setProvider(FirebaseDBProvider());
    return await _provider.openFromPath(path);
  }

  String get path => _provider.path;

  /// Get the current subscription ID (user ID who owns the database)
  /// Returns empty string if not using FirebaseDBProvider or if no subscription
  String get subscriptionId {
    if (_provider is FirebaseDBProvider) {
      return (_provider as FirebaseDBProvider).subscriptionId;
    }
    return '';
  }

  Future<void> close() async => await _provider.close();

  Future<List<String>> getAvailableDatabases() async =>
      await _provider.getAvailableDatabases();

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
          int? limitToLast}) async =>
      await _provider.query(table,
          path: path,
          where: where,
          whereArgs: whereArgs,
          orderBy: orderBy,
          orderByChild: orderByChild,
          equalTo: equalTo,
          startAt: startAt,
          endAt: endAt,
          limitToFirst: limitToFirst,
          limitToLast: limitToLast);

  Future<String?> insert(String table, Map<String, dynamic> data,
      {ConflictAlgorithm? conflictAlgorithm, String? key, String? path}) async {
    _incrementPending();
    try {
      return await _provider.insert(table, data,
          conflictAlgorithm: conflictAlgorithm, key: key, path: path);
    } finally {
      _decrementPending();
    }
  }

  Future<void> update(String table, Map<String, dynamic> data,
      {String? path,
      String? key,
      String? where,
      List<dynamic>? whereArgs,
      String? orderByChild,
      dynamic equalTo}) async {
    _incrementPending();
    try {
      await _provider.update(table, data,
          path: path,
          key: key,
          where: where,
          whereArgs: whereArgs,
          orderByChild: orderByChild,
          equalTo: equalTo);
    } finally {
      _decrementPending();
    }
  }

  Future<void> delete(String table,
      {String? path,
      String? key,
      String? where,
      List<dynamic>? whereArgs,
      String? orderByChild,
      dynamic equalTo}) async {
    _incrementPending();
    try {
      await _provider.delete(table,
          path: path,
          key: key,
          where: where,
          whereArgs: whereArgs,
          orderByChild: orderByChild,
          equalTo: equalTo);
    } finally {
      _decrementPending();
    }
  }

  Future<String?> shareDatabase() async {
    if (_provider is! FirebaseDBProvider) {
      throw Exception('Can only share a cloud database.');
    }
    return await (_provider as FirebaseDBProvider).shareDatabase();
  }

  Future<bool> openFromId(String id) async {
    if (_provider is! FirebaseDBProvider) setProvider(FirebaseDBProvider());
    return await (_provider as FirebaseDBProvider).openFromId(id);
  }

  /// Open a club team context. This sets the provider to use ClubSync collections
  /// at the root level instead of subscription-based paths.
  /// Returns true if the club team exists and was opened successfully.
  Future<bool> openClubTeam(int clubId, int teamId) async {
    if (_provider is! FirebaseDBProvider) setProvider(FirebaseDBProvider());

    // Verify the team exists and belongs to the club
    final snapshot = await FirebaseDatabase.instance
        .ref('ClubTeams')
        .child(teamId.toString())
        .get();

    if (!snapshot.exists || snapshot.value == null) {
      return false;
    }

    final teamData = Map<String, dynamic>.from(snapshot.value as Map);
    final teamClubId = teamData['clubId'] as int?;

    if (teamClubId != clubId) {
      return false;
    }

    // Set a special path to indicate we're in club mode
    // This will be used by the provider to determine which collections to use
    await (_provider as FirebaseDBProvider).openFromPath('ClubTeams/$teamId');
    return true;
  }

  /// Check if the current database context is a club team
  bool get isClubTeam => _provider.path.startsWith('ClubTeams/');

  /// Open a shared database by owner and database name.
  /// Returns true if the database was opened successfully and user has access.
  Future<bool> openSharedDatabase(String ownerId, String databaseName) async {
    if (_provider is! FirebaseDBProvider) {
      setProvider(FirebaseDBProvider());
    }

    // Check if user has access
    final accessLevel = await DatabaseSharingService.instance
        .checkDatabaseAccess(ownerId, databaseName);

    if (accessLevel == null) {
      debugPrint(
          'openSharedDatabase: No access to database $databaseName owned by $ownerId');
      return false;
    }

    // Construct the path to the shared database
    final sharedDbPath = 'subscriptionIds/$ownerId/databases/$databaseName';

    // Open the database
    final opened =
        await (_provider as FirebaseDBProvider).openFromPath(sharedDbPath);

    if (opened) {
      debugPrint(
          'openSharedDatabase: Opened shared database with $accessLevel access');
    }

    return opened;
  }

  /// Get information about shared databases available to the current user.
  Future<List<Map<String, dynamic>>> getSharedDatabasesInfo() async {
    return await DatabaseSharingService.instance.getSharedDatabases();
  }

  /// Grant access to the current database to another user (Pro only).
  Future<bool> shareDatabaseWithUser(String userEmail,
      {String accessLevel = 'read'}) async {
    if (_provider is! FirebaseDBProvider) {
      debugPrint('shareDatabaseWithUser: Can only share cloud databases');
      return false;
    }

    final dbPath = _provider.path;
    if (dbPath.isEmpty) {
      debugPrint('shareDatabaseWithUser: No database currently open');
      return false;
    }

    // Extract database name from path
    String databaseName = dbPath;
    if (dbPath.contains('/')) {
      databaseName = dbPath.split('/').last;
    }

    return await DatabaseSharingService.instance.grantDatabaseAccess(
      databaseName,
      userEmail,
      accessLevel: accessLevel,
    );
  }

  /// Revoke access to the current database from a user (Pro only).
  Future<bool> unshareDatabaseFromUser(String userEmail) async {
    if (_provider is! FirebaseDBProvider) {
      debugPrint('unshareDatabaseFromUser: Can only manage cloud databases');
      return false;
    }

    final dbPath = _provider.path;
    if (dbPath.isEmpty) {
      debugPrint('unshareDatabaseFromUser: No database currently open');
      return false;
    }

    // Extract database name from path
    String databaseName = dbPath;
    if (dbPath.contains('/')) {
      databaseName = dbPath.split('/').last;
    }

    return await DatabaseSharingService.instance.revokeDatabaseAccess(
      databaseName,
      userEmail,
    );
  }

  /// Get list of users who have access to the current database.
  Future<List<Map<String, dynamic>>> getDatabaseAccessList() async {
    if (_provider is! FirebaseDBProvider) {
      debugPrint('getDatabaseAccessList: Can only manage cloud databases');
      return [];
    }

    final dbPath = _provider.path;
    if (dbPath.isEmpty) {
      debugPrint('getDatabaseAccessList: No database currently open');
      return [];
    }

    // Extract database name from path
    String databaseName = dbPath;
    if (dbPath.contains('/')) {
      databaseName = dbPath.split('/').last;
    }

    return await DatabaseSharingService.instance
        .getDatabaseAccessList(databaseName);
  }

  Future<bool> exists(String dbName) async {
    final databases = await getAvailableDatabases();
    return databases.contains(dbName);
  }
}

// Convert Firestore values (Timestamp, GeoPoint, nested maps/lists) to JSON-friendly values.
dynamic _firestoreValueToJson(dynamic value) {
  if (value == null) return null;
  if (value is Map) {
    final out = <String, dynamic>{};
    value.forEach((k, v) => out[k.toString()] = _firestoreValueToJson(v));
    return out;
  }
  if (value is List) return value.map(_firestoreValueToJson).toList();
  if (value is fs.Timestamp) return value.toDate().toIso8601String();
  if (value is fs.GeoPoint)
    return {'lat': value.latitude, 'lng': value.longitude};
  return value;
}
