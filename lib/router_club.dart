import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:team_sync/models/club.dart';
import 'package:team_sync/models/game.dart';
import 'package:team_sync/models/player.dart';
import 'package:team_sync/models/season.dart';
import 'package:team_sync/services/database_service.dart';
import 'package:team_sync/widgets/club_home_page.dart';
import 'package:team_sync/widgets/club_stats_page.dart';
import 'package:team_sync/widgets/home_page.dart';
import 'package:team_sync/widgets/player_profile_page.dart';
import 'package:team_sync/widgets/players_page.dart';
import 'package:team_sync/widgets/responsive/mobile/mobile_game_page.dart';
import 'package:team_sync/widgets/responsive/tablet/tablet_game_page.dart';
import 'package:team_sync/widgets/season_page.dart';
import 'package:team_sync/widgets/season_stats_page.dart';
import 'package:team_sync/widgets/settings_page.dart';
import 'package:team_sync/widgets/sign_in_page.dart';

/// Router for ClubSync app with distinct URLs for each page
///
/// ClubSync supports multi-team club management with admin controls and mobile stat entry.
/// Pages handle their own data loading using FutureBuilder internally.
/// The router only provides IDs via path parameters.
final routerClub = GoRouter(
  initialLocation: '/',
  routes: [
    // ==================== CLUB ROUTES ====================

    // Root - Club selection
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const ClubHomePage(),
    ),

    // Specific club by ID
    GoRoute(
      path: '/club/:clubId',
      name: 'club',
      builder: (context, state) {
        final clubId = state.pathParameters['clubId']!;
        return ClubHomePage(clubId: clubId);
      },
    ),

    // Team within club - loads team view with club context
    GoRoute(
      path: '/club/:clubId/team/:teamId',
      name: 'club-team',
      builder: (context, state) {
        final clubId = int.tryParse(state.pathParameters['clubId']!);
        final teamId = int.tryParse(state.pathParameters['teamId']!);
        final club = state.extra as Club?;

        return HomePage(
          teamId: teamId,
          club: club,
          clubId: clubId,
        );
      },
      routes: [
        // Season page within club team
        GoRoute(
          path: 'season/:seasonId',
          name: 'club-team-season',
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
            // Season stats
            GoRoute(
              path: 'stats',
              name: 'club-team-season-stats',
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
              name: 'club-team-season-players',
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
              routes: [
                // Player profile
                GoRoute(
                  path: ':playerId',
                  name: 'club-team-player-profile',
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
                      future: _loadPlayerAndSeason(seasonId, playerId),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          final loadedPlayer =
                              snapshot.data!['player'] as Player;
                          final loadedSeason =
                              snapshot.data!['season'] as Season;
                          return PlayerProfilePage(
                            player: loadedPlayer,
                            currentSeason: loadedSeason,
                          );
                        } else if (snapshot.hasError) {
                          return Scaffold(
                            appBar: AppBar(title: const Text('Error')),
                            body: Center(
                                child: Text(
                                    'Error loading player: ${snapshot.error}')),
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

            // Game page
            GoRoute(
              path: 'game/:gameId',
              name: 'club-team-game',
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

    // Club stats page
    GoRoute(
      path: '/club/:clubId/stats',
      name: 'club-stats',
      builder: (context, state) {
        final clubId = int.parse(state.pathParameters['clubId']!);
        final club = state.extra as Club?;

        if (club != null) {
          return ClubStatsPage(club: club);
        }

        // Load club if not passed
        return FutureBuilder<Club?>(
          future: Club.fromId(clubId),
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data != null) {
              return ClubStatsPage(club: snapshot.data!);
            } else if (snapshot.hasError) {
              return Scaffold(
                appBar: AppBar(title: const Text('Error')),
                body: Center(
                    child: Text('Error loading club: ${snapshot.error}')),
              );
            }
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          },
        );
      },
    ),

    // Club settings page
    GoRoute(
      path: '/club/:clubId/settings',
      name: 'club-settings',
      builder: (context, state) {
        final club = state.extra as Club?;
        return SettingsPage(team: null, club: club);
      },
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

// Helper function to load player and season
Future<Map<String, dynamic>?> _loadPlayerAndSeason(
    int seasonId, int playerId) async {
  try {
    final season = await _loadSeasonById(seasonId);
    if (season == null) return null;

    final player = season.players.firstWhere((p) => p.id == playerId);
    return {'season': season, 'player': player};
  } catch (e) {
    return null;
  }
}
