import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:team_sync/services/subscription_service.dart';

/// An abstract class that defines the interface for database operations.
/// This allows for interchangeable implementations (e.g., local, cloud).
abstract class DatabaseProvider {
  /// Opens a connection to the database.
  Future<void> open(String path);

  /// The path to the current database file.
  String get path;

  /// Closes the database connection.
  Future<void> close();

  Future<List<String>> getAvailableDatabases();

  /// Executes a raw SQL query.
  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<dynamic>? whereArgs, String? orderBy});

  /// Inserts a record into a table.
  Future<int> insert(String table, Map<String, dynamic> data,
      {ConflictAlgorithm? conflictAlgorithm});

  /// Updates records in a table.
  Future<int> update(String table, Map<String, dynamic> data,
      {String? where, List<dynamic>? whereArgs});

  /// Deletes records from a table.
  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs});
}

/// A concrete implementation of [DatabaseProvider] for a local sqflite database.
class LocalDatabaseProvider implements DatabaseProvider {
  Database? _database;

  @override
  Future<List<String>> getAvailableDatabases() => Future.value([]);

  @override
  Future<void> open(String path) async {
    _database =
        await openDatabase(path, version: 1, onCreate: (db, version) async {
      await db.execute('''
    CREATE TABLE Teams (
      id INTEGER PRIMARY KEY,
      name TEXT NOT NULL,
      shortName TEXT NOT NULL
    )
  ''');
      await db.execute('''
    CREATE TABLE Seasons (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      teamId INTEGER NOT NULL,
      FOREIGN KEY (teamId) REFERENCES Teams (id) ON DELETE CASCADE
    )
  ''');

      await db.execute('''
    CREATE TABLE Players (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      name TEXT NOT NULL,
      number INTEGER
    )
  ''');

      await db.execute('''
    CREATE TABLE Games (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      seasonId INTEGER NOT NULL,
      date TEXT NOT NULL,
      opponent TEXT NOT NULL,
      isHomeGame INTEGER NOT NULL,
      goalsFor INTEGER,
      goalsAgainst INTEGER,
      notes TEXT,
      FOREIGN KEY (seasonId) REFERENCES Seasons (id) ON DELETE CASCADE
    )
  ''');

      await db.execute('''
    CREATE TABLE GameStats (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      gameId INTEGER NOT NULL,
      playerId INTEGER NOT NULL,
      goals INTEGER,
      assists INTEGER,
      saves INTEGER,
      FOREIGN KEY (gameId) REFERENCES Games (id) ON DELETE CASCADE,
      FOREIGN KEY (playerId) REFERENCES Players (id) ON DELETE CASCADE
    )
  ''');
    });
  }

  @override
  String get path => _database?.path ?? '';

  @override
  Future<void> close() async => await _database?.close();

  @override
  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<dynamic>? whereArgs, String? orderBy}) async {
    return await _database!
        .query(table, where: where, whereArgs: whereArgs, orderBy: orderBy);
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> data,
      {ConflictAlgorithm? conflictAlgorithm}) async {
    return await _database!
        .insert(table, data, conflictAlgorithm: conflictAlgorithm);
  }

  @override
  Future<int> update(String table, Map<String, dynamic> data,
      {String? where, List<dynamic>? whereArgs}) async {
    return await _database!
        .update(table, data, where: where, whereArgs: whereArgs);
  }

  @override
  Future<int> delete(String table,
      {String? where, List<dynamic>? whereArgs}) async {
    return await _database!.delete(table, where: where, whereArgs: whereArgs);
  }
}

