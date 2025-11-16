import 'package:team_sync/services/database_service.dart';

/// Independent highlight not tied to a game event
class PlayerHighlight {
  final int id;
  final int playerId;
  final String title;
  final String? description;
  final String videoUrl;
  final DateTime date;

  PlayerHighlight({
    required this.id,
    required this.playerId,
    required this.title,
    this.description,
    required this.videoUrl,
    required this.date,
  });

  factory PlayerHighlight.fromMap(Map<String, dynamic> map) {
    return PlayerHighlight(
      id: map['id'],
      playerId: map['playerId'],
      title: map['title'],
      description: map['description'],
      videoUrl: map['videoUrl'],
      date: DateTime.parse(map['date']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'playerId': playerId,
      'title': title,
      'description': description,
      'videoUrl': videoUrl,
      'date': date.toIso8601String(),
    };
  }

  static Future<List<PlayerHighlight>> listFromPlayerId(int playerId) async {
    final results = await DatabaseService.instance
        .query('PlayerHighlights', orderByChild: 'playerId', equalTo: playerId);
    final highlights = results.map((h) => PlayerHighlight.fromMap(h)).toList();
    highlights.sort((a, b) => b.date.compareTo(a.date)); // Most recent first
    return highlights;
  }

  Future<void> save() async {
    await DatabaseService.instance.insert(
      'PlayerHighlights',
      toMap(),
      key: id.toString(),
    );
  }

  Future<void> delete() async {
    await DatabaseService.instance.delete(
      'PlayerHighlights',
      key: id.toString(),
    );
  }
}
