import 'package:flutter_test/flutter_test.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/speech_event_service.dart';

void main() {
  group('SpeechEventService.parseEventTranscript', () {
    late Game mockGame;
    late List<Player> homePlayers;
    late List<Player> awayPlayers;

    setUp(() {
      final homeTeam = Team(id: 1, fullName: 'Home Team', shortName: 'Home');
      final awayTeam = Team(id: 2, fullName: 'Away Team', shortName: 'Away');

      mockGame = Game.initial(
        seasonId: 1,
        homeTeam: homeTeam,
        awayTeam: awayTeam,
      );

      homePlayers = [
        Player(id: 10, teamId: 1, seasonId: 1, firstName: 'Todd', lastName: 'Tarbox', number: 5),
        Player(id: 11, teamId: 1, seasonId: 1, firstName: 'John', lastName: 'Smith', number: 10),
        Player(id: 12, teamId: 1, seasonId: 1, firstName: 'Lionel', lastName: 'Messi', number: 10),
      ];

      awayPlayers = [
        Player(id: 20, teamId: 2, seasonId: 1, firstName: 'Cristiano', lastName: 'Ronaldo', number: 7),
      ];
    });

    test('should match player by full name', () async {
      final event = await SpeechEventService.instance.parseEventTranscript(
        'goal by Todd Tarbox',
        mockGame,
        1,
        testHomePlayers: homePlayers,
        testAwayPlayers: awayPlayers,
      );

      expect(event, isNotNull);
      expect(event!.eventType, 'Shot');
      expect(event.eventData, 0); // Goal
      expect(event.player, isNotNull);
      expect(event.player!.id, 10);
      expect(event.team.id, 1);
    });

    test('should match player by first name only', () async {
      final event = await SpeechEventService.instance.parseEventTranscript(
        'foul on Todd',
        mockGame,
        1,
        testHomePlayers: homePlayers,
        testAwayPlayers: awayPlayers,
      );

      expect(event, isNotNull);
      expect(event!.eventType, 'Foul');
      expect(event.player, isNotNull);
      expect(event.player!.id, 10);
      expect(event.team.id, 1);
    });

    test('should match player by last name only', () async {
      final event = await SpeechEventService.instance.parseEventTranscript(
        'save by Tarbox',
        mockGame,
        1,
        testHomePlayers: homePlayers,
        testAwayPlayers: awayPlayers,
      );

      expect(event, isNotNull);
      expect(event!.eventType, 'Save');
      expect(event.player, isNotNull);
      expect(event.player!.id, 10);
      expect(event.team.id, 1);
    });

    test('should match player by number', () async {
      final event = await SpeechEventService.instance.parseEventTranscript(
        'goal number five',
        mockGame,
        1,
        testHomePlayers: homePlayers,
        testAwayPlayers: awayPlayers,
      );

      expect(event, isNotNull);
      expect(event!.eventType, 'Shot');
      expect(event.player, isNotNull);
      expect(event.player!.id, 10);
      expect(event.team.id, 1);
    });
    
    test('should match away player by name', () async {
      final event = await SpeechEventService.instance.parseEventTranscript(
        'yellow card Cristiano',
        mockGame,
        1,
        testHomePlayers: homePlayers,
        testAwayPlayers: awayPlayers,
      );

      expect(event, isNotNull);
      expect(event!.eventType, 'Card');
      expect(event.eventData, 1);
      expect(event.player, isNotNull);
      expect(event.player!.id, 20);
      expect(event.team.id, 2);
    });
    
    test('should correctly handle no player found', () async {
      final event = await SpeechEventService.instance.parseEventTranscript(
        'goal', // Just goal, no name
        mockGame,
        1,
        testHomePlayers: homePlayers,
        testAwayPlayers: awayPlayers,
      );

      expect(event, isNotNull);
      // No player explicitly defined in the speech text
      expect(event!.player, isNull);
    });

  });
}
