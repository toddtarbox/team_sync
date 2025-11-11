import 'dart:collection';

import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season_stats.dart';
import 'package:team_sync/models/stat_leaders.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';

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

  factory GameStats.fromEvents(int teamId, List<GameEvent> events) {
    final stats = GameStats(teamId: teamId);

    for (final event in events) {
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
      }
    }
    return stats;
  }

  @override
  Future<HashMap<Player, int>> getStatPlayers(LeaderCategory category) async {
    HashMap<int, int>? sourceTable;
    final HashMap<Player, int> players = HashMap<Player, int>();

    switch (category) {
      case LeaderCategory.goals:
        sourceTable = _playerGoals;
        break;
      case LeaderCategory.ownGoalsEarned:
        sourceTable = _teamOwnGoals;
        break;
      case LeaderCategory.penaltyKickGoals:
        sourceTable = _playerPenaltyKickGoals;
        break;
      case LeaderCategory.penaltyKicksTaken:
        sourceTable = _playerPenaltyKicksTaken;
        break;
      case LeaderCategory.assists:
        sourceTable = _playerAssists;
        break;
      case LeaderCategory.shots:
        sourceTable = _playerShots;
        break;
      case LeaderCategory.shotsOnGoal:
        sourceTable = _playerShotsOnGoal;
        break;
      case LeaderCategory.shotsOffPost:
        sourceTable = _playerShotsOffPost;
        break;
      case LeaderCategory.saves:
        sourceTable = _playerSaves;
        break;
      case LeaderCategory.offsides:
        sourceTable = _playerOffsides;
        break;
      case LeaderCategory.fouls:
        sourceTable = _playerFouls;
        break;
      case LeaderCategory.yellows:
        sourceTable = _playerYellows;
        break;
      case LeaderCategory.secondYellowReds:
        sourceTable = _playerSecondYellows;
        break;
      case LeaderCategory.reds:
        sourceTable = _playerReds;
        break;
    }

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
      required this.gameLinks});

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
        gameLinks: '');
  }

  static Future<Game> fromMap(Map<String, dynamic> map) async {
    final date = DateFormat('MM.dd.yyyy').parse(map['date']);

    final homeTeam = await Team.fromId(map['homeTeamId']);
    final awayTeam = await Team.fromId(map['awayTeamId']);

    return Game(
        id: map['id'],
        seasonId: map['seasonId'],
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        homeTeamScore: map['homeTeamScore'],
        awayTeamScore: map['awayTeamScore'],
        date: date,
        gameStatus: GameStatus.fromString(map['gameStatus'].toString()),
        description: map['description'],
        gameLinks: map['gameLinks']);
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

    final games = await Future.wait(results
        .map((g) async => await Game.fromMap(g))
        .toList(growable: false));
    games.sort((a, b) => a.date.compareTo(b.date));

    return games;
  }

  static Future<List<Game>> listFromTeamId(int teamId) async {
    final homeResults = await DatabaseService.instance
        .query('Games', orderByChild: 'homeTeamId', equalTo: teamId);
    final awayResults = await DatabaseService.instance
        .query('Games', orderByChild: 'awayTeamId', equalTo: teamId);
    final results = homeResults + awayResults;

    final games = await Future.wait(results
        .map((g) async => await Game.fromMap(g))
        .toList(growable: false));
    games.sort((a, b) => a.date.compareTo(b.date));

    return games;
  }

  Future<List<GameEvent>> loadGameEvents() async {
    allGameEvents = await GameEvent.listFromGameId(id);
    scoringEvents = allGameEvents
        .where((e) =>
            e.eventMinute > -2 &&
            (e.eventType == 'Shot' || e.eventType == 'PenaltyKick') &&
            e.eventData == ShotResult.goal.index)
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
    awayTeamScore = scoringEvents.where((e) => e.team.id == awayTeam.id).length;
    homeTeamScore = scoringEvents.where((e) => e.team.id == homeTeam.id).length;

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
    gameStatus = GameStatus.fromString(status.toString());
    saveGame();
  }

  Future<bool> saveGame() async {
    if (homeTeam.id > 0 && awayTeam.id > 0) {
      final saveFormat = DateFormat('MM.dd.yyyy');

      final data = {
        'id': id == -1 ? DateTime.now().millisecondsSinceEpoch : id,
        'seasonId': seasonId,
        'homeTeamId': homeTeam.id,
        'awayTeamId': awayTeam.id,
        'homeTeamScore': homeTeamScore,
        'awayTeamScore': awayTeamScore,
        'date': saveFormat.format(date),
        'gameStatus': gameStatus.index,
        'description': description,
        'gameLinks': gameLinks,
      };

      if (id == -1) {
        await DatabaseService.instance.insert('Games', data,
            conflictAlgorithm: ConflictAlgorithm.replace);
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
