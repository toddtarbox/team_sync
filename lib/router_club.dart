import 'package:go_router/go_router.dart';
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
        final teamId = int.tryParse(state.pathParameters['teamId']!);
        // HomePage will load the club data internally based on the team's clubId
        return HomePage(teamId: teamId);
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
