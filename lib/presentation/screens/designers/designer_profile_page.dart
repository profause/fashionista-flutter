import 'package:fashionista/core/assets/app_icons.dart';
import 'package:fashionista/data/models/designers/bloc/designer_bloc.dart';
import 'package:fashionista/data/models/designers/bloc/designer_event.dart';
import 'package:fashionista/data/models/designers/bloc/designer_state.dart';
import 'package:fashionista/presentation/screens/designers/edit_designer_profile_screen.dart';
import 'package:fashionista/presentation/screens/designers/widgets/featured_images_widget.dart';
import 'package:fashionista/presentation/screens/profile/widgets/profile_info_card_widget.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_icon_rounded.dart';
import 'package:fashionista/presentation/widgets/rating_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DesignerProfilePage extends StatefulWidget {
  final String designerUid;
  const DesignerProfilePage({super.key, required this.designerUid});

  @override
  State<DesignerProfilePage> createState() => _DesignerProfilePageState();
}

class _DesignerProfilePageState extends State<DesignerProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<DesignerBloc>().add(LoadDesigner(widget.designerUid));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocBuilder<DesignerBloc, DesignerState>(
        builder: (context, state) {
          switch (state) {
            case DesignerLoading():
              return const Center(child: CircularProgressIndicator());
            case DesignerLoaded(:final designer):
              return SingleChildScrollView(
                child: Column(
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
                          suffix: CustomIconButtonRounded(
                            iconData: Icons.arrow_right,
                            size: 24,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditDesignerProfileScreen(
                                        designer: designer,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ProfileInfoCardWidget(
                      items: [
                        ProfileInfoItem(
                          icon: Icons.store_mall_directory_outlined,
                          title: 'Business Name',
                          value: designer.businessName == ''
                              ? 'No business name'
                              : designer.businessName,
                          suffix: CustomIconButtonRounded(
                            iconData: Icons.arrow_right,
                            size: 24,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditDesignerProfileScreen(
                                        designer: designer,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                        ProfileInfoItem(
                          icon: Icons.map_outlined,
                          title: 'Location',
                          value: designer.location == ''
                              ? 'No location'
                              : designer.location,
                          suffix: CustomIconButtonRounded(
                            iconData: Icons.edit_location,
                            size: 24,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      EditDesignerProfileScreen(
                                        designer: designer,
                                      ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    FeaturedImagesWidget(designer: designer),
                    const SizedBox(height: 8),
                    Card(
                      color: colorScheme.onPrimary,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.zero, // instead of circular(0)
                      ),
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: SizedBox(
                        width: double.infinity, // 👈 makes the card full width
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Likes & Ratings',
                                style: textTheme.titleSmall,
                              ),
                              const SizedBox(height: 4),
                              RatingInputWidget(
                                initialRating: designer.ratings!,
                                color: colorScheme.primary,
                                size: 24,
                                readOnly: true,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: colorScheme.onPrimary,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.zero, // instead of circular(0)
                      ),
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: SizedBox(
                        width: double.infinity, // 👈 makes the card full width
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Socials', style: textTheme.titleSmall),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Image.asset(
                                    AppIcons.facebook,
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(width: 8),
                                  Image.asset(
                                    AppIcons.x,
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(width: 8),
                                  Image.asset(
                                    AppIcons.instagram,
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(width: 8),
                                  Image.asset(
                                    AppIcons.tiktok,
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.cover,
                                  ),
                                  const SizedBox(width: 8),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      color: colorScheme.onPrimary,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.zero, // instead of circular(0)
                      ),
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      child: SizedBox(
                        width: double.infinity, // 👈 makes the card full width
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
                              Row(
                                children: [
                                  Text(
                                    designer.bio ?? '',
                                    style: textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Divider(color: Colors.grey.shade300),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  CustomIconRounded(icon: Icons.tag),
                                  const SizedBox(width: 8),
                                  Text("Featured Tags"),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: List.generate(
                                  designer.tags.split('|').length,
                                  (index) => Chip(
                                    label: Text(
                                      designer.tags.split('|')[index],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    //MultiImageUploader(userId: designer.uid),
                  ],
                ),
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