/// A concrete implementation of [DatabaseProvider] for a cloud-based Firebase database.
class FirebaseDBProvider implements DatabaseProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _subscriptionId;
  String _path = '';
  late DocumentSnapshot _dbDocumentSnapshot;

  @override
  Future<List<String>> getAvailableDatabases() async {
    _subscriptionId =
        SubscriptionService.instance.customerInfo.originalAppUserId;

    final databases = await _firestore
        .collection('subscriptionIds')
        .doc(_subscriptionId)
        .collection('databases')
        .get();

    return databases.docs.map((doc) => doc.id).toList();
  }

  @override
  Future<void> open(String path) async {
    _subscriptionId =
        SubscriptionService.instance.customerInfo.originalAppUserId;

    _path = path;

    final dbDocument = _firestore
        .collection('subscriptionIds')
        .doc(_subscriptionId)
        .collection('databases')
        .doc(_path);

    _dbDocumentSnapshot = await dbDocument.get();
    if (!_dbDocumentSnapshot.exists) {
      await dbDocument.set({'version': 1});
    }
  }

  @override
  String get path => _path;

  @override
  Future<void> close() async {
    // No-op for Firebase.
  }

  @override
  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<dynamic>? whereArgs, String? orderBy}) async {
    Query q = _dbDocumentSnapshot.reference.collection(table);
    if (where != null && whereArgs != null) {
      q = q.where(where.replaceAll('=?', ''), isEqualTo: whereArgs.first);
    }
    if (orderBy != null) {
      if (orderBy.contains('DESC')) {
        orderBy = orderBy.replaceAll('DESC', '').trim();
        q = q.orderBy(orderBy, descending: true);
      } else {
        q = q.orderBy(orderBy);
      }
    }
    final snapshot = await q.get();
    return snapshot.docs
        .map((doc) => doc.data() as Map<String, dynamic>)
        .toList();
  }

  @override
  Future<int> insert(String table, Map<String, dynamic> data,
      {ConflictAlgorithm? conflictAlgorithm}) async {
    final collectionRef = _dbDocumentSnapshot.reference.collection(table);

    AggregateQuery aggregateQuery = collectionRef.count();
    AggregateQuerySnapshot snapshot = await aggregateQuery.get();
    int existingRows = snapshot.count ?? 0;
    existingRows++;

    data['id'] = existingRows;
    await collectionRef.doc(existingRows.toString()).set(data);

    return existingRows;
  }

  @override
  Future<int> update(String table, Map<String, dynamic> data,
      {String? where, List<dynamic>? whereArgs}) async {
    final snapshot = await _dbDocumentSnapshot.reference
        .collection(table)
        .where(where!, isEqualTo: whereArgs!.first)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.update(data);
    }
    return snapshot.docs.length;
  }

  @override
  Future<int> delete(String table,
      {String? where, List<dynamic>? whereArgs}) async {
    final snapshot = await _dbDocumentSnapshot.reference
        .collection(table)
        .where(where!, isEqualTo: whereArgs!.first)
        .get();
    for (final doc in snapshot.docs) {
      await doc.reference.delete();
    }
    return snapshot.docs.length;
  }
}

/// A service class that abstracts the database provider from the UI.
/// The rest of the app will interact with this service, which delegates
/// calls to the underlying [DatabaseProvider].
/// This is a singleton to ensure a single database connection.
class DatabaseService {
  // The single, static instance of the database service.
  static final DatabaseService instance = DatabaseService._internal();

  // The internal provider for database operations.
  late DatabaseProvider _provider;

  // Factory constructor is not needed for this singleton pattern.

  // A private constructor.
  DatabaseService._internal() {
    // Default to the local provider.
    _provider = LocalDatabaseProvider();
  }

  /// Sets the database provider for the service.
  /// This allows for swapping the database implementation (e.g., for testing).
  void setProvider(DatabaseProvider provider) {
    _provider = provider;
  }

  Future<void> open(String path) => _provider.open(path);

  String get path => _provider.path;

  Future<void> close() => _provider.close();

  Future<List<String>> getAvailableDatabases() {
    return _provider.getAvailableDatabases();
  }

  Future<List<Map<String, dynamic>>> query(String table,
          {String? where, List<dynamic>? whereArgs, String? orderBy}) =>
      _provider.query(table,
          where: where, whereArgs: whereArgs, orderBy: orderBy);

  Future<int> insert(String table, Map<String, dynamic> data,
          {ConflictAlgorithm? conflictAlgorithm}) =>
      _provider.insert(table, data, conflictAlgorithm: conflictAlgorithm);

  Future<int> update(String table, Map<String, dynamic> data,
          {String? where, List<dynamic>? whereArgs}) =>
      _provider.update(table, data, where: where, whereArgs: whereArgs);

  Future<int> delete(String table, {String? where, List<dynamic>? whereArgs}) =>
      _provider.delete(table, where: where, whereArgs: whereArgs);
}
