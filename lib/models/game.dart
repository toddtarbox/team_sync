import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/stat_leaders.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/services/sport_strategy.dart';

class GameStats implements StatLeaders {
  final int teamId;

  GameStats({required this.teamId});

  final HashMap<int, int> _playerGoals = HashMap<int, int>();
  final HashMap<int, int> _teamOwnGoals = HashMap<int, int>();
  final HashMap<int, int> _playerPenaltyKickGoals = HashMap<int, int>();
  final HashMap<int, int> _playerPenaltyKicksTaken = HashMap<int, int>();
  final HashMap<int, int> _playerAssists = HashMap<int, int>();
  final HashMap<int, int> _playerShots = HashMap<int, int>();
  final HashMap<int, int> _playerShotsOnGoal = HashMap<int, int>();
  final HashMap<int, int> _playerShotsOffPost = HashMap<int, int>();
  final HashMap<int, int> _playerSaves = HashMap<int, int>();
  final HashMap<int, int> _playerOffsides = HashMap<int, int>();
  final HashMap<int, int> _playerFouls = HashMap<int, int>();
  final HashMap<int, int> _playerYellows = HashMap<int, int>();
  final HashMap<int, int> _playerSecondYellows = HashMap<int, int>();
  final HashMap<int, int> _playerReds = HashMap<int, int>();

  // Basketball / Generic
  final HashMap<int, int> _playerPoints = HashMap<int, int>();
  final HashMap<int, int> _playerThreePointersMade = HashMap<int, int>();
  final HashMap<int, int> _playerThreePointersAttempted = HashMap<int, int>();
  final HashMap<int, int> _playerTwoPointersMade = HashMap<int, int>();
  final HashMap<int, int> _playerTwoPointersAttempted = HashMap<int, int>();
  final HashMap<int, int> _playerFreeThrowsMade = HashMap<int, int>();
  final HashMap<int, int> _playerFreeThrowsAttempted = HashMap<int, int>();
  final HashMap<int, int> _playerRebounds = HashMap<int, int>();
  final HashMap<int, int> _playerOffRebounds = HashMap<int, int>();
  final HashMap<int, int> _playerDefRebounds = HashMap<int, int>();
  final HashMap<int, int> _playerSteals = HashMap<int, int>();
  final HashMap<int, int> _playerBlocks = HashMap<int, int>();
  final HashMap<int, int> _playerTurnovers = HashMap<int, int>();

  factory GameStats.fromEvents(int teamId, List<GameEvent> events) {
    final stats = GameStats(teamId: teamId);

    for (final event in events) {
      if (event.team.id != teamId) continue;
      if (event.player == null) continue;
      final playerId = event.player!.id;

      switch (event.eventType) {
        case 'Shot':
          stats._playerShots
              .update(playerId, (value) => value + 1, ifAbsent: () => 1);

          if (event.eventData == ShotResult.goal.index) {
            if (playerId == -2) {
              stats._teamOwnGoals
                  .update(playerId, (value) => value + 1, ifAbsent: () => 1);
            } else {
              stats._playerGoals
                  .update(playerId, (value) => value + 1, ifAbsent: () => 1);
              stats._playerShotsOnGoal
                  .update(playerId, (value) => value + 1, ifAbsent: () => 1);
            }
          } else if (event.eventData == ShotResult.onTargetSave.index) {
            stats._playerShotsOnGoal
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          } else if (event.eventData == ShotResult.offTargetPost.index) {
            stats._playerShotsOffPost
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          }

          // Fallback: treat soccer-style shot goals as 1 point in basketball stats
          if (SportStrategy.current.sportId == 'basketball' &&
              event.eventData == ShotResult.goal.index) {
            stats._playerPoints
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
            stats._playerTwoPointersMade
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
            stats._playerTwoPointersAttempted
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          }
          break;

        case 'PenaltyKick':
          stats._playerPenaltyKicksTaken
              .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          if (event.eventData == ShotResult.goal.index) {
            stats._playerGoals
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
            stats._playerPenaltyKickGoals
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          }
          break;

        case 'Assist':
          stats._playerAssists
              .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          break;

        case 'Save':
          stats._playerSaves
              .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          break;

        case 'Offsides':
          stats._playerOffsides
              .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          break;

        case 'Foul':
          stats._playerFouls
              .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          break;

        case 'Card':
          if (event.eventData == 0) {
            stats._playerYellows
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          } else if (event.eventData == 1) {
            stats._playerSecondYellows
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          } else if (event.eventData == 2) {
            stats._playerReds
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          }
          break;

        // Basketball / Generic
        case 'Point':
          stats._playerPoints.update(
              playerId, (value) => value + event.eventData,
              ifAbsent: () => event.eventData);

          if (event.eventData == 3) {
            stats._playerThreePointersMade
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
            stats._playerThreePointersAttempted
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          } else if (event.eventData == 2) {
            stats._playerTwoPointersMade
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
            stats._playerTwoPointersAttempted
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          } else if (event.eventData == 1) {
            stats._playerFreeThrowsMade
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
            stats._playerFreeThrowsAttempted
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          }
          break;

        case 'Miss':
          if (event.eventData == 3) {
            stats._playerThreePointersAttempted
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          } else if (event.eventData == 2) {
            stats._playerTwoPointersAttempted
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          } else if (event.eventData == 1) {
            stats._playerFreeThrowsAttempted
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          }
          break;

        case 'Rebound':
          stats._playerRebounds
              .update(playerId, (value) => value + 1, ifAbsent: () => 1);

          if (event.eventData == 2) {
            stats._playerOffRebounds
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          } else if (event.eventData == 3) {
            stats._playerDefRebounds
                .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          }
          break;

        case 'Steal':
          stats._playerSteals
              .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          break;

        case 'Block':
          stats._playerBlocks
              .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          break;

        case 'Turnover':
          stats._playerTurnovers
              .update(playerId, (value) => value + 1, ifAbsent: () => 1);
          break;
      }
    }
    return stats;
  }

