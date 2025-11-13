// Export the platform-specific implementation (web vs others).
// Use package imports to ensure analyzer resolves paths correctly.
export 'package:team_sync/widgets/twitter_feed_stub.dart'
    if (dart.library.html) 'package:team_sync/widgets/twitter_feed_web.dart';
