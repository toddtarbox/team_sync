import 'package:dart_twitter_api/twitter_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/twitter_credentials_service.dart';

/// Service for sending tweets using configured team Twitter credentials.
///
/// This service provides a centralized way to:
/// 1. Initialize Twitter API with team credentials
/// 2. Send tweets from anywhere in the app
/// 3. Show adhoc tweet dialogs with character counting
/// 4. Handle Twitter configuration checks
class TwitterService {
  static final TwitterService instance = TwitterService._internal();
  factory TwitterService() => instance;
  TwitterService._internal();

  TwitterApi? _twitterAPI;
  int? _currentTeamId;

  /// Initialize Twitter API with credentials for a specific team.
  /// Uses flutter_secure_storage for legacy local credentials.
  Future<bool> initializeWithLocalCredentials() async {
    if (kIsWeb) {
      debugPrint('Twitter init: Skipping on web');
      return false;
    }

    try {
      const storage = FlutterSecureStorage();
      final consumerKey = await storage.read(key: 'twitter_consumer_key') ?? '';
      final consumerSecret =
          await storage.read(key: 'twitter_consumer_secret') ?? '';
      final accessToken = await storage.read(key: 'twitter_access_token') ?? '';
      final accessTokenSecret =
          await storage.read(key: 'twitter_access_token_secret') ?? '';

      if (consumerKey.isEmpty ||
          consumerSecret.isEmpty ||
          accessToken.isEmpty ||
          accessTokenSecret.isEmpty) {
        debugPrint('Twitter init: Missing credentials');
        debugPrint('  consumerKey: ${consumerKey.isEmpty ? "empty" : "set"}');
        debugPrint(
            '  consumerSecret: ${consumerSecret.isEmpty ? "empty" : "set"}');
        debugPrint('  accessToken: ${accessToken.isEmpty ? "empty" : "set"}');
        debugPrint(
            '  accessTokenSecret: ${accessTokenSecret.isEmpty ? "empty" : "set"}');
        return false;
      }

      _twitterAPI = TwitterApi(
        client: TwitterClient(
          consumerKey: consumerKey,
          consumerSecret: consumerSecret,
          token: accessToken,
          secret: accessTokenSecret,
        ),
      );

      debugPrint(
          'Twitter init: Successfully initialized with local credentials');
      return true;
    } catch (e) {
      debugPrint('Error initializing Twitter with local credentials: $e');
      return false;
    }
  }

  /// Initialize Twitter API with credentials from Firebase for a specific team.
  Future<bool> initializeWithTeamCredentials(int teamId) async {
    if (kIsWeb) {
      return false;
    }

    try {
      final credentials =
          await TwitterCredentialsService.loadCredentials(teamId);

      if (credentials == null) {
        return false;
      }

      _twitterAPI = TwitterApi(
        client: TwitterClient(
          consumerKey: credentials.consumerKey,
          consumerSecret: credentials.consumerSecret,
          token: credentials.accessToken,
          secret: credentials.accessTokenSecret,
        ),
      );

      _currentTeamId = teamId;
      return true;
    } catch (e) {
      debugPrint('Error initializing Twitter with team credentials: $e');
      return false;
    }
  }

  /// Check if Twitter is configured (either locally or for a team).
  Future<bool> isConfigured({int? teamId}) async {
    if (kIsWeb) {
      return false;
    }

    if (teamId != null) {
      final hasTeamCreds =
          await TwitterCredentialsService.hasCredentials(teamId);
      debugPrint('Twitter isConfigured (team $teamId): $hasTeamCreds');
      return hasTeamCreds;
    }

    // Check local credentials
    try {
      const storage = FlutterSecureStorage();
      final consumerKey = await storage.read(key: 'twitter_consumer_key') ?? '';
      final consumerSecret =
          await storage.read(key: 'twitter_consumer_secret') ?? '';
      final accessToken = await storage.read(key: 'twitter_access_token') ?? '';
      final accessTokenSecret =
          await storage.read(key: 'twitter_access_token_secret') ?? '';

      final isConfigured = consumerKey.isNotEmpty &&
          consumerSecret.isNotEmpty &&
          accessToken.isNotEmpty &&
          accessTokenSecret.isNotEmpty;

      debugPrint('Twitter isConfigured (local): $isConfigured');
      if (!isConfigured) {
        debugPrint('  consumerKey: ${consumerKey.isEmpty ? "empty" : "set"}');
        debugPrint(
            '  consumerSecret: ${consumerSecret.isEmpty ? "empty" : "set"}');
        debugPrint('  accessToken: ${accessToken.isEmpty ? "empty" : "set"}');
        debugPrint(
            '  accessTokenSecret: ${accessTokenSecret.isEmpty ? "empty" : "set"}');
      }

      return isConfigured;
    } catch (e) {
      debugPrint('Error checking Twitter configuration: $e');
      return false;
    }
  }

  /// Send a tweet with the configured credentials.
  /// Returns true if successful, false otherwise.
  Future<bool> sendTweet(String text) async {
    if (kIsWeb) {
      return false;
    }

    if (_twitterAPI == null) {
      debugPrint('Twitter API not initialized. Call initialize() first.');
      return false;
    }

    if (text.isEmpty || text.length > 280) {
      debugPrint('Tweet text must be between 1 and 280 characters.');
      return false;
    }

    try {
      await _twitterAPI!.tweetService.update(status: text);
      return true;
    } catch (e) {
      debugPrint('Error sending tweet: $e');
      return false;
    }
  }

  /// Get the Twitter handle for a team (from stored credentials or API)
  Future<String?> getTwitterHandle({int? teamId}) async {
    if (kIsWeb) {
      return null;
    }

    try {
      // First, try to get stored handle from team data
      if (teamId != null) {
        final results = await DatabaseService.instance.query(
          'Teams',
          orderByChild: 'id',
          equalTo: teamId,
        );

        if (results.isNotEmpty) {
          final teamData = results.first;
          final storedHandle = teamData['twitterHandle'] as String?;
          if (storedHandle != null && storedHandle.isNotEmpty) {
            return storedHandle;
          }
        }
      }

      // If no stored handle, try to get from local credentials
      const storage = FlutterSecureStorage();
      final localHandle = await storage.read(key: 'twitter_handle');
      if (localHandle != null && localHandle.isNotEmpty) {
        return localHandle;
      }

      // If still no handle and we have initialized API, try to fetch from Twitter API
      if (_twitterAPI != null) {
        try {
          final user = await _twitterAPI!.userService.usersShow();
          final handle = user.screenName;

          // Cache the handle for future use
          if (handle != null && teamId != null) {
            await DatabaseService.instance.update(
              'Teams',
              {'twitterHandle': handle},
              orderByChild: 'id',
              equalTo: teamId,
            );
          } else if (handle != null) {
            await storage.write(key: 'twitter_handle', value: handle);
          }

          return handle;
        } catch (e) {
          debugPrint('Error fetching Twitter handle from API: $e');
        }
      }

      return null;
    } catch (e) {
      debugPrint('Error getting Twitter handle: $e');
      return null;
    }
  }

  /// Get the current team ID that Twitter is initialized for.
  int? get currentTeamId => _currentTeamId;

  /// Check if Twitter API is initialized and ready to send tweets.
  bool get isInitialized => _twitterAPI != null;

  /// Reset the Twitter service (useful when switching teams).
  void reset() {
    _twitterAPI = null;
    _currentTeamId = null;
  }
}