  @override
  Future<HashMap<Player, int>> getStatPlayers(String category) async {
    HashMap<int, int>? sourceTable;
    final HashMap<Player, int> players = HashMap<Player, int>();

    switch (category) {
      case 'goals':
        sourceTable = _playerGoals;
        break;
      case 'ownGoalsEarned':
        sourceTable = _teamOwnGoals;
        break;
      case 'penaltyKickGoals':
        sourceTable = _playerPenaltyKickGoals;
        break;
      case 'penaltyKicksTaken':
        sourceTable = _playerPenaltyKicksTaken;
        break;
      case 'assists':
        sourceTable = _playerAssists;
        break;
      case 'shots':
        sourceTable = _playerShots;
        break;
      case 'shotsOnGoal':
        sourceTable = _playerShotsOnGoal;
        break;
      case 'shotsOffPost':
        sourceTable = _playerShotsOffPost;
        break;
      case 'saves':
        sourceTable = _playerSaves;
        break;
      case 'offsides':
        sourceTable = _playerOffsides;
        break;
      case 'corners':
        // Corners are team stats, not player stats
        return players;
      case 'fouls':
        sourceTable = _playerFouls;
        break;
      case 'yellows':
        sourceTable = _playerYellows;
        break;
      case 'secondYellowReds':
        sourceTable = _playerSecondYellows;
        break;
      case 'reds':
        sourceTable = _playerReds;
        break;
      // Basketball / Generic
      case 'points':
        sourceTable = _playerPoints;
        break;
      case 'threePointersMade':
        sourceTable = _playerThreePointersMade;
        break;
      case 'threePointersAttempted':
        sourceTable = _playerThreePointersAttempted;
        break;
      case 'twoPointersMade':
        sourceTable = _playerTwoPointersMade;
        break;
      case 'twoPointersAttempted':
        sourceTable = _playerTwoPointersAttempted;
        break;
      case 'freeThrowsMade':
        sourceTable = _playerFreeThrowsMade;
        break;
      case 'freeThrowsAttempted':
        sourceTable = _playerFreeThrowsAttempted;
        break;
      case 'rebounds':
        sourceTable = _playerRebounds;
        break;
      case 'offRebounds':
        sourceTable = _playerOffRebounds;
        break;
      case 'defRebounds':
        sourceTable = _playerDefRebounds;
        break;
      case 'steals':
        sourceTable = _playerSteals;
        break;
      case 'blocks':
        sourceTable = _playerBlocks;
        break;
      case 'turnovers':
        sourceTable = _playerTurnovers;
        break;
    }

    if (sourceTable == null) return players;

    for (int playerId in sourceTable.keys) {
      if (playerId != -1) {
        Player? player = await Player.fromId(playerId);
        if (player != null) {
          players[player] = sourceTable[playerId] ?? 0;
        }
      }
    }

    return players;
  }
}

