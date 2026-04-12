/// App flavor/mode configuration
enum AppMode {
  soccer, // Single-team management
  basketball,
}

/// Global app configuration
class AppConfig {
  final AppMode mode;
  final String appName;
  final String appId;
  final bool enableTeamFeatures;

  const AppConfig({
    required this.mode,
    required this.appName,
    required this.appId,
    required this.enableTeamFeatures,
  });

  /// Soccer configuration (single-team app)
  static const soccer = AppConfig(
    mode: AppMode.soccer,
    appName: 'TeamSync',
    appId: 'com.tsquared.team_sync.soccer',
    enableTeamFeatures: true,
  );

  static const basketball = AppConfig(
    mode: AppMode.basketball,
    appName: 'TeamSync',
    appId: 'com.tsquared.team_sync.basketball',
    enableTeamFeatures: true,
  );

  /// Current app configuration (set at build time)
  static late AppConfig current;

  /// Initialize app configuration
  static void initialize(AppConfig config) {
    current = config;
  }

  /// Check if this is Soccer app
  bool get isSoccer => mode == AppMode.soccer;

  /// Check if this is Basketball app
  bool get isBasketball => mode == AppMode.basketball;
}
