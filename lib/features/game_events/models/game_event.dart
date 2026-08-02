import 'package:flutter/material.dart';
import 'package:team_sync/features/games/models/game.dart';
import 'package:team_sync/features/players/models/player.dart';
import 'package:team_sync/features/teams/models/team.dart';

import 'package:team_sync/core/services/database_service.dart';
import 'package:team_sync/features/sports/services/sport_strategy.dart';

enum ShotResult {
  goal,
  onTargetSave,
  offTargetPost,
  offTarget,
  onTargetBlock,
  notInitialized;

  static ShotResult fromInt(int i) {
    switch (i) {
      case 0:
        return ShotResult.goal;
      case 1:
        return ShotResult.onTargetSave;
      case 2:
        return ShotResult.offTargetPost;
      case 3:
        return ShotResult.offTarget;
      case 4:
        return ShotResult.onTargetBlock;
    }

    return ShotResult.notInitialized;
  }

  String get display {
    switch (index) {
      case 0:
        return 'Goal';
      case 1:
        return 'Saved';
      case 2:
        return 'Post';
      case 3:
        return 'Off Target';
      case 4:
        return 'Blocked';
    }

    return '-';
  }
}

enum CornerResult {
  none,
  shot,
  goal,
  cleared;

  static CornerResult fromInt(int i) {
    switch (i) {
      case 0:
        return CornerResult.none;
      case 1:
        return CornerResult.shot;
      case 2:
        return CornerResult.goal;
      case 3:
        return CornerResult.cleared;
    }

    return CornerResult.none;
  }

  String get display {
    switch (index) {
      case 0:
        return 'None';
      case 1:
        return 'Shot';
      case 2:
        return 'Goal';
      case 3:
        return 'Cleared';
    }

    return '';
  }
}

class Shot extends GameEvent {
  ShotResult get result => ShotResult.fromInt(eventData);

  Shot(
      {required super.id,
      required super.index,
      required super.player,
      required super.team,
      required super.game,
      required super.seasonId,
      required super.eventType,
      required super.eventMinute,
      required super.eventPeriod,
      required super.eventUrls,
      required super.eventData,
      super.isFromImport = false});
}

class Assist extends GameEvent {
  Assist(
      {required super.id,
      required super.index,
      required super.player,
      required super.team,
      required super.game,
      required super.seasonId,
      required super.eventType,
      required super.eventMinute,
      required super.eventPeriod,
      required super.eventUrls,
      required super.eventData,
      super.isFromImport = false});
}

class Save extends GameEvent {
  Save(
      {required super.id,
      required super.index,
      required super.player,
      required super.team,
      required super.game,
      required super.seasonId,
      required super.eventType,
      required super.eventMinute,
      required super.eventPeriod,
      required super.eventUrls,
      required super.eventData,
      super.isFromImport = false});
}

class PenaltyKick extends GameEvent {
  ShotResult get result => ShotResult.fromInt(eventData);

  PenaltyKick(
      {required super.id,
      required super.index,
      required super.player,
      required super.team,
      required super.game,
      required super.seasonId,
      required super.eventType,
      required super.eventMinute,
      required super.eventPeriod,
      required super.eventUrls,
      required super.eventData,
      super.isFromImport = false});
}

class Corner extends GameEvent {
  CornerResult get result => CornerResult.fromInt(eventData);

  Corner(
      {required super.id,
      required super.index,
      required super.player,
      required super.team,
      required super.game,
      required super.seasonId,
      required super.eventType,
      required super.eventMinute,
      required super.eventPeriod,
      required super.eventUrls,
      required super.eventData,
      super.isFromImport = false});
}

class Foul extends GameEvent {
  Foul(
      {required super.id,
      required super.index,
      required super.player,
      required super.team,
      required super.game,
      required super.seasonId,
      required super.eventType,
      required super.eventMinute,
      required super.eventPeriod,
      required super.eventUrls,
      required super.eventData,
      super.isFromImport = false});
}

