import 'package:go_router/go_router.dart';
import 'package:team_sync/models/club.dart';
import 'package:team_sync/widgets/club_home_page.dart';
import 'package:team_sync/widgets/home_page.dart';
import 'package:team_sync/widgets/settings_page.dart';
import 'package:team_sync/widgets/sign_in_page.dart';

/// Router for ClubSync app with distinct URLs for each page
///
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

    // Team within club - will load club data in the page
    GoRoute(
      path: '/club/:clubId/team/:teamId',
      name: 'club-team',
      builder: (context, state) {
        final clubId = int.tryParse(state.pathParameters['clubId']!);
        final teamId = int.tryParse(state.pathParameters['teamId']!);

        // HomePage needs the club object to open the club team context
        // We'll use extra parameter to pass the club, or load it if needed
        final club = state.extra as Club?;

        return HomePage(
          teamId: teamId,
          club: club,
          clubId: clubId,
        );
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
