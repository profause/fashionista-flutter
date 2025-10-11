import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/hive/hive_client_service.dart';
import 'package:fashionista/data/services/hive/hive_closet_item_service.dart';
import 'package:fashionista/data/services/hive/hive_design_collection_service.dart';
import 'package:fashionista/data/services/hive/hive_designer_reviews_service.dart';
import 'package:fashionista/data/services/hive/hive_designers_service.dart';
import 'package:fashionista/data/services/hive/hive_outfit_service.dart';
import 'package:fashionista/data/services/hive/hive_trend_comment_service.dart';
import 'package:fashionista/data/services/hive/hive_trend_service.dart';
import 'package:fashionista/data/services/hive/hive_work_order_service.dart';
import 'package:fashionista/data/services/hive/hive_work_order_status_progress_service.dart';
import 'package:fashionista/domain/usecases/auth/signout_usecase.dart';
import 'package:fashionista/presentation/screens/auth/sign_in_screen.dart';
import 'package:fashionista/presentation/screens/profile/user_interest_screen.dart';
import 'package:fashionista/presentation/screens/profile/widgets/profile_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class UserProfilePage extends StatelessWidget {
  final User user;
  const UserProfilePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: ListView(
        padding: const EdgeInsets.only(top:4,bottom: 8),
        children: [
          // personal info
          ProfileInfoCardWidget(
            items: [
              ProfileInfoItem(
                icon: Icons.person,
                title: 'Full name',
                value: user.fullName,
              ),
              ProfileInfoItem(
                icon: Icons.person_outline_outlined,
                title: 'User name',
                value: user.userName,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // contact info
          ProfileInfoCardWidget(
            items: [
              ProfileInfoItem(
                icon: Icons.phone,
                title: 'Mobile number',
                value: user.mobileNumber,
              ),
              ProfileInfoItem(
                icon: Icons.email,
                title: 'Email',
                value: user.email,
              ),
              ProfileInfoItem(
                icon: Icons.location_city,
                title: 'Location',
                value: user.location,
              ),
            ],
          ),
          const SizedBox(height: 8),

          // demographic info
          ProfileInfoCardWidget(
            items: [
              ProfileInfoItem(
                icon: Icons.female,
                title: 'Gender',
                value: user.gender,
              ),
              ProfileInfoItem(
                icon: Icons.calendar_month,
                title: 'Date of birth',
                value: user.dateOfBirth == null
                    ? ''
                    : DateFormat('yyyy-MM-dd').format(user.dateOfBirth!),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // account info
          ProfileInfoCardWidget(
            items: [
              ProfileInfoItem(
                icon: Icons.account_box,
                title: 'Account type',
                value: user.accountType,
              ),
              ProfileInfoItem(
                icon: Icons.calendar_today,
                title: 'Joined',
                value: user.joinedDate == null
                    ? ''
                    : DateFormat('yyyy-MM-dd').format(user.joinedDate!),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ProfileInfoCardWidget(
            items: [
              ProfileInfoItem(
                title: 'Exploring fashion identity',
                value: '',
                suffix: CustomIconButtonRounded(
                  iconData: Icons.interests_outlined,
                  size: 24,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserInterestScreen(fromWhere: 'UserProfilePage'),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // sign out
          const SizedBox(height: 8),
          Card(
            margin: const EdgeInsets.all(0),
            color: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(0),
            ),
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => _signOut(context),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Sign out',
                      style: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    if (!context.mounted) return;

    final shouldSignOut = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );

    if (shouldSignOut == true && context.mounted) {
      context.read<UserBloc>().clear();
      context.read<AuthProviderCubit>().setAuthState('', '', '', false);

      // ✅ show loading safely
      //await _showLoadingDialog(context);

      await sl<SignOutUsecase>().call('');
      await sl<HiveDesignersService>().clearCache();
      await sl<HiveTrendService>().clearCache();
      await sl<HiveTrendCommentService>().clearCache();
      await sl<HiveDesignCollectionService>().clearCache();
      await sl<HiveClosetItemService>().clearCache();
      await sl<HiveClientService>().clearCache();
      await sl<HiveOutfitService>().clearCache();
      await sl<HiveWorkOrderService>().clearCache();
      await sl<HiveWorkOrderStatusProgressService>().clearCache();
      await sl<HiveDesignerReviewsService>().clearCache();

      // ✅ remove loading dialog safely
      //if (context.mounted) {
      //Navigator.of(context, rootNavigator: true).maybePop();
      //}

      // ✅ navigate to sign in
      // if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const SignInScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 400),
        ),
        (route) => false,
      );
      //}
    }
  }
}
