import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:team_sync/models/career_stats.dart';
import 'package:team_sync/models/game.dart';
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

  Future<CareerStats?> getCareerStats(int teamId) async {
    try {
      final results = await DatabaseService.instance
          .query('Events', where: 'teamId=?', whereArgs: [teamId]);
      return CareerStats.fromMap(id, results);
    } catch (ex) {
      return null;
    }
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
