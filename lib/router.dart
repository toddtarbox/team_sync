import 'package:go_router/go_router.dart';
import 'package:team_sync/widgets/home_page.dart';

final router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/:databaseId',
      builder: (context, state) =>
          HomePage(databaseId: state.pathParameters['databaseId']!),
    ),
  ],
);
