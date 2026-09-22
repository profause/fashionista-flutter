import 'dart:async';
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/firebase/firebase_user_service.dart';
import 'package:fashionista/domain/usecases/profile/fetch_user_profile_usecase.dart';
import 'package:fashionista/presentation/screens/designers/designer_profile_page.dart';
import 'package:fashionista/presentation/screens/profile/user_profile_page.dart';
import 'package:fashionista/presentation/widgets/banner_image_widget.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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
              context.go('/sign-in');
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
    const double maxAvatarRadius = 40;
    const double minAvatarRadius = 32;
    const double expandedHeight = 176;
     final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return BlocBuilder<UserBloc, User>(
      builder: (context, user) {
        if (user.uid != null) {
          return DefaultTabController(
            length: user.accountType.toLowerCase() == 'designer' ? 2 : 1,
            child: Scaffold(
              backgroundColor: context.canvasBackground,
              body: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      pinned: false,
                      expandedHeight: expandedHeight,
                      backgroundColor: context.canvasBackground,
                      foregroundColor: context.onCanvasText,
                      elevation: 0,
                      surfaceTintColor: Colors.transparent,
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(top: 10, right: 12),
                          child: Row(
                            children: [
                              _GlassActionButton(
                                iconData: Icons.edit,
                                onPressed: () {
                                  context.push('/edit-profile');
                                },
                              ),
                              const SizedBox(width: 8),
                              _GlassActionButton(
                                iconData: Icons.settings_outlined,
                                onPressed: () {
                                  context.push('/settings');
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
                          double avatarRadius =
                              maxAvatarRadius -
                              (maxAvatarRadius - minAvatarRadius) *
                                  shrinkFactor;
                          return FlexibleSpaceBar(
                            collapseMode: CollapseMode.parallax,
                            background: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Banner image
                                BannerImageWidget(
                                  uid: user.uid!,
                                  url: ValueNotifier(user.bannerImage!),
                                  isEditable: false,
                                ),
                                Positioned(
                                  top:
                                      (expandedHeight / 2) + (avatarRadius / 2),
                                  left: 16,
                                  child: buildProfileAvatar(avatarRadius, user),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      bottom: PreferredSize(
                        preferredSize: const Size.fromHeight(
                          0,
                        ),
                        child: TabBar(
                          labelColor: colorScheme.primary,
                          unselectedLabelColor: AppTheme.darkGrey,
                          indicatorColor: AppTheme.appIconColor.withValues(
                            alpha: 1,
                          ),
                          dividerColor: AppTheme.lightGrey,
                          dividerHeight: 0,
                          indicatorWeight: 2,
                          tabAlignment: TabAlignment.start,
                          labelPadding: const EdgeInsets.all(0),
                          //padding: const EdgeInsets.all(64),
                          isScrollable: true,
                          indicator: UnderlineTabIndicator(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              width: 4,
                              color: AppTheme.appIconColor.withValues(alpha: 1),
                            ),
                            // insets: EdgeInsets.symmetric(
                            //   horizontal: 60,
                            // ), // adjust for fixed width
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
                                
                              ),
                            ),
                            //Tab(text: "Profile"),
                            if (user.accountType.toLowerCase() ==
                                "designer") ...[
                              Container(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 8,
                                  horizontal: 8,
                                ),
                                // divider color
                                child: Text(
                                  "Designer Card",
                                 
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ];
                },
                body: TabBarView(
                  children: [
                    UserProfilePage(user: user),
                    if (user.accountType.toLowerCase() == "designer") ...[
                      DesignerProfilePage(designerUid: user.uid!),
                    ],
                  ],
                ),
              ),
            ),
          );
        } else {
          return const SizedBox.shrink();
        }
      },
    );
  }

  Widget buildProfileAvatar(double radius, User user) {
    final double avatarSize = radius * 2;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: avatarSize,
          height: avatarSize,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: context.cardSurface,
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 12,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: ClipOval(
            child: CachedNetworkImage(
              fit: BoxFit.cover,
              imageUrl: user.profileImage,
              errorListener: (error) {},
              placeholder: (context, url) => DefaultProfileAvatar(
                key: ValueKey(user.uid),
                name: null,
                size: avatarSize - 6,
                uid: user.uid!,
              ),
              errorWidget: (context, url, error) => DefaultProfileAvatar(
                key: ValueKey(user.uid),
                name: null,
                size: avatarSize - 6,
                uid: user.uid!,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: context.accent,
              shape: BoxShape.circle,
              border: Border.all(color: context.cardSurface, width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0x33000000), blurRadius: 4),
              ],
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 26, height: 26),
              icon: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
              onPressed: () {
                _showImageSourceDialog();
              },
            ),
          ),
        ),
        if (_isUploading) ...[
          const Positioned(
            bottom: -2,
            right: -2,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ],
      ],
    );
  }

  Future<void> _getUserDetails() async {
    try {
      //showLoadingDialog(context);
      final userBloc = context.read<UserBloc>();
      String uid =
          //firebase_auth.FirebaseAuth.instance.currentUser.uid ??
          userBloc.state.uid!;

      if (uid.isEmpty) {
        uid = userBloc.state.uid!;
      }
      // if (uid.isEmpty) return;

      final result = await sl<FetchUserProfileUsecase>().call(uid);
      result.fold(
        (ifLeft) {
          if (mounted) {
            // Dismiss the dialog manually
            //dismissLoadingDialog(context);
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ifLeft)));
        },
        (ifRight) {
          userBloc.add(UpdateUser(ifRight));

          if (mounted) {
            // Dismiss the dialog manually
            //dismissLoadingDialog(context);
          }
        },
      );
    } catch (e) {
      if (mounted) {
        // Dismiss the dialog manually
        dismissLoadingDialog(context);
      }
    }
  }

  // _chooseImageSource(BuildContext context) {
  //   if (mounted) {
  //     showDialog(
  //       context: context,
  //       builder: (ctx) => AlertDialog(
  //         title: const Text('Upload Image'),
  //         content: const Text('Choose your image source:'),
  //         actions: [
  //           TextButton(
  //             onPressed: () {
  //               _pickImage(ImageSource.camera);
  //             },
  //             child: const Text('Camera'),
  //           ),
  //           TextButton(
  //             onPressed: () {
  //               _pickImage(ImageSource.gallery);
  //             },
  //             child: const Text('Gallery'),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  // }

  XFile? _imageFile;
  CroppedFile? _croppedFile;
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source);

      if (pickedFile == null) {
        // User canceled → just close the dialog if it's still open
        if (mounted) {
          Navigator.of(context, rootNavigator: true).pop();
        }
        return;
      }

      setState(() {
        _imageFile = pickedFile;
      });

      if (mounted) {
        // Dismiss the dialog manually (only when successful)
        Navigator.of(context, rootNavigator: true).pop();
      }

      await _cropImage();
    } catch (e) {
      // Optionally show an error message
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to pick image: $e")));
      }
    }
  }

  Future<void> _showImageSourceDialog() async {
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Choose Image Source"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text("Gallery"),
              onTap: () => _pickImage(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text("Camera"),
              onTap: () => _pickImage(ImageSource.camera),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cropImage() async {
    try {
      final colorScheme = Theme.of(context).colorScheme;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: _imageFile!.path,
        aspectRatio: const CropAspectRatio(ratioX: 1.0, ratioY: 1.0),
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

      if (croppedFile == null) {
        // User cancelled → just return without uploading
        return;
      }

      if (mounted) {
        setState(() {
          _croppedFile = croppedFile;
        });
      }

      await _uploadImage();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Failed to crop image: $e")));
      }
    }
  }

  Future<void> _uploadImage() async {
    if (_croppedFile != null) {
      setState(() {
        _isUploading = true;
      });
      final result = await sl<FirebaseUserService>()
          .uploadProfileImageToCloudinary(_croppedFile!);

      result.fold(
        (error) {
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

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // prevent accidental dismiss
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void dismissLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }
}

class _GlassActionButton extends StatelessWidget {
  final IconData iconData;
  final VoidCallback onPressed;
  const _GlassActionButton({required this.iconData, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final bool isDark = context.isDarkTheme;
    return GestureDetector(
      onTap: onPressed,
      child: ClipOval(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.16)
                  : Colors.white.withValues(alpha: 0.70),
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.30)
                    : Colors.white.withValues(alpha: 0.80),
              ),
            ),
            child: Icon(iconData, size: 18, color: context.onCanvasText),
          ),
        ),
      ),
    );
  }
}

class CropAspectRatioPresetCustom implements CropAspectRatioPresetData {
  @override
  (int, int)? get data => (2, 3);

  @override
  String get name => '2x3 (customized)';
}
