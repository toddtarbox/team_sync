import 'package:intl/intl.dart';
import 'package:sqflite/sqflite.dart';
import 'package:team_sync/models/game_event.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/team.dart';

class GameStat {
  final String name;
  final String dialogName;
  final String category;
  final int teamStat;
  final int opponentStat;
  Map<Player, int> playerStats = {};

  GameStat(this.name, this.dialogName, this.category, this.teamStat,
      this.opponentStat);
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
  int milliSecondsLeft;
  Player? homeKeeper;
  Player? awayKeeper;

  List<GameEvent> allGameEvents = [];
  List<GameEvent> events = [];
  List<GameEvent> shootoutEvents = [];

  String displayName(int teamId) {
    if (teamId == homeTeam.id) {
      return 'vs ${awayTeam.fullName}';
    } else {
      return '@ ${homeTeam.fullName}';
    }
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
      required this.milliSecondsLeft,
      required this.homeKeeper,
      required this.awayKeeper});

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
        milliSecondsLeft: 0,
        homeKeeper: Player.initial(teamId: homeTeam.id, seasonId: seasonId),
        awayKeeper: Player.initial(teamId: awayTeam.id, seasonId: seasonId));
  }

  static Future<Game> fromMap(Database db, Map<String, dynamic> map) async {
    final date = DateFormat('MM.dd.yyyy').parse(map['date']);

    final homeTeam = await Team.fromId(db, map['homeTeamId']);
    final awayTeam = await Team.fromId(db, map['awayTeamId']);

    final homeTeamKeeper = await Player.fromId(db, map['homeKeeperId']);
    final awayTeamKeeper = await Player.fromId(db, map['awayKeeperId']);

    return Game(
        id: map['id'],
        seasonId: map['seasonId'],
        homeTeam: homeTeam,
        awayTeam: awayTeam,
        homeTeamScore: map['homeTeamScore'],
        awayTeamScore: map['awayTeamScore'],
        date: date,
        gameStatus: GameStatus.fromString(map['gameStatus']),
        milliSecondsLeft: map['milliSecondsLeft'],
        homeKeeper: homeTeamKeeper,
        awayKeeper: awayTeamKeeper);
  }

  static Future<Game?> fromId(Database db, int id) async {
    final results = await db.query('Games', where: 'id=?', whereArgs: [id]);
    if (results.isNotEmpty) {
      return Game.fromMap(db, results.first);
    } else {
      return null;
    }
  }

  static Future<List<Game>> listFromSeasonId(Database db, int seasonId) async {
    final results =
        await db.query('Games', where: 'seasonId=?', whereArgs: [seasonId]);

    final games = await Future.wait(results
        .map((g) async => await Game.fromMap(db, g))
        .toList(growable: false));
    games.sort((a, b) => a.date.compareTo(b.date));

    return games;
  }

  Future<void> loadGameEvents(Database db) async {
    allGameEvents = await GameEvent.listFromGameId(db, id);
    events =
        allGameEvents.where((e) => e.eventMinute > -2).toList(growable: false);
    shootoutEvents =
        allGameEvents.where((e) => e.eventMinute < -2).toList(growable: false);
  }

  Future<void> updateScore(Database db) async {
    await loadGameEvents(db);
    awayTeamScore = events
        .where((e) =>
            e.eventType == 'Shot' &&
            e.eventData == 0 &&
            e.team.id == awayTeam.id)
        .length;
    homeTeamScore = events
        .where((e) =>
            e.eventType == 'Shot' &&
            e.eventData == 0 &&
            e.team.id == homeTeam.id)
        .length;

    saveGame(db);
  }

  Future<void> advanceGame(Database db) async {
    final newIndex = gameStatus.index + 1;
    if (newIndex < 9) {
      gameStatus = GameStatus.fromString((newIndex).toString());
      saveGame(db);
    }
  }

  Future<void> endGame(Database db, int status) async {
    gameStatus = GameStatus.fromString(status.toString());
    saveGame(db);
  }

  Future<bool> saveGame(Database db) async {
    if (homeTeam.id > 0 && awayTeam.id > 0) {
      final saveFormat = DateFormat('MM.dd.yyyy');

      await db.insert(
          'Games',
          {
            'id': id == -1 ? null : id,
            'seasonId': seasonId,
            'homeTeamId': homeTeam.id,
            'awayTeamId': awayTeam.id,
            'homeTeamScore': homeTeamScore,
            'awayTeamScore': awayTeamScore,
            'date': saveFormat.format(date),
            'gameStatus': gameStatus.index,
            'milliSecondsLeft': milliSecondsLeft,
            'homeKeeperId': homeKeeper?.id ?? -1,
            'awayKeeperId': awayKeeper?.id ?? -1
          },
          conflictAlgorithm: ConflictAlgorithm.replace);
      return true;
    }

    return false;
  }

  Future<GameStat> getStats(Database db, String name, String dialogName,
      String category, int data, int teamId) async {
    GameStat stat;
    if (data != -1) {
      int teamStat = allGameEvents
          .where((e) =>
              e.eventType == category &&
              e.eventData == data &&
              e.team.id == teamId &&
              e.eventMinute > 0)
          .length;
      int opponentStat = allGameEvents
          .where((e) =>
              e.eventType == category &&
              e.eventData == data &&
              e.team.id != teamId &&
              e.eventMinute > 0)
          .length;

      stat = GameStat(name, dialogName, category, teamStat, opponentStat);

      final playerSet = allGameEvents
          .where((e) => e.eventType == category)
          .map((e) => e.player?.id)
          .where((e) => e != null)
          .toSet();
      for (final id in playerSet) {
        if (id != null && id != -1) {
          final player = await Player.fromId(db, id);
          stat.playerStats[player!] = allGameEvents
              .where((e) =>
                  e.player?.id == id &&
                  e.eventType == category &&
                  e.eventMinute > 0 &&
                  e.eventData == data)
              .toList(growable: false)
              .length;
        }
      }
    } else {
      int teamStat = allGameEvents
          .where((e) =>
              e.eventType == category &&
              e.team.id == teamId &&
              e.eventMinute > 0)
          .length;
      int opponentStat = allGameEvents
          .where((e) =>
              e.eventType == category &&
              e.team.id != teamId &&
              e.eventMinute > 0)
          .length;

      stat = GameStat(name, dialogName, category, teamStat, opponentStat);

      final playerSet = allGameEvents
          .where((e) => e.eventType == category)
          .map((e) => e.player?.id)
          .where((e) => e != null)
          .toSet();
      for (final id in playerSet) {
        if (id != null && id != -1) {
          final player = await Player.fromId(db, id);
          stat.playerStats[player!] = allGameEvents
              .where((e) =>
                  e.player?.id == id &&
                  e.eventType == category &&
                  e.eventMinute > 0)
              .toList(growable: false)
              .length;
        }
      }
    }

    stat.playerStats.removeWhere((_, count) => count == 0);

    return stat;
  }
}
