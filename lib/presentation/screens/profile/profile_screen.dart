import 'dart:async';

import 'package:fashionista/core/assets/app_images.dart';
import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/widgets/bloc/previous_screen_state_cubit.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/domain/usecases/auth/signout_usecase.dart';
import 'package:fashionista/presentation/screens/auth/sign_in_screen.dart';
import 'package:fashionista/presentation/screens/profile/edit_profile_screen.dart';
import 'package:fashionista/presentation/screens/profile/widgets/profile_info_card_widget.dart';
import 'package:fashionista/presentation/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late PreviousScreenStateCubit _previousScreenStateCubit;
  late final StreamSubscription<firebase_auth.User?> _userSubscription;
  @override
  void initState() {
    super.initState();
    _previousScreenStateCubit = context.read<PreviousScreenStateCubit>();
    _previousScreenStateCubit.setPreviousScreen('ProfileScreen');

    // Listen for Firebase Auth user changes
    _userSubscription = firebase_auth.FirebaseAuth.instance
        .userChanges()
        .listen((firebase_auth.User? user) {
          if (user == null) {
            // User signed out → redirect to login
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.of(context, rootNavigator: true).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const SignInScreen()),
                (route) => false,
              );
            });
          }
        });
  }

  @override
  void dispose() {
    _userSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.surface,
        title: Text(
          'Profile',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(8),
          child: BlocBuilder<UserBloc, User>(
            builder: (context, user) => Column(
              mainAxisAlignment: MainAxisAlignment.center, // center vertically
              crossAxisAlignment:
                  CrossAxisAlignment.center, // center horizontally
              children: [
                Center(
                  // ensures horizontal centering
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(
                        60,
                      ), // match avatar shape
                      onTap: () {},
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Avatar
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(60),
                              onTap: () {},
                              child: CircleAvatar(
                                radius: 60,
                                backgroundColor: AppTheme.lightGrey,
                                backgroundImage: user.profileImage != ''
                                    ? NetworkImage(user.profileImage)
                                    : const AssetImage(AppImages.avatar)
                                          as ImageProvider,
                              ),
                            ),
                          ),

                          // Camera button
                          Positioned(
                            bottom: 4, // slight overlap
                            right: 4,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: colorScheme.onPrimary,
                              child: IconButton(
                                padding:
                                    EdgeInsets.zero, // removes default padding
                                icon: Icon(
                                  Icons.camera_alt,
                                  size: 24,
                                  color: colorScheme.primary,
                                ),
                                onPressed: () {
                                  // Handle camera click
                                },
                                splashRadius: 24,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    side: BorderSide(
                      color: AppTheme.lightGrey,
                    ), // Outline color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8), // Rounded corners
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ), // Optional padding
                  ),
                  child: Text(
                    'Edit profile',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
                const SizedBox(height: 16),
                //personal info
                ProfileInfoCardWidget(
                  items: [
                    {'title': 'Full name', 'value': user.fullName},
                    {'title': 'User name', 'value': user.userName},
                  ],
                ),
                const SizedBox(height: 16),
                //contact info
                ProfileInfoCardWidget(
                  items: [
                    {'title': 'Mobile number', 'value': user.mobileNumber},
                    {'title': 'Email', 'value': user.email},
                    {'title': 'Location', 'value': user.location},
                  ],
                ),
                //demographic info
                const SizedBox(height: 16),
                ProfileInfoCardWidget(
                  items: [
                    {'title': 'Gender', 'value': user.gender},
                    {
                      'title': 'Date of birth',
                      'value': user.dateOfBirth == null
                          ? ''
                          : DateFormat('yyyy-MM-dd').format(user.dateOfBirth!),
                    },
                  ],
                ),
                const SizedBox(height: 16),
                //account info
                ProfileInfoCardWidget(
                  items: [
                    {'title': 'Account type', 'value': user.accountType},
                    {
                      'title': 'Joined',
                      'value': user.joinedDate == null
                          ? ''
                          : DateFormat('yyyy-MM-dd').format(user.joinedDate!),
                    },
                  ],
                ),
                const SizedBox(height: 16),
                Card(
                  color: colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SettingsScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Settings',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8), // Space between buttons
                        Expanded(
                          child: TextButton(
                            onPressed: () => _signOut(context),
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              'Sign out',
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    if (mounted) {
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

      if (shouldSignOut == true) {
        if (mounted) {
          context.read<UserBloc>().clear();
          context.read<AuthProviderCubit>().setAuthState('', '', '', false);
          showDialog(
            context: context,
            barrierDismissible: false, // Prevent dismissing
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
          sl<SignOutUsecase>().call('');
        }
      }
    }
  }
}
