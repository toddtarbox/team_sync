import 'package:team_sync/features/players/models/player.dart';
import 'package:team_sync/features/seasons/models/season.dart';
import 'package:team_sync/features/teams/models/team.dart';
import 'package:team_sync/features/teams/models/team_accomplishment.dart';
import 'package:team_sync/core/services/database_service.dart';

class TeamManagementService {
  static final TeamManagementService instance =
      TeamManagementService._internal();

  TeamManagementService._internal();

  /// Updates a team's name and shortName. Validates that the name is unique.
  Future<void> updateTeamName(
      Team team, String newFullName, String newShortName) async {
    final allTeams = await Team.all();

    // Check for exact matches on full name or short name, excluding the current team
    final isDuplicateFullName = allTeams.any((t) =>
        t.id != team.id &&
        t.fullName.toLowerCase() == newFullName.toLowerCase());
    final isDuplicateShortName = allTeams.any((t) =>
        t.id != team.id &&
        t.shortName.toLowerCase() == newShortName.toLowerCase());

    if (isDuplicateFullName) {
      throw Exception(
          'A team with the full name "$newFullName" already exists.');
    }
    if (isDuplicateShortName) {
      throw Exception(
          'A team with the short name "$newShortName" already exists.');
    }

    final updateData = {
      'fullName': newFullName,
      'shortName': newShortName,
    };

    await DatabaseService.instance
        .update('Teams', updateData, key: team.id.toString());
    Team.invalidate(team.id);
  }

  /// Deletes a team. Throws an exception if games are attached.
  Future<void> deleteTeam(Team team) async {
    // Check for games
    final homeGames = await DatabaseService.instance
        .query('Games', orderByChild: 'homeTeamId', equalTo: team.id);
    final awayGames = await DatabaseService.instance
        .query('Games', orderByChild: 'awayTeamId', equalTo: team.id);

    if (homeGames.isNotEmpty || awayGames.isNotEmpty) {
      throw Exception(
          'Cannot delete ${team.fullName} because it has existing games. Please merge or delete the games first.');
    }

    // Delete associated resources without games (if any exist)
    final seasons = await Season.fromTeamId(team.id);
    for (var season in seasons) {
      await DatabaseService.instance
          .delete('Seasons', key: season.id.toString());
    }

    final players = await Player.allFromTeamId(team.id);
    for (var player in players.values) {
      await DatabaseService.instance
          .delete('Players', key: player.id.toString());
    }

    final events = await DatabaseService.instance
        .query('Events', orderByChild: 'teamId', equalTo: team.id);
    for (var event in events) {
      await DatabaseService.instance
          .delete('Events', key: event['id'].toString());
    }

    final accs = await TeamAccomplishment.listFromTeamId(team.id);
    for (var acc in accs) {
      await DatabaseService.instance
          .delete('TeamAccomplishments', key: acc.id.toString());
    }

    await DatabaseService.instance
        .delete('BestGameStats', key: team.id.toString());
    await DatabaseService.instance.delete('Teams', key: team.id.toString());

    Team.invalidate(team.id);
  }

  /// Merges a source team into a target team, transferring all related data.
  Future<void> mergeTeam(Team source, Team target) async {
    if (source.id == target.id) {
      throw Exception('Cannot merge a team into itself.');
    }

    // 1. Update Games
    final homeGames = await DatabaseService.instance
        .query('Games', orderByChild: 'homeTeamId', equalTo: source.id);
    for (var gameMap in homeGames) {
      final updatedGame = Map<String, dynamic>.from(gameMap);
      updatedGame['homeTeamId'] = target.id;
      await DatabaseService.instance
          .update('Games', updatedGame, key: gameMap['id'].toString());
    }

    final awayGames = await DatabaseService.instance
        .query('Games', orderByChild: 'awayTeamId', equalTo: source.id);
    for (var gameMap in awayGames) {
      final updatedGame = Map<String, dynamic>.from(gameMap);
      updatedGame['awayTeamId'] = target.id;
      await DatabaseService.instance
          .update('Games', updatedGame, key: gameMap['id'].toString());
    }

    // 2. Update Events
    final events = await DatabaseService.instance
        .query('Events', orderByChild: 'teamId', equalTo: source.id);
    for (var event in events) {
      final updatedEvent = Map<String, dynamic>.from(event);
      updatedEvent['teamId'] = target.id;
      await DatabaseService.instance
          .update('Events', updatedEvent, key: event['id'].toString());
    }

    // 3. Update Seasons
    final seasons = await Season.fromTeamId(source.id);
    for (var season in seasons) {
      await DatabaseService.instance
          .update('Seasons', {'teamId': target.id}, key: season.id.toString());
    }

    // 4. Update Players
    // Retrieve by query to get maps directly so we can grab id without instantiating fully if we don't need to,
    // but using Player.allFromTeamId works too to get the existing player objects
    final playerMaps = await DatabaseService.instance
        .query('Players', orderByChild: 'teamId', equalTo: source.id);
    for (var playerMap in playerMaps) {
      final updatedSeasonId = playerMap['seasonId']; // Unchanged
      final newTeamIdSeasonId = '${target.id}_$updatedSeasonId';

      final updatedPlayerMap = Map<String, dynamic>.from(playerMap);
      updatedPlayerMap['teamId'] = target.id;
      updatedPlayerMap['teamId_seasonId'] = newTeamIdSeasonId;

      await DatabaseService.instance
          .update('Players', updatedPlayerMap, key: playerMap['id'].toString());
    }

    // 5. Update Team Accomplishments
    final accs = await DatabaseService.instance.query('TeamAccomplishments',
        orderByChild: 'teamId', equalTo: source.id);
    for (var acc in accs) {
      final updatedAcc = Map<String, dynamic>.from(acc);
      updatedAcc['teamId'] = target.id;
      await DatabaseService.instance
          .update('TeamAccomplishments', updatedAcc, key: acc['id'].toString());
    }

    // Clear best game stats cache for the target team since its games have changed
    await DatabaseService.instance
        .delete('BestGameStats', key: target.id.toString());
    await DatabaseService.instance
        .delete('BestGameStats', key: source.id.toString());

    // 6. Delete source team
    await DatabaseService.instance.delete('Teams', key: source.id.toString());

    Team.invalidate(source.id);
    Team.invalidate(target.id);
  }
}
