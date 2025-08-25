import 'package:fashionista/core/service_locator/service_locator.dart';
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
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_icon_rounded.dart';
import 'package:fashionista/presentation/widgets/social_handle_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return BlocBuilder<DesignerBloc, DesignerState>(
      builder: (context, designerState) {
        _businessNameController.text = widget.designer.businessName;
        _mobileNumberController.text = widget.designer.mobileNumber;
        _locationController.text = widget.designer.location;
        _bioController.text = widget.designer.bio ?? '';

        socialHandles =
            widget.designer.socialHandles ?? SocialHandle.defaults();

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
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              foregroundColor: colorScheme.primary,
              backgroundColor: colorScheme.onPrimary,
              title: Text(
                'Designer',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium!.copyWith(fontWeight: FontWeight.bold),
              ),
              elevation: 0,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: CustomIconButtonRounded(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await _saveDesignerProfile(widget.designer, context);
                        //Navigator.of(context).pop();
                      }
                    },
                    iconData: Icons.check,
                  ),
                ),
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
                      
                      BannerImageWidget(uid: widget.designer.uid, url: ValueNotifier(widget.designer.bannerImage!)),

                      const SizedBox(height: 4),
                      Padding(
                        padding: EdgeInsetsGeometry.all(16),
                        child: Text(
                          "Your next client is looking — make sure they see your best.",
                        ),
                      ),

                      //const SizedBox(height: 4),
                      Card(
                        color: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CustomIconRounded(
                                    icon: Icons.store_mall_directory,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
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
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Card(
                        color: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CustomIconRounded(
                                    icon: Icons.phone_android_outlined,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
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
                                ],
                              ),
                              Divider(
                                height: 16,
                                thickness: 1,
                                indent: 48,
                                color: Colors.grey[300],
                              ),
                              Row(
                                children: [
                                  CustomIconRounded(icon: Icons.edit_location),
                                  const SizedBox(width: 8),
                                  Expanded(
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
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      FeaturedImagesWidget(designer: widget.designer),
                      const SizedBox(height: 4),
                      Card(
                        color: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CustomIconRounded(icon: Icons.tag),
                                  const SizedBox(width: 8),
                                  Text("Featured Tags"),
                                ],
                              ),
                              const SizedBox(height: 12),
                              TagInputField(
                                label: '',
                                hint:
                                    'Type and press Enter, Space or Comma to add a tag',
                                valueIn: widget.designer.tags == ''
                                    ? []
                                    : widget.designer.tags.split('|'),
                                valueOut: (value) =>
                                    _tagsController.text = value.join('|'),
                              ),
                              // Wrap(
                              //   spacing: 8,
                              //   runSpacing: 8,
                              //   children: List.generate(
                              //     widget.designer.tags.length,
                              //     (index) => Chip(
                              //       label: Text(
                              //         widget.designer.tags[index],
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
                        color: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CustomIconRounded(icon: Icons.link),
                                  const SizedBox(width: 8),
                                  Text("Social Media Handles"),
                                ],
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
                        color: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CustomIconRounded(
                                    icon: Icons.account_box_outlined,
                                  ),
                                  const SizedBox(width: 8),
                                  Text("Bio"),
                                ],
                              ),
                              TextFormField(
                                controller: _bioController,
                                style: textTheme.titleSmall,
                                decoration: InputDecoration(
                                  hintText: "Give us your vibe in a few words.",
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
      },
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

    //debugPrint("Designer: $designerCopy");

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
                // _pickImage(ImageSource.gallery);
                _pickImageMultiple();
              },
              child: const Text('Gallery'),
            ),
          ],
        ),
      );
    }
  }

  XFile? _imageFile;
  //CroppedFile? _croppedFile;
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
    //_cropImage();
  }

  Future<void> _pickImageMultiple() async {
    // Pick multiple images.

    final List<XFile> imageFiles = await ImagePicker().pickMultiImage(
      limit: 4,
      requestFullMetadata: true,
    );

    setState(() {});
    if (mounted) {
      // Dismiss the dialog manually
      Navigator.of(context, rootNavigator: true).pop();
    }
    //_uploadImages(imageFiles);
  }
}
