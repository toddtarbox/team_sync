import 'package:flutter/foundation.dart';
import 'package:team_sync/features/data_import/models/import_models.dart';
import 'package:team_sync/features/players/models/player.dart';
import 'package:team_sync/features/seasons/models/season.dart';
import 'package:team_sync/features/teams/models/team.dart';
import 'package:team_sync/core/services/database_service.dart';

class EntityMatcherService {
  /// Match team by name
  Future<EntityMatch> matchTeam(Map<String, dynamic> data) async {
    final teamName = data['fullName']?.toString() ?? data['name']?.toString();
    if (teamName == null || teamName.isEmpty) {
      return const EntityMatch(
        entityType: 'Team',
        confidence: 0.0,
        matchType: MatchType.none,
      );
    }

    try {
      final teams = await Team.all();

      EntityMatch? bestMatch;
      double bestScore = 0.0;

      for (final team in teams) {
        final score = _calculateStringSimilarity(teamName, team.fullName);
        if (score > bestScore) {
          bestScore = score;
          bestMatch = EntityMatch(
            entityType: 'Team',
            existingId: team.id,
            existingName: team.fullName,
            confidence: score,
            matchType: score >= 0.95 ? MatchType.exact : MatchType.fuzzy,
            existingData: {
              'id': team.id,
              'fullName': team.fullName,
              'shortName': team.shortName,
            },
          );
        }
      }

      return bestMatch ??
          const EntityMatch(
            entityType: 'Team',
            confidence: 0.0,
            matchType: MatchType.createNew,
          );
    } catch (e) {
      debugPrint('Error matching team: $e');
      return const EntityMatch(
        entityType: 'Team',
        confidence: 0.0,
        matchType: MatchType.none,
      );
    }
  }

  /// Match player by name and jersey number
  Future<EntityMatch> matchPlayer(
    Map<String, dynamic> data,
    int teamId,
    int seasonId,
  ) async {
    final firstName = data['firstName']?.toString();
    final lastName = data['lastName']?.toString();

    if (firstName == null || lastName == null) {
      return const EntityMatch(
        entityType: 'Player',
        confidence: 0.0,
        matchType: MatchType.none,
      );
    }

    try {
      // First, check if player already exists in this specific season
      // (exact match: same name AND same season)
      final playersInSeason =
          await Player.listFromTeamIdSeasonId(teamId, seasonId);

      for (final player in playersInSeason) {
        final firstNameScore =
            _calculateStringSimilarity(firstName, player.firstName);
        final lastNameScore =
            _calculateStringSimilarity(lastName, player.lastName);
        final nameScore = (firstNameScore + lastNameScore) / 2;

        // If we find a player with the same name in this season, it's an exact match
        if (nameScore >= 0.95) {
          return EntityMatch(
            entityType: 'Player',
            existingId: player.id,
            existingName: player.displayName,
            confidence: 1.0,
            matchType: MatchType.exact,
            existingData: {
              'id': player.id,
              'firstName': player.firstName,
              'lastName': player.lastName,
              'number': player.number,
              'seasonId': player.seasonId,
            },
          );
        }
      }

      // If not found in this season, check ALL seasons for this team to find
      // if this player exists in other seasons (to reuse the same player ID)
      final allPlayers = await Player.allFromTeamId(teamId);

      EntityMatch? bestMatch;
      double bestScore = 0.0;

      for (final player in allPlayers.values) {
        // Match by name only - number can be different across seasons
        final firstNameScore =
            _calculateStringSimilarity(firstName, player.firstName);
        final lastNameScore =
            _calculateStringSimilarity(lastName, player.lastName);
        final nameScore = (firstNameScore + lastNameScore) / 2;

        if (nameScore > bestScore && nameScore >= 0.95) {
          bestScore = nameScore;
          bestMatch = EntityMatch(
            entityType: 'Player',
            existingId: player.id,
            existingName: player.displayName,
            confidence: nameScore,
            matchType:
                MatchType.fuzzy, // Fuzzy because it's from a different season
            existingData: {
              'id': player.id,
              'firstName': player.firstName,
              'lastName': player.lastName,
              'number': player.number,
              'seasonId': player.seasonId,
              'foundInDifferentSeason': true,
            },
          );
        }
      }

      // If found in another season, return fuzzy match to create new record
      // with same player ID but for this season
      if (bestMatch != null) {
        debugPrint('Player $firstName $lastName found in another season '
            '(ID: $bestMatch.existingId). Will create new season record with same player ID.');
        return bestMatch;
      }

      // Not found anywhere, create new player
      return const EntityMatch(
        entityType: 'Player',
        confidence: 0.0,
        matchType: MatchType.createNew,
      );
    } catch (e) {
      debugPrint('Error matching player: $e');
      return const EntityMatch(
        entityType: 'Player',
        confidence: 0.0,
        matchType: MatchType.none,
      );
    }
  }

