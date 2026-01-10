import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/models/best_game_stats.dart';
import 'package:team_sync/models/calculation_progress.dart';
import 'package:team_sync/models/career_stats.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/season_stat.dart';
import 'package:team_sync/models/season_stats.dart';
import 'package:team_sync/services/database_service.dart';

class Team extends Equatable {
  final int id;
  final String fullName;
  final String shortName;
  final Color color1;
  final Color color2;
  final String? logoUrl;
  final String? createdBy; // User ID of team creator (team admin)
  final List<String>? adminIds; // List of team admin user IDs
  final String? liveUrl;
  final String? summary; // Team summary/description
  final String? organizationLogoUrl; // Organization/school logo
  final bool?
      isLogoSquare; // Team logo shape: true = square, false/null = circle
  final bool?
      isOrganizationLogoSquare; // Organization logo shape: true = square, false/null = circle

  const Team({
    required this.id,
    required this.fullName,
    required this.shortName,
    this.color1 = Colors.green,
    this.color2 = Colors.green,
    this.logoUrl,
    this.createdBy,
    this.adminIds,
    this.liveUrl,
    this.summary,
    this.organizationLogoUrl,
    this.isLogoSquare,
    this.isOrganizationLogoSquare,
  });

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'],
      fullName: map['fullName'],
      shortName: map['shortName'],
      color1: map['color1'] != null && map['color1'] != 0
          ? Color(map['color1'])
          : Colors.green,
      color2: map['color2'] != null && map['color2'] != 0
          ? Color(map['color2'])
          : Colors.green,
      logoUrl: map['logoUrl'],
      createdBy: map['createdBy'],
      adminIds:
          map['adminIds'] != null ? List<String>.from(map['adminIds']) : null,
      liveUrl: map['liveUrl'],
      summary: map['summary'],
      organizationLogoUrl: map['organizationLogoUrl'],
      isLogoSquare: map['isLogoSquare'],
      isOrganizationLogoSquare: map['isOrganizationLogoSquare'],
    );
  }

  /// Check if a user is an admin of this team
  /// Includes: team creator, team admins, and database owner (subscription ID)
  bool isTeamAdmin(String? userId) {
    if (userId == null) return false;
    if (createdBy == userId) return true;
    if (adminIds != null && adminIds!.contains(userId)) return true;

    // Check if user is the database owner (subscription ID)
    final subscriptionId = DatabaseService.instance.subscriptionId;
    if (subscriptionId.isNotEmpty && subscriptionId == userId) return true;

    return false;
  }

  static final Map<int, Team> _teamCache = {};

  static void clearCache() {
    _teamCache.clear();
  }

  static void invalidate(int id) {
    _teamCache.remove(id);
  }

  static Future<Team> fromId(int id) async {
    if (_teamCache.containsKey(id)) {
      return _teamCache[id]!;
    }
    final results = await DatabaseService.instance
        .query('Teams', orderByChild: 'id', equalTo: id);
    final team = Team.fromMap(results.first);
    _teamCache[id] = team;
    return team;
  }

  static Future<List<Team>> all() async {
    final results = await DatabaseService.instance.query('Teams');
    return results.map((t) => Team.fromMap(t)).toList(growable: false);
  }

  static Future<List<Team>> listFromSeasonId(int seasonId) async {
    // Get all games for this season
    final games = await DatabaseService.instance
        .query('Games', orderByChild: 'seasonId', equalTo: seasonId);

    // Extract unique team IDs from homeTeamId and awayTeamId
    final teamIds = <int>{};
    for (final game in games) {
      if (game['homeTeamId'] != null) {
        teamIds.add(game['homeTeamId'] as int);
      }
      if (game['awayTeamId'] != null) {
        teamIds.add(game['awayTeamId'] as int);
      }
    }

    // Fetch all teams by their IDs
    final teams = await Future.wait(teamIds.map((id) => Team.fromId(id)));

    return teams;
  }

  Future<dynamic> fetchAllDataForCareer() async {
    return await DatabaseService.instance
        .query('Events', orderByChild: 'teamId', equalTo: id);
  }

  Future<dynamic> fetchAllDataForSeason() async {
    final seasonsFuture = Season.fromTeamId(id);
    final playersFuture = Player.allFromTeamId(id);
    final eventsFuture = DatabaseService.instance
        .query('Events', orderByChild: 'teamId', equalTo: id);

    final results =
        await Future.wait([seasonsFuture, playersFuture, eventsFuture]);
    return {'seasons': results[0], 'players': results[1], 'events': results[2]};
  }

  Future<dynamic> fetchAllDataForGame() async {
    final gamesFuture = Game.listFromTeamId(id);
    final seasonsFuture = Season.fromTeamId(id);
    final playersFuture = Player.allFromTeamId(id);
    final eventsFuture = GameEvent.listFromTeamId(id);

    final results = await Future.wait(
        [gamesFuture, seasonsFuture, playersFuture, eventsFuture]);
    return {
      'games': results[0],
      'seasons': results[1],
      'players': results[2],
      'events': results[3]
    };
  }

  Future<Map<LeaderCategory, MapEntry<Player, int>>> calculateCareerStats(
      dynamic data,
      {StreamController<CalculationProgress>? progressController}) async {
    // Emit initial progress
    progressController?.add(CalculationProgress(
        total: LeaderCategory.values.length,
        current: 0,
        message: 'Starting...'));
    await Future.delayed(Duration.zero);

    final events = data as List<Map<String, dynamic>>;
    final stats = CareerStats.fromMap(id, events);
    final careerStats = <LeaderCategory, MapEntry<Player, int>>{};
    int i = 0;
    for (final category in LeaderCategory.values) {
      progressController?.add(CalculationProgress(
          total: LeaderCategory.values.length,
          current: i,
          message: 'Calculating ${category.name}'));
      // Allow the UI to update with progress
      await Future.delayed(Duration.zero);

      final statPlayers = await stats.getStatPlayers(category);
      if (statPlayers.isNotEmpty) {
        final sortedStats = List.from(statPlayers.entries);
        sortedStats.sort((a, b) => b.value.compareTo(a.value));
        careerStats[category] = sortedStats.first;
      }
      i++;
    }
    return careerStats;
  }

  Future<Map<LeaderCategory, SeasonStat>> calculateBestSeasonStats(dynamic data,
      {StreamController<CalculationProgress>? progressController}) async {
    // Emit initial progress
    progressController?.add(CalculationProgress(
        total: LeaderCategory.values.length,
        current: 0,
        message: 'Starting...'));
    await Future.delayed(Duration.zero);

    final seasons = data['seasons'] as List<Season>;
    final players = data['players'] as Map<int, Player>;
    final events = data['events'] as List<Map<String, dynamic>>;
    final bestSeasonStats = <LeaderCategory, SeasonStat>{};

    final eventsBySeason = <int, List<Map<String, dynamic>>>{};
    for (final event in events) {
      final seasonId = event['seasonId'] as int;
      if (!eventsBySeason.containsKey(seasonId)) {
        eventsBySeason[seasonId] = [];
      }
      eventsBySeason[seasonId]!.add(event);
    }
    int i = 0;
    for (final category in LeaderCategory.values) {
      if (category == LeaderCategory.ownGoalsEarned ||
          category == LeaderCategory.corners) {
        i++;
        continue;
      }
      progressController?.add(CalculationProgress(
          total: LeaderCategory.values.length,
          current: i,
          message: 'Calculating ${category.name}'));
      // Allow the UI to update with progress
      await Future.delayed(Duration.zero);

      int bestValue = 0;
      Player? bestPlayer;
      Season? bestSeason;

      for (final season in seasons) {
        final seasonEvents = eventsBySeason[season.id] ?? [];
        final seasonStats = SeasonStats.fromMap(id, season.id, seasonEvents);
        final statPlayers = await seasonStats.getStatPlayers(category);

        for (final entry in statPlayers.entries) {
          if (entry.value > bestValue) {
            final player = players[entry.key.id];
            if (player != null) {
              bestValue = entry.value;
              bestPlayer = player;
              bestSeason = season;
            }
          }
        }
      }

      if (bestPlayer != null && bestSeason != null) {
        bestSeasonStats[category] = SeasonStat(
            player: bestPlayer, season: bestSeason, value: bestValue);
      }
      i++;
    }
    return bestSeasonStats;
  }

  Future<BestGameStats> calculateBestGameStats(dynamic data,
      {StreamController<CalculationProgress>? progressController}) async {
    // Emit initial progress
    progressController?.add(CalculationProgress(
        total: LeaderCategory.values.length,
        current: 0,
        message: 'Starting...'));
    await Future.delayed(Duration.zero);

    final games = data['games'] as List<Game>;
    final seasons = data['seasons'] as List<Season>;
    final players = data['players'] as Map<int, Player>;
    final events = data['events'] as List<GameEvent>;
    final bestGameStats = BestGameStats();

    // Build event lookup map
    final eventsByGame = <int, List<GameEvent>>{};
    for (final event in events) {
      final gameId = event.game.id;
      if (!eventsByGame.containsKey(gameId)) {
        eventsByGame[gameId] = [];
      }
      eventsByGame[gameId]!.add(event);
    }

    // Process games in batches to avoid memory issues
    const batchSize = 50;
    final totalGames = games.length;

    int i = 0;
    for (final category in LeaderCategory.values) {
      if (category == LeaderCategory.ownGoalsEarned ||
          category == LeaderCategory.corners) {
        i++;
        continue;
      }
      progressController?.add(CalculationProgress(
          total: LeaderCategory.values.length,
          current: i,
          message: 'Calculating ${category.name}'));
      // Allow the UI to update with progress
      await Future.delayed(Duration.zero);

      int bestValue = 0;
      Player? bestPlayer;
      Game? bestGame;
      Season? bestSeason;

      // Process games in batches
      for (int batchStart = 0;
          batchStart < totalGames;
          batchStart += batchSize) {
        final batchEnd = (batchStart + batchSize < totalGames)
            ? batchStart + batchSize
            : totalGames;
        final gameBatch = games.sublist(batchStart, batchEnd);

        for (final game in gameBatch) {
          final gameEvents = eventsByGame[game.id] ?? [];
          if (gameEvents.isEmpty) continue;

          final gameStats = GameStats.fromEvents(id, gameEvents);
          final statPlayers = await gameStats.getStatPlayers(category);

          for (final entry in statPlayers.entries) {
            if (entry.value > bestValue) {
              final player = players[entry.key.id];
              if (player != null) {
                bestValue = entry.value;
                bestPlayer = player;
                bestGame = game;
                bestSeason = seasons.firstWhere((s) => s.id == game.seasonId);
              }
            }
          }
        }

        // Allow garbage collection between batches
        await Future.delayed(const Duration(milliseconds: 10));
      }

      if (bestPlayer != null && bestGame != null && bestSeason != null) {
        bestGameStats.setBestStat(
            category, bestPlayer, bestGame, bestSeason, bestValue);
      }
      i++;
    }
    return bestGameStats;
  }

  /// Update best game stats for a specific completed game
  /// This is called after a game is finalized to incrementally update cached stats
  Future<void> updateBestGameStatsForGame(Game game) async {
    try {
      // Load current cached best game stats
      final currentBestStats = await BestGameStats.loadFromDatabase(id);

      // Load game events and calculate stats for this game
      final gameEvents = await GameEvent.listFromGameId(game.id);
      if (gameEvents.isEmpty) return;

      final gameStats = GameStats.fromEvents(id, gameEvents);

      // Load seasons for this team and find the one matching this game
      final seasons = await Season.fromTeamId(id);
      final season = seasons.where((s) => s.id == game.seasonId).firstOrNull;
      if (season == null) return;

      // Check each category to see if this game has a new best
      bool hasUpdates = false;
      for (final category in LeaderCategory.values) {
        if (category == LeaderCategory.ownGoalsEarned ||
            category == LeaderCategory.corners) {
          continue;
        }

        final statPlayers = await gameStats.getStatPlayers(category);
        if (statPlayers.isEmpty) continue;

        // Find the best player in this game for this category
        int bestGameValue = 0;
        Player? bestGamePlayer;
        for (final entry in statPlayers.entries) {
          if (entry.value > bestGameValue) {
            bestGameValue = entry.value;
            bestGamePlayer = entry.key;
          }
        }

        if (bestGamePlayer == null || bestGameValue == 0) continue;

        // Check if this beats the current best
        final currentBest = currentBestStats.getBestStat(category);
        if (currentBest == null || bestGameValue > currentBest.value) {
          currentBestStats.setBestStat(
            category,
            bestGamePlayer,
            game,
            season,
            bestGameValue,
          );
          hasUpdates = true;
        }
      }

      // Save updates to database if there were any changes
      if (hasUpdates) {
        await currentBestStats.saveToDatabase(id);
      }
    } catch (e) {
      debugPrint('Error updating best game stats: $e');
    }
  }

  /// Get best game stats, using cached values from database if available
  /// Falls back to full recalculation if cache is empty
  Future<BestGameStats> getBestGameStats({
    StreamController<CalculationProgress>? progressController,
  }) async {
    // Try to load from cache first
    final cachedStats = await BestGameStats.loadFromDatabase(id);

    if (cachedStats.hasCachedStats) {
      // Return cached stats immediately
      progressController?.add(CalculationProgress(
          total: 1, current: 1, message: 'Loaded from cache'));
      return cachedStats;
    }

    // No cache exists, calculate from scratch
    progressController?.add(CalculationProgress(
        total: 1, current: 0, message: 'Building cache...'));

    final data = await fetchAllDataForGame();
    final calculatedStats = await calculateBestGameStats(data,
        progressController: progressController);

    // Save to database for future use
    await calculatedStats.saveToDatabase(id);

    return calculatedStats;
  }

  /// Rebuild entire best game stats cache from scratch
  /// Use this when data integrity issues are suspected or after bulk imports
  Future<void> rebuildBestGameStatsCache({
    StreamController<CalculationProgress>? progressController,
  }) async {
    progressController?.add(CalculationProgress(
        total: 1, current: 0, message: 'Rebuilding cache...'));

    final data = await fetchAllDataForGame();
    final calculatedStats = await calculateBestGameStats(data,
        progressController: progressController);

    await calculatedStats.saveToDatabase(id);

    progressController?.add(
        CalculationProgress(total: 1, current: 1, message: 'Cache rebuilt'));
  }

  Future<List<MapEntry<Player, int>>> getCareerStatsForCategory(
      LeaderCategory category) async {
    final results = await DatabaseService.instance
        .query('Events', orderByChild: 'teamId', equalTo: id);
    final stats = CareerStats.fromMap(id, results);
    final statPlayers = await stats.getStatPlayers(category);
    final sortedStats = List.from(statPlayers.entries);
    sortedStats.sort((a, b) => b.value.compareTo(a.value));
    return sortedStats.cast<MapEntry<Player, int>>();
  }

  Future<List<SeasonStat>> getAllSeasonStatsForCategory(
      LeaderCategory category) async {
    final data = await fetchAllDataForSeason();
    final allSeasonStats = await getAllSeasonStats(data);
    return allSeasonStats[category] ?? [];
  }

  Future<Map<LeaderCategory, List<SeasonStat>>> getAllSeasonStats(
      dynamic data) async {
    final allSeasonStats = <LeaderCategory, List<SeasonStat>>{};
    final seasons = data['seasons'] as List<Season>;
    final players = data['players'] as Map<int, Player>;
    final events = data['events'] as List<Map<String, dynamic>>;

    final eventsBySeason = <int, List<Map<String, dynamic>>>{};
    for (final event in events) {
      final seasonId = event['seasonId'] as int;
      if (!eventsBySeason.containsKey(seasonId)) {
        eventsBySeason[seasonId] = [];
      }
      eventsBySeason[seasonId]!.add(event);
    }

    for (final category in LeaderCategory.values) {
      allSeasonStats[category] = [];
      for (final season in seasons) {
        final seasonEvents = eventsBySeason[season.id] ?? [];
        final seasonStats = SeasonStats.fromMap(id, season.id, seasonEvents);
        final statPlayers = await seasonStats.getStatPlayers(category);

        for (final entry in statPlayers.entries) {
          final player = players[entry.key.id];
          if (player != null) {
            allSeasonStats[category]!.add(
                SeasonStat(player: player, season: season, value: entry.value));
          }
        }
      }
    }

    return allSeasonStats;
  }

  Future<List<BestGameStat>> getAllGameStatsForCategory(
      LeaderCategory category) async {
    final data = await fetchAllDataForGame();
    final games = data['games'] as List<Game>;
    final seasons = data['seasons'] as List<Season>;
    final players = data['players'] as Map<int, Player>;
    final events = data['events'] as List<GameEvent>;
    final gameStatsList = <BestGameStat>[];

    final eventsByGame = <int, List<GameEvent>>{};
    for (final event in events) {
      final gameId = event.game.id;
      if (!eventsByGame.containsKey(gameId)) {
        eventsByGame[gameId] = [];
      }
      eventsByGame[gameId]!.add(event);
    }

    for (final game in games) {
      final gameEvents = eventsByGame[game.id] ?? [];
      final gameStats = GameStats.fromEvents(id, gameEvents);
      final statPlayers = await gameStats.getStatPlayers(category);

      for (final entry in statPlayers.entries) {
        final player = players[entry.key.id];
        if (player != null) {
          gameStatsList.add(BestGameStat(
              player: player,
              game: game,
              season: seasons.firstWhere((s) => s.id == game.seasonId),
              value: entry.value));
        }
      }
    }
    gameStatsList.sort((a, b) => b.value.compareTo(a.value));
    return gameStatsList;
  }

  Future<List<Game>> getGameHistory(int teamId) async {
    try {
      return Game.listFromTeamId(teamId);
    } catch (ex) {
      return [];
    }
  }

  @override
  List<Object?> get props => [
        id,
        color1,
        color2,
        createdBy,
        adminIds,
        liveUrl,
        summary,
        organizationLogoUrl,
        isLogoSquare,
        isOrganizationLogoSquare,
      ];
}
