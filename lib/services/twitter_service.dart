import 'package:dart_twitter_api/twitter_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
      return await TwitterCredentialsService.hasCredentials(teamId);
    }

    // Check local credentials
    const storage = FlutterSecureStorage();
    final consumerKey = await storage.read(key: 'twitter_consumer_key') ?? '';
    final consumerSecret =
        await storage.read(key: 'twitter_consumer_secret') ?? '';
    final accessToken = await storage.read(key: 'twitter_access_token') ?? '';
    final accessTokenSecret =
        await storage.read(key: 'twitter_access_token_secret') ?? '';

    return consumerKey.isNotEmpty &&
        consumerSecret.isNotEmpty &&
        accessToken.isNotEmpty &&
        accessTokenSecret.isNotEmpty;
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