enum GameStatus {
  notStarted,
  firstHalf,
  halftime,
  secondHalf,
  overtimeNotStarted,
  firstHalfOvertime,
  overtimeHalftime,
  secondHalfOvertime,
  shootout,
  gameFinal,
  gameFinalOT,
  gameFinalPKs;

  static GameStatus fromString(String s) {
    switch (s) {
      case '0':
        return GameStatus.notStarted;
      case '1':
        return GameStatus.firstHalf;
      case '2':
        return GameStatus.halftime;
      case '3':
        return GameStatus.secondHalf;
      case '4':
        return GameStatus.overtimeNotStarted;
      case '5':
        return GameStatus.firstHalfOvertime;
      case '6':
        return GameStatus.overtimeHalftime;
      case '7':
        return GameStatus.secondHalfOvertime;
      case '8':
        return GameStatus.shootout;
      case '9':
        return GameStatus.gameFinal;
      case '10':
        return GameStatus.gameFinalOT;
      case '11':
        return GameStatus.gameFinalPKs;
    }

    return GameStatus.notStarted;
  }

  String get display {
    switch (index) {
      case 0:
        return 'Not Started';
      case 1:
        return '1st Half';
      case 2:
        return 'Halftime';
      case 3:
        return '2nd Half';
      case 4:
        return 'OT';
      case 5:
        return 'OT - 1st Half';
      case 6:
        return 'OT - Halftime';
      case 7:
        return 'OT - 2nd Half';
      case 8:
        return 'Shootout';
      case 9:
        return 'Final';
      case 10:
        return 'Final - OT';
      case 11:
        return 'Final - PKs';
    }

    return '-';
  }
}

class Game {
  final int id;
  final int seasonId;
  Team homeTeam;
  Team awayTeam;
  int homeTeamScore;
  int awayTeamScore;
  DateTime date;
  GameStatus gameStatus;
  String? description;
  String? gameLinks;
  String? imageUrl; // Optional image URL for the game
  bool isScrimmage;

  List<GameEvent> allGameEvents = [];
  List<GameEvent> scoringEvents = [];
  List<GameEvent> gameEvents = [];
  List<GameEvent> shootoutEvents = [];

  String displayName(int teamId) {
    final descToAdd =
        description?.isEmpty ?? true == true ? '' : ' ($description) ';

    if (teamId == homeTeam.id) {
      return 'vs ${awayTeam.shortName}$descToAdd';
    } else {
      return '@ ${homeTeam.shortName}$descToAdd';
    }
  }

  String getScore(int teamId, {int? minute}) {
    // If no scoring events exist and no minute filter is applied,
    // use the stored scores (for imported games without event data)
    if (scoringEvents.isEmpty && minute == null) {
      final teamScore = isHomeTeam(teamId) ? homeTeamScore : awayTeamScore;
      final opponentScore = isHomeTeam(teamId) ? awayTeamScore : homeTeamScore;
      return '$teamScore - $opponentScore';
    }

    int teamScore = 0;
    int opponentScore = 0;

    for (final event in scoringEvents) {
      if (minute != null) {
        if (event.eventMinute <= minute) {
          if (event.team.id == teamId) {
            teamScore++;
          } else {
            opponentScore++;
          }
        }
      } else {
        if (event.team.id == teamId) {
          teamScore++;
        } else {
          opponentScore++;
        }
      }
    }

    return '$teamScore - $opponentScore';
  }

  bool isHomeTeam(int teamId) {
    return teamId == homeTeam.id;
  }

  bool get isTie {
    return gameStatus.index >= 9 && homeTeamScore == awayTeamScore;
  }

  bool isWin(int teamId) {
    return (teamId == homeTeam.id && homeTeamScore > awayTeamScore) ||
        (teamId == awayTeam.id && awayTeamScore > homeTeamScore);
  }

