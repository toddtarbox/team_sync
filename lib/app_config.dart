/// App flavor/mode configuration
enum AppMode {
  teamSync, // Single-team management
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

  /// TeamSync configuration (single-team app)
  static const teamSync = AppConfig(
    mode: AppMode.teamSync,
    appName: 'TeamSync',
    appId: 'com.tsquared.team_sync.soccer',
    enableTeamFeatures: true,
  );

  /// Current app configuration (set at build time)
  static late AppConfig current;

  /// Initialize app configuration
  static void initialize(AppConfig config) {
    current = config;
  }

  /// Check if this is TeamSync app
  bool get isTeamSync => mode == AppMode.teamSync;
}