  /// Match season by name and team
  Future<EntityMatch> matchSeason(Map<String, dynamic> data, int teamId) async {
    final seasonName = data['name']?.toString();
    if (seasonName == null || seasonName.isEmpty) {
      return const EntityMatch(
        entityType: 'Season',
        confidence: 0.0,
        matchType: MatchType.none,
      );
    }

    try {
      final seasons = await Season.fromTeamId(teamId);

      EntityMatch? bestMatch;
      double bestScore = 0.0;

      for (final season in seasons) {
        final score = _calculateStringSimilarity(seasonName, season.name);
        if (score > bestScore) {
          bestScore = score;
          bestMatch = EntityMatch(
            entityType: 'Season',
            existingId: season.id,
            existingName: season.name,
            confidence: score,
            matchType: score >= 0.95 ? MatchType.exact : MatchType.fuzzy,
            existingData: {
              'id': season.id,
              'name': season.name,
              'teamId': season.teamId,
            },
          );
        }
      }

      return bestMatch ??
          const EntityMatch(
            entityType: 'Season',
            confidence: 0.0,
            matchType: MatchType.createNew,
          );
    } catch (e) {
      debugPrint('Error matching season: $e');
      return const EntityMatch(
        entityType: 'Season',
        confidence: 0.0,
        matchType: MatchType.none,
      );
    }
  }

  /// Calculate string similarity using Levenshtein distance
  double _calculateStringSimilarity(String s1, String s2) {
    if (s1 == s2) return 1.0;
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    final str1 = s1.toLowerCase().trim();
    final str2 = s2.toLowerCase().trim();

    if (str1 == str2) return 1.0;

    final distance = _levenshteinDistance(str1, str2);
    final maxLength = s1.length > s2.length ? s1.length : s2.length;

    return 1.0 - (distance / maxLength);
  }

  /// Calculate Levenshtein distance between two strings
  int _levenshteinDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;

    final matrix = List.generate(
      s1.length + 1,
      (i) => List.filled(s2.length + 1, 0),
    );

    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        final cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,
          matrix[i][j - 1] + 1,
          matrix[i - 1][j - 1] + cost,
        ].reduce((a, b) => a < b ? a : b);
      }
    }

    return matrix[s1.length][s2.length];
  }

  /// Match game by season, date, and teams
  Future<EntityMatch> matchGame(Map<String, dynamic> data) async {
    final seasonId = data['seasonId'];
    final date = data['date'];
    final homeTeamId = data['homeTeamId'];
    final awayTeamId = data['awayTeamId'];

    if (seasonId == null ||
        date == null ||
        homeTeamId == null ||
        awayTeamId == null) {
      return const EntityMatch(
        entityType: 'Game',
        confidence: 0.0,
        matchType: MatchType.none,
      );
    }

    try {
      // Query games for this season
      final games = await DatabaseService.instance.query(
        'Games',
        orderByChild: 'seasonId',
        equalTo: seasonId,
      );

      for (final game in games) {
        // Strict match on teams and date
        if (game['homeTeamId'] == homeTeamId &&
            game['awayTeamId'] == awayTeamId &&
            game['date'] == date) {
          return EntityMatch(
            entityType: 'Game',
            existingId: game['id'],
            confidence: 1.0,
            matchType: MatchType.exact,
            existingData: Map<String, dynamic>.from(game as Map),
          );
        }
      }

      return const EntityMatch(
        entityType: 'Game',
        confidence: 0.0,
        matchType: MatchType.createNew,
      );
    } catch (e) {
      debugPrint('Error matching game: $e');
      return const EntityMatch(
        entityType: 'Game',
        confidence: 0.0,
        matchType: MatchType.none,
      );
    }
  }
}
