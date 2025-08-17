import 'dart:async';
import 'package:fashionista/core/assets/app_images.dart';
import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/widgets/bloc/previous_screen_state_cubit.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/firebase_user_service.dart';
import 'package:fashionista/domain/usecases/auth/signout_usecase.dart';
import 'package:fashionista/domain/usecases/profile/fetch_user_profile_usecase.dart';
import 'package:fashionista/presentation/screens/auth/sign_in_screen.dart';
import 'package:fashionista/presentation/screens/profile/edit_profile_screen.dart';
import 'package:fashionista/presentation/screens/profile/widgets/profile_info_card_widget.dart';
import 'package:fashionista/presentation/screens/settings/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late PreviousScreenStateCubit _previousScreenStateCubit;
  late AuthProviderCubit _authProviderCubit;
  late final StreamSubscription<firebase_auth.User?> _userSubscription;
  bool _isUploading = false;
  @override
  void initState() {
    super.initState();
    _isUploading = false;
    if (mounted) {
      _previousScreenStateCubit = context.read<PreviousScreenStateCubit>();
      _previousScreenStateCubit.setPreviousScreen('ProfileScreen');
      _authProviderCubit = context.read<AuthProviderCubit>();
      // Listen for Firebase Auth user changes
      _userSubscription = firebase_auth.FirebaseAuth.instance
          .userChanges()
          .listen((firebase_auth.User? user) {
            if (user == null && !_authProviderCubit.state.isAuthenticated) {
              // User signed out → redirect to login
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.of(context, rootNavigator: true).pop();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const SignInScreen()),
                  (route) => false,
                );
              });
            } else {
              _getUserDetails();
            }
          });
    }
  }

  @override
  void dispose() {
    _userSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    //final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: Text(
          'Profile',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
        toolbarHeight: 0,
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
                //const SizedBox(height: 8),
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
                                  _chooseImageSource(context);
                                },
                                splashRadius: 24,
                              ),
                            ),
                          ),
                          // Centered loader overlay
                          if (_isUploading)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.black.withValues(
                                    alpha: 0.20,
                                  ), // subtle dim
                                ),
                                alignment: Alignment.center,
                                child: const SizedBox(
                                  width: 36,
                                  height: 36,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
                //personal info
                ProfileInfoCardWidget(
                  items: [
                    {'title': 'Full name', 'value': user.fullName},
                    {'title': 'User name', 'value': user.userName},
                  ],
                ),
                const SizedBox(height: 8),
                //contact info
                ProfileInfoCardWidget(
                  items: [
                    {'title': 'Mobile number', 'value': user.mobileNumber},
                    {'title': 'Email', 'value': user.email},
                    {'title': 'Location', 'value': user.location},
                  ],
                ),
                //demographic info
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
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

  Future<void> _getUserDetails() async {
    try {
      final userBloc = context.read<UserBloc>();
      final uid = userBloc.state.uid;
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final result = await sl<FetchUserProfileUsecase>().call(uid!);
      result.fold(
        (ifLeft) {
          if (mounted) {
            // Dismiss the dialog manually
            Navigator.of(context, rootNavigator: true).pop();
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ifLeft)));
        },
        (ifRight) {
          userBloc.clear();
          userBloc.add(UpdateUser(ifRight));
          if (mounted) {
            // Dismiss the dialog manually
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        // Dismiss the dialog manually
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  _chooseImageSource(BuildContext context) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Upload Image'),
          content: const Text('Choose your image source:'),
          actions: [
            TextButton(
              onPressed: () {
                _pickImage(ImageSource.camera);
              },
              child: const Text('Camera'),
            ),
            TextButton(
              onPressed: () {
                _pickImage(ImageSource.gallery);
              },
              child: const Text('Gallery'),
            ),
          ],
        ),
      );
    }
  }

  XFile? _imageFile;
  CroppedFile? _croppedFile;
  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    setState(() {
      if (pickedFile != null) {
        _imageFile = pickedFile;
      }
    });
    if (mounted) {
      // Dismiss the dialog manually
      Navigator.of(context, rootNavigator: true).pop();
    }
    _cropImage();
  }

  Future<void> _cropImage() async {
    final colorScheme = Theme.of(context).colorScheme;
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: _imageFile!.path,
      aspectRatio: CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
      compressFormat: ImageCompressFormat.jpg,
      compressQuality: 40,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: colorScheme.surface,
          toolbarWidgetColor: colorScheme.primary,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPresetCustom(),
          ],
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioPresets: [
            CropAspectRatioPreset.original,
            CropAspectRatioPreset.square,
            CropAspectRatioPreset.ratio4x3,
            CropAspectRatioPresetCustom(),
          ],
        ),
      ],
    );

    setState(() {
      _croppedFile = croppedFile ?? _croppedFile;
    });

    _uploadImage();
  }

  Future<void> _uploadImage() async {
    if (_croppedFile != null) {
      setState(() {
        _isUploading = true;
      });
      final result = await sl<FirebaseUserService>().uploadProfileImage(
        _croppedFile!,
      );

      result.fold(
        (error) {
          debugPrint('Error: $error');
          _clearImageFile();
          setState(() {
            _isUploading = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
        },
        (url) {
          UserBloc userBloc = context.read<UserBloc>();
          User user = userBloc.state;
          user = user.copyWith(profileImage: url);
          userBloc.add(UpdateUser(user));

          debugPrint('Uploaded! Image URL: $url');
          _clearImageFile();
          setState(() {
            _isUploading = false;
          });
        },
      );
    }
  }

  void _clearImageFile() {
    setState(() {
      _imageFile = null;
      _croppedFile = null;
    });
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

class CropAspectRatioPresetCustom implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (2, 3);

  @override
  String get name => '2x3 (customized)';
}
