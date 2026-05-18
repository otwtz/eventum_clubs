import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/registration_screen.dart';
import '../../features/shell/shell_screen.dart';
import '../../features/home/screens/club_detail_screen.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/map/screens/map_screen.dart';
import '../../features/news/screens/news_screen.dart';
import '../../features/profile/screens/my_subscriptions_screen.dart';
import '../../features/profile/screens/profile_screen.dart';
import '../../features/coach/screens/coach_profile_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: authState.isAuthenticated ? '/news' : '/login',
    redirect: (context, state) {
      final isAuthenticated = authState.isAuthenticated;
      final location = state.matchedLocation;
      final isAuthScreen = location == '/login' || location == '/registration';

      if (!isAuthenticated && !isAuthScreen) {
        return '/login';
      }
      if (isAuthenticated && isAuthScreen) {
        return '/news';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/registration',
        builder: (context, state) => const RegistrationScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => ShellScreen(child: child),
        routes: [
          GoRoute(
            path: '/club/:id',
            builder: (context, state) => ClubDetailScreen(
              clubId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/news',
            builder: (context, state) => const NewsScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/profile/subscriptions',
            builder: (context, state) => const MySubscriptionsScreen(),
          ),
          GoRoute(
            path: '/profile/coach',
            builder: (context, state) => const CoachProfileScreen(),
          ),
        ],
      ),
    ],
  );
});
