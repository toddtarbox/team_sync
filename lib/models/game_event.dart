import 'package:flutter/material.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';

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

  @override
  String get imageAsset {
    switch (result) {
      case ShotResult.goal:
        return 'assets/images/pngs/goal.png';

      case ShotResult.onTargetSave:
        return 'assets/images/pngs/saved.png';

      case ShotResult.offTargetPost:
        return 'assets/images/pngs/offpost.png';

      case ShotResult.offTarget:
        return 'assets/images/pngs/offtarget.png';

      case ShotResult.onTargetBlock:
        return 'assets/images/pngs/blocked.png';

      case ShotResult.notInitialized:
        return 'assets/images/pngs/empty.png';
    }
  }

  @override
  String get display {
    if (player != null) {
      if (result == ShotResult.goal) {
        return 'Goal';
      }
      return 'Shot - ${result.display}';
    }

    if (result == ShotResult.goal) {
      return 'Goal';
    }

    return 'Shot - ${result.display}';
  }

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
      required super.eventData});
}

class Assist extends GameEvent {
  @override
  String get imageAsset {
    return 'assets/images/pngs/cleat.png';
  }

  @override
  String get display {
    if (player != null) {
      return 'Assist: ${player!.displayName}';
    }

    return 'Assist';
  }

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
      required super.eventData});
}

class Save extends GameEvent {
  @override
  String get display {
    if (player != null) {
      return 'Save by ${player!.displayName}';
    }

    return 'Save by ${team.shortName}';
  }

  @override
  String get imageAsset {
    return 'assets/images/pngs/gloves.png';
  }

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
      required super.eventData});
}

class PenaltyKick extends GameEvent {
  ShotResult get result => ShotResult.fromInt(eventData);

  @override
  String get display {
    if (player != null) {
      return '${result.display} - ${player!.displayName} (PK)';
    }

    return '${result.display} - ${team.shortName} (PK)';
  }

  @override
  String get imageAsset {
    switch (result) {
      case ShotResult.goal:
        return 'assets/images/pngs/goal.png';

      case ShotResult.onTargetSave:
        return 'assets/images/pngs/saved.png';

      case ShotResult.offTargetPost:
        return 'assets/images/pngs/offpost.png';

      case ShotResult.offTarget:
        return 'assets/images/pngs/offtarget.png';

      case ShotResult.onTargetBlock:
        return 'assets/images/pngs/blocked.png';

      case ShotResult.notInitialized:
        return 'assets/images/pngs/empty.png';
    }
  }

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
      required super.eventData});
}

class Corner extends GameEvent {
  CornerResult get result => CornerResult.fromInt(eventData);

  @override
  String get display {
    return 'Corner kick for ${team.shortName} ${result == CornerResult.none ? '' : ' - ${result.display}'}';
  }

  @override
  String get imageAsset {
    return 'assets/images/pngs/corner.png';
  }

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
      required super.eventData});
}

class Foul extends GameEvent {
  @override
  String get display {
    if (player != null) {
      return 'Foul by ${player!.displayName}';
    }

    return 'Foul by ${team.shortName}';
  }

  @override
  String get imageAsset {
    return 'assets/images/pngs/foul.png';
  }

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
      required super.eventData});
}

class Offsides extends GameEvent {
  @override
  String get display {
    if (player != null) {
      return 'Offsides on ${player!.displayName}';
    }

    return 'Offsides on ${team.shortName}';
  }

  @override
  String get imageAsset {
    return 'assets/images/pngs/flag.png';
  }

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
      required super.eventData});
}

class GameCard extends GameEvent {
  @override
  String get display {
    if (player != null) {
      return 'Card by ${player!.displayName}';
    }

    return 'Card for ${team.shortName}';
  }

  @override
  String get imageAsset {
    if (eventData == 0) {
      return 'assets/images/pngs/yellow.png';
    } else if (eventData == 1) {
      return 'assets/images/pngs/second_yellow_red.png';
    } else {
      return 'assets/images/pngs/red.png';
    }
  }

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
      required super.eventData});
}

class Period extends GameEvent {
  GameStatus get status => GameStatus.fromString(eventData.toString());

  @override
  Widget get image {
    return const Icon(Icons.timer, size: 48, color: Colors.grey);
  }

  @override
  String get display {
    switch (status) {
      case GameStatus.notStarted:
        return '';
      case GameStatus.firstHalf:
        return 'Game Started';
      case GameStatus.halftime:
        return 'Halftime';
      case GameStatus.secondHalf:
        return '2nd Half Started';
      case GameStatus.overtimeNotStarted:
        return 'Headed to Overtime';
      case GameStatus.firstHalfOvertime:
        return 'Overtime Started';
      case GameStatus.overtimeHalftime:
        return 'Overtime Halftime';
      case GameStatus.secondHalfOvertime:
        return '2nd Half Overtime Started';
      case GameStatus.shootout:
        return 'Shootout';
      case GameStatus.gameFinal:
        return 'Game Over';
      case GameStatus.gameFinalOT:
        return 'Game Over - Overtime';
      case GameStatus.gameFinalPKs:
        return 'Game Over - PKs';
    }
  }

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
      required super.eventData});
}

class GameEvent {
  final int id;
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

  String get display {
    return eventType;
  }

  String get imageAsset {
    return 'assets/images/pngs/empty.png';
  }

  Widget get image {
    return Image.asset(imageAsset, width: 36, height: 36);
  }

