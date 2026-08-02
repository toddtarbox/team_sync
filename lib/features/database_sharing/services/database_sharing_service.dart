import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:team_sync/core/services/subscription_service.dart';

/// Service for managing database access sharing between users.
///
/// Allows Pro users to grant access to their databases to other users,
/// enabling cross-platform collaboration (e.g., Android/Google and iOS/Apple users).
class DatabaseSharingService {
  static final DatabaseSharingService instance =
      DatabaseSharingService._internal();

  DatabaseSharingService._internal();

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  /// Get current user's UID
  String? get _currentUserId => FirebaseAuth.instance.currentUser?.uid;

  /// Check if current user is a Pro subscriber
  bool get _isProUser => SubscriptionService.instance.isSubscribed;

  /// Grant access to a database for another user.
  ///
  /// [databaseName] - The name of the database to share
  /// [targetUserEmail] - Email of the user to grant access to
  /// [accessLevel] - 'read' or 'write' (default: 'read')
  ///
  /// Returns true if access was granted successfully.
  Future<bool> grantDatabaseAccess(
    String databaseName,
    String targetUserEmail, {
    String accessLevel = 'read',
  }) async {
    if (_currentUserId == null) {
      debugPrint('grantDatabaseAccess: No user logged in');
      return false;
    }

    if (!_isProUser) {
      debugPrint('grantDatabaseAccess: User is not a Pro subscriber');
      return false;
    }

    try {
      // Look up target user by email
      final targetUserId = await _getUserIdByEmail(targetUserEmail);
      if (targetUserId == null) {
        debugPrint('grantDatabaseAccess: User not found: $targetUserEmail');
        return false;
      }

      // Validate access level
      if (accessLevel != 'read' && accessLevel != 'write') {
        debugPrint('grantDatabaseAccess: Invalid access level: $accessLevel');
        return false;
      }

      // Store the access grant
      final accessPath =
          'database_access/$_currentUserId/$databaseName/shared_with/$targetUserId';
      await _database.ref(accessPath).set({
        'email': targetUserEmail,
        'accessLevel': accessLevel,
        'grantedAt': ServerValue.timestamp,
        'grantedBy': _currentUserId,
      });

      // Also store a reverse mapping for the target user to find shared databases
      final userAccessPath =
          'user_database_access/$targetUserId/$_currentUserId/$databaseName';
      await _database.ref(userAccessPath).set({
        'ownerEmail': FirebaseAuth.instance.currentUser?.email ?? '',
        'accessLevel': accessLevel,
        'grantedAt': ServerValue.timestamp,
        'databasePath':
            'subscriptionIds/$_currentUserId/databases/$databaseName',
      });

      debugPrint(
          'grantDatabaseAccess: Access granted to $targetUserEmail for $databaseName');
      return true;
    } catch (e, stackTrace) {
      debugPrint('grantDatabaseAccess: Error granting access: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Revoke access to a database for a user.
  Future<bool> revokeDatabaseAccess(
    String databaseName,
    String targetUserEmail,
  ) async {
    if (_currentUserId == null) {
      debugPrint('revokeDatabaseAccess: No user logged in');
      return false;
    }

    if (!_isProUser) {
      debugPrint('revokeDatabaseAccess: User is not a Pro subscriber');
      return false;
    }

    try {
      final targetUserId = await _getUserIdByEmail(targetUserEmail);
      if (targetUserId == null) {
        debugPrint('revokeDatabaseAccess: User not found: $targetUserEmail');
        return false;
      }

      // Remove the access grant
      final accessPath =
          'database_access/$_currentUserId/$databaseName/shared_with/$targetUserId';
      await _database.ref(accessPath).remove();

      // Remove the reverse mapping
      final userAccessPath =
          'user_database_access/$targetUserId/$_currentUserId/$databaseName';
      await _database.ref(userAccessPath).remove();

      debugPrint(
          'revokeDatabaseAccess: Access revoked for $targetUserEmail on $databaseName');
      return true;
    } catch (e, stackTrace) {
      debugPrint('revokeDatabaseAccess: Error revoking access: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }

  /// Get list of users who have access to a database.
  Future<List<Map<String, dynamic>>> getDatabaseAccessList(
      String databaseName) async {
    if (_currentUserId == null) {
      debugPrint('getDatabaseAccessList: No user logged in');
      return [];
    }

    try {
      final accessPath =
          'database_access/$_currentUserId/$databaseName/shared_with';
      final snapshot = await _database.ref(accessPath).get();

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final accessData = snapshot.value as Map<dynamic, dynamic>;
      final accessList = <Map<String, dynamic>>[];

      for (final entry in accessData.entries) {
        final userId = entry.key.toString();
        final data = entry.value as Map<dynamic, dynamic>;
        accessList.add({
          'userId': userId,
          'email': data['email']?.toString() ?? 'Unknown',
          'accessLevel': data['accessLevel']?.toString() ?? 'read',
          'grantedAt': data['grantedAt'], // Keep as-is (int or dynamic)
        });
      }

      return accessList;
    } catch (e, stackTrace) {
      debugPrint('getDatabaseAccessList: Error: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Get list of databases shared with the current user.
  Future<List<Map<String, dynamic>>> getSharedDatabases() async {
    if (_currentUserId == null) {
      debugPrint('getSharedDatabases: No user logged in');
      return [];
    }

    try {
      final userAccessPath = 'user_database_access/$_currentUserId';
      final snapshot = await _database.ref(userAccessPath).get();

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      final accessData = snapshot.value as Map<dynamic, dynamic>;
      final sharedDatabases = <Map<String, dynamic>>[];

      for (final ownerEntry in accessData.entries) {
        final ownerId = ownerEntry.key.toString();
        final ownerDatabases = ownerEntry.value as Map<dynamic, dynamic>;

        for (final dbEntry in ownerDatabases.entries) {
          final dbName = dbEntry.key.toString();
          final data = dbEntry.value as Map<dynamic, dynamic>;
          sharedDatabases.add({
            'ownerId': ownerId,
            'ownerEmail': data['ownerEmail']?.toString() ?? '',
            'databaseName': dbName,
            'databasePath': data['databasePath']?.toString() ?? '',
            'accessLevel': data['accessLevel']?.toString() ?? 'read',
            'grantedAt': data['grantedAt'], // Keep as-is (int or dynamic)
          });
        }
      }

      return sharedDatabases;
    } catch (e, stackTrace) {
      debugPrint('getSharedDatabases: Error: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// Check if current user has access to a specific database.
  Future<String?> checkDatabaseAccess(
      String ownerId, String databaseName) async {
    if (_currentUserId == null) {
      return null;
    }

    // Owner always has full access
    if (_currentUserId == ownerId) {
      return 'write';
    }

    try {
      final userAccessPath =
          'user_database_access/$_currentUserId/$ownerId/$databaseName';
      final snapshot = await _database.ref(userAccessPath).get();

      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }

      final data = snapshot.value as Map<dynamic, dynamic>;
      return data['accessLevel']?.toString();
    } catch (e) {
      debugPrint('checkDatabaseAccess: Error: $e');
      return null;
    }
  }

  /// Look up user ID by email.
  /// Note: This requires a users collection or Firebase Auth Admin SDK.
  /// For now, this is a placeholder that uses a simple lookup table.
  ///
  /// TODO: Implement proper user lookup using Firebase Functions or Admin SDK
  Future<String?> _getUserIdByEmail(String email) async {
    try {
      // Try to find user in a users lookup table
      final usersRef = _database.ref('users');
      final snapshot = await usersRef
          .orderByChild('email')
          .equalTo(email.toLowerCase())
          .limitToFirst(1)
          .get();

      if (snapshot.exists && snapshot.value != null) {
        final usersMap = snapshot.value as Map<dynamic, dynamic>;
        final userId = usersMap.keys.first.toString();
        return userId;
      }

      // User not found in lookup table
      debugPrint('_getUserIdByEmail: User not found for email: $email');
      return null;
    } catch (e) {
      debugPrint('_getUserIdByEmail: Error: $e');
      return null;
    }
  }

  /// Register current user in the users lookup table.
  /// Should be called when a user signs in.
  /// Also links the UID to the email for cross-platform database access.
  Future<void> registerUserInLookup() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      debugPrint('registerUserInLookup: No user logged in');
      return;
    }

    // Apple Sign-In only provides email on first sign-in
    // Check if email is available, if not try to get it from existing user record
    String? email = user.email;

    if (email == null || email.isEmpty) {
      debugPrint(
          'registerUserInLookup: Email not available from auth provider, checking existing record');
      try {
        final existingUserSnapshot =
            await _database.ref('users/${user.uid}').get();
        if (existingUserSnapshot.exists) {
          final existingData =
              existingUserSnapshot.value as Map<dynamic, dynamic>;
          email = existingData['email']?.toString();
          debugPrint(
              'registerUserInLookup: Found email in existing record: $email');
        }
      } catch (e) {
        debugPrint('registerUserInLookup: Error checking existing user: $e');
      }
    }

    // If still no email, we cannot proceed with registration
    if (email == null || email.isEmpty) {
      debugPrint('registerUserInLookup: Cannot register user without email');
      return;
    }

    try {
      email = email.toLowerCase();
      final uid = user.uid;

      // 1. Register in users table (for user lookup by email)
      await _database.ref('users/$uid').set({
        'email': email,
        'displayName': user.displayName ?? '',
        'photoURL': user.photoURL ?? '',
        'lastSeen': ServerValue.timestamp,
      });

      // 2. Link UID to email for cross-platform access
      // Create email hash for Firebase key compatibility (no @ or .)
      final emailHash = base64Encode(utf8.encode(email))
          .replaceAll('=', '')
          .replaceAll('+', '-')
          .replaceAll('/', '_');

      final identityRef = _database.ref('user_identities/$emailHash');
      final identitySnapshot = await identityRef.get();

      if (!identitySnapshot.exists) {
        // First time this email is used - create new identity
        await identityRef.set({
          'email': email,
          'primaryUid': uid,
          'uids': {uid: true},
          'createdAt': ServerValue.timestamp,
          'lastUpdated': ServerValue.timestamp,
        });
        debugPrint(
            'registerUserInLookup: Created new identity for $email (UID: $uid)');
      } else {
        // Email exists - add this UID to the list
        final data = identitySnapshot.value as Map<dynamic, dynamic>;
        final existingUids = data['uids'] as Map<dynamic, dynamic>?;

        if (existingUids == null || !existingUids.containsKey(uid)) {
          await identityRef.update({
            'uids/$uid': true,
            'lastUpdated': ServerValue.timestamp,
          });
          debugPrint(
              'registerUserInLookup: Linked UID $uid to existing email $email');
        } else {
          // UID already linked, just update last seen
          await identityRef.update({
            'lastUpdated': ServerValue.timestamp,
          });
          debugPrint('registerUserInLookup: Updated last seen for $email');
        }
      }

      debugPrint('registerUserInLookup: User registered: $email');
    } catch (e, stackTrace) {
      if (e.toString().contains('permission-denied')) {
        debugPrint(
            'registerUserInLookup: Permission denied (expected in testing/restricted environments).');
      } else {
        debugPrint('registerUserInLookup: Error: $e');
        debugPrint('Stack trace: $stackTrace');
      }
    }
  }

  /// Get all UIDs associated with the current user.
  /// Cross-provider linking has been removed - now just returns current UID.
  Future<List<String>> getAllLinkedUids() async {
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? [user.uid] : [];
  }

  /// Update access level for a user on a database.
  Future<bool> updateDatabaseAccess(
    String databaseName,
    String targetUserEmail,
    String newAccessLevel,
  ) async {
    if (_currentUserId == null) {
      debugPrint('updateDatabaseAccess: No user logged in');
      return false;
    }

    if (!_isProUser) {
      debugPrint('updateDatabaseAccess: User is not a Pro subscriber');
      return false;
    }

    if (newAccessLevel != 'read' && newAccessLevel != 'write') {
      debugPrint('updateDatabaseAccess: Invalid access level: $newAccessLevel');
      return false;
    }

    try {
      final targetUserId = await _getUserIdByEmail(targetUserEmail);
      if (targetUserId == null) {
        debugPrint('updateDatabaseAccess: User not found: $targetUserEmail');
        return false;
      }

      // Update the access level
      final accessPath =
          'database_access/$_currentUserId/$databaseName/shared_with/$targetUserId';
      await _database.ref(accessPath).update({
        'accessLevel': newAccessLevel,
        'updatedAt': ServerValue.timestamp,
      });

      // Update the reverse mapping
      final userAccessPath =
          'user_database_access/$targetUserId/$_currentUserId/$databaseName';
      await _database.ref(userAccessPath).update({
        'accessLevel': newAccessLevel,
        'updatedAt': ServerValue.timestamp,
      });

      debugPrint(
          'updateDatabaseAccess: Access level updated for $targetUserEmail on $databaseName');
      return true;
    } catch (e, stackTrace) {
      debugPrint('updateDatabaseAccess: Error: $e');
      debugPrint('Stack trace: $stackTrace');
      return false;
    }
  }
}
