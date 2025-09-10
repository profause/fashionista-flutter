import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc.dart';
import 'package:fashionista/data/models/closet/bloc/closet_outfit_bloc_event.dart';
import 'package:fashionista/data/models/closet/outfit_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/firebase/firebase_closet_service.dart';
import 'package:fashionista/presentation/screens/closet/widgets/outfit_tag_picker_widget.dart';
import 'package:fashionista/presentation/widgets/custom_autocomplete_form_field_widget.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_text_input_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:uuid/uuid.dart';

final occasions = [
  {
    "label": "Wedding",
    "icon":
        Icons.favorite, // ❤️ or use wedding rings icon from other icon packs
  },
  {
    "label": "Office",
    "icon": Icons.work_outline, // briefcase
  },
  {
    "label": "Dinner",
    "icon": Icons.restaurant_menu, // 🍽️
  },
  {
    "label": "Party",
    "icon": Icons.celebration, // 🎉
  },
  {
    "label": "Beach",
    "icon": Icons.beach_access, // 🌴
  },
  {
    "label": "Casual",
    "icon": Icons.weekend, // 🛋️
  },
];

final outfitTags = [
  "Summer",
  "Winter",
  "Travel",
  "Casual",
  "Formal",
  "Luxury",
  "Trendy",
  "Streetwear",
  "Vintage",
  "Sporty",
  "Chic",
  "Night Out",
];

class AddOrEditOutfitScreen extends StatefulWidget {
  final OutfitModel? outfitModel;
  const AddOrEditOutfitScreen({super.key, this.outfitModel});

  @override
  State<AddOrEditOutfitScreen> createState() => _AddOrEditOutfitScreenState();
}

class _AddOrEditOutfitScreenState extends State<AddOrEditOutfitScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _styleController;
  late TextEditingController _occasionController;
  late TextEditingController _tagsController;
  late List<FeaturedMediaModel> previewImages = [];

  late UserBloc userBloc;
  //late List<Color> _selectedColors = [];
  late bool isEdit = false;
  List<String> selectedTags = [];

  @override
  void initState() {
    super.initState();
    isEdit = widget.outfitModel!.uid!.isNotEmpty ? true : false;
    userBloc = context.read<UserBloc>();
    _styleController = TextEditingController();
    _styleController.text = widget.outfitModel?.style ?? '';
    _occasionController = TextEditingController();
    _occasionController.text = widget.outfitModel?.occassion ?? '';
    _tagsController = TextEditingController();
    selectedTags = widget.outfitModel?.tags?.split('|') ?? [];
    widget.outfitModel?.closetItems.forEach((item) {
      previewImages.add(item.featuredMedia.first);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final random = Random();
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: Text(
          'Add outfit to your closet',
          style: textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: CustomIconButtonRounded(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  await _saveOutfitItem(
                    widget.outfitModel ?? OutfitModel.empty(),
                  );
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
          padding: const EdgeInsets.all(12),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height:
                      MediaQuery.of(context).size.height *
                      0.40, // 👈 40% of screen height
                  child: Container(
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: MasonryGridView.builder(
                      //padding: const EdgeInsets.only(top: 4),
                      shrinkWrap:
                          true, // ✅ important when inside SingleChildScrollView
                      physics:
                          const NeverScrollableScrollPhysics(), // ✅ let parent handle scroll
                      cacheExtent: 10,
                      gridDelegate:
                          SliverSimpleGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: previewImages.length > 4 ? 3 : 2,
                          ),
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 2,
                      itemCount: previewImages.length,
                      itemBuilder: (context, index) {
                        final preview = previewImages[index];
                        // 👇 Assign different aspect ratios randomly for variety
                        final aspectRatioOptions = [1 / 1];
                        final aspectRatio =
                            aspectRatioOptions[random.nextInt(
                              aspectRatioOptions.length,
                            )];
                        return Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: AspectRatio(
                            aspectRatio: aspectRatio,
                            child: CachedNetworkImage(
                              imageUrl: preview.url!.isEmpty
                                  ? ''
                                  : preview.url!.trim(),
                              fit: BoxFit.cover,
                              placeholder: (context, url) => const Center(
                                child: SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) {
                                return const CustomColoredBanner(text: '');
                              },
                              errorListener: (value) {},
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                CustomTextInputFieldWidget(
                  autofocus: true,
                  controller: _styleController,
                  hint: 'Describe your style inspiration...',
                  minLines: 1,
                  maxLength: 50,
                  validator: (value) {
                    if ((value ?? "").isEmpty) {
                      return 'Describe your style inspiration...';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 8),
                CustomAutocompleteFormFieldWidget(
                  controller: _occasionController,
                  autoCompleteItems: occasions,
                  hintText: 'Describe the occassion...',
                ),
                const SizedBox(height: 16),
                Text('Featured tags', style: textTheme.titleSmall),
                const SizedBox(height: 8),
                OutfitTagPickerWidget(
                  availableTags: outfitTags,
                  selectedTags: selectedTags,
                  onChanged: (newTags) {
                    setState(() {
                      selectedTags = newTags;
                      _tagsController.text = newTags.join('|');
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _saveOutfitItem(OutfitModel outfit) async {
    try {
      User user = userBloc.state;
      String createdBy =
          user.uid ?? firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      //_buttonLoadingStateCubit.setLoading(true);
      final style = _styleController.text.trim();
      final occassion = _occasionController.text.trim();
      final tags = _tagsController.text.trim();
      final outfitId = isEdit ? outfit.uid : Uuid().v4();
      final createdAt = isEdit
          ? outfit.createdAt
          : DateTime.now().millisecondsSinceEpoch;

      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      outfit = outfit.copyWith(
        uid: outfitId,
        style: style,
        occassion: occassion,
        tags: tags,
        createdAt: createdAt,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
        createdBy: createdBy,
        isFavourite: false,
      );

      final result = isEdit
          ? await sl<FirebaseClosetService>().updateOutfit(outfit)
          : await sl<FirebaseClosetService>().addOutfit(outfit);

      result.fold(
        (l) {
          // _buttonLoadingStateCubit.setLoading(false);
          if (mounted) {
            Navigator.of(context).pop();
          }
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l)));
        },
        (r) {
          // _buttonLoadingStateCubit.setLoading(false);
          if (!mounted) return;
          context.read<ClosetOutfitBloc>().add(
            const LoadOutfitsCacheFirstThenNetwork(''),
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✅ Outfit saved successfully!')),
          );
          Navigator.pop(context);
          if (!isEdit) {
            Navigator.pop(context, true);
          }
        },
      );
    } on firebase_auth.FirebaseException catch (e) {
      //_buttonLoadingStateCubit.setLoading(false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }

  @override
  void dispose() {
    _styleController.dispose();
    _occasionController.dispose();
    _tagsController.dispose();
    previewImages.clear();
    super.dispose();
  }
}
