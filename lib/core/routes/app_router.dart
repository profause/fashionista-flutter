import 'package:fashionista/presentation/screens/auth/sign_in_screen.dart';
import 'package:fashionista/presentation/screens/clients/clients_and_projects_screen.dart';
import 'package:fashionista/presentation/screens/closet/closet_screen.dart';
import 'package:fashionista/presentation/screens/home/home_screen.dart';
import 'package:fashionista/presentation/screens/main/main_screen.dart';
import 'package:fashionista/presentation/screens/notification/notification_screen.dart';
import 'package:fashionista/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:fashionista/presentation/screens/profile/create_profile_screen.dart';
import 'package:fashionista/presentation/screens/profile/profile_screen.dart';
import 'package:fashionista/presentation/screens/splash/splash_screen.dart';
import 'package:fashionista/presentation/screens/trends/discover_trends_screen.dart';
import 'package:fashionista/presentation/screens/trends/trends_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppRouter {
  static final router = GoRouter(
    //refreshListenable: loginState,
    // 4
    debugLogDiagnostics: true,
    initialLocation: '/',
    // 5
    routes: <RouteBase>[
      GoRoute(
        name: 'SplashScreen',
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),

      GoRoute(
        name: 'OnboardingScreen',
        path: '/onboarding',
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: OnboardingScreen(),
          transitionsBuilder: _fadeTransition,
          transitionDuration: Duration(milliseconds: 800),
        ),
      ),

      GoRoute(
        name: 'SignInScreen',
        path: '/sign-in',
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: SignInScreen(),
          transitionsBuilder: _fadeTransition,
          transitionDuration: Duration(milliseconds: 800),
        ),
      ),

      GoRoute(
        name: 'CreateProfileScreen',
        path: '/create-profile',
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: CreateProfileScreen(),
          transitionsBuilder: _fadeTransition,
          transitionDuration: Duration(milliseconds: 800),
        ),
      ),

      GoRoute(
        name: 'MainScreen',
        path: '/main',
        routes: [
          GoRoute(
            name: 'HomeScreen',
            path: 'home',
            builder: (context, state) => const HomeScreen(),
            routes: [
              GoRoute(
                name: 'TrendsScreen',
                path: 'trends',
                builder: (context, state) => const TrendsScreen(),
              ),
              GoRoute(
                name: 'DiscoverTrendsScreen',
                path: 'discover-trends',
                builder: (context, state) => const DiscoverTrendsScreen(),
              ),
              GoRoute(
                name: 'NotificationScreen',
                path: 'notifications',
                builder: (context, state) => const NotificationScreen(),
              ),
            ],
          ),
          GoRoute(
            name: 'ClientsAndProjectsScreen',
            path: 'clients',
            builder: (context, state) => const ClientsAndProjectsScreen(),
          ),
          GoRoute(
            name: 'ClosetScreen',
            path: 'closet',
            builder: (context, state) => const ClosetScreen(),
          ),
          GoRoute(
            name: 'ProfileScreen',
            path: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
        pageBuilder: (context, state) => const CustomTransitionPage(
          child: MainScreen(),
          transitionsBuilder: _fadeTransition,
          transitionDuration: Duration(milliseconds: 800),
        ),
      ),
    ],
  );
}

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}
