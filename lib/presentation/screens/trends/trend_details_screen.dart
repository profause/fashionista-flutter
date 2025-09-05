import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/models/trends/bloc/trend_comment_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_comment_bloc_event.dart';
import 'package:fashionista/data/models/trends/bloc/trend_comment_bloc_state.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/domain/usecases/trends/add_trend_comment_usecase.dart';
import 'package:fashionista/presentation/screens/trends/widgets/comment_widget.dart';
import 'package:fashionista/presentation/screens/trends/widgets/custom_trend_like_button_widget.dart';
import 'package:fashionista/presentation/widgets/custom_colored_banner.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:fashionista/presentation/widgets/video_preview_widget.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TrendDetailsScreen extends StatefulWidget {
  final TrendFeedModel trendInfo;
  final int initialIndex;
  const TrendDetailsScreen({
    super.key,
    required this.trendInfo,
    required this.initialIndex,
  });

  @override
  State<TrendDetailsScreen> createState() => _TrendDetailsScreenState();
}

class _TrendDetailsScreenState extends State<TrendDetailsScreen> {
  late PageController _controller;
  late int _currentIndex;
  bool showDetails = true;
  final userId = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _commentController = TextEditingController();
  bool addCommentLoading = false;

  @override
  void initState() {
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
    context.read<TrendCommentBloc>().add(
      LoadTrendCommentsCacheFirstThenNetwork(widget.trendInfo.uid!),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: Text(
          'Trend',
          style: textTheme.titleLarge!.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        elevation: 0,
        actions: [
          if (userId == widget.trendInfo.createdBy) ...[
            IconButton(
              onPressed: () async {
                final canDelete = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete Post'),
                    content: const Text(
                      'Are you sure you want to delete this post?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red,
                        ),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );

                if (canDelete == true) {
                  if (mounted) {
                    showDialog(
                      context: context,
                      barrierDismissible: false, // Prevent dismissing
                      builder: (_) =>
                          const Center(child: CircularProgressIndicator()),
                    );
                  }

                  _deleteTrend(widget.trendInfo);
                }
              },
              icon: Icon(Icons.delete),
              color: colorScheme.primary,
            ),
            //const SizedBox(width: 4,),
          ],
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(12),
          physics: const BouncingScrollPhysics(),
          children: [
            Row(
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
                              radius: 30,
                              backgroundColor: AppTheme.lightGrey,
                              backgroundImage: CachedNetworkImageProvider(
                                widget.trendInfo.author.avatar!,
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
                Text(
                  widget.trendInfo.author.name!,
                  style: textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(height: 16, thickness: 1, color: Colors.grey[300]),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.trendInfo.description.trim(),
                style: textTheme.bodyLarge,
                textAlign: TextAlign.start,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height:
                  MediaQuery.of(context).size.height *
                  0.5, // take half screen height
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  GestureDetector(
                    onTap: () => setState(() {
                      showDetails = !showDetails;
                    }), //Navigator.pop(context, true),
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: widget.trendInfo.featuredMedia.length,
                      onPageChanged: (index) {
                        setState(() => _currentIndex = index);
                      },
                      itemBuilder: (context, index) {
                        final featuredMedia =
                            widget.trendInfo.featuredMedia[index];
                        return AspectRatio(
                          aspectRatio:
                              featuredMedia.type!.toLowerCase() == 'video'
                              ? 9 / 16
                              : featuredMedia.aspectRatio ?? 16 / 9,
                          child: featuredMedia.type!.toLowerCase() == 'video'
                              ? VideoPreviewWidget(
                                  videoUrl: featuredMedia.url!,
                                  aspectRatio: 9 / 16,
                                )
                              : CachedNetworkImage(
                                  imageUrl: featuredMedia.url!.isEmpty
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
                                    return const CustomColoredBanner(
                                      text: 'No Image',
                                    );
                                  },
                                ),
                        );
                      },
                    ),
                  ),
                  // Dot indicators
                  Positioned(
                    bottom: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        widget.trendInfo.featuredMedia.length,
                        (index) {
                          final isActive = index == _currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            height: 8,
                            width: isActive ? 20 : 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? colorScheme.primary
                                  : Colors.grey[400],
                              borderRadius: BorderRadius.circular(20),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.comment_outlined, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      widget.trendInfo.numberOfComments.toString(),
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Icon(Icons.people_outline, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      widget.trendInfo.numberOfComments.toString(),
                      style: textTheme.bodyMedium,
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    CustomTrendLikeButtonWidget(
                      trendId: widget.trendInfo.uid!,
                      isLikedNotifier: ValueNotifier(
                        LikeObject(
                          count: widget.trendInfo.numberOfLikes == null
                              ? 0
                              : widget.trendInfo.numberOfLikes!,
                          isLiked: widget.trendInfo.isLiked!,
                        ),
                      ),
                    ),
                    //Icon(Icons.favorite_outline, color: colorScheme.primary),
                    // const SizedBox(width: 4),
                    // Text(
                    //   widget.trendInfo.numberOfLikes.toString(),
                    //   style: textTheme.bodyMedium,
                    // ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(height: 16, thickness: 1, color: Colors.grey[300]),
            const SizedBox(height: 8),

            //commemts
            BlocBuilder<TrendCommentBloc, TrendCommentBlocState>(
              builder: (context, state) {
                switch (state) {
                  case TrendCommentLoading():
                    return const Center(
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(),
                      ),
                    );
                  case TrendCommentError(:final message):
                    return Center(child: Text("Error: $message"));
                  case TrendCommentsLoaded(:final comments):
                    return ListView.separated(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: comments.length,
                      separatorBuilder: (context, index) => const Divider(
                        height: .1,
                        thickness: .1,
                        indent: 40,
                        endIndent: 20,
                      ),
                      itemBuilder: (context, index) {
                        final comment = comments[index];
                        return CommentWidget(
                          comment: comment,
                          onDelete: () {
                            context.read<TrendCommentBloc>().add(
                              LoadTrendCommentsCacheFirstThenNetwork(
                                widget.trendInfo.uid!,
                              ),
                            );
                          },
                        );
                      },
                    );
                  case TrendCommentsEmpty():
                    return Center(
                      child: PageEmptyWidget(
                        title: "No comments yet",
                        subtitle: "Add new comments to see them here.",
                        icon: Icons.comment_outlined,
                        iconSize: 48,
                        fontSize: 16,
                      ),
                    );
                  default:
                    return Center(
                      child: PageEmptyWidget(
                        title: "No comments yet",
                        subtitle: "Add new comments to see them here.",
                        icon: Icons.comment_outlined,
                        iconSize: 48,
                        fontSize: 16,
                      ),
                    );
                }
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            border: Border(top: BorderSide(color: Colors.grey[300]!)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  minLines: 1,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    hintText: "Add a comment...",
                    border: InputBorder.none,
                  ),
                ),
              ),
              addCommentLoading
                  ? SizedBox(
                      height: 18,
                      width: 18,
                      child: const CircularProgressIndicator(strokeWidth: 2),
                    )
                  : IconButton(
                      onPressed: _addComment,
                      icon: Icon(Icons.send, color: colorScheme.primary),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteTrend(TrendFeedModel trend) async {}

  Future<void> _addComment() async {
    try {
      final text = _commentController.text.trim();
      if (text.isNotEmpty) {
        setState(() {
          addCommentLoading = true;
        });
        // Dispatch your bloc event or call API here print("Send comment: $text");
        UserBloc userBloc = context.read<UserBloc>();
        User user = userBloc.state;
        String createdBy =
            user.uid ?? firebase_auth.FirebaseAuth.instance.currentUser!.uid;
        //_buttonLoadingStateCubit.setLoading(true);
        final author = AuthorModel.empty().copyWith(
          uid: createdBy,
          name: user.fullName,
          avatar: user.profileImage,
        );

        final comment = CommentModel.empty().copyWith(
          text: text,
          author: author,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          refId: widget.trendInfo.uid,
        );

        final result = await sl<AddTrendCommentUsecase>().call(comment);

        result.fold(
          (failure) {
            setState(() {
              addCommentLoading = false;
            });
          },
          (comment) {
            context.read<TrendCommentBloc>().add(
              LoadTrendCommentsCacheFirstThenNetwork(widget.trendInfo.uid!),
            );
            setState(() {
              addCommentLoading = false;
            });
            _commentController.clear();
            FocusScope.of(context).unfocus();
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("✅ comment added successfully!")),
            );
          },
        );
      }
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
    _commentController.dispose();
    super.dispose();
  }
}