class Offsides extends GameEvent {
  Offsides(
      {required super.id,
      required super.index,
      required super.player,
      required super.team,
      required super.game,
      required super.seasonId,
      required super.eventType,
      required super.eventMinute,
      required super.eventPeriod,
      required super.eventUrls,
      required super.eventData,
      super.isFromImport = false});
}

class GameCard extends GameEvent {
  GameCard(
      {required super.id,
      required super.index,
      required super.player,
      required super.team,
      required super.game,
      required super.seasonId,
      required super.eventType,
      required super.eventMinute,
      required super.eventPeriod,
      required super.eventUrls,
      required super.eventData,
      super.isFromImport = false});
}

class Period extends GameEvent {
  GameStatus get status => GameStatus.fromString(eventData.toString());

  Period(
      {required super.id,
      required super.index,
      required super.player,
      required super.team,
      required super.game,
      required super.seasonId,
      required super.eventType,
      required super.eventMinute,
      required super.eventPeriod,
      required super.eventUrls,
      required super.eventData,
      super.isFromImport = false});
}

class GameEvent {
  int id;
  int index; // Added index field for ordering
  Player? player;
  Team team;
  final Game game;
  final int seasonId;
  String eventType;
  int eventMinute;
  int eventPeriod;
  int eventData;
  String? eventUrls;
  final bool isFromImport;

  String get teamIdSeasonId => '${team.id}_$seasonId';

  String get display {
    return SportStrategy.current.formatEventDisplay(this);
  }

  String get imageAsset {
    return SportStrategy.current.getEventImageAsset(this);
  }

  Widget get image {
    return Image.asset(imageAsset, width: 36, height: 36);
  }

  bool get shouldTweet {
    return (eventType == 'Period') ||
        ((eventType == 'Shot' || eventType == 'PenaltyKick') &&
            eventData == ShotResult.goal.index);
  }

  /// Helper to check if this event is a goal (either a Shot or PenaltyKick that resulted in a goal)
  bool get isGoalEvent {
    return SportStrategy.current.isGoalEvent(this);
  }

  int get eventValue => SportStrategy.current.getEventValue(this);

  String tweetText(Game game) {
    if (eventType == 'Period') {
      String tweetText = (this as Period).display;
      if (tweetText == '1st Half' ||
          tweetText == '2nd Half' ||
          tweetText == '1st OT' ||
          tweetText == '2nd OT' ||
          tweetText == 'Overtime' ||
          tweetText == 'Shootout') {
        tweetText += ' Starting';
      }
      return '$tweetText\n\n${game.tweetStatusAtEvent(this)}';
    } else if (isGoalEvent) {
      String tweetText;
      if (player != null) {
        if (player!.id == -2) {
          final isHomeTeam = game.homeTeam.id == team.id;
          final opponentTeamName = isHomeTeam ? game.awayTeam.shortName : game.homeTeam.shortName;
          tweetText = '($eventMinute\') Own Goal by $opponentTeamName';
        } else {
          tweetText = '($eventMinute\') Goal by ${player!.displayName}';
        }
      } else {
        tweetText = '($eventMinute\') Goal by ${team.shortName}';
      }

      tweetText = '$tweetText\n\n${game.tweetStatus()}';

      return tweetText;
    }

    return '';
  }

  GameEvent(
      {required this.id,
      required this.index,
      required this.player,
      required this.team,
      required this.game,
      required this.seasonId,
      required this.eventType,
      required this.eventMinute,
      required this.eventPeriod,
      required this.eventUrls,
      required this.eventData,
      this.isFromImport = false});

  static GameEvent initial(
      {required Team team,
      required Game game,
      required int seasonId,
      required String eventType,
      required int eventMinute,
      required int eventPeriod,
      required String eventUrls,
      required int eventData}) {
    return GameEvent(
        id: -1,
        index: -1,
        player: null,
        team: team,
        game: game,
        seasonId: seasonId,
        eventType: eventType,
        eventMinute: eventMinute,
        eventPeriod: eventPeriod,
        eventUrls: eventUrls,
        eventData: eventData,
        isFromImport: false);
  }

