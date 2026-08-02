import 'package:flutter/material.dart';
import 'package:team_sync/app_config.dart';
import 'package:team_sync/features/seasons/models/career_stats.dart';
import 'package:team_sync/features/game_events/models/game_event.dart';
import 'package:team_sync/features/seasons/models/season_stats.dart';

abstract class SportStrategy {
  static SportStrategy? _instance;
  static SportStrategy get current {
    if (_instance == null) {
      throw StateError(
          'SportStrategy not initialized. Call SportStrategy.initialize() first.');
    }
    return _instance!;
  }

  static void initialize(SportStrategy strategy) {
    _instance = strategy;
  }

  String get appTitle;
  Color get primaryColor;
  String get appIconAsset;
  IconData get sportIcon;
  String get sportId;
  String get webUrl;
  AppConfig get appConfig;

  // Event formatting
  String formatEventDisplay(GameEvent event);
  String getEventImageAsset(GameEvent event);
  bool isGoalEvent(GameEvent event);
  int getEventValue(GameEvent event);
  String get scoreCategory;
  String get gameTerminology;
  String get gameReportTerminology;

  // Stats
  SeasonStats createSeasonStats(
      int teamId, int seasonId, List<Map<String, dynamic>> events);

  Future<CareerStats> createCareerStats(
      int teamId, List<Map<String, dynamic>> events);

  // We'll return a list of String keys for now, or dynamic
  List<String> get leaderCategories;

  // You might want specific methods to calculate stats from a list of events
  // But for now let's focus on the display/formatting which is the most visible coupling
}
