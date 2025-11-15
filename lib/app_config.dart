/// App flavor/mode configuration
enum AppMode {
  teamSync, // Single-team management
  clubSync, // Multi-team club management
}

/// Global app configuration
class AppConfig {
  final AppMode mode;
  final String appName;
  final String appId;
  final bool enableClubFeatures;
  final bool enableTeamFeatures;

  const AppConfig({
    required this.mode,
    required this.appName,
    required this.appId,
    required this.enableClubFeatures,
    required this.enableTeamFeatures,
  });

  /// TeamSync configuration (single-team app)
  static const teamSync = AppConfig(
    mode: AppMode.teamSync,
    appName: 'TeamSync',
    appId: 'com.tsquared.team_sync',
    enableClubFeatures: false,
    enableTeamFeatures: true,
  );

  /// ClubSync configuration (multi-team club app)
  static const clubSync = AppConfig(
    mode: AppMode.clubSync,
    appName: 'ClubSync',
    appId: 'com.tsquared.club_sync',
    enableClubFeatures: true,
    enableTeamFeatures: true,
  );

  /// Current app configuration (set at build time)
  static late AppConfig current;

  /// Initialize app configuration
  static void initialize(AppConfig config) {
    current = config;
  }

  /// Check if club features should be shown
  bool get showClubFeatures => enableClubFeatures;

  /// Check if this is TeamSync app
  bool get isTeamSync => mode == AppMode.teamSync;

  /// Check if this is ClubSync app
  bool get isClubSync => mode == AppMode.clubSync;
}
