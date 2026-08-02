/// Database collection names for TeamSync (nested structure)
///
/// TeamSync uses: subscriptionIds/{uid}/databases/{db}/Teams/, etc.
/// These are nested and don't conflict with other collections.
class TeamSyncCollections {
  static const String teams = 'Teams';
  static const String seasons = 'Seasons';
  static const String games = 'Games';
  static const String players = 'Players';
  static const String events = 'Events';
}
