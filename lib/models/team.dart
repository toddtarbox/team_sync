import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/models/best_game_stats.dart';
import 'package:team_sync/models/calculation_progress.dart';
import 'package:team_sync/models/career_stats.dart';
import 'package:team_sync/models/game.dart';
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

  const Team(
      {required this.id,
      required this.fullName,
      required this.shortName,
      this.color1 = Colors.green,
      this.color2 = Colors.green});

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
            : Colors.green);
  }

  static Future<Team> fromId(int id) async {
    final results = await DatabaseService.instance
        .query('Teams', where: 'id=?', whereArgs: [id]);
    return Team.fromMap(results.first);
  }

  static Future<List<Team>> all() async {
    final results = await DatabaseService.instance.query('Teams');
    return results.map((t) => Team.fromMap(t)).toList(growable: false);
  }

  Future<dynamic> fetchAllDataForCareer() async {
    return await DatabaseService.instance
        .query('Events', where: 'teamId=?', whereArgs: [id]);
  }

  Future<dynamic> fetchAllDataForSeason() async {
    final seasonsFuture = Season.fromTeamId(id);
    final playersFuture = Player.allFromTeamId(id);
    final eventsFuture = DatabaseService.instance
        .query('Events', where: 'teamId=?', whereArgs: [id]);

    final results =
        await Future.wait([seasonsFuture, playersFuture, eventsFuture]);
    return {'seasons': results[0], 'players': results[1], 'events': results[2]};
  }

  Future<dynamic> fetchAllDataForGame() async {
    final gamesFuture = Game.listFromTeamId(id);
    final seasonsFuture = Season.fromTeamId(id);
    final playersFuture = Player.allFromTeamId(id);

    final results =
        await Future.wait([gamesFuture, seasonsFuture, playersFuture]);
    return {'games': results[0], 'seasons': results[1], 'players': results[2]};
  }

  Future<Map<LeaderCategory, MapEntry<Player, int>>> calculateCareerStats(
      dynamic data,
      {StreamController<CalculationProgress>? progressController}) async {
    final events = data as List<Map<String, dynamic>>;
    final stats = CareerStats.fromMap(id, events);
    final careerStats = <LeaderCategory, MapEntry<Player, int>>{};
    int i = 0;
    for (final category in LeaderCategory.values) {
      progressController?.add(CalculationProgress(
          total: LeaderCategory.values.length,
          current: i,
          message: 'Calculating ${category.name}'));
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
      if (category == LeaderCategory.ownGoalsEarned) {
        i++;
        continue;
      }
      progressController?.add(CalculationProgress(
          total: LeaderCategory.values.length,
          current: i,
          message: 'Calculating ${category.name}'));
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
    final games = data['games'] as List<Game>;
    final seasons = data['seasons'] as List<Season>;
    final players = data['players'] as Map<int, Player>;
    final bestGameStats = BestGameStats();
    int i = 0;
    for (final category in LeaderCategory.values) {
      progressController?.add(CalculationProgress(
          total: LeaderCategory.values.length,
          current: i,
          message: 'Calculating ${category.name}'));
      int bestValue = 0;
      Player? bestPlayer;
      Game? bestGame;
      Season? bestSeason;

      for (final game in games) {
        await game.loadGameEvents();
        final gameStats = game.getStats(id);
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

      if (bestPlayer != null && bestGame != null && bestSeason != null) {
        bestGameStats.setBestStat(
            category, bestPlayer, bestGame, bestSeason, bestValue);
      }
      i++;
    }
    return bestGameStats;
  }

  Future<List<MapEntry<Player, int>>> getCareerStatsForCategory(
      LeaderCategory category) async {
    final results = await DatabaseService.instance
        .query('Events', where: 'teamId=?', whereArgs: [id]);
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
    final gameStatsList = <BestGameStat>[];

    for (final game in games) {
      await game.loadGameEvents();
      final gameStats = game.getStats(id);
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
  List<Object?> get props => [id, color1, color2];
}
