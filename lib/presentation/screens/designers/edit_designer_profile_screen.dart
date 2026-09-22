import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/widgets/tag_input_field.dart';
import 'package:fashionista/data/models/designers/bloc/designer_bloc.dart';
import 'package:fashionista/data/models/designers/bloc/designer_event.dart';
import 'package:fashionista/data/models/designers/bloc/designer_state.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/models/designers/social_handle_model.dart';
import 'package:fashionista/domain/usecases/designers/update_designer_usecase.dart';
import 'package:fashionista/presentation/screens/designers/widgets/featured_images_widget.dart';
import 'package:fashionista/presentation/screens/profile/widgets/profile_info_text_field_widget.dart';
import 'package:fashionista/presentation/widgets/banner_image_widget.dart';
import 'package:fashionista/presentation/widgets/custom_icon_rounded.dart';
import 'package:fashionista/presentation/widgets/social_handle_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditDesignerProfileScreen extends StatefulWidget {
  final Designer designer;
  const EditDesignerProfileScreen({super.key, required this.designer});

  @override
  State<EditDesignerProfileScreen> createState() =>
      _EditDesignerProfileScreenState();
}

class _EditDesignerProfileScreenState extends State<EditDesignerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _businessNameController;
  late TextEditingController _mobileNumberController;
  late TextEditingController _locationController;
  late TextEditingController _tagsController;
  late TextEditingController _facebookSocialHandleController;
  late TextEditingController _xSocialHandleController;
  late TextEditingController _instagramSocialHandleController;
  late TextEditingController _tiktokSocialHandleController;
  late TextEditingController _bioController;

  List<SocialHandle> socialHandles = [];

  @override
  void initState() {
    context.read<DesignerBloc>().add(UpdateDesigner(widget.designer));
    _businessNameController = TextEditingController();
    _mobileNumberController = TextEditingController();
    _locationController = TextEditingController();
    _tagsController = TextEditingController();
    _bioController = TextEditingController();
    _facebookSocialHandleController = TextEditingController();
    _xSocialHandleController = TextEditingController();
    _instagramSocialHandleController = TextEditingController();
    _tiktokSocialHandleController = TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _mobileNumberController.dispose();
    _locationController.dispose();
    _tagsController.dispose();
    _bioController.dispose();
    _facebookSocialHandleController.dispose();
    _xSocialHandleController.dispose();
    _instagramSocialHandleController.dispose();
    _tiktokSocialHandleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return BlocBuilder<DesignerBloc, DesignerState>(
      builder: (context, state) {
        switch (state) {
          case DesignerLoading():
            return const Center(child: CircularProgressIndicator());
          case DesignerLoaded(:final designer):
            _businessNameController.text = designer.businessName;
            _mobileNumberController.text = designer.mobileNumber;
            _locationController.text = designer.location;
            _bioController.text = designer.bio ?? '';
            socialHandles = designer.socialHandles ?? SocialHandle.defaults();

            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, result) async {
                if (didPop) return; // Already popped
                Navigator.of(context).pop(result);
                // if (_hasMissingRequiredFields()) {
                //   bool leave = await _showIncompleteDialog();
                //   if (leave) {} //Navigator.of(context).pop(result);
                // } else {
                //   await _saveProfile(user); // Auto-save before leaving
                //   //Navigator.of(context).pop(result);
                // }
              }, // We decide manually
              child: Scaffold(
                backgroundColor: context.canvasBackground,
                appBar: AppBar(
                  backgroundColor: context.cardSurface,
                  surfaceTintColor: Colors.transparent,
                  foregroundColor: context.onCanvasText,
                  elevation: 0,
                  centerTitle: true,
                  title: Text(
                    'Designer Profile',
                    style: Theme.of(context).textTheme.titleMedium!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.onCanvasText,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await _saveDesignerProfile(designer, context);
                        }
                      },
                      child: Text(
                        'Save',
                        style: Theme.of(context).textTheme.labelLarge!.copyWith(
                          fontWeight: FontWeight.w600,
                          color: context.accent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
                body: SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          BannerImageWidget(
                            uid: designer.uid,
                            url: ValueNotifier(designer.bannerImage!),
                          ),

                          const Padding(
                            padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                            child: Text(
                              "Your next client is looking — make sure they see your best.",
                            ),
                          ),
                          const SizedBox(height: 16),

                          /// Business Dossier — the three identity fields of the
                          /// designer, grouped into one card as per the design.
                          Card(
                            color: context.cardSurface,
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            elevation: 1,
                            shadowColor: const Color(0x0A000000),
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: context.hairline),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CustomIconRounded(
                                        icon: Icons.storefront_outlined,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Business Dossier',
                                          style: textTheme.titleSmall!.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: context.onCanvasText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _dossierRow(
                                    icon: Icons.drive_file_rename_outline,
                                    child: ProfileInfoTextFieldWidget(
                                      label: 'Business Name',
                                      controller: _businessNameController,
                                      hint: 'Enter your Business Name',
                                      validator: (value) {
                                        if (!RegExp(
                                          r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
                                        ).hasMatch(value!)) {
                                          return 'Please enter a valid name';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _dossierDivider(),
                                  _dossierRow(
                                    icon: Icons.call_outlined,
                                    child: ProfileInfoTextFieldWidget(
                                      label: 'Mobile Number',
                                      controller: _mobileNumberController,
                                      hint: 'Enter your business mobile number',
                                      validator: (value) {
                                        if (!RegExp(
                                          r'^((\+?\d{1,2}\s?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$)?',
                                        ).hasMatch(value!)) {
                                          return 'Please enter a valid mobile number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  _dossierDivider(),
                                  _dossierRow(
                                    icon: Icons.location_on_outlined,
                                    child: ProfileInfoTextFieldWidget(
                                      label: 'Business Location',
                                      controller: _locationController,
                                      hint: 'Enter your Business location',
                                      validator: (value) {
                                        if (!RegExp(
                                          r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
                                        ).hasMatch(value!)) {
                                          return 'Please enter a valid location';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _sectionHeaderCard(
                            icon: Icons.photo_library_outlined,
                            title: 'Featured Creations',
                            meta:
                                '${designer.featuredImages?.length ?? 0} / 4 slots',
                            subtitle:
                                'Selected pieces displayed on VIP tailoring commissions and lookbooks.',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: FeaturedImagesWidget(designer: designer),
                          ),
                          const SizedBox(height: 16),
                          Card(
                            color: context.cardSurface,
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            elevation: 1,
                            shadowColor: const Color(0x0A000000),
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: context.hairline),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CustomIconRounded(icon: Icons.tag),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Featured Tags',
                                          style: textTheme.titleSmall!.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: context.onCanvasText,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'Discovery filters',
                                        style: textTheme.labelSmall!.copyWith(
                                          color: context.mutedText,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 48),
                                    child: Text(
                                      'Helps clients discover your atelier across wardrobe categories.',
                                      style: textTheme.bodySmall!.copyWith(
                                        color: context.descriptionText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TagInputField(
                                    label: '',
                                    hint:
                                        'Type and press Enter, Space or Comma to add a tag',
                                    valueIn: designer.tags == ''
                                        ? []
                                        : designer.tags.split('|'),
                                    valueOut: (value) =>
                                        _tagsController.text = value.join('|'),
                                  ),
                                  // Wrap(
                                  //   spacing: 8,
                                  //   runSpacing: 8,
                                  //   children: List.generate(
                                  //     designer.tags.length,
                                  //     (index) => Chip(
                                  //       label: Text(
                                  //         designer.tags[index],
                                  //       ),
                                  //     ),
                                  //   ),
                                  // ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Card(
                            color: context.cardSurface,
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            elevation: 1,
                            shadowColor: const Color(0x0A000000),
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: context.hairline),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CustomIconRounded(
                                        icon: Icons.hub_outlined,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Connected Channels',
                                          style: textTheme.titleSmall!.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: context.onCanvasText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 48),
                                    child: Text(
                                      'Social Media Handles',
                                      style: textTheme.bodySmall!.copyWith(
                                        color: context.descriptionText,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SocialHandleFieldWidget(
                                    provider: "Facebook",
                                    socialHandles: socialHandles,
                                    valueOut: (value) {
                                      final index = socialHandles.indexWhere(
                                        (h) =>
                                            h.provider.toLowerCase() ==
                                            value.provider.toLowerCase(),
                                      );
                                      index != -1
                                          ? socialHandles[index] = value
                                          : socialHandles.add(value);
                                    },
                                  ),
                                  SocialHandleFieldWidget(
                                    provider: "Instagram",
                                    socialHandles: socialHandles,
                                    valueOut: (value) {
                                      final index = socialHandles.indexWhere(
                                        (h) =>
                                            h.provider.toLowerCase() ==
                                            value.provider.toLowerCase(),
                                      );
                                      index != -1
                                          ? socialHandles[index] = value
                                          : socialHandles.add(value);
                                    },
                                  ),
                                  SocialHandleFieldWidget(
                                    provider: "X",
                                    socialHandles: socialHandles,
                                    valueOut: (value) {
                                      final index = socialHandles.indexWhere(
                                        (h) =>
                                            h.provider.toLowerCase() ==
                                            value.provider.toLowerCase(),
                                      );
                                      index != -1
                                          ? socialHandles[index] = value
                                          : socialHandles.add(value);
                                    },
                                  ),
                                  SocialHandleFieldWidget(
                                    provider: "TikTok",
                                    socialHandles: socialHandles,
                                    valueOut: (value) {
                                      final index = socialHandles.indexWhere(
                                        (h) =>
                                            h.provider.toLowerCase() ==
                                            value.provider.toLowerCase(),
                                      );
                                      index != -1
                                          ? socialHandles[index] = value
                                          : socialHandles.add(value);
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Card(
                            color: context.cardSurface,
                            margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                            elevation: 1,
                            shadowColor: const Color(0x0A000000),
                            surfaceTintColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: context.hairline),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CustomIconRounded(
                                        icon: Icons.badge_outlined,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Studio Biography',
                                          style: textTheme.titleSmall!.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: context.onCanvasText,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  TextFormField(
                                    controller: _bioController,
                                    style: textTheme.titleSmall,
                                    maxLength: 300,
                                    decoration: InputDecoration(
                                      hintText:
                                          "Give us your vibe in a few words.",
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      hintStyle: textTheme.titleSmall,
                                      filled: true,
                                      fillColor: Colors.transparent,
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
              ),
            );

          case DesignerError(:final message):
            return Center(child: Text("Error: $message"));
          default:
            return const Center(child: Text("No designer data"));
        }
      },
    );
  }

  /// A row inside the Business Dossier card: a small leading icon plus the
  /// field it labels.
  Widget _dossierRow({required IconData icon, required Widget child}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(icon, size: 18, color: context.secondaryLabel),
        ),
        const SizedBox(width: 10),
        Expanded(child: child),
      ],
    );
  }

  Widget _dossierDivider() =>
      Divider(height: 20, thickness: 1, indent: 28, color: context.hairline);

  /// Header-only card for sections whose content widget renders its own card
  /// (e.g. [FeaturedImagesWidget]).
  Widget _sectionHeaderCard({
    required IconData icon,
    required String title,
    String? meta,
    String? subtitle,
  }) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      color: context.cardSurface,
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      elevation: 1,
      shadowColor: const Color(0x0A000000),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: context.hairline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CustomIconRounded(icon: icon),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: textTheme.titleSmall!.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.onCanvasText,
                    ),
                  ),
                ),
                if (meta != null)
                  Text(
                    meta,
                    style: textTheme.labelSmall!.copyWith(
                      color: context.mutedText,
                    ),
                  ),
              ],
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 48),
                child: Text(
                  subtitle,
                  style: textTheme.bodySmall!.copyWith(
                    color: context.descriptionText,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveDesignerProfile(
    Designer designer,
    BuildContext context,
  ) async {
    if (!mounted) return;
    //await context.read<DesignerBloc>().add(SaveDesigner(designer));
    final mobileNumber = _mobileNumberController.text;
    final location = _locationController.text;
    final bio = _bioController.text;
    final businessName = _businessNameController.text;
    final tags = _tagsController.text;

    final socials = socialHandles;

    final designerCopy = designer.copyWith(
      mobileNumber: mobileNumber,
      location: location,
      bio: bio,
      businessName: businessName,
      tags: tags,
      socialHandles: socials,
    );

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final result = await sl<UpdateDesignerUsecase>().call(designerCopy);

    result.fold(
      (failure) {
        if (mounted) {
          // Dismiss the dialog manually
          Navigator.of(context, rootNavigator: true).pop();
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure)));
      },
      (success) {
        context.read<DesignerBloc>().add(LoadDesigner(designer.uid));
        if (mounted) {
          // Dismiss the dialog manually
          Navigator.of(context, rootNavigator: true).pop();
          Navigator.pop(context);
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully updated your designer profile.'),
          ),
        );
      },
    );
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
  //               // _pickImage(ImageSource.gallery);
  //               _pickImageMultiple();
  //             },
  //             child: const Text('Gallery'),
  //           ),
  //         ],
  //       ),
  //     );
  //   }
  // }

  //XFile? _imageFile;
  //CroppedFile? _croppedFile;
  // Future<void> _pickImage(ImageSource source) async {
  //   final pickedFile = await ImagePicker().pickImage(source: source);
  //   setState(() {
  //     if (pickedFile != null) {
  //       _imageFile = pickedFile;
  //     }
  //   });
  //   if (mounted) {
  //     // Dismiss the dialog manually
  //     Navigator.of(context, rootNavigator: true).pop();
  //   }
  //   //_cropImage();
  // }

  // Future<void> _pickImageMultiple() async {
  //   // Pick multiple images.

  //   final List<XFile> imageFiles = await ImagePicker().pickMultiImage(
  //     limit: 4,
  //     requestFullMetadata: true,
  //   );

  //   setState(() {});
  //   if (mounted) {
  //     // Dismiss the dialog manually
  //     Navigator.of(context, rootNavigator: true).pop();
  //   }
  //   //_uploadImages(imageFiles);
  // }
}
