import 'package:fashionista/core/assets/app_icons.dart';
import 'package:fashionista/data/models/designers/bloc/designer_bloc.dart';
import 'package:fashionista/data/models/designers/bloc/designer_event.dart';
import 'package:fashionista/data/models/designers/bloc/designer_state.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/presentation/screens/designers/widgets/featured_images_widget.dart';
import 'package:fashionista/presentation/screens/profile/widgets/profile_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/custom_icon_rounded.dart';
import 'package:fashionista/presentation/widgets/rating_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';

class DesignerDetailsProfilePage extends StatefulWidget {
  final Designer designer;
  const DesignerDetailsProfilePage({super.key, required this.designer});

  @override
  State<DesignerDetailsProfilePage> createState() =>
      _DesignerDetailsProfilePageState();
}

class _DesignerDetailsProfilePageState
    extends State<DesignerDetailsProfilePage> {
  @override
  void initState() {
    super.initState();
    //context.read<DesignerBloc>().add(UpdateDesigner(widget.designer));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocProvider(
      create: (_) => DesignerBloc()..add(UpdateDesigner(widget.designer)),
      child: BlocBuilder<DesignerBloc, DesignerState>(
        builder: (context, state) {
          switch (state) {
            case DesignerLoading():
              return const Center(child: CircularProgressIndicator());
            case DesignerLoaded(:final designer):
              // ✅ Use ListView so it respects TabBarView constraints
              return ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  ProfileInfoCardWidget(
                    items: [
                      ProfileInfoItem(
                        icon: Icons.person_outline_outlined,
                        title: '',
                        value: designer.name,
                      ),
                    ],
                  ),
                  ProfileInfoCardWidget(
                    items: [
                      ProfileInfoItem(
                        icon: Icons.phone_android_outlined,
                        title: 'Mobile Number',
                        value: designer.mobileNumber,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ProfileInfoCardWidget(
                    items: [
                      ProfileInfoItem(
                        icon: Icons.store_mall_directory_outlined,
                        title: 'Business Name',
                        value: designer.businessName.isEmpty
                            ? 'No business name'
                            : designer.businessName,
                      ),
                      ProfileInfoItem(
                        icon: Icons.map_outlined,
                        title: 'Location',
                        value: designer.location.isEmpty
                            ? 'No location'
                            : designer.location,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  FeaturedImagesWidget(designer: designer, isEditable: false),
                  const SizedBox(height: 8),

                  /// Likes & Ratings card
                  Card(
                    color: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Likes & Ratings', style: textTheme.titleSmall),
                          const SizedBox(height: 4),
                          RatingInputWidget(
                            initialRating: designer.averageRating ?? 0,
                            color: colorScheme.primary,
                            size: 24,
                            readOnly: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  /// Socials card
                  Card(
                    color: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(0),
                    ),
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Socials', style: textTheme.titleSmall),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                HugeIcons.strokeRoundedFacebook01,
                                size: 32,
                                color: colorScheme.onSurface,
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                HugeIcons.strokeRoundedNewTwitter,
                                size: 32,
                                color: colorScheme.onSurface,
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                HugeIcons.strokeRoundedInstagram,
                                size: 32,
                                color: colorScheme.onSurface,
                              ),
                              const SizedBox(width: 8),
                              Icon(
                                HugeIcons.strokeRoundedTiktok,
                                size: 32,
                                color: colorScheme.onSurface,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  /// Bio + Tags card
                  Card(
                    color: colorScheme.onPrimary,
                    margin: const EdgeInsets.symmetric(vertical: 2),
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
                              Text("Bio", style: textTheme.titleSmall),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(designer.bio ?? '', style: textTheme.bodyMedium),
                          const SizedBox(height: 8),
                          Divider(color: Colors.grey.shade300),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              CustomIconRounded(icon: Icons.tag),
                              const SizedBox(width: 8),
                              Text(
                                "Featured Tags",
                                style: textTheme.titleSmall,
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6, // 👈 reduced padding
                            children: designer.tags.isEmpty
                                ? [SizedBox(height: 1)]
                                : designer.tags
                                      .split('|')
                                      .where((tag) => tag.trim().isNotEmpty)
                                      .map((tag) => Chip(label: Text(tag)))
                                      .toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            case DesignerError(:final message):
              return Center(child: Text("Error: $message"));
            default:
              return const Center(child: Text("No designer data"));
          }
        },
      ),
    );
  }
}
