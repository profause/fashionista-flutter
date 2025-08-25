import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/domain/usecases/auth/signout_usecase.dart';
import 'package:fashionista/presentation/screens/auth/sign_in_screen.dart';
import 'package:fashionista/presentation/screens/profile/widgets/profile_info_card_widget.dart';
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
        padding: const EdgeInsets.all(8),
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

          // sign out
          Card(
            color: colorScheme.onPrimary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
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
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(color: Colors.red),
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

  /// 🔹 Show a simple loading dialog
  Future<void> _showLoadingDialog(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
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
      await _showLoadingDialog(context);

      await sl<SignOutUsecase>().call('');

      // ✅ remove loading dialog safely
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).maybePop();
      }

      // ✅ navigate to sign in
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SignInScreen(),
            transitionsBuilder: (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
            transitionDuration: const Duration(milliseconds: 800),
          ),
          (route) => false,
        );
      }
    }
  }
}
