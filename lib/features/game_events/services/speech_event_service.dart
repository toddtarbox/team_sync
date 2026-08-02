import 'package:flutter/foundation.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:team_sync/features/games/models/game.dart';
import 'package:team_sync/features/game_events/models/game_event.dart';
import 'package:team_sync/features/players/models/player.dart';

class SpeechEventService {
  static final SpeechEventService instance = SpeechEventService._internal();
  SpeechEventService._internal();

  final SpeechToText _speechToText = SpeechToText();
  bool _isInitialized = false;

  Future<bool> initialize() async {
    if (_isInitialized) return true;
    try {
      _isInitialized = await _speechToText.initialize();
      return _isInitialized;
    } catch (e) {
      debugPrint('Error initializing speech recognition: $e');
      return false;
    }
  }

  void stopListening() {
    if (_speechToText.isListening) {
      _speechToText.stop();
    }
  }

  Future<void> startListening({
    required Function(String text, bool isFinal) onResult,
    required Function(String error) onError,
  }) async {
    if (!await initialize()) {
      onError('Speech recognition could not be initialized.');
      return;
    }

    if (_speechToText.isListening) {
      _speechToText.stop();
    }

    await _speechToText.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenFor: const Duration(seconds: 15),
      pauseFor: const Duration(seconds: 3),
      listenOptions: SpeechListenOptions(
        cancelOnError: true,
        listenMode: ListenMode.dictation,
      ),
    );
  }

  /// Parses the transcript to create an initial GameEvent.
  /// Matches events by keywords and players by name/number comparison.
  Future<GameEvent?> parseEventTranscript(
    String transcript, 
    Game game, 
    int seasonId, {
    List<Player>? testHomePlayers,
    List<Player>? testAwayPlayers,
  }) async {
    final text = transcript.toLowerCase();

    // 1. Identify Event Type
    String eventType = 'Shot';
    int eventData = 0; // Default Goal

    if (text.contains('goal') || text.contains('score')) {
      eventType = 'Shot';
      eventData = 0; // ShotResult.goal.index
    } else if (text.contains('save')) {
      eventType = 'Save';
    } else if (text.contains('foul')) {
      eventType = 'Foul';
    } else if (text.contains('assist')) {
      eventType = 'Assist';
    } else if (text.contains('yellow')) {
      eventType = 'Card';
      eventData = 1; // Yellow
    } else if (text.contains('red')) {
      eventType = 'Card';
      eventData = 2; // Red
    } else if (text.contains('corner')) {
      eventType = 'Corner';
    } else if (text.contains('offside')) {
      eventType = 'Offsides';
    } else if (text.contains('shot')) {
      eventType = 'Shot';
      eventData = 3; // Off Target by default, user can correct it
      if (text.contains('post')) eventData = 2;
      if (text.contains('block')) eventData = 4;
      if (text.contains('save')) eventData = 1;
    } else {
      // If we can't identify the event, we fail early to not create junk
      return null;
    }

    // 2. Identify Player Name/Team
    Player? matchedPlayer;
    var matchedTeam = game.homeTeam; // Default to home team if unknown

    try {
      final homePlayers = testHomePlayers ?? await Player.listFromTeamIdSeasonId(game.homeTeam.id, seasonId);
      final awayPlayers = testAwayPlayers ?? await Player.listFromTeamIdSeasonId(game.awayTeam.id, seasonId);

      final combinedPlayers = [
        ...homePlayers.map((p) => {'player': p, 'team': game.homeTeam}),
        ...awayPlayers.map((p) => {'player': p, 'team': game.awayTeam}),
      ];

      // Score matches
      int bestScore = -1;
      Map<String, dynamic>? bestMatch;

      for (var entry in combinedPlayers) {
        final player = entry['player'] as Player;
        int score = 0;
        final fName = player.firstName.toLowerCase();
        final lName = player.lastName.toLowerCase();
        final fullName = '$fName $lName';

        // Direct full name match
        if (text.contains(fullName)) score += 10;
        // Direct individual name matches
        if (fName.isNotEmpty && text.contains(RegExp('\\b$fName\\b'))) score += 3;
        if (lName.isNotEmpty && text.contains(RegExp('\\b$lName\\b'))) score += 3;

        // Try number fallback 
        if (player.number > -1) {
          final numStr = player.number.toString();
          final numWord = _numberToWord(player.number);
          
          if (text.contains(RegExp('\\b$numStr\\b')) || text.contains(RegExp('\\b$numWord\\b'))) {
            score += 4;
          }
        }

        if (score > bestScore && score > 0) {
          bestScore = score;
          bestMatch = entry;
        }
      }

      if (bestMatch != null) {
        matchedPlayer = bestMatch['player'] as Player;
        matchedTeam = bestMatch['team']; // Type is Team
      } else {
        // Just try to identify team if no player found
        if (text.contains('opponent') || 
            text.contains(game.awayTeam.fullName.toLowerCase()) || 
            text.contains(game.awayTeam.shortName.toLowerCase())) {
          matchedTeam = game.awayTeam;
        } else if (text.contains(game.homeTeam.fullName.toLowerCase()) || 
                   text.contains(game.homeTeam.shortName.toLowerCase())) {
          matchedTeam = game.homeTeam;
        }
      }
    } catch (e) {
      debugPrint('Speech parser failed to fetch players: $e');
    }

    // Build the initial event object
    final event = GameEvent.initial(
      team: matchedTeam,
      game: game,
      seasonId: seasonId,
      eventType: eventType,
      eventMinute: -1, // Unassigned, modal will try to calculate or prompt
      eventPeriod: -1, // Will be filled dynamically by GameView modal
      eventUrls: '',
      eventData: eventData,
    );

    if (matchedPlayer != null) {
       event.player = matchedPlayer;
    }

    return event;
  }

  String _numberToWord(int n) {
    if (n < 0 || n > 99) return n.toString();
    const ones = ['zero', 'one', 'two', 'three', 'four', 'five', 'six', 'seven', 'eight', 'nine', 'ten', 'eleven', 'twelve', 'thirteen', 'fourteen', 'fifteen', 'sixteen', 'seventeen', 'eighteen', 'nineteen'];
    const tens = ['', '', 'twenty', 'thirty', 'forty', 'fifty', 'sixty', 'seventy', 'eighty', 'ninety'];
    if (n < 20) return ones[n];
    if (n % 10 == 0) return tens[n ~/ 10];
    return '${tens[n ~/ 10]} ${ones[n % 10]}';
  }
}