  Game(
      {required this.id,
      required this.seasonId,
      required this.homeTeam,
      required this.awayTeam,
      required this.homeTeamScore,
      required this.awayTeamScore,
      required this.date,
      required this.gameStatus,
      required this.description,
      required this.gameLinks,
      this.imageUrl,
      this.isScrimmage = false});

  bool get isCompleted => gameStatus.index >= 9;

  static Game initial(
      {required int seasonId, required Team homeTeam, required Team awayTeam}) {
    return Game(
        id: -1,
        seasonId: seasonId,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        homeTeamScore: 0,
        awayTeamScore: 0,
        date: DateTime.now(),
        gameStatus: GameStatus.fromString('0'),
        description: '',
        gameLinks: '',
        imageUrl: '',
        isScrimmage: false);
  }

  static Future<Game> fromMap(Map<String, dynamic> map) async {
    // Add null safety checks for required integer fields
    final id = map['id'];
    final seasonId = map['seasonId'];
    final homeTeamId = map['homeTeamId'];
    final awayTeamId = map['awayTeamId'];
    final homeTeamScore = map['homeTeamScore'];
    final awayTeamScore = map['awayTeamScore'];

    if (id == null) {
      throw Exception('Game map missing required field: id');
    }
    if (seasonId == null) {
      throw Exception('Game map missing required field: seasonId');
    }
    if (homeTeamId == null) {
      throw Exception('Game map missing required field: homeTeamId');
    }
    if (awayTeamId == null) {
      throw Exception('Game map missing required field: awayTeamId');
    }

    // Try to parse date in multiple formats for backward compatibility
    DateTime date;
    try {
      // First try ISO8601 format (includes time)
      date = DateTime.parse(map['date']);
    } catch (e) {
      try {
        // Fallback to old MM.dd.yyyy format (date only)
        date = DateFormat('MM.dd.yyyy').parse(map['date']);
      } catch (e2) {
        // If both fail, use current date as fallback
        debugPrint('Error parsing date "${map['date']}": $e, $e2');
        date = DateTime.now();
      }
    }

    final homeTeam = await Team.fromId(
        homeTeamId is int ? homeTeamId : int.parse(homeTeamId.toString()));
    final awayTeam = await Team.fromId(
        awayTeamId is int ? awayTeamId : int.parse(awayTeamId.toString()));

    return Game(
        id: id is int ? id : int.parse(id.toString()),
        seasonId: seasonId is int ? seasonId : int.parse(seasonId.toString()),
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        homeTeamScore: homeTeamScore != null
            ? (homeTeamScore is int
                ? homeTeamScore
                : int.parse(homeTeamScore.toString()))
            : 0,
        awayTeamScore: awayTeamScore != null
            ? (awayTeamScore is int
                ? awayTeamScore
                : int.parse(awayTeamScore.toString()))
            : 0,
        date: date,
        gameStatus: GameStatus.fromString(map['gameStatus']?.toString() ?? '0'),
        description: map['description'],
        gameLinks: map['gameLinks'],
        imageUrl: map['imageUrl'],
        isScrimmage: map['isScrimmage'] == 1 ||
            map['isScrimmage'] == true ||
            map['isScrimmage'] == 'true');
  }

  static Future<Game?> fromId(int id) async {
    final results = await DatabaseService.instance
        .query('Games', orderByChild: 'id', equalTo: id);
    if (results.isNotEmpty) {
      return Game.fromMap(results.first);
    } else {
      return null;
    }
  }

  static Future<List<Game>> listFromSeasonId(int seasonId) async {
    final results = await DatabaseService.instance
        .query('Games', orderByChild: 'seasonId', equalTo: seasonId);

    // Process games in batches to avoid OOM from too many concurrent operations
    const batchSize = 50;
    final games = <Game>[];

    for (int i = 0; i < results.length; i += batchSize) {
      final end =
          (i + batchSize < results.length) ? i + batchSize : results.length;
      final batch = results.sublist(i, end);

      final batchGames = await Future.wait(batch
          .map((g) async => await Game.fromMap(g))
          .toList(growable: false));

      games.addAll(batchGames);

      // Allow garbage collection between batches
      await Future.delayed(const Duration(milliseconds: 10));
    }

    games.sort((a, b) => a.date.compareTo(b.date));
    return games;
  }

