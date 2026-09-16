import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/designers/bloc/designer_bloc.dart';
import 'package:fashionista/data/models/designers/bloc/designer_event.dart';
import 'package:fashionista/data/models/designers/bloc/designer_state.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/presentation/screens/designers/designer_collection_page.dart';
import 'package:fashionista/presentation/screens/designers/designer_details_profile_page.dart';
import 'package:fashionista/presentation/screens/designers/designer_review_page.dart';
import 'package:fashionista/presentation/widgets/banner_image_widget.dart';
import 'package:fashionista/presentation/widgets/custom_favourite_designer_icon_button.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

class DesignerDetailsScreen extends StatefulWidget {
  final String designerId;
  const DesignerDetailsScreen({super.key, required this.designerId});

  @override
  State<DesignerDetailsScreen> createState() => _DesignerDetailsScreenState();
}

class _DesignerDetailsScreenState extends State<DesignerDetailsScreen> {
  static const double _coverHeight = 176;

  @override
  void initState() {
    super.initState();
    // Show status bar, hide navigation bar
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top], // keep only status bar
    );

    context.read<DesignerBloc>().add(
      LoadDesigner(widget.designerId, isFromCache: true),
    );
  }

  @override
  void dispose() {
    // Restore system UI when leaving
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return BlocBuilder<DesignerBloc, DesignerState>(
      buildWhen: (context, state) {
        return state is DesignerLoaded || state is DesignerUpdated;
      },
      builder: (context, state) {
        final designer = switch (state) {
          DesignerLoaded(:final designer) => designer,
          DesignerUpdated(:final designer) => designer,
          _ => null,
        };
        if (designer == null) {
          if (state is DesignerError) {
            return Scaffold(
              backgroundColor: colorScheme.surface,
              body: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Error: ${state.message}'),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => context.read<DesignerBloc>().add(
                        LoadDesigner(
                          widget.designerId,
                          isFromCache: false,
                        ),
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            backgroundColor: context.canvasBackground,
            appBar: AppBar(
              backgroundColor: context.canvasBackground,
              foregroundColor: context.onCanvasText,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              title: Text('Profile', style: textTheme.titleMedium),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new),
                onPressed: () => context.pop(),
              ),
            ),
            body: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildCover(designer),
                  _buildIdentity(designer),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _TabBarDelegate(
                      color: context.cardSurface,
                      tabBar: TabBar(
                        labelColor: context.accent,
                        unselectedLabelColor: context.mutedText,
                        indicatorColor: context.accent,
                        dividerColor: context.hairline,
                        dividerHeight: 1,
                        indicatorWeight: 3,
                        indicatorSize: TabBarIndicatorSize.label,
                        labelPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                        tabAlignment: TabAlignment.start,
                        labelStyle: textTheme.titleSmall!.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: const [
                          Tab(text: 'About'),
                          Tab(text: 'Highlights & Collections'),
                          Tab(text: 'Reviews'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  DesignerDetailsProfilePage(designer: designer),
                  DesignerCollectionPage(designer: designer),
                  DesignerReviewPage(designer: designer),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCover(Designer designer) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: _coverHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            BannerImageWidget(
              uid: designer.uid,
              url: ValueNotifier(designer.bannerImage!),
              isEditable: false,
              height: _coverHeight,
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.25, 1],
                  colors: [
                    Colors.black.withValues(alpha: 0.3),
                    Colors.transparent,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 16,
              child: _FloatingCircleButton(
                icon: Icons.ios_share,
                onPressed: () => _shareProfile(designer),
              ),
            ),
            Positioned(
              top: 12,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: CustomFavouriteDesignerIconButton(
                  designerId: widget.designerId,
                  isFavouriteNotifier: ValueNotifier(designer.isFavourite!),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdentity(Designer designer) {
    final textTheme = Theme.of(context).textTheme;
    final double? averageRating = designer.averageRating;
    final int? reviewCount = designer.reviewCount;

    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.translate(
            offset: const Offset(0, -40),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Hero(tag: designer.uid, child: buildProfileAvatar(designer)),
                  const Spacer(),
                  _MessageButton(onPressed: () => _showContactSheet(designer)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        designer.name,
                        style: textTheme.headlineSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: context.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        'Designer',
                        style: textTheme.labelSmall!.copyWith(
                          color: context.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (averageRating != null) ...[
                      _InfoPill(
                        icon: Icons.star_rounded,
                        iconColor: context.accent,
                        label:
                            '${averageRating.toStringAsFixed(1)}'
                            '${reviewCount != null && reviewCount > 0 ? ' ($reviewCount reviews)' : ''}',
                      ),
                    ],
                    if (designer.location.isNotEmpty)
                      _InfoPill(
                        icon: Icons.location_on_outlined,
                        iconColor: context.secondaryLabel,
                        label: designer.location,
                      ),
                  ],
                ),
                if ((designer.bio ?? '').isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote,
                        size: 18,
                        color: context.mutedText,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          designer.bio!,
                          style: textTheme.bodyMedium!.copyWith(
                            fontStyle: FontStyle.italic,
                            color: context.descriptionText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget buildProfileAvatar(Designer designer) {
    const double radius = 42;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: Colors.white,
          borderOnForeground: true,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: const EdgeInsets.all(4.0),
            child: InkWell(
              borderRadius: BorderRadius.circular(radius),
              onTap: () {},
              child: designer.profileImage != ''
                  ? CircleAvatar(
                      radius: radius,
                      backgroundColor: AppTheme.lightGrey,
                      backgroundImage: CachedNetworkImageProvider(
                        designer.profileImage!,
                        errorListener: (error) {},
                      ),
                    )
                  : DefaultProfileAvatar(
                      name: null,
                      size: radius * 1.8,
                      uid: designer.uid,
                    ),
            ),
          ),
        ),
      ],
    );
  }

  void _shareProfile(Designer designer) {
    final lines = <String>[
      designer.name,
      if (designer.businessName.isNotEmpty) designer.businessName,
      if (designer.location.isNotEmpty) designer.location,
    ];
    Clipboard.setData(ClipboardData(text: lines.join('\n')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile details copied to clipboard')),
    );
  }

  void _showContactSheet(Designer designer) {
    final textTheme = Theme.of(context).textTheme;
    final mobileNumber = designer.mobileNumber;
    if (mobileNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This designer has no contact number yet')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(designer.name, style: textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  mobileNumber,
                  style: textTheme.bodyMedium!.copyWith(
                    color: context.mutedText,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          await _launchUri(
                            Uri(scheme: 'tel', path: mobileNumber),
                          );
                        },
                        icon: const Icon(Icons.call, size: 18),
                        label: const Text('Call'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          await _launchUri(
                            Uri(scheme: 'sms', path: mobileNumber),
                          );
                        },
                        icon: const Icon(Icons.sms_outlined, size: 18),
                        label: const Text('SMS'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: mobileNumber));
                          if (sheetContext.mounted) {
                            Navigator.pop(sheetContext);
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Mobile number copied'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.copy_outlined, size: 18),
                        label: const Text('Copy'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _launchUri(Uri uri) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open that action')),
        );
      }
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open that action')),
      );
    }
  }
}

class _FloatingCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  const _FloatingCircleButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      elevation: 2,
      shadowColor: const Color(0x33000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: Colors.black87),
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  const _InfoPill({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.hairline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium!.copyWith(
                color: context.onCanvasText,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _MessageButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Material(
      color: context.accent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            children: [
              const Icon(Icons.chat_bubble_outline, size: 17, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                'Message',
                style: textTheme.labelLarge!.copyWith(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final Color color;
  final TabBar tabBar;
  const _TabBarDelegate({required this.color, required this.tabBar});

  @override
  double get minExtent => 48;

  @override
  double get maxExtent => 48;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(color: color, child: tabBar);
  }

  @override
  bool shouldRebuild(covariant _TabBarDelegate oldDelegate) {
    return color != oldDelegate.color || tabBar != oldDelegate.tabBar;
  }
}