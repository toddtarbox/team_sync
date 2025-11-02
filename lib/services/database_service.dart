import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// An abstract class that defines the interface for database operations.
/// This allows for interchangeable implementations (e.g., local, cloud).
abstract class DatabaseProvider {
  /// Opens a connection to the database.
  Future<bool> open(String path);

  /// The path to the current database file.
  String get path;

  Future<bool> get isImporting;

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
  Future<bool> open(String path) async {
    _database =
        await openDatabase(path, version: 1, onCreate: (db, version) async {
      db.execute(
          "create table Seasons (id integer primary key autoincrement, " +
              "name text not null, " +
              "teamId integer not null);");

      db.execute("create table Teams (id integer primary key autoincrement, " +
          "fullName text not null, " +
          "shortName text not null, " +
          "color1 integer not null, " +
          "color2 integer not null);");

      db.execute("create table Games (id integer primary key autoincrement, " +
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
          "number integer not null, primary key(id, teamId, seasonId));");

      db.execute("create table Events (id integer primary key autoincrement, " +
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
    });

    return true;
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

  @override
  Future<bool> get isImporting => Future.value(false);
}

/// A concrete implementation of [DatabaseProvider] for a cloud-based Firebase database.
class FirebaseDBProvider implements DatabaseProvider {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late String _subscriptionId;
  String _path = '';
  late DocumentSnapshot _dbDocumentSnapshot;
  DocumentSnapshot get dbDocumentSnapshot => _dbDocumentSnapshot;

  String? get publicShareId {
    final data = _dbDocumentSnapshot.data() as Map<String, dynamic>?;
    if (data != null && data.containsKey('publicShareId')) {
      return data['publicShareId'] as String?;
    }
    return null;
  }

  @override
  Future<bool> get isImporting async =>
      ((await _dbDocumentSnapshot.reference.get()).data()
          as Map<String, dynamic>)['isImporting'] ==
      true;

  Future<void> set(Map<String, dynamic> map) async {
    await _dbDocumentSnapshot.reference.update(map);
  }

  Future<void> _getSubscriptionId() async {
    if (FirebaseAuth.instance.currentUser == null) {
      AuthProvider provider;
      if (Platform.isIOS) {
        provider = AppleAuthProvider()
            .addScope('ASAuthorizationScopeFullName')
            .addScope('ASAuthorizationScopeEmail');
      } else {
        provider = GoogleAuthProvider();
      }

      // Get the current user from Firebase Auth.
      var firebaseUser = FirebaseAuth.instance.currentUser;
      if (firebaseUser == null) {
        await FirebaseAuth.instance.signInWithProvider(provider);
      }
    }

    _subscriptionId = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  Future<List<String>> getAvailableDatabases() async {
    await _getSubscriptionId();

    final databases = await _firestore
        .collection('subscriptionIds')
        .doc(_subscriptionId)
        .collection('databases')
        .get();

    return databases.docs.map((doc) => doc.id).toList();
  }

  @override
  Future<bool> open(String path) async {
    await _getSubscriptionId();

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

    return !(await isImporting);
  }

  @override
  String get path => _path;

  @override
  Future<void> close() async {}

  @override
  Future<List<Map<String, dynamic>>> query(String table,
      {String? where, List<dynamic>? whereArgs, String? orderBy}) async {
    Query q = _dbDocumentSnapshot.reference.collection(table);
    if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
      final fields = where.split(' AND ');
      int index = 0;

      for (var arg in whereArgs) {
        final field = fields[index++].replaceAll('=?', '');
        q = q.where(field, isEqualTo: arg);
      }
    }

    if (orderBy != null) {
      if (orderBy.contains('DESC')) {
        orderBy = orderBy.replaceAll('DESC', '').trim();
        q = q.orderBy(orderBy, descending: true);
      } else {
        orderBy = orderBy.replaceAll('ASC', '').trim();
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

    // For importing data, we must preserve the original ID.
    // We check if the incoming data already has an ID.
    if (table != 'Players' && data.containsKey('id') && data['id'] != null) {
      final id = data['id'];
      // Use the existing ID as the document ID in Firestore.
      // .set() will create or overwrite the document, which is perfect for an import.
      await collectionRef.doc(id.toString()).set(data);
      return id;
    } else {
      AggregateQuery aggregateQuery = collectionRef.count();
      AggregateQuerySnapshot snapshot = await aggregateQuery.get();
      int existingRows = snapshot.count ?? 0;
      existingRows++;

      data['id'] = existingRows;

      await collectionRef.doc().set(data);
      return 1;
    }
  }

  @override
  Future<int> update(String table, Map<String, dynamic> data,
      {String? where, List<dynamic>? whereArgs}) async {
    Query q = _dbDocumentSnapshot.reference.collection(table);
    if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
      final fields = where.split(' AND ');
      int index = 0;

      for (var arg in whereArgs) {
        final field = fields[index++].replaceAll('=?', '');
        q = q.where(field, isEqualTo: arg);
      }
    }
    final snapshot = await q.get();
    for (final doc in snapshot.docs) {
      await doc.reference.update(data);
    }
    return snapshot.docs.length;
  }

  @override
  Future<int> delete(String table,
      {String? where, List<dynamic>? whereArgs}) async {
    Query q = _dbDocumentSnapshot.reference.collection(table);
    if (where != null && whereArgs != null && whereArgs.isNotEmpty) {
      final fields = where.split(' AND ');
      int index = 0;

      for (var arg in whereArgs) {
        final field = fields[index++].replaceAll('=?', '');
        q = q.where(field, isEqualTo: arg);
      }
    }
    final snapshot = await q.get();
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

  bool get isLocalDatabase => _provider is LocalDatabaseProvider;
  String? get publicShareId {
    if (_provider is FirebaseDBProvider) {
      return (_provider as FirebaseDBProvider).publicShareId;
    }
    return null;
  }

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

  Future<bool> get isImporting async => await _provider.isImporting;

  /// Imports a local SQLite database into a specified Firestore database.
  ///
  /// This method reads all data from the tables in the local database
  /// and writes them to the corresponding collections in Firestore.
  /// It respects table dependencies to ensure data integrity.
  Future<void> importToCloud() async {
    if (_provider is FirebaseDBProvider || await isImporting) {
      return;
    }

    final cloudProvider = FirebaseDBProvider();

    final cloudDbName = _provider.path.split('/').last;
    await cloudProvider.open(cloudDbName);

    // Define the order of table migration to respect foreign key constraints.
    const tablesToMigrate = ['Teams', 'Seasons', 'Players', 'Games', 'Events'];

    await cloudProvider.set({'isImporting': true});

    for (final table in tablesToMigrate) {
      debugPrint('Querying table: $table');
      final dataToMigrate = await _provider.query(table);

      debugPrint('Migrating table: $table - ${dataToMigrate.length} rows');
      final rowMigrationPromises = dataToMigrate.map((row) async {
        // Our updated `insert` method on the cloud provider will use the
        // existing ID from the row, preserving data integrity.
        cloudProvider.insert(table, row);
      });
      await Future.wait(rowMigrationPromises);
    }

    await cloudProvider.set({'isImporting': false});

    await _provider.close();
    setProvider(cloudProvider);

    debugPrint('Importing complete');
  }

  Future<String> shareDatabase() async {
    if (_provider is! FirebaseDBProvider) {
      throw Exception("Can only share a cloud database.");
    }

    final firebaseProvider = _provider as FirebaseDBProvider;
    final dbDoc = firebaseProvider.dbDocumentSnapshot;
    final data = dbDoc.data() as Map<String, dynamic>?;

    // If it's already shared, return the existing ID.
    if (data != null && data.containsKey('publicShareId')) {
      return data['publicShareId'] as String;
    }

    // Otherwise, create a new share.
    final random = Random();
    String publicId;
    bool exists;
    do {
      publicId = (100000 + random.nextInt(900000)).toString();
      final mappingDoc = await FirebaseFirestore.instance
          .collection('shared_databases')
          .doc(publicId)
          .get();
      exists = mappingDoc.exists;
    } while (exists);

    await FirebaseFirestore.instance
        .collection('shared_databases')
        .doc(publicId)
        .set({'databasePath': dbDoc.reference.path});

    // Save the public ID back to the source database for future lookups.
    await dbDoc.reference.update({'publicShareId': publicId});

    return publicId;
  }

  Future<bool> open(String path) async => await _provider.open(path);

  String get path => _provider.path;

  Future<void> close() async => await _provider.close();
  Future<List<String>> getAvailableDatabases() async =>
      await _provider.getAvailableDatabases();
  Future<List<Map<String, dynamic>>> query(String table,
          {String? where, List<dynamic>? whereArgs, String? orderBy}) async =>
      await _provider.query(table,
          where: where, whereArgs: whereArgs, orderBy: orderBy);

  Future<int> insert(String table, Map<String, dynamic> data,
          {ConflictAlgorithm? conflictAlgorithm}) async =>
      await _provider.insert(table, data, conflictAlgorithm: conflictAlgorithm);
  Future<int> update(String table, Map<String, dynamic> data,
          {String? where, List<dynamic>? whereArgs}) async =>
      await _provider.update(table, data, where: where, whereArgs: whereArgs);

  Future<int> delete(String table,
          {String? where, List<dynamic>? whereArgs}) async =>
      await _provider.delete(table, where: where, whereArgs: whereArgs);

  Future<bool> exists(String dbName) async {
    final databases = await getAvailableDatabases();
    return databases.contains(dbName);
  }
}
