import 'dart:convert';

import 'package:encrypt/encrypt.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:team_sync/services/database_service.dart';

/// Service for managing encrypted Twitter API credentials stored in Firebase.
///
/// Twitter credentials are sensitive and need to be:
/// 1. Shared across devices/users (stored in Firebase, not local secure storage)
/// 2. Protected from unauthorized access (encrypted)
/// 3. Only accessible by team admins
class TwitterCredentialsService {
  static const String _encryptionKeyStorageKey = 'twitter_encryption_key';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  /// Model for Twitter credentials
  static const String _consumerKeyField = 'consumerKey';
  static const String _consumerSecretField = 'consumerSecret';
  static const String _accessTokenField = 'accessToken';
  static const String _accessTokenSecretField = 'accessTokenSecret';

  /// Get or generate an encryption key for a specific team.
  /// This key is stored in Firebase and shared across all team admins' devices.
  /// Each team has its own unique key.
  static Future<Key> _getOrCreateEncryptionKey(int teamId) async {
    // First, try to get the key from local cache
    final cacheKey = '${_encryptionKeyStorageKey}_team_$teamId';
    String? keyString = await _secureStorage.read(key: cacheKey);

    if (keyString != null) {
      return Key(base64.decode(keyString));
    }

    // If not in cache, try to get from Firebase
    final results = await DatabaseService.instance.query(
      'Teams',
      orderByChild: 'id',
      equalTo: teamId,
    );

    if (results.isNotEmpty) {
      final teamData = results.first;
      final firebaseKeyString = teamData['twitterEncryptionKey'] as String?;

      if (firebaseKeyString != null) {
        // Cache the key locally for faster access
        await _secureStorage.write(key: cacheKey, value: firebaseKeyString);
        return Key(base64.decode(firebaseKeyString));
      }
    }

    // If no key exists, generate a new one and store in Firebase
    final key = Key.fromSecureRandom(32);
    keyString = base64.encode(key.bytes);

    // Store in Firebase
    await DatabaseService.instance.update(
      'Teams',
      {'twitterEncryptionKey': keyString},
      orderByChild: 'id',
      equalTo: teamId,
    );

    // Cache locally
    await _secureStorage.write(key: cacheKey, value: keyString);

    return key;
  }

  /// Encrypt a string value using the team's encryption key
  static Future<String> _encrypt(String plainText, int teamId) async {
    final key = await _getOrCreateEncryptionKey(teamId);
    final iv =
        IV.fromSecureRandom(16); // Generate random IV for each encryption
    final encrypter = Encrypter(AES(key));

    final encrypted = encrypter.encrypt(plainText, iv: iv);

    // Return IV + encrypted data as base64 (IV is needed for decryption)
    return base64.encode(iv.bytes + encrypted.bytes);
  }

  /// Decrypt a string value using the team's encryption key
  static Future<String> _decrypt(String encryptedText, int teamId) async {
    final key = await _getOrCreateEncryptionKey(teamId);
    final bytes = base64.decode(encryptedText);

    // Extract IV (first 16 bytes) and encrypted data (rest)
    final iv = IV(bytes.sublist(0, 16));
    final encryptedBytes = bytes.sublist(16);

    final encrypter = Encrypter(AES(key));
    return encrypter.decrypt(Encrypted(encryptedBytes), iv: iv);
  }

  /// Save Twitter credentials for a team (encrypted in Firebase)
  static Future<void> saveCredentials({
    required int teamId,
    required String consumerKey,
    required String consumerSecret,
    required String accessToken,
    required String accessTokenSecret,
  }) async {
    // Encrypt each credential using the team's encryption key
    final encryptedConsumerKey = await _encrypt(consumerKey, teamId);
    final encryptedConsumerSecret = await _encrypt(consumerSecret, teamId);
    final encryptedAccessToken = await _encrypt(accessToken, teamId);
    final encryptedAccessTokenSecret =
        await _encrypt(accessTokenSecret, teamId);

    // Store in Firebase under the team's data
    final data = {
      _consumerKeyField: encryptedConsumerKey,
      _consumerSecretField: encryptedConsumerSecret,
      _accessTokenField: encryptedAccessToken,
      _accessTokenSecretField: encryptedAccessTokenSecret,
      'updatedAt': DateTime.now().toIso8601String(),
    };

    await DatabaseService.instance.update(
      'Teams',
      {'twitterCredentials': data},
      orderByChild: 'id',
      equalTo: teamId,
    );
  }

  /// Load Twitter credentials for a team (decrypt from Firebase)
  static Future<TwitterCredentials?> loadCredentials(int teamId) async {
    try {
      final results = await DatabaseService.instance.query(
        'Teams',
        orderByChild: 'id',
        equalTo: teamId,
      );

      if (results.isEmpty) return null;

      final teamData = results.first;

      // Firebase returns Map<Object?, Object?>, need to convert to Map<String, dynamic>
      final rawCredentials = teamData['twitterCredentials'];
      if (rawCredentials == null) return null;

      // Convert Map<Object?, Object?> to Map<String, dynamic>
      final credentialsData = Map<String, dynamic>.from(rawCredentials as Map);

      // Decrypt each credential using the team's encryption key
      final consumerKey =
          await _decrypt(credentialsData[_consumerKeyField] as String, teamId);
      final consumerSecret = await _decrypt(
          credentialsData[_consumerSecretField] as String, teamId);
      final accessToken =
          await _decrypt(credentialsData[_accessTokenField] as String, teamId);
      final accessTokenSecret = await _decrypt(
          credentialsData[_accessTokenSecretField] as String, teamId);

      return TwitterCredentials(
        consumerKey: consumerKey,
        consumerSecret: consumerSecret,
        accessToken: accessToken,
        accessTokenSecret: accessTokenSecret,
      );
    } catch (e) {
      // If decryption fails or data is missing, return null
      return null;
    }
  }

  /// Delete Twitter credentials for a team
  static Future<void> deleteCredentials(int teamId) async {
    await DatabaseService.instance.update(
      'Teams',
      {'twitterCredentials': null},
      orderByChild: 'id',
      equalTo: teamId,
    );
  }

  /// Check if credentials exist for a team
  static Future<bool> hasCredentials(int teamId) async {
    final results = await DatabaseService.instance.query(
      'Teams',
      orderByChild: 'id',
      equalTo: teamId,
    );

    if (results.isEmpty) return false;

    final teamData = results.first;
    return teamData['twitterCredentials'] != null;
  }
}

/// Model class for Twitter credentials
class TwitterCredentials {
  final String consumerKey;
  final String consumerSecret;
  final String accessToken;
  final String accessTokenSecret;

  const TwitterCredentials({
    required this.consumerKey,
    required this.consumerSecret,
    required this.accessToken,
    required this.accessTokenSecret,
  });

  bool get isEmpty =>
      consumerKey.isEmpty &&
      consumerSecret.isEmpty &&
      accessToken.isEmpty &&
      accessTokenSecret.isEmpty;
}
