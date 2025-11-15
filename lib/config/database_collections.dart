/// Database collection names for ClubSync
///
/// ClubSync and TeamSync share the same Firebase project (team-sync-soccer).
/// To avoid conflicts, ClubSync uses prefixed collection names at the root level,
/// while TeamSync uses nested collections under subscriptionIds/{uid}/databases/{db}/.
class ClubSyncCollections {
  // Club organization data (root level - unique to ClubSync)
  static const String clubs = 'Clubs';

  // ClubSync collections with "Club" prefix to avoid conflicts
  static const String teams = 'ClubTeams';
  static const String seasons = 'ClubSeasons';
  static const String games = 'ClubGames';
  static const String players = 'ClubPlayers';
  static const String events = 'ClubEvents';
}

/// Database collection names for TeamSync (nested structure)
///
/// TeamSync uses: subscriptionIds/{uid}/databases/{db}/Teams/, etc.
/// These are nested and don't conflict with ClubSync's root-level collections.
class TeamSyncCollections {
  static const String teams = 'Teams';
  static const String seasons = 'Seasons';
  static const String games = 'Games';
  static const String players = 'Players';
  static const String events = 'Events';
}
