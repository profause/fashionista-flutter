import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/get_relative_time.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/featured_media/featured_media_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/social_interactions/social_interaction_model.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_event.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/domain/usecases/trends/like_or_unlike_trend_usecase.dart';
import 'package:fashionista/presentation/screens/trends/trend_details_screen.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:fashionista/presentation/widgets/video_preview_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrendInfoCardWidgetDiscoverPage extends StatefulWidget {
  final TrendFeedModel trendInfo;
  const TrendInfoCardWidgetDiscoverPage({super.key, required this.trendInfo});

  @override
  State<TrendInfoCardWidgetDiscoverPage> createState() =>
      _TrendInfoCardWidgetDiscoverPageState();
}

class _TrendInfoCardWidgetDiscoverPageState
    extends State<TrendInfoCardWidgetDiscoverPage>
    with SingleTickerProviderStateMixin {
  final ValueNotifier<bool> isLikedNotifier = ValueNotifier(false);
  late AnimationController _controller;
  late UserBloc _userBloc;

  @override
  void initState() {
    _userBloc = context.read<UserBloc>();
    isLikedNotifier.value = widget.trendInfo.isLiked!;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    isLikedNotifier.addListener(() {
      if (isLikedNotifier.value) {
        if (!mounted) return;
        _controller.forward(from: 0); // restart burst animation
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final FeaturedMediaModel featuredMedia =
        widget.trendInfo.featuredMedia.first;

    return Material(
      color: colorScheme.onPrimary,
      //borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias, // ensures ripple stays within rounded shape
      child: InkWell(
        //borderRadius: BorderRadius.circular(12),
        splashColor: colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: Colors.transparent,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TrendDetailsScreen(
                trendInfo: widget.trendInfo,
                initialIndex: 0,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                color: Colors.white,
                borderOnForeground: true,
                borderRadius: BorderRadius.circular(60),
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {},
                    child: widget.trendInfo.author.avatar!.isNotEmpty
                        ? CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.lightGrey,
                            backgroundImage: CachedNetworkImageProvider(
                              widget.trendInfo.author.avatar!,
                              errorListener: (p0) {},
                            ),
                          )
                        : DefaultProfileAvatar(
                            name: null,
                            size: 18 * 1.8,
                            uid: widget.trendInfo.author.uid!,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.trendInfo.author.name!,
                      style: textTheme.labelLarge!.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.trendInfo.description,
                      style: textTheme.bodyMedium!,
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: widget.trendInfo.tags!.isEmpty
                          ? [const SizedBox(height: 1)]
                          : widget.trendInfo.tags!
                                .split(',')
                                .where((tag) => tag.trim().isNotEmpty)
                                .map(
                                  (tag) => Chip(
                                    elevation: 0,
                                    backgroundColor: Colors.transparent,
                                    label: Text('#$tag'),
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      side: BorderSide(
                                        color: colorScheme.surface,
                                        width: 1,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                )
                                .toList(),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: AspectRatio(
                        aspectRatio:
                            featuredMedia.type!.toLowerCase() == 'video'
                            ? 9 / 16
                            : featuredMedia.aspectRatio ?? 1 / 1,
                        child: featuredMedia.type!.toLowerCase() == 'video'
                            ? VideoPreviewWidget(
                                videoUrl:
                                    widget.trendInfo.featuredMedia.first.url!,
                                onTap: () {},
                              )
                            : CachedNetworkImage(
                                imageUrl: widget.trendInfo.featuredMedia.isEmpty
                                    ? ''
                                    : featuredMedia.url!.trim(),
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
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.only(right: 8),
                      child: Row(
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CustomIconButtonRounded(
                                backgroundColor: Colors.transparent,
                                onPressed: () {},
                                iconData: Icons.access_time,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatRelativeTime(widget.trendInfo.createdAt!),
                                style: textTheme.bodySmall,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.end,
                            spacing: 12,
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  CustomIconButtonRounded(
                                    backgroundColor: Colors.transparent,
                                    onPressed: () {},
                                    iconData: Icons.comment_outlined,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.trendInfo.numberOfComments}',
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ValueListenableBuilder<bool>(
                                    valueListenable: isLikedNotifier,
                                    builder: (_, isLiked, __) {
                                      return CustomIconButtonRounded(
                                        backgroundColor: Colors.transparent,
                                        onPressed: () async {
                                          isLikedNotifier.value = !isLiked;

                                          final author = AuthorModel.empty()
                                              .copyWith(
                                                uid: _userBloc.state.uid,
                                                name: _userBloc.state.fullName,
                                                avatar: _userBloc
                                                    .state
                                                    .profileImage,
                                              );
                                          final result =
                                              await sl<
                                                    LikeOrUnlikeTrendUsecase
                                                  >()
                                                  .call(
                                                    SocialInteractionModel.empty()
                                                        .copyWith(
                                                          refId: widget
                                                              .trendInfo
                                                              .uid,
                                                          author: author,
                                                        ),
                                                  );
                                          result.fold((l) {}, (r) {
                                            isLikedNotifier.value = r;
                                            final t = widget.trendInfo.copyWith(
                                              isLiked: r,
                                            );
                                            context.read<TrendBloc>().add(
                                              UpdateCachedTrend(t),
                                            );
                                            if (!mounted) return;
                                            setState(() {
                                              isLiked = r;
                                            });
                                          });
                                        },
                                        iconData: Icons.favorite_border,
                                        icon: AnimatedSwitcher(
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          transitionBuilder:
                                              (child, animation) {
                                                final inAnimation =
                                                    Tween<Offset>(
                                                      begin: const Offset(
                                                        0,
                                                        0.3,
                                                      ),
                                                      end: Offset.zero,
                                                    ).animate(
                                                      CurvedAnimation(
                                                        parent: animation,
                                                        curve: Curves.bounceOut,
                                                      ),
                                                    );

                                                final outAnimation =
                                                    Tween<Offset>(
                                                      begin: Offset.zero,
                                                      end: const Offset(
                                                        0,
                                                        -0.3,
                                                      ),
                                                    ).animate(
                                                      CurvedAnimation(
                                                        parent: animation,
                                                        curve: Curves.bounceIn,
                                                      ),
                                                    );

                                                if (child.key ==
                                                    ValueKey(isLiked)) {
                                                  return ClipRect(
                                                    child: SlideTransition(
                                                      position: inAnimation,
                                                      child: FadeTransition(
                                                        opacity: animation,
                                                        child: child,
                                                      ),
                                                    ),
                                                  );
                                                } else {
                                                  return ClipRect(
                                                    child: SlideTransition(
                                                      position: outAnimation,
                                                      child: FadeTransition(
                                                        opacity: animation,
                                                        child: child,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              },
                                          child: Icon(
                                            size: 16,
                                            isLiked
                                                ? Icons.favorite
                                                : Icons
                                                      .favorite_border_outlined,
                                            key: ValueKey(isLiked),
                                          ),
                                        ),
                                        size: 16,
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${widget.trendInfo.numberOfLikes}',
                                    style: textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
