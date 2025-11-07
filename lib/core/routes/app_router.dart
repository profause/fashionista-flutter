import 'package:fashionista/presentation/screens/auth/sign_in_screen.dart';
import 'package:fashionista/presentation/screens/clients/client_details_screen.dart';
import 'package:fashionista/presentation/screens/clients/clients_and_projects_screen.dart';
import 'package:fashionista/presentation/screens/closet/add_or_edit_closet_items_page.dart';
import 'package:fashionista/presentation/screens/closet/add_or_edit_outfit_plan_screen.dart';
import 'package:fashionista/presentation/screens/closet/add_or_edit_outfit_screen.dart';
import 'package:fashionista/presentation/screens/closet/closet_screen.dart';
import 'package:fashionista/presentation/screens/designers/designer_details_screen.dart';
import 'package:fashionista/presentation/screens/home/home_screen.dart';
import 'package:fashionista/presentation/screens/main/main_screen.dart';
import 'package:fashionista/presentation/screens/notification/notification_screen.dart';
import 'package:fashionista/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:fashionista/presentation/screens/profile/create_profile_screen.dart';
import 'package:fashionista/presentation/screens/profile/edit_profile_screen.dart';
import 'package:fashionista/presentation/screens/profile/profile_screen.dart';
import 'package:fashionista/presentation/screens/profile/user_interest_screen.dart';
import 'package:fashionista/presentation/screens/settings/settings_screen.dart';
import 'package:fashionista/presentation/screens/splash/splash_screen.dart';
import 'package:fashionista/presentation/screens/trends/add_trend_screen.dart';
import 'package:fashionista/presentation/screens/trends/trend_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

GoRouter appRouter = GoRouter(
  debugLogDiagnostics: true,
  initialLocation: '/',
  routes: [
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
        transitionDuration: Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      name: 'SignInScreen',
      path: '/sign-in',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: SignInScreen(),
        transitionsBuilder: _fadeTransition,
        transitionDuration: Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      name: 'CreateProfileScreen',
      path: '/create-profile',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: CreateProfileScreen(),
        transitionsBuilder: _fadeTransition,
        transitionDuration: Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      name: 'UserInterestScreen',
      path: '/user-interests',
      pageBuilder: (context, state) {
        final fromWhere = state.uri.queryParameters['fromwhere'];
        return CustomTransitionPage(
          child: UserInterestScreen(fromWhere: fromWhere),
          transitionsBuilder: _fadeTransition,
          transitionDuration: Duration(milliseconds: 300),
        );
      },
    ),
    GoRoute(
      name: 'NotificationScreen',
      path: '/notifications',
      builder: (context, state) => const NotificationScreen(),
    ),
    GoRoute(
      name: 'EditProfileScreen',
      path: '/edit-profile',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: EditProfileScreen(),
        transitionsBuilder: _fadeTransition,
        transitionDuration: Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      name: 'SettingsScreen',
      path: '/settings',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: SettingsScreen(),
        transitionsBuilder: _fadeTransition,
        transitionDuration: Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      name: 'AddOrEditClosetItemsPage',
      path: '/closet/add-item',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: AddOrEditClosetItemsPage(),
        transitionsBuilder: _fadeTransition,
        transitionDuration: Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      name: 'AddOrEditOutfitScreen',
      path: '/closet/add-outfit',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: AddOrEditOutfitScreen(),
        transitionsBuilder: _fadeTransition,
        transitionDuration: Duration(milliseconds: 300),
      ),
    ),

    GoRoute(
      name: 'AddOrEditOutfitPlanScreen',
      path: '/closet/outfit-planner',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: AddOrEditOutfitPlanScreen(),
        transitionsBuilder: _fadeTransition,
        transitionDuration: Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: '/trends/:id',
      name: 'TrendDetailsScreen',
      builder: (context, state) =>
          TrendDetailsScreen(trendId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/clients/:id',
      name: 'ClientDetailsScreen',
      builder: (context, state) =>
          ClientDetailsScreen(clientId: state.pathParameters['id']!),
    ),
    GoRoute(
      name: 'AddTrendScreen',
      path: '/trends-new',
      pageBuilder: (context, state) => const CustomTransitionPage(
        child: AddTrendScreen(),
        transitionsBuilder: _fadeTransition,
        transitionDuration: Duration(milliseconds: 300),
      ),
    ),
    GoRoute(
      path: '/designers/:id',
      name: 'DesignerDetailsScreen',
      builder: (context, state) =>
          DesignerDetailsScreen(designerId: state.pathParameters['id']!),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainScreen(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'HomeScreen',
              path: '/home',
              builder: (context, state) => const HomeScreen(),
              routes: [
                GoRoute(
                  name: 'TrendsScreen',
                  path: '/trends',
                  builder: (context, state) =>
                      const HomeScreen(route: '/trends'),
                ),
                GoRoute(
                  name: 'DiscoverTrendsScreen',
                  path: '/discover-trends',
                  builder: (context, state) =>
                      const HomeScreen(route: '/discover-trends'),
                ),
              ],
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              name: ' ClientsAndProjectsScreen',
              path: '/clients',
              builder: (context, state) => const ClientsAndProjectsScreen(),
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'ClosetScreen',
              path: '/closet',
              builder: (context, state) => const ClosetScreen(),
            ),
          ],
        ),

        StatefulShellBranch(
          routes: [
            GoRoute(
              name: 'ProfileScreen',
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
