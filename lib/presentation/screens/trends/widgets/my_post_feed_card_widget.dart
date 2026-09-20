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
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:fashionista/presentation/widgets/video_preview_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

/// Stitch-styled feed card (author header, 4:5 media, interaction footer) used
/// by the "My Posts" section of the For You tab.
class MyPostFeedCardWidget extends StatefulWidget {
  const MyPostFeedCardWidget({
    super.key,
    required this.trendInfo,
    this.onLikeTap,
  });

  final TrendFeedModel trendInfo;
  final Function(bool)? onLikeTap;

  @override
  State<MyPostFeedCardWidget> createState() => _MyPostFeedCardWidgetState();
}

class _MyPostFeedCardWidgetState extends State<MyPostFeedCardWidget> {
  final ValueNotifier<bool> isLikedNotifier = ValueNotifier<bool>(false);
  late UserBloc _userBloc;
  late int _likeCount;

  @override
  void initState() {
    _userBloc = context.read<UserBloc>();
    isLikedNotifier.value = widget.trendInfo.isLiked ?? false;
    _likeCount = widget.trendInfo.numberOfLikes ?? 0;
    super.initState();
  }

  @override
  void dispose() {
    isLikedNotifier.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    final bool next = !isLikedNotifier.value;
    isLikedNotifier.value = next;
    setState(() => _likeCount = _updatedCount(next));

    final author = AuthorModel.empty().copyWith(
      uid: _userBloc.state.uid,
      name: _userBloc.state.fullName,
      avatar: _userBloc.state.profileImage,
    );

    final result = await sl<LikeOrUnlikeTrendUsecase>().call(
      SocialInteractionModel.empty().copyWith(
        refId: widget.trendInfo.uid,
        author: author,
      ),
    );

    result.fold((failure) {}, (isLiked) {
      if (!mounted) return;
      isLikedNotifier.value = isLiked;
      if (isLiked != next) {
        setState(() => _likeCount = _updatedCount(isLiked));
      }
      widget.onLikeTap?.call(isLiked);
      context.read<TrendBloc>().add(
        UpdateTrend(widget.trendInfo.copyWith(isLiked: isLiked)),
      );
    });
  }

  int _updatedCount(bool isLiked) {
    final int base = widget.trendInfo.numberOfLikes ?? 0;
    return isLiked ? base + 1 : base;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final trend = widget.trendInfo;
    final String avatar = trend.author.avatar ?? '';
    final String name = trend.author.name ?? '';
    final String createdAt = trend.createdAt == null
        ? ''
        : formatRelativeTime(trend.createdAt!);

    return Container(
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.hairline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/trends/${trend.uid}'),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, textTheme, avatar, name, createdAt),
              _buildMedia(context),
              Padding(
                padding: const EdgeInsets.only(top: 12, left: 4, right: 4),
                child: Row(
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: isLikedNotifier,
                      builder: (context, isLiked, _) {
                        return _FeedActionButton(
                          icon: isLiked
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: isLiked ? context.accent : context.secondaryLabel,
                          label: '$_likeCount',
                          onTap: _toggleLike,
                        );
                      },
                    ),
                    const SizedBox(width: 16),
                    _FeedActionButton(
                      icon: Icons.chat_bubble_outline,
                      label: '${trend.numberOfComments ?? 0}',
                      onTap: () => context.push('/trends/${trend.uid}'),
                    ),
                    const SizedBox(width: 16),
                    _FeedActionButton(
                      icon: Icons.ios_share,
                      onTap: () {},
                    ),
                    const Spacer(),
                    _FeedActionButton(
                      icon: Icons.bookmark_border,
                      onTap: () {},
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

  Widget _buildHeader(
    BuildContext context,
    TextTheme textTheme,
    String avatar,
    String name,
    String createdAt,
  ) {
    return Row(
      children: [
        ClipOval(
          child: SizedBox(
            width: 32,
            height: 32,
            child: avatar.isEmpty
                ? DefaultProfileAvatar(
                    name: name,
                    size: 32,
                    uid: widget.trendInfo.author.uid ?? '',
                  )
                : CachedNetworkImage(
                    imageUrl: avatar,
                    fit: BoxFit.cover,
                    errorListener: (error) {},
                    placeholder: (_, _) => DefaultProfileAvatar(
                      name: name,
                      size: 32,
                      uid: widget.trendInfo.author.uid ?? '',
                    ),
                    errorWidget: (_, _, _) => DefaultProfileAvatar(
                      name: name,
                      size: 32,
                      uid: widget.trendInfo.author.uid ?? '',
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),
              if (widget.trendInfo.description.isNotEmpty)
                Text(
                  widget.trendInfo.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                    height: 1.3,
                    color: context.mutedText,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          createdAt,
          style: textTheme.labelSmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            letterSpacing: 0,
            color: context.mutedText,
          ),
        ),
        IconButton(
          onPressed: () {},
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          icon: Icon(Icons.more_horiz, size: 18, color: context.secondaryLabel),
        ),
      ],
    );
  }

  Widget _buildMedia(BuildContext context) {
    final List<FeaturedMediaModel> media = widget.trendInfo.featuredMedia;
    if (media.isEmpty || (media.first.url ?? '').isEmpty) {
      return const SizedBox.shrink();
    }

    final FeaturedMediaModel featuredMedia = media.first;
    final bool isVideo = featuredMedia.type?.toLowerCase() == 'video';

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: AspectRatio(
          aspectRatio: isVideo
              ? 9 / 16
              : (featuredMedia.aspectRatio ?? 4 / 5),
          child: isVideo
              ? VideoPreviewWidget(videoUrl: featuredMedia.url!, onTap: () {})
              : CachedNetworkImage(
                  imageUrl: featuredMedia.url!.trim(),
                  fit: BoxFit.cover,
                  errorListener: (value) {},
                  placeholder: (context, url) => const Center(
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) =>
                      const CustomColoredBanner(text: ''),
                ),
        ),
      ),
    );
  }
}

class _FeedActionButton extends StatelessWidget {
  const _FeedActionButton({
    required this.icon,
    this.label,
    this.color,
    this.onTap,
  });

  final IconData icon;
  final String? label;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final Color tint = color ?? context.secondaryLabel;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: tint),
            if (label != null) ...[
              const SizedBox(width: 6),
              Text(
                label!,
                style: textTheme.labelSmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                  color: color ?? context.onCanvasText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
