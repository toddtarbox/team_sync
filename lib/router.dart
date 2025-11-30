import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:team_sync/l10n/app_localizations.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/models/team.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/data_import_page.dart';
import 'package:team_sync/widgets/debug_migration_page.dart';
import 'package:team_sync/widgets/history_versus_page.dart';
import 'package:team_sync/widgets/player_profile_page.dart';
import 'package:team_sync/widgets/players_page.dart';
import 'package:team_sync/widgets/record_holders_page.dart';
import 'package:team_sync/widgets/responsive/mobile/mobile_game_page.dart';
import 'package:team_sync/widgets/responsive/tablet/tablet_game_page.dart';
import 'package:team_sync/widgets/season_page.dart';
import 'package:team_sync/widgets/season_stats_page.dart';
import 'package:team_sync/widgets/settings_page.dart';
import 'package:team_sync/widgets/sign_in_page.dart';
import 'package:team_sync/widgets/team_sync/team_home_page.dart';

/// Router for TeamSync app with distinct URLs for each page
///
/// TeamSync is designed for single-team management with subscription-based data storage.
/// Pages handle their own data loading using FutureBuilder internally.
/// The router only provides IDs via path parameters.
final router = GoRouter(
  initialLocation: '/',
  routes: [
    // ==================== TEAM ROUTES ====================

    // Root - Team home (default team or selection)
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const TeamHomePage(),
    ),

    // Specific team by database ID (shared public ID)
    GoRoute(
      path: '/team/:databaseId',
      name: 'team',
      builder: (context, state) {
        final databaseId = state.pathParameters['databaseId']!;
        return TeamHomePage(databaseId: databaseId);
      },
      routes: [
        // ==================== SEASON ROUTES (nested under team) ====================

        // Season page
        GoRoute(
          path: 'season/:seasonId',
          name: 'season',
          builder: (context, state) {
            final seasonId = int.parse(state.pathParameters['seasonId']!);
            final season = state.extra as Season?;

            if (season != null) {
              return SeasonPage(season: season);
            }

            // Build a future that opens the shared DB from the route parameter if present,
            // then loads the season by id. This avoids relying on Uri.base parsing here.
            final databaseId = state.pathParameters['databaseId'];
            final future = () async {
              if (databaseId != null) {
                try {
                  await DatabaseService.instance
                      .openFromId(databaseId)
                      .timeout(const Duration(seconds: 10));
                } catch (e) {
                  debugPrint('Router: failed to open DB $databaseId: $e');
                }
              }
              return await _loadSeasonById(seasonId);
            }();

            return FutureBuilder<Season?>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return SeasonPage(season: snapshot.data!);
                } else if (snapshot.hasError) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Error')),
                    body: Center(
                        child: Text('Error loading season: ${snapshot.error}')),
                  );
                }
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              },
            );
          },
          routes: [
            // Season stats page
            GoRoute(
              path: 'stats',
              name: 'season-stats',
              builder: (context, state) {
                final seasonId = int.parse(state.pathParameters['seasonId']!);
                final season = state.extra as Season?;

                if (season != null) {
                  return SeasonStatsPage(season: season);
                }

                // Open the database first if we have a databaseId, then load the season
                final databaseId = state.pathParameters['databaseId'];
                final future = () async {
                  if (databaseId != null) {
                    try {
                      await DatabaseService.instance
                          .openFromId(databaseId)
                          .timeout(const Duration(seconds: 10));
                    } catch (e) {
                      debugPrint('Router: failed to open DB $databaseId: $e');
                    }
                  }
                  return await _loadSeasonById(seasonId);
                }();

                return FutureBuilder<Season?>(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return SeasonStatsPage(season: snapshot.data!);
                    } else if (snapshot.hasError) {
                      return Scaffold(
                        appBar: AppBar(title: const Text('Error')),
                        body: Center(
                            child: Text(
                                'Error loading season: ${snapshot.error}')),
                      );
                    }
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  },
                );
              },
            ),

            // Players page
            GoRoute(
              path: 'players',
              name: 'season-players',
              builder: (context, state) {
                final seasonId = int.parse(state.pathParameters['seasonId']!);
                final season = state.extra as Season?;

                if (season != null) {
                  return PlayersPage(season: season);
                }

                // Open the database first if we have a databaseId, then load the season
                final databaseId = state.pathParameters['databaseId'];
                final future = () async {
                  if (databaseId != null) {
                    try {
                      await DatabaseService.instance
                          .openFromId(databaseId)
                          .timeout(const Duration(seconds: 10));
                    } catch (e) {
                      debugPrint('Router: failed to open DB $databaseId: $e');
                    }
                  }
                  return await _loadSeasonById(seasonId);
                }();

                return FutureBuilder<Season?>(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      return PlayersPage(season: snapshot.data!);
                    } else if (snapshot.hasError) {
                      return Scaffold(
                        appBar: AppBar(title: const Text('Error')),
                        body: Center(
                            child: Text(
                                'Error loading season: ${snapshot.error}')),
                      );
                    }
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  },
                );
              },
              routes: [
                // Player profile page
                GoRoute(
                  path: ':playerId',
                  name: 'player-profile',
                  builder: (context, state) {
                    final seasonId =
                        int.parse(state.pathParameters['seasonId']!);
                    final playerId =
                        int.parse(state.pathParameters['playerId']!);
                    final extras = state.extra as Map<String, dynamic>?;
                    final player = extras?['player'] as Player?;
                    final season = extras?['season'] as Season?;

                    if (player != null && season != null) {
                      return PlayerProfilePage(
                        player: player,
                        currentSeason: season,
                      );
                    }

                    return FutureBuilder<Map<String, dynamic>?>(
                      future: _loadPlayerAndSeason(seasonId, playerId,
                          state.pathParameters['databaseId']),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Scaffold(
                            body: Center(child: CircularProgressIndicator()),
                          );
                        }

                        if (snapshot.hasError) {
                          return Scaffold(
                            appBar: AppBar(title: const Text('Error')),
                            body: Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline,
                                        size: 48, color: Colors.red),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Error loading player',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${snapshot.error}',
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasData && snapshot.data != null) {
                          final loadedPlayer =
                              snapshot.data!['player'] as Player;
                          final loadedSeason =
                              snapshot.data!['season'] as Season;
                          return PlayerProfilePage(
                            player: loadedPlayer,
                            currentSeason: loadedSeason,
                          );
                        }

                        // Should not reach here, but handle gracefully
                        final loc = AppLocalizations.of(context)!;
                        return Scaffold(
                          appBar: AppBar(title: const Text('Error')),
                          body: Center(
                            child: Text(loc.playerNotFound),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),

            // Game page
            GoRoute(
              path: 'game/:gameId',
              name: 'game',
              builder: (context, state) {
                final seasonId = int.parse(state.pathParameters['seasonId']!);
                final gameId = int.parse(state.pathParameters['gameId']!);
                final extras = state.extra as Map<String, dynamic>?;
                final season = extras?['season'] as Season?;
                final game = extras?['game'] as Game?;

                if (season != null && game != null) {
                  if (ResponsiveBreakpoints.of(context).largerThan(MOBILE)) {
                    return TabletGamePage(season: season, game: game);
                  } else {
                    return MobileGamePage(season: season, game: game);
                  }
                }

                final databaseId = state.pathParameters['databaseId'];
                final future = () async {
                  if (databaseId != null) {
                    try {
                      await DatabaseService.instance
                          .openFromId(databaseId)
                          .timeout(const Duration(seconds: 10));
                    } catch (e) {
                      debugPrint('Router: failed to open DB $databaseId: $e');
                    }
                  }
                  return await _loadSeasonAndGame(seasonId, gameId);
                }();

                return FutureBuilder<Map<String, dynamic>?>(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final loadedSeason = snapshot.data!['season'] as Season;
                      final loadedGame = snapshot.data!['game'] as Game;
                      if (ResponsiveBreakpoints.of(context)
                          .largerThan(MOBILE)) {
                        return TabletGamePage(
                            season: loadedSeason, game: loadedGame);
                      } else {
                        return MobileGamePage(
                            season: loadedSeason, game: loadedGame);
                      }
                    } else if (snapshot.hasError) {
                      return Scaffold(
                        appBar: AppBar(title: const Text('Error')),
                        body: Center(
                            child:
                                Text('Error loading game: ${snapshot.error}')),
                      );
                    }
                    return const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  },
                );
              },
            ),
          ],
        ),

        // ==================== TEAM STATS ROUTES ====================

        // History versus page
        GoRoute(
          path: 'history',
          name: 'history-versus',
          builder: (context, state) {
            final team = state.extra as Team?;

            if (team != null) {
              return HistoryVersusPage(team: team);
            }

            return FutureBuilder<Team?>(
              future:
                  _loadTeamByDatabaseId(state.pathParameters['databaseId']!),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return HistoryVersusPage(team: snapshot.data!);
                } else if (snapshot.hasError) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Error')),
                    body: Center(
                        child: Text('Error loading team: ${snapshot.error}')),
                  );
                }
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              },
            );
          },
        ),

        // Record holders page
        GoRoute(
          path: 'records',
          name: 'record-holders',
          builder: (context, state) {
            final team = state.extra as Team?;

            if (team != null) {
              return RecordHoldersPage(team: team);
            }

            return FutureBuilder<Team?>(
              future:
                  _loadTeamByDatabaseId(state.pathParameters['databaseId']!),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return RecordHoldersPage(team: snapshot.data!);
                } else if (snapshot.hasError) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Error')),
                    body: Center(
                        child: Text('Error loading team: ${snapshot.error}')),
                  );
                }
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              },
            );
          },
        ),

        // Team settings page
        GoRoute(
          path: 'settings',
          name: 'team-settings',
          builder: (context, state) {
            final team = state.extra as Team?;

            if (team != null) {
              return SettingsPage(team: team, club: null);
            }

            return FutureBuilder<Team?>(
              future:
                  _loadTeamByDatabaseId(state.pathParameters['databaseId']!),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  return SettingsPage(team: snapshot.data!, club: null);
                } else if (snapshot.hasError) {
                  return Scaffold(
                    appBar: AppBar(title: const Text('Error')),
                    body: Center(
                        child: Text('Error loading team: ${snapshot.error}')),
                  );
                }
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              },
            );
          },
        ),
      ],
    ),

    // ==================== AUTH & UTILITY ROUTES ====================

    GoRoute(
      path: '/signin',
      name: 'signin',
      builder: (context, state) => const SignInPage(),
    ),

    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => SettingsPage(team: null, club: null),
    ),

    GoRoute(
      path: '/import',
      name: 'import',
      builder: (context, state) => const DataImportPage(),
    ),

    GoRoute(
      path: '/debug-migration',
      name: 'debug-migration',
      builder: (context, state) => const DebugMigrationPage(),
    ),

    // ==================== LEGACY URL REDIRECT ====================

    // Redirect old URL format (/:databaseId) to new format (/team/:databaseId)
    // This is placed last to act as a catch-all for old shared URLs
    GoRoute(
      path: '/:databaseId',
      redirect: (context, state) {
        final databaseId = state.pathParameters['databaseId'];
        // Redirect if it looks like a database ID (6 digits numeric)
        if (databaseId != null &&
            databaseId.length == 6 &&
            int.tryParse(databaseId) != null) {
          return '/team/$databaseId';
        }
        // If not a database ID format, return null to show 404
        return null;
      },
    ),
  ],
);