  static Future<List<Game>> listFromTeamId(int teamId) async {
    final homeResults = await DatabaseService.instance
        .query('Games', orderByChild: 'homeTeamId', equalTo: teamId);
    final awayResults = await DatabaseService.instance
        .query('Games', orderByChild: 'awayTeamId', equalTo: teamId);
    final results = homeResults + awayResults;

    // Process games in batches to avoid OOM from too many concurrent operations
    const batchSize = 50;
    final games = <Game>[];

    for (int i = 0; i < results.length; i += batchSize) {
      final end =
          (i + batchSize < results.length) ? i + batchSize : results.length;
      final batch = results.sublist(i, end);

      final batchGames = await Future.wait(batch
          .map((g) async => await Game.fromMap(g))
          .toList(growable: false));

      games.addAll(batchGames);

      // Allow garbage collection between batches
      await Future.delayed(const Duration(milliseconds: 10));
    }

    games.sort((a, b) => a.date.compareTo(b.date));

    return games;
  }

  Future<List<GameEvent>> loadGameEvents() async {
    allGameEvents = await GameEvent.listFromGameId(id);
    scoringEvents = allGameEvents
        .where((e) => e.eventMinute > -2 && e.isGoalEvent)
        .toList(growable: false);
    scoringEvents.sort((a, b) => a.eventMinute.compareTo(b.eventMinute));

    gameEvents =
        allGameEvents.where((e) => e.eventMinute > -2).toList(growable: true);
    gameEvents.sort((a, b) => a.eventPeriod.compareTo(b.eventPeriod));
    gameEvents.sort((a, b) => a.index.compareTo(b.index));

    shootoutEvents =
        allGameEvents.where((e) => e.eventMinute == -2).toList(growable: false);

    return allGameEvents;
  }

  Future<void> updateScore() async {
    await loadGameEvents();
    homeTeamScore = 0;
    awayTeamScore = 0;

    for (final event in scoringEvents) {
      if (event.team.id == homeTeam.id) {
        homeTeamScore += event.eventValue;
      } else if (event.team.id == awayTeam.id) {
        awayTeamScore += event.eventValue;
      }
    }

    saveGame();
  }

  Future<void> advanceGame() async {
    final newIndex = gameStatus.index + 1;
    if (newIndex < 9) {
      gameStatus = GameStatus.fromString((newIndex).toString());
      saveGame();
    }
  }

  Future<void> endGame(int status) async {
    final previousStatus = gameStatus;
    gameStatus = GameStatus.fromString(status.toString());
    await saveGame();

    // If game is being finalized (status >= 9), update best game stats
    if (gameStatus.index >= 9 && previousStatus.index < 9) {
      // Update stats for both teams asynchronously
      homeTeam.updateBestGameStatsForGame(this);
      awayTeam.updateBestGameStatsForGame(this);
    }
  }

  Future<bool> saveGame() async {
    if (homeTeam.id > 0 && awayTeam.id > 0) {
      // Use ISO8601 format to preserve time information
      // The fromMap method now handles both old (MM.dd.yyyy) and new (ISO8601) formats
      final data = {
        'id': id == -1 ? DateTime.now().millisecondsSinceEpoch : id,
        'seasonId': seasonId,
        'homeTeamId': homeTeam.id,
        'awayTeamId': awayTeam.id,
        'homeTeamScore': homeTeamScore,
        'awayTeamScore': awayTeamScore,
        'date': date.toIso8601String(),
        'gameStatus': gameStatus.index,
        'description': description,
        'gameLinks': gameLinks,
        'imageUrl': imageUrl,
        'isScrimmage': isScrimmage ? 1 : 0,
      };

      if (id == -1) {
        await DatabaseService.instance.insert('Games', data);
      } else {
        await DatabaseService.instance
            .update('Games', data, key: id.toString());
      }
      return true;
    }

    return false;
  }

  Future<GameStats> getStats(int teamId) async {
    await loadGameEvents();
    return GameStats.fromEvents(teamId, allGameEvents);
  }

  String tweetStatus() {
    return '${homeTeam.shortName}: $homeTeamScore - ${awayTeam.shortName}: $awayTeamScore';
  }
}