  static Future<GameEvent?> fromMap(Map<String, dynamic> map) async {
    // Validate required int fields first
    final id = map['id'] as int?;
    final gameId = map['gameId'] as int?;
    final eventMinute = map['eventMinute'] as int?;
    final eventPeriod = map['eventPeriod'] as int?;
    final eventData = map['eventData'] as int?;
    final eventType = map['eventType'] as String?;
    final isFromImport = (map['isFromImport'] as bool?) ?? false;

    if (id == null ||
        gameId == null ||
        eventMinute == null ||
        eventPeriod == null ||
        eventData == null ||
        eventType == null) {
      return null;
    }

    final game = await Game.fromId(gameId);
    if (game == null) {
      return null;
    }

    var teamId = map['teamId'] as int?;
    if (teamId == null) {
      return null;
    }

    if (teamId == -1) {
      if (map['playerId'] != -1) {
        teamId = 1;
      } else {
        return null;
      }
    }

    final team = await Team.fromId(teamId);

    final playerId = map['playerId'] as int?;
    // Allow null player (for opponent stats or team stats)
    Player? player;
    if (playerId != null) {
      player = await Player.singleFromIdSeasonId(playerId, game.seasonId);
    }

    // Use game.seasonId as fallback if map['seasonId'] is null
    final seasonId = (map['seasonId'] as int?) ?? game.seasonId;

    final eventUrls = map['eventUrls'] as String?;

    if (eventType == 'Period') {
      return Period(
          id: id,
          index: map['index'] ?? id,
          player: player,
          team: team,
          game: game,
          seasonId: seasonId,
          eventType: eventType,
          eventMinute: eventMinute,
          eventPeriod: eventPeriod,
          eventUrls: eventUrls,
          eventData: eventData,
          isFromImport: isFromImport);
    } else if (eventType == 'Shot') {
      return Shot(
          id: id,
          index: map['index'] ?? id,
          player: player,
          team: team,
          game: game,
          seasonId: seasonId,
          eventType: eventType,
          eventMinute: eventMinute,
          eventPeriod: eventPeriod,
          eventUrls: eventUrls,
          eventData: eventData,
          isFromImport: isFromImport);
    } else if (eventType == 'Assist') {
      return Assist(
          id: id,
          index: map['index'] ?? id,
          player: player,
          team: team,
          game: game,
          seasonId: seasonId,
          eventType: eventType,
          eventMinute: eventMinute,
          eventPeriod: eventPeriod,
          eventUrls: eventUrls,
          eventData: eventData,
          isFromImport: isFromImport);
    } else if (eventType == 'Save') {
      return Save(
          id: id,
          index: map['index'] ?? id,
          player: player,
          team: team,
          game: game,
          seasonId: seasonId,
          eventType: eventType,
          eventMinute: eventMinute,
          eventPeriod: eventPeriod,
          eventUrls: eventUrls,
          eventData: eventData,
          isFromImport: isFromImport);
    } else if (eventType == 'PenaltyKick') {
      return PenaltyKick(
          id: id,
          index: map['index'] ?? id,
          player: player,
          team: team,
          game: game,
          seasonId: seasonId,
          eventType: eventType,
          eventMinute: eventMinute,
          eventPeriod: eventPeriod,
          eventUrls: eventUrls,
          eventData: eventData,
          isFromImport: isFromImport);
    } else if (eventType == 'Corner') {
      return Corner(
          id: id,
          index: map['index'] ?? id,
          player: player,
          team: team,
          game: game,
          seasonId: seasonId,
          eventType: eventType,
          eventMinute: eventMinute,
          eventPeriod: eventPeriod,
          eventUrls: eventUrls,
          eventData: eventData,
          isFromImport: isFromImport);
    } else if (eventType == 'Foul') {
      return Foul(
          id: id,
          index: map['index'] ?? id,
          player: player,
          team: team,
          game: game,
          seasonId: seasonId,
          eventType: eventType,
          eventMinute: eventMinute,
          eventPeriod: eventPeriod,
          eventUrls: eventUrls,
          eventData: eventData,
          isFromImport: isFromImport);
    } else if (eventType == 'Offsides') {
      return Offsides(
          id: id,
          index: map['index'] ?? id,
          player: player,
          team: team,
          game: game,
          seasonId: seasonId,
          eventType: eventType,
          eventMinute: eventMinute,
          eventPeriod: eventPeriod,
          eventUrls: eventUrls,
          eventData: eventData,
          isFromImport: isFromImport);
    } else if (eventType == 'Card') {
      return GameCard(
          id: id,
          index: map['index'] ?? id,
          player: player,
          team: team,
          game: game,
          seasonId: seasonId,
          eventType: eventType,
          eventMinute: eventMinute,
          eventPeriod: eventPeriod,
          eventUrls: eventUrls,
          eventData: eventData,
          isFromImport: isFromImport);
    }

    return GameEvent(
        id: id,
        index: map['index'] ?? id,
        player: player,
        team: team,
        game: game,
        seasonId: seasonId,
        eventType: eventType,
        eventMinute: eventMinute,
        eventPeriod: eventPeriod,
        eventUrls: eventUrls,
        eventData: eventData,
        isFromImport: isFromImport);
  }

