import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/debug_migration_page.dart';
import 'package:team_sync/widgets/home_page.dart';
import 'package:team_sync/widgets/players_page.dart';
import 'package:team_sync/widgets/responsive/mobile/mobile_game_page.dart';
import 'package:team_sync/widgets/responsive/tablet/tablet_game_page.dart';
import 'package:team_sync/widgets/season_page.dart';
import 'package:team_sync/widgets/season_stats_page.dart';
import 'package:team_sync/widgets/settings_page.dart';
import 'package:team_sync/widgets/sign_in_page.dart';

/// Router for TeamSync app with distinct URLs for each page
///
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
      builder: (context, state) => const HomePage(),
    ),

    // Specific team by database ID (shared public ID)
    GoRoute(
      path: '/team/:databaseId',
      name: 'team',
      builder: (context, state) {
        final databaseId = state.pathParameters['databaseId']!;
        return HomePage(databaseId: databaseId);
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

            return FutureBuilder<Season?>(
              future: _loadSeasonById(seasonId),
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

                return FutureBuilder<Season?>(
                  future: _loadSeasonById(seasonId),
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

                return FutureBuilder<Season?>(
                  future: _loadSeasonById(seasonId),
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

                return FutureBuilder<Map<String, dynamic>?>(
                  future: _loadSeasonAndGame(seasonId, gameId),
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
      ],
    ),

    // Team by numeric ID with nested season routes
    GoRoute(
      path: '/team/id/:teamId',
      name: 'team-id',
      builder: (context, state) {
        final teamId = int.tryParse(state.pathParameters['teamId']!);
        return HomePage(teamId: teamId);
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

            return FutureBuilder<Season?>(
              future: _loadSeasonById(seasonId),
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

                return FutureBuilder<Season?>(
                  future: _loadSeasonById(seasonId),
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

                return FutureBuilder<Season?>(
                  future: _loadSeasonById(seasonId),
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

                return FutureBuilder<Map<String, dynamic>?>(
                  future: _loadSeasonAndGame(seasonId, gameId),
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