  bool get shouldTweet {
    return (eventType == 'Period') ||
        ((eventType == 'Shot' || eventType == 'PenaltyKick') &&
            eventData == ShotResult.goal.index);
  }

  String tweetText(Game game) {
    if (eventType == 'Period') {
      return (this as Period).display;
    } else if ((eventType == 'Shot' || eventType == 'PenaltyKick') &&
        eventData == ShotResult.goal.index) {
      String tweetText;
      if (player != null) {
        tweetText = '($eventMinute\') Goal by ${player!.displayName}';
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
      required this.eventData});

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
        eventData: eventData);
  }

  static Future<GameEvent?> fromMap(Map<String, dynamic> map) async {
    final game = await Game.fromId(map['gameId']);
    if (game == null) {
      return null;
    }

    final team = await Team.fromId(map['teamId']);
    final player =
        await Player.singleFromIdSeasonId(map['playerId'], game.seasonId);

    final eventType = map['eventType'];
    if (eventType == 'Period') {
      return Period(
          id: map['id'],
          index: map['index'] ?? map['id'],
          player: player,
          team: team,
          game: game,
          seasonId: map['seasonId'],
          eventType: map['eventType'],
          eventMinute: map['eventMinute'],
          eventPeriod: map['eventPeriod'],
          eventUrls: map['eventUrls'],
          eventData: map['eventData']);
    } else if (eventType == 'Shot') {
      return Shot(
          id: map['id'],
          index: map['index'] ?? map['id'],
          player: player,
          team: team,
          game: game,
          seasonId: map['seasonId'],
          eventType: map['eventType'],
          eventMinute: map['eventMinute'],
          eventPeriod: map['eventPeriod'],
          eventUrls: map['eventUrls'],
          eventData: map['eventData']);
    } else if (eventType == 'Assist') {
      return Assist(
          id: map['id'],
          index: map['index'] ?? map['id'],
          player: player,
          team: team,
          game: game,
          seasonId: map['seasonId'],
          eventType: map['eventType'],
          eventMinute: map['eventMinute'],
          eventPeriod: map['eventPeriod'],
          eventUrls: map['eventUrls'],
          eventData: map['eventData']);
    } else if (eventType == 'Save') {
      return Save(
          id: map['id'],
          index: map['index'] ?? map['id'],
          player: player,
          team: team,
          game: game,
          seasonId: map['seasonId'],
          eventType: map['eventType'],
          eventMinute: map['eventMinute'],
          eventPeriod: map['eventPeriod'],
          eventUrls: map['eventUrls'],
          eventData: map['eventData']);
    } else if (eventType == 'PenaltyKick') {
      return PenaltyKick(
          id: map['id'],
          index: map['index'] ?? map['id'],
          player: player,
          team: team,
          game: game,
          seasonId: map['seasonId'],
          eventType: map['eventType'],
          eventMinute: map['eventMinute'],
          eventPeriod: map['eventPeriod'],
          eventUrls: map['eventUrls'],
          eventData: map['eventData']);
    } else if (eventType == 'Corner') {
      return Corner(
          id: map['id'],
          index: map['index'] ?? map['id'],
          player: player,
          team: team,
          game: game,
          seasonId: map['seasonId'],
          eventType: map['eventType'],
          eventMinute: map['eventMinute'],
          eventPeriod: map['eventPeriod'],
          eventUrls: map['eventUrls'],
          eventData: map['eventData']);
    } else if (eventType == 'Foul') {
      return Foul(
          id: map['id'],
          index: map['index'] ?? map['id'],
          player: player,
          team: team,
          game: game,
          seasonId: map['seasonId'],
          eventType: map['eventType'],
          eventMinute: map['eventMinute'],
          eventPeriod: map['eventPeriod'],
          eventUrls: map['eventUrls'],
          eventData: map['eventData']);
    } else if (eventType == 'Offsides') {
      return Offsides(
          id: map['id'],
          index: map['index'] ?? map['id'],
          player: player,
          team: team,
          game: game,
          seasonId: map['seasonId'],
          eventType: map['eventType'],
          eventMinute: map['eventMinute'],
          eventPeriod: map['eventPeriod'],
          eventUrls: map['eventUrls'],
          eventData: map['eventData']);
    } else if (eventType == 'Card') {
      return GameCard(
          id: map['id'],
          index: map['index'] ?? map['id'],
          player: player,
          team: team,
          game: game,
          seasonId: map['seasonId'],
          eventType: map['eventType'],
          eventMinute: map['eventMinute'],
          eventPeriod: map['eventPeriod'],
          eventUrls: map['eventUrls'],
          eventData: map['eventData']);
    }

    return GameEvent(
        id: map['id'],
        index: map['index'] ?? map['id'],
        player: player,
        team: team,
        game: game,
        seasonId: map['seasonId'],
        eventType: map['eventType'],
        eventMinute: map['eventMinute'],
        eventPeriod: map['eventPeriod'],
        eventUrls: map['eventUrls'],
        eventData: map['eventData']);
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

    final events = await Future.wait(results
        .map((g) async => await GameEvent.fromMap(g))
        .toList(growable: false));

    return events.whereType<GameEvent>().toList();
  }

  static Future<List<GameEvent>> listFromTeamId(int teamId) async {
    final results = await DatabaseService.instance
        .query('Events', orderByChild: 'teamId', equalTo: teamId);
    final events = await Future.wait(results
        .map((g) async => await GameEvent.fromMap(g))
        .toList(growable: false));
    return events.whereType<GameEvent>().toList();
  }
}