  static Future<List<GameEvent>> listFromGameId(int gameId) async {
    final results = await DatabaseService.instance
        .query('Events', orderByChild: 'gameId', equalTo: gameId);
    // Apply index sort locally
    results.sort((a, b) {
      final ai = a['index'] ?? a['id'];
      final bi = b['index'] ?? b['id'];
      return (ai as int).compareTo(bi as int);
    });

    // Process events in batches to avoid OOM from too many concurrent operations
    const batchSize = 100;
    final events = <GameEvent>[];

    for (int i = 0; i < results.length; i += batchSize) {
      final end =
          (i + batchSize < results.length) ? i + batchSize : results.length;
      final batch = results.sublist(i, end);

      final batchEvents = await Future.wait(batch
          .map((g) async => await GameEvent.fromMap(g))
          .toList(growable: false));

      events.addAll(batchEvents.whereType<GameEvent>());

      // Allow garbage collection between batches
      await Future.delayed(const Duration(milliseconds: 5));
    }

    return events;
  }

  static Future<List<GameEvent>> listFromTeamId(int teamId) async {
    final results = await DatabaseService.instance
        .query('Events', orderByChild: 'teamId', equalTo: teamId);

    // Process events in batches to avoid OOM from too many concurrent operations
    const batchSize = 100;
    final events = <GameEvent>[];

    for (int i = 0; i < results.length; i += batchSize) {
      final end =
          (i + batchSize < results.length) ? i + batchSize : results.length;
      final batch = results.sublist(i, end);

      final batchEvents = await Future.wait(batch
          .map((g) async => await GameEvent.fromMap(g))
          .toList(growable: false));

      events.addAll(batchEvents.whereType<GameEvent>());

      // Allow garbage collection between batches
      await Future.delayed(const Duration(milliseconds: 10));
    }

    return events;
  }

  static Future<List<GameEvent>> listFromTeamIdSeasonId(
      int teamId, int seasonId) async {
    final results = await DatabaseService.instance.query('Events',
        orderByChild: 'teamId_seasonId', equalTo: '${teamId}_$seasonId');

    // Process events in batches to avoid OOM from too many concurrent operations
    const batchSize = 100;
    final events = <GameEvent>[];

    for (int i = 0; i < results.length; i += batchSize) {
      final end =
          (i + batchSize < results.length) ? i + batchSize : results.length;
      final batch = results.sublist(i, end);

      final batchEvents = await Future.wait(batch
          .map((g) async => await GameEvent.fromMap(g))
          .toList(growable: false));

      events.addAll(batchEvents.whereType<GameEvent>());

      // Allow garbage collection between batches
      await Future.delayed(const Duration(milliseconds: 5));
    }

    return events;
  }
}
