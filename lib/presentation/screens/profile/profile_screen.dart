import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/firebase_user_service.dart';
import 'package:fashionista/domain/usecases/profile/fetch_user_profile_usecase.dart';
import 'package:fashionista/presentation/screens/auth/sign_in_screen.dart';
import 'package:fashionista/presentation/screens/designers/designer_profile_page.dart';
import 'package:fashionista/presentation/screens/profile/edit_profile_screen.dart';
import 'package:fashionista/presentation/screens/profile/user_profile_page.dart';
import 'package:fashionista/presentation/screens/settings/settings_screen.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late AuthProviderCubit _authProviderCubit;
  late final StreamSubscription<firebase_auth.User?> _userSubscription;
  bool _isUploading = false;
  @override
  void initState() {
    super.initState();

    _isUploading = false;
    if (mounted) {
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
    final textTheme = Theme.of(context).textTheme;

    const double maxAvatarRadius = 60;
    const double minAvatarRadius = 32;
    const double expandedHeight = 250;
    return DefaultTabController(
      length: 2,
      child: BlocBuilder<UserBloc, User>(
        builder: (context, user) {
          if (user.uid != null) {
            return Scaffold(
              backgroundColor: colorScheme.surface,
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      pinned: true,
                      expandedHeight: expandedHeight,
                      backgroundColor: colorScheme.onPrimary,
                      foregroundColor: colorScheme.primary,
                      elevation: 0,
                      title: Text(user.fullName, style: textTheme.titleLarge!),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(right: 18),
                          child: Row(
                            children: [
                              CustomIconButtonRounded(
                                size: 20,
                                iconData: Icons.edit,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: context
                                            .read<
                                              UserBloc
                                            >(), // reuse existing cubit
                                        child: EditProfileScreen(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              CustomIconButtonRounded(
                                size: 20,
                                iconData: Icons.settings,
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: context
                                            .read<
                                              UserBloc
                                            >(), // reuse existing cubit
                                        child: SettingsScreen(),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                      flexibleSpace: LayoutBuilder(
                        builder: (context, constraints) {
                          final double shrinkOffset =
                              expandedHeight - constraints.maxHeight;
                          final double shrinkFactor =
                              (shrinkOffset / (expandedHeight - kToolbarHeight))
                                  .clamp(0.0, 1.0);
                          final double avatarRadius =
                              maxAvatarRadius -
                              (maxAvatarRadius - minAvatarRadius) *
                                  shrinkFactor;
                          return FlexibleSpaceBar(
                            collapseMode: CollapseMode.parallax,
                            background: SafeArea(
                              child: Column(
                                children: [
                                  const SizedBox(height: 56),
                                  Center(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            borderRadius: BorderRadius.circular(
                                              60,
                                            ),
                                            onTap: () {},

                                            child: user.profileImage != ''
                                                ? CircleAvatar(
                                                    radius: 60,
                                                    backgroundColor:
                                                        AppTheme.lightGrey,
                                                    backgroundImage:
                                                        CachedNetworkImageProvider(
                                                          user.profileImage,
                                                        ),
                                                  )
                                                : DefaultProfileAvatar(
                                                    name: null,
                                                    size: 120,
                                                    uid: user.uid!,
                                                  ),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 4, // slight overlap
                                          right: 4,

                                          child: CustomIconButtonRounded(
                                            onPressed: () {
                                              _chooseImageSource(context);
                                            },
                                            iconData: Icons.camera_alt,
                                          ),
                                        ),
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
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 3,
                                                    ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      bottom: TabBar(
                        labelColor: colorScheme.primary,
                        unselectedLabelColor: AppTheme.darkGrey,
                        indicatorColor: colorScheme.primary,
                        dividerColor: AppTheme.lightGrey,
                        dividerHeight: 0,
                        indicatorWeight: 2,
                        indicator: UnderlineTabIndicator(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            width: 4,
                            color: colorScheme.primary,
                          ),
                          insets: EdgeInsets.symmetric(
                            horizontal: 50,
                          ), // adjust for fixed width
                        ),
                        tabs: [
                          Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            // divider color
                            child: Text(
                              "Profile",
                              style: textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          //Tab(text: "Profile"),
                          Container(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 8,
                            ),
                            // divider color
                            child: Text(
                              "Designer Card",
                              style: textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  children: [
                    UserProfilePage(user: user),
                    DesignerProfilePage(designerUid: user.uid!),
                  ],
                ),
              ),
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<void> _getUserDetails() async {
    try {
      final userBloc = context.read<UserBloc>();
      final uid = userBloc.state.uid;

      if (uid != null) return;
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
}

class CropAspectRatioPresetCustom implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (2, 3);

  @override
  String get name => '2x3 (customized)';
}