// Helper function to load season by ID
Future<Season?> _loadSeasonById(int seasonId) async {
  try {
    final results = await DatabaseService.instance
        .query('Seasons', orderByChild: 'id', equalTo: seasonId);
    if (results.isEmpty) return null;
    final season = Season.fromMap(results.first);
    await season.load();
    return season;
  } catch (e) {
    return null;
  }
}

// Helper function to load both season and game
Future<Map<String, dynamic>?> _loadSeasonAndGame(
    int seasonId, int gameId) async {
  try {
    final season = await _loadSeasonById(seasonId);
    if (season == null) return null;

    final game = season.games.firstWhere((g) => g.id == gameId);
    return {'season': season, 'game': game};
  } catch (e) {
    return null;
  }
}

// Helper function to load team by database ID
Future<Team?> _loadTeamByDatabaseId(String databaseId) async {
  try {
    final opened = await DatabaseService.instance.openFromId(databaseId);
    if (!opened) return null;

    final teamResult =
        await DatabaseService.instance.query('Teams', orderByChild: 'id');
    if (teamResult.isEmpty) return null;

    // Try team with id=1 first
    var teamMap = teamResult.firstWhere(
      (t) => t['id'] == 1,
      orElse: () => teamResult.first,
    );

    final team = Team.fromMap(teamMap);

    // If no seasons for this team, find the team that has seasons
    final allSeasons =
        await DatabaseService.instance.query('Seasons', orderByChild: 'teamId');

    if (allSeasons.isNotEmpty) {
      final targetTeamId = allSeasons.first['teamId'];
      teamMap = teamResult.firstWhere(
        (t) => t['id'] == targetTeamId,
        orElse: () => teamResult.first,
      );
      return Team.fromMap(teamMap);
    }

    return team;
  } catch (e) {
    return null;
  }
}

// Helper function to load player and season data
Future<Map<String, dynamic>?> _loadPlayerAndSeason(
    int seasonId, int playerId, String? databaseId) async {
  try {
    // Open the database if databaseId is provided
    if (databaseId != null) {
      final opened = await DatabaseService.instance.openFromId(databaseId);
      if (!opened) {
        throw Exception('Failed to open database: $databaseId');
      }
    }

    final season = await _loadSeasonById(seasonId);
    if (season == null) {
      throw Exception('Season not found: $seasonId');
    }

    // Try to find player in season's player list
    Player? player;
    try {
      player = season.players.firstWhere((p) => p.id == playerId);
    } catch (e) {
      // Player not in season's player list, load directly from database
      final playerResults = await DatabaseService.instance
          .query('Players', orderByChild: 'id', equalTo: playerId);

      if (playerResults.isEmpty) {
        throw Exception('Player not found: $playerId');
      }

      player = Player.fromMap(playerResults.first);
    }

    return {'season': season, 'player': player};
  } catch (e) {
    debugPrint('Error loading player and season: $e');
    rethrow; // Re-throw so FutureBuilder can catch it as an error
  }
}
