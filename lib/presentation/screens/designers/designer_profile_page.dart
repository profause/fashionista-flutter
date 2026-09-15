import 'package:fashionista/core/theme/app.theme.dart';
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
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

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
    final textTheme = Theme.of(context).textTheme;

    return BlocBuilder<DesignerBloc, DesignerState>(
      builder: (context, state) {
        switch (state) {
          case DesignerLoading():
            return const Center(child: CircularProgressIndicator());
          case DesignerLoaded(:final designer):
            // ✅ Use ListView so it respects TabBarView constraints
            return ListView(
              padding: const EdgeInsets.only(
                top: 8,
                bottom: 20,
                left: 16,
                right: 16,
              ),
              children: [
                FilledButton.icon(
                  onPressed: () {
                    context.push('/designers/${designer.uid}');
                  },
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Go to designer page'),
                  style: FilledButton.styleFrom(
                    backgroundColor: context.accent,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ProfileInfoCardWidget(
                  items: [
                    ProfileInfoItem(
                      icon: Icons.person_outline_outlined,
                      title: 'Designer name',
                      value: designer.name,
                      suffix: CustomIconButtonRounded(
                        iconData: Icons.edit,
                        size: 18,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditDesignerProfileScreen(designer: designer),
                            ),
                          );
                        },
                      ),
                    ),
                    ProfileInfoItem(
                      icon: Icons.store_mall_directory_outlined,
                      title: 'Business name',
                      value: designer.businessName.isEmpty
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
                                  EditDesignerProfileScreen(designer: designer),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ProfileInfoCardWidget(
                  items: [
                    ProfileInfoItem(
                      icon: Icons.phone_android_outlined,
                      title: 'Mobile number',
                      value: designer.mobileNumber,
                      suffix: CustomIconButtonRounded(
                        iconData: Icons.arrow_right,
                        size: 24,
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  EditDesignerProfileScreen(designer: designer),
                            ),
                          );
                        },
                      ),
                    ),
                    ProfileInfoItem(
                      icon: Icons.map_outlined,
                      title: 'Location',
                      value: designer.location.isEmpty
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
                                  EditDesignerProfileScreen(designer: designer),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FeaturedImagesWidget(designer: designer),
                const SizedBox(height: 12),

                /// Likes & Ratings card
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Likes & Ratings', style: textTheme.titleSmall),
                      const SizedBox(height: 8),
                      RatingInputWidget(
                        initialRating: designer.averageRating ?? 0,
                        color: context.accent,
                        size: 24,
                        readOnly: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                /// Socials card
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Socials', style: textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            HugeIcons.strokeRoundedFacebook01,
                            size: 32,
                            color: context.onCanvasText,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            HugeIcons.strokeRoundedNewTwitter,
                            size: 32,
                            color: context.onCanvasText,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            HugeIcons.strokeRoundedInstagram,
                            size: 32,
                            color: context.onCanvasText,
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            HugeIcons.strokeRoundedTiktok,
                            size: 32,
                            color: context.onCanvasText,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                /// Bio + Tags card
                _SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const CustomIconRounded(
                            icon: Icons.account_box_outlined,
                          ),
                          const SizedBox(width: 8),
                          Text('Bio', style: textTheme.titleSmall),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(designer.bio ?? '', style: textTheme.bodyMedium),
                      const SizedBox(height: 12),
                      Divider(color: context.hairline, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const CustomIconRounded(icon: Icons.tag),
                          const SizedBox(width: 8),
                          Text('Featured Tags', style: textTheme.titleSmall),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: -6, // 👈 reduced padding
                        children: designer.tags.isEmpty
                            ? [const SizedBox(height: 1)]
                            : designer.tags
                                  .split('|')
                                  .map(
                                    (tag) => Chip(
                                      label: Text(tag),
                                      backgroundColor: context.iconSubstrate,
                                      labelStyle: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: context.onCanvasText,
                                      ),
                                      side: BorderSide(color: context.hairline),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18),
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                    ),
                                  )
                                  .toList(),
                      ),
                    ],
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
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.hairline),
      ),
      child: child,
    );
  }
}
