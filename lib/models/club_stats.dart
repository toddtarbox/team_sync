import 'dart:collection';

import 'package:team_sync/models/player.dart';
import 'package:team_sync/services/database_service.dart';

/// Aggregated statistics across all teams in a club
class ClubStats {
  final int clubId;

  final HashMap<int, int> _teamGoals = HashMap<int, int>();
  final HashMap<int, int> _teamGoalsAgainst = HashMap<int, int>();
  final HashMap<int, int> _teamWins = HashMap<int, int>();
  final HashMap<int, int> _teamLosses = HashMap<int, int>();
  final HashMap<int, int> _teamDraws = HashMap<int, int>();

  // Player stats across all teams
  final HashMap<int, int> _playerGoals = HashMap<int, int>();
  final HashMap<int, int> _playerAssists = HashMap<int, int>();
  final HashMap<int, int> _playerShots = HashMap<int, int>();
  final HashMap<int, int> _playerSaves = HashMap<int, int>();
  final HashMap<int, int> _playerYellowCards = HashMap<int, int>();
  final HashMap<int, int> _playerRedCards = HashMap<int, int>();

  ClubStats({required this.clubId});

  static Future<ClubStats> fromClubId(int clubId) async {
    final stats = ClubStats(clubId: clubId);

    // Get all teams in the club
    final teams = await DatabaseService.instance
        .query('Teams', orderByChild: 'clubId', equalTo: clubId);

    for (final teamMap in teams) {
      final teamId = teamMap['id'] as int;

      // Get all events for this team
      final events = await DatabaseService.instance
          .query('Events', orderByChild: 'teamId', equalTo: teamId);

      // Get all games for this team
      final games = await DatabaseService.instance
          .query('Games', orderByChild: 'homeTeamId', equalTo: teamId);
      final awayGames = await DatabaseService.instance
          .query('Games', orderByChild: 'awayTeamId', equalTo: teamId);

      // Calculate team record
      int wins = 0, losses = 0, draws = 0;
      int goalsFor = 0, goalsAgainst = 0;

      for (final game in [...games, ...awayGames]) {
        final homeScore = game['homeTeamScore'] as int;
        final awayScore = game['awayTeamScore'] as int;
        final isHome = game['homeTeamId'] == teamId;

        if (isHome) {
          goalsFor += homeScore;
          goalsAgainst += awayScore;
          if (homeScore > awayScore) {
            wins++;
          } else if (homeScore < awayScore) {
            losses++;
          } else {
            draws++;
          }
        } else {
          goalsFor += awayScore;
          goalsAgainst += homeScore;
          if (awayScore > homeScore) {
            wins++;
          } else if (awayScore < homeScore) {
            losses++;
          } else {
            draws++;
          }
        }
      }

      stats._teamGoals[teamId] = goalsFor;
      stats._teamGoalsAgainst[teamId] = goalsAgainst;
      stats._teamWins[teamId] = wins;
      stats._teamLosses[teamId] = losses;
      stats._teamDraws[teamId] = draws;

      // Process events for player stats
      for (final event in events) {
        final playerId = event['playerId'] as int?;
        if (playerId == null || playerId < 0) continue;

        final eventType = event['eventType'] as String;
        final eventData = event['eventData'] as int?;

        switch (eventType) {
          case 'Shot':
            stats._playerShots
                .update(playerId, (v) => v + 1, ifAbsent: () => 1);
            if (eventData == 0) {
              // Goal
              stats._playerGoals
                  .update(playerId, (v) => v + 1, ifAbsent: () => 1);
            }
            break;
          case 'PenaltyKick':
            if (eventData == 0) {
              // Goal
              stats._playerGoals
                  .update(playerId, (v) => v + 1, ifAbsent: () => 1);
            }
            break;
          case 'Assist':
            stats._playerAssists
                .update(playerId, (v) => v + 1, ifAbsent: () => 1);
            break;
          case 'Save':
            stats._playerSaves
                .update(playerId, (v) => v + 1, ifAbsent: () => 1);
            break;
          case 'Card':
            if (eventData == 0) {
              // Yellow
              stats._playerYellowCards
                  .update(playerId, (v) => v + 1, ifAbsent: () => 1);
            } else if (eventData == 2) {
              // Red
              stats._playerRedCards
                  .update(playerId, (v) => v + 1, ifAbsent: () => 1);
            }
            break;
        }
      }
    }

    return stats;
  }

  // Get top scorers across all teams
  Future<List<MapEntry<Player, int>>> getTopScorers({int limit = 10}) async {
    final entries = _playerGoals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final result = <MapEntry<Player, int>>[];
    for (final entry in entries.take(limit)) {
      final player = await Player.fromId(entry.key);
      if (player != null) {
        result.add(MapEntry(player, entry.value));
      }
    }
    return result;
  }

  // Get top assist providers across all teams
  Future<List<MapEntry<Player, int>>> getTopAssists({int limit = 10}) async {
    final entries = _playerAssists.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final result = <MapEntry<Player, int>>[];
    for (final entry in entries.take(limit)) {
      final player = await Player.fromId(entry.key);
      if (player != null) {
        result.add(MapEntry(player, entry.value));
      }
    }
    return result;
  }

  // Get team standings
  Map<int, Map<String, int>> getTeamStandings() {
    final standings = <int, Map<String, int>>{};

    for (final teamId in _teamWins.keys) {
      standings[teamId] = {
        'wins': _teamWins[teamId] ?? 0,
        'losses': _teamLosses[teamId] ?? 0,
        'draws': _teamDraws[teamId] ?? 0,
        'goalsFor': _teamGoals[teamId] ?? 0,
        'goalsAgainst': _teamGoalsAgainst[teamId] ?? 0,
        'points': (_teamWins[teamId] ?? 0) * 3 + (_teamDraws[teamId] ?? 0),
      };
    }

    return standings;
  }

  int get totalGames {
    final wins = _teamWins.values.fold<int>(0, (sum, val) => sum + val);
    final losses = _teamLosses.values.fold<int>(0, (sum, val) => sum + val);
    final draws = _teamDraws.values.fold<int>(0, (sum, val) => sum + val);
    return wins + losses + draws;
  }

  int get totalGoals =>
      _playerGoals.values.fold<int>(0, (sum, val) => sum + val);

  int get totalAssists =>
      _playerAssists.values.fold<int>(0, (sum, val) => sum + val);
}
