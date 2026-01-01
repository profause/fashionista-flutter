import 'package:fashionista/presentation/screens/auth/sign_in_screen.dart';
import 'package:fashionista/presentation/screens/clients/add_client_screen.dart';
import 'package:fashionista/presentation/screens/clients/client_details_screen.dart';
import 'package:fashionista/presentation/screens/clients/clients_and_projects_screen.dart';
import 'package:fashionista/presentation/screens/closet/add_or_edit_closet_items_page.dart';
import 'package:fashionista/presentation/screens/closet/add_or_edit_outfit_plan_screen.dart';
import 'package:fashionista/presentation/screens/closet/add_or_edit_outfit_screen.dart';
import 'package:fashionista/presentation/screens/closet/closet_screen.dart';
import 'package:fashionista/presentation/screens/designers/designer_details_screen.dart';
import 'package:fashionista/presentation/screens/designers/designers_screen.dart';
import 'package:fashionista/presentation/screens/designers/my_designers_screen.dart';
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
import 'package:fashionista/presentation/screens/work_order/add_work_order_screen.dart';
import 'package:fashionista/presentation/screens/work_order/edit_work_order_screen.dart';
import 'package:fashionista/presentation/screens/work_order/project_details_screen.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_request_screen.dart';
import 'package:fashionista/presentation/screens/work_order/work_order_timeline_screen.dart';
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
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      name: 'SignInScreen',
      path: '/sign-in',
      builder: (context, state) => const SignInScreen(),
    ),
    GoRoute(
      name: 'CreateProfileScreen',
      path: '/create-profile',
      builder: (context, state) => const CreateProfileScreen(),
    ),
    GoRoute(
      name: 'UserInterestScreen',
      path: '/user-interests',
      builder: (context, state) {
        final fromWhere = state.uri.queryParameters['fromwhere'];
        return UserInterestScreen(fromWhere: fromWhere);
      },
    ),
    GoRoute(
      name: 'NotificationScreen',
      path: '/notifications',
      builder: (context, state) => const NotificationScreen(),
    ),
    GoRoute(
      name: 'DesignersScreen',
      path: '/designers',
      builder: (context, state) => const DesignersScreen(),
    ),
    GoRoute(
      name: 'EditProfileScreen',
      path: '/edit-profile',
      builder: (context, state) => const EditProfileScreen(),
    ),

    GoRoute(
      name: 'SettingsScreen',
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      name: 'AddOrEditClosetItemsPage',
      path: '/closet/add-item',
      builder: (context, state) => const AddOrEditClosetItemsPage(),
    ),
    GoRoute(
      name: 'AddOrEditOutfitScreen',
      path: '/closet/add-outfit',
      builder: (context, state) => const AddOrEditOutfitScreen(),
    ),

    GoRoute(
      name: 'AddOrEditOutfitPlanScreen',
      path: '/closet/outfit-planner',
      builder: (context, state) => const AddOrEditOutfitPlanScreen(),
    ),
    GoRoute(
      path: '/trends/:id',
      name: 'TrendDetailsScreen',
      builder: (context, state) =>
          TrendDetailsScreen(trendId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/clients/view/:id',
      name: 'ClientDetailsScreen',
      builder: (context, state) =>
          ClientDetailsScreen(clientId: state.pathParameters['id']!),
    ),

    GoRoute(
      name: 'AddClientScreen',
      path: '/clients/add',
      builder: (context, state) => AddClientScreen(),
    ),
    GoRoute(
      name: 'AddClientScreenWithMobileNumber',
      path: '/clients/add/:id',
      builder: (context, state) =>
          AddClientScreen(clientMobileNumber: state.pathParameters['id']!),
    ),
    GoRoute(
      name: 'AddWorkOrderScreen',
      path: '/workorders/add',
      builder: (context, state) => const AddWorkOrderScreen(),
    ),
    GoRoute(
      name: 'WorkOrderRequestScreen',
      path: '/workorders/request/:id',
      builder: (context, state) => WorkOrderRequestScreen(
        workOrderRequestId: state.pathParameters['id']!,
      ),
    ),
    GoRoute(
      name: 'EditWorkOrderScreen',
      path: '/workorders/edit/:id',
      builder: (context, state) =>
          EditWorkOrderScreen(workOrderId: state.pathParameters['id']!),
    ),
    GoRoute(
      name: 'WorkOrderTimelineScreen',
      path: '/workorders/timeline/:id',
      builder: (context, state) =>
          WorkOrderTimelineScreen(workOrderId: state.pathParameters['id']!),
    ),

    GoRoute(
      name: 'ProjectDetailsScreen',
      path: '/workorders/details/:id',
      builder: (context, state) =>
          ProjectDetailsScreen(workOrderId: state.pathParameters['id']!),
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

    GoRoute(
      name: 'MyDesignersScreen',
      path: '/my-designers',
      builder: (context, state) => MyDesignersScreen(),
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
