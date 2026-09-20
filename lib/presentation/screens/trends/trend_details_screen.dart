import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/app_toast.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/get_relative_time.dart';
import 'package:fashionista/core/widgets/bloc/getstarted_stats_cubit.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_event.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_state.dart';
import 'package:fashionista/data/models/trends/bloc/trend_comment_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_comment_bloc_event.dart';
import 'package:fashionista/data/models/trends/bloc/trend_comment_bloc_state.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/data/models/work_order/work_order_model.dart';
import 'package:fashionista/data/services/firebase/firebase_designers_service.dart';
import 'package:fashionista/data/services/firebase/firebase_notification_service.dart';
import 'package:fashionista/data/services/firebase/firebase_trends_service.dart';
import 'package:fashionista/data/services/firebase/firebase_work_order_service.dart';
import 'package:fashionista/domain/usecases/trends/add_trend_comment_usecase.dart';
import 'package:fashionista/domain/usecases/trends/delete_trend_comment_usecase.dart';
import 'package:fashionista/presentation/screens/trends/widgets/comment_widget.dart';
import 'package:fashionista/presentation/screens/trends/widgets/custom_trend_like_button_widget.dart';
import 'package:fashionista/presentation/widgets/appbar_title.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:fashionista/presentation/widgets/featured_media_widget.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:fashionista/presentation/widgets/rating_input_widget.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class TrendDetailsScreen extends StatefulWidget {
  final String trendId;
  const TrendDetailsScreen({super.key, required this.trendId});

  @override
  State<TrendDetailsScreen> createState() => _TrendDetailsScreenState();
}

class _TrendDetailsScreenState extends State<TrendDetailsScreen>
    with WidgetsBindingObserver {
  final userId = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _commentFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  late TrendFeedModel trendInfo;

  bool addCommentLoading = false;
  late UserBloc _userBloc;

  final ValueNotifier<List<Designer>> designersNotifier =
      ValueNotifier<List<Designer>>([]);
  bool loadingFashionDesigners = true;
  Timer? _debounce;
  late ValueNotifier<List<Designer>>
  _selectedDesignersNotifier; // ✅ selection state

  @override
  void initState() {
    super.initState();
    _userBloc = context.read<UserBloc>();
    context.read<TrendBloc>().add(LoadTrend(widget.trendId, isFromCache: true));
    context.read<TrendCommentBloc>().add(
      LoadTrendCommentsCacheFirstThenNetwork(widget.trendId),
    );
    WidgetsBinding.instance.addObserver(this);
    _selectedDesignersNotifier = ValueNotifier<List<Designer>>([]);
    _loadFashionDesigners();
  }

  /// 🔑 Detect keyboard changes
  @override
  void didChangeMetrics() {
    final bottomInset = WidgetsBinding.instance.window.viewInsets.bottom;
    if (bottomInset > 0) {
      // keyboard opened
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TrendBloc, TrendBlocState>(
      buildWhen: (context, state) {
        return state is TrendLoaded || state is TrendUpdated;
      },
      builder: (context, state) {
        switch (state) {
          case TrendLoaded(:final trend):
          case TrendUpdated(:final trend):
            trendInfo = trend;
            final textTheme = Theme.of(context).textTheme;
            return Scaffold(
              resizeToAvoidBottomInset: true,
              backgroundColor: context.canvasBackground,
              appBar: AppBar(
                backgroundColor: context.canvasBackground,
                foregroundColor: context.onCanvasText,
                elevation: 0,
                scrolledUnderElevation: 0,
                shape: Border(bottom: BorderSide(color: context.hairline)),
                title: const AppBarTitle(title: 'Trend'),
                actions: [
                  if (userId == trendInfo.createdBy) ...[
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
                          _deleteTrend(trendInfo);
                        }
                      },
                      icon: const Icon(Icons.delete_outline, size: 22),
                      color: context.secondaryLabel,
                      tooltip: 'Delete post',
                    ),
                  ],
                ],
              ),
              body: SafeArea(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAuthorHeader(context, textTheme),
                      _buildMedia(context),
                      _buildActionBar(context),
                      _buildTags(context, textTheme),
                      _buildComments(context, textTheme),
                    ],
                  ),
                ),
              ),
              bottomNavigationBar: _buildCommentComposer(context, textTheme),
            );
        }
        return const SizedBox.shrink();
      },
    );
  }

  /// Author row: avatar, name + post time and the more-options action.
  Widget _buildAuthorHeader(BuildContext context, TextTheme textTheme) {
    final String name = trendInfo.author.name ?? '';
    final int? createdAt = trendInfo.createdAt;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          _buildAvatar(context, 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  createdAt == null ? '' : formatRelativeTime(createdAt),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.labelSmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0,
                    height: 1.2,
                    color: context.mutedText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _actionIcon(
            context,
            Icons.more_horiz,
            () => _showOptionsBottomsheet(context),
          ),
        ],
      ),
    );
  }

  /// Circular author avatar with the initials fallback.
  Widget _buildAvatar(BuildContext context, double size) {
    final String avatar = trendInfo.author.avatar ?? '';
    final String name = trendInfo.author.name ?? '';
    final String uid = trendInfo.author.uid ?? '';

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: context.hairline),
      ),
      child: avatar.isEmpty
          ? DefaultProfileAvatar(name: name, size: size, uid: uid)
          : CachedNetworkImage(
              imageUrl: avatar,
              fit: BoxFit.cover,
              errorListener: (error) {},
              placeholder: (_, _) =>
                  DefaultProfileAvatar(name: name, size: size, uid: uid),
              errorWidget: (_, _, _) =>
                  DefaultProfileAvatar(name: name, size: size, uid: uid),
            ),
    );
  }

  /// Hero media with the caption rendered over a bottom gradient.
  Widget _buildMedia(BuildContext context) {
    if (trendInfo.featuredMedia.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FeaturedMediaWidget(
        featuredMedia: trendInfo.featuredMedia,
        caption: trendInfo.description.trim(),
      ),
    );
  }

  /// Like / comment / share tray with a hairline separating it from comments.
  Widget _buildActionBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: context.hairline)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            CustomTrendLikeButtonWidget(
              trendId: trendInfo.uid!,
              backgroundColor: Colors.transparent,
              iconSize: 24,
              iconColor: context.onCanvasText,
              likedIconColor: context.accent,
              isLikedNotifier: ValueNotifier(
                LikeObject(
                  count: trendInfo.numberOfLikes ?? 0,
                  isLiked: trendInfo.isLiked!,
                ),
              ),
              onPressed: (isLiked) {
                final updateTrend = trendInfo.copyWith(isLiked: isLiked);
                context.read<TrendBloc>().add(UpdateTrend(updateTrend));

                final cubit = context.read<GetstartedStatsCubit>();
                final currentLikes = cubit.state['likes'] ?? 0;
                final newLike = isLiked
                    ? currentLikes + 1
                    : (currentLikes > 0 ? currentLikes - 1 : 0);

                cubit.updateLikes(newLike);
              },
            ),
            const SizedBox(width: 20),
            _actionIcon(
              context,
              Icons.chat_bubble_outline,
              () => _commentFocusNode.requestFocus(),
            ),
            const SizedBox(width: 20),
            _actionIcon(
              context,
              Icons.share_outlined,
              () => _showRequestBottomsheet(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionIcon(BuildContext context, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Icon(icon, size: 24, color: context.onCanvasText),
      ),
    );
  }

  /// Post tags rendered as subtle pills under the action bar.
  Widget _buildTags(BuildContext context, TextTheme textTheme) {
    final List<String> tags = (trendInfo.tags ?? '')
        .split(',')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toList();

    if (tags.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: tags.map((tag) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: context.secondaryButtonBg,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: context.hairline),
            ),
            child: Text(
              '#$tag',
              style: textTheme.labelSmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 0,
                color: context.onCanvasText,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  /// Comments feed rendered as chat bubbles.
  Widget _buildComments(BuildContext context, TextTheme textTheme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: BlocBuilder<TrendCommentBloc, TrendCommentBlocState>(
        builder: (context, state) {
          switch (state) {
            case TrendCommentLoading():
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              );
            case TrendCommentError(:final message):
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    "Error: $message",
                    style: textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            case TrendCommentsLoaded(:final comments):
              if (comments.isEmpty) return _buildEmptyComments(textTheme);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: comments.map((comment) {
                  return CommentWidget(
                    comment: comment,
                    onDelete: () => _deleteComment(comment),
                  );
                }).toList(),
              );
            case TrendCommentsEmpty():
              return _buildEmptyComments(textTheme);
            default:
              return _buildEmptyComments(textTheme);
          }
        },
      ),
    );
  }

  Widget _buildEmptyComments(TextTheme textTheme) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: PageEmptyWidget(
        title: "No comments yet",
        subtitle: "Add new comments to see them here.",
        icon: Icons.comment_outlined,
        iconSize: 48,
        fontSize: 16,
      ),
    );
  }

  /// Sticky composer: pill input with the brand coloured send action.
  Widget _buildCommentComposer(BuildContext context, TextTheme textTheme) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),

          child: Container(
            padding: const EdgeInsets.only(left: 16, right: 6),
            decoration: BoxDecoration(
              color: context.iconSubstrate,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: context.hairline),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    focusNode: _commentFocusNode,
                    minLines: 1,
                    maxLines: 3,
                    style: textTheme.bodyMedium?.copyWith(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      hintStyle: textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: context.mutedText,
                      ),
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      fillColor: Colors.transparent,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                addCommentLoading
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        onPressed: _addComment,
                        icon: const Icon(Icons.send_rounded, size: 22),
                        color: context.accent,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 38,
                          minHeight: 38,
                        ),
                        tooltip: 'Post comment',
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _deleteComment(CommentModel comment) async {
    try {
      final result = await sl<DeleteTrendCommentUsecase>().call(comment);
      result.fold(
        (failure) {
          setState(() {
            addCommentLoading = false;
          });
        },
        (comment) {
          context.read<TrendCommentBloc>().add(
            LoadTrendCommentsCacheFirstThenNetwork(trendInfo.uid!),
          );
          setState(() {});
          _commentController.clear();
          FocusScope.of(context).unfocus();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ comment deleted successfully!")),
          );
        },
      );
    } on firebase_auth.FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }

  Future<void> _deleteTrend(TrendFeedModel trend) async {
    try {
      // create a dynamic list of futures
      showLoadingDialog(context);
      final List<Future<dartz.Either>> futures = trend.featuredMedia
          .map((e) => sl<FirebaseTrendsService>().deleteTrendImage(e.url!))
          .toList();

      // also add delete by id
      futures.add(sl<FirebaseTrendsService>().deleteTrendById(trend.uid!));

      // wait for all and capture results
      final results = await Future.wait(futures);

      // handle each result
      for (final result in results) {
        result.fold(
          (failure) {
            // handle failure
            debugPrint("Delete failed: $failure");
          },
          (success) {
            // handle success
            debugPrint("Delete success: $success");
          },
        );
      }

      if (!mounted) return;
      context.read<TrendBloc>().add(DeleteTrend(trend.uid!));
      dismissLoadingDialog(context);
      Navigator.pop(context);
    } on firebase_auth.FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // prevent accidental dismiss
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void dismissLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

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
          refId: trendInfo.uid,
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
              LoadTrendCommentsCacheFirstThenNetwork(trendInfo.uid!),
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
    WidgetsBinding.instance.removeObserver(this);
    _commentController.dispose();
    _commentFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showOptionsBottomsheet(BuildContext context) {
    //final textTheme = Theme.of(context).textTheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.4, // how tall it opens initially
          minChildSize: 0.4,
          maxChildSize: 0.5,
          shouldCloseOnMinExtent: false,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// Handle bar
                    Center(
                      child: Container(
                        height: 4,
                        width: 40,
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: context.softBorder,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton(
                        onPressed: () {
                          //show request workorder bottomsheet
                          Navigator.pop(context);
                          _showRequestBottomsheet(context);
                        },
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          backgroundColor: context.secondaryButtonBg,
                          foregroundColor: context.onCanvasText,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.share_outlined,
                              size: 18,
                              color: context.accent,
                            ),
                            const SizedBox(width: 8),
                            const Text('Share with your favorite designers'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _loadFashionDesigners() async {
    _debounce?.cancel(); // cancel previous timer
    _debounce = Timer(const Duration(milliseconds: 1500), () async {
      final result = await sl<FirebaseDesignersService>()
          .findDesignersWithFilter(4, 'created_date');

      await result.fold((failure) async {}, (designers) {
        designersNotifier.value = designers;
        loadingFashionDesigners = false;
      });
    });
  }

  void _showRequestBottomsheet(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final TextEditingController designerSearchTextFieldController =
        TextEditingController();
    final TextEditingController commentTextFieldController =
        TextEditingController();
    String searchText = "";

    final AuthorModel client = AuthorModel.empty().copyWith(
      name: _userBloc.state.fullName,
      mobileNumber: _userBloc.state.mobileNumber,
      uid: _userBloc.state.uid,
      avatar: _userBloc.state.profileImage,
    );

    WorkOrderModel workOrderRequest = WorkOrderModel.empty().copyWith(
      description: '',
      title: trendInfo.description,
      status: 'REQUEST',
      workOrderType: 'REQUEST',
      featuredMedia: trendInfo.featuredMedia,
      tags: trendInfo.tags,
      client: client,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.9,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return GestureDetector(
                  // Tap outside text field to dismiss keyboard
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Drag handle
                          Center(
                            child: Container(
                              height: 4,
                              width: 36,
                              decoration: BoxDecoration(
                                color: context.softBorder,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Header
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Share Trend',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: context.onCanvasText,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => Navigator.pop(context),
                                borderRadius: BorderRadius.circular(999),
                                child: Padding(
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.close,
                                    size: 20,
                                    color: context.secondaryLabel,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Share this trend with your favorite designers',
                            style: textTheme.bodySmall?.copyWith(
                              fontSize: 14,
                              height: 1.3,
                              color: context.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Search
                          TextField(
                            controller: designerSearchTextFieldController,
                            style: textTheme.bodyMedium?.copyWith(
                              fontSize: 15,
                              color: context.onCanvasText,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search designers...',
                              hintStyle: textTheme.bodyMedium?.copyWith(
                                fontSize: 15,
                                color: context.placeholderText,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                size: 18,
                                color: context.secondaryLabel,
                              ),
                              filled: true,
                              fillColor: context.iconSubstrate,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 14,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: context.hairline),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: context.accent),
                              ),
                            ),
                            onChanged: (value) {
                              setModalState(() => searchText = value);
                            },
                          ),
                          const SizedBox(height: 2),
                          ValueListenableBuilder<List<Designer>>(
                            valueListenable: designersNotifier,
                            builder: (context, designers, _) {
                              if (loadingFashionDesigners) {
                                return const Center(
                                  child: SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }

                              if (designers.isEmpty) {
                                return Text(
                                  "No designers found",
                                  style: textTheme.bodyMedium,
                                );
                              }
                              const itemHeight = 64.0;
                              final filteredDesigners = searchText.isEmpty
                                  ? designers
                                  : designers.where((designer) {
                                      final name = designer.name.toLowerCase();
                                      final mobileNumber = designer.mobileNumber
                                          .toLowerCase();
                                      final businessName = designer.businessName
                                          .toLowerCase();
                                      return name.contains(
                                            searchText.toLowerCase(),
                                          ) ||
                                          mobileNumber.contains(
                                            searchText.toLowerCase(),
                                          ) ||
                                          businessName.contains(
                                            searchText.toLowerCase(),
                                          );
                                    }).toList();

                              return ValueListenableBuilder<List<Designer>>(
                                valueListenable: _selectedDesignersNotifier,
                                builder: (context, selectedDesigners, _) {
                                  return SizedBox(
                                    height:
                                        (filteredDesigners.length * itemHeight)
                                            .clamp(0, 300),
                                    child: ListView.separated(
                                      padding: EdgeInsets.zero,
                                      itemCount: filteredDesigners.length,
                                      separatorBuilder: (_, _) => Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: context.hairline,
                                      ),
                                      itemBuilder: (context, index) {
                                        final item = filteredDesigners[index];
                                        final isSelected = selectedDesigners
                                            .any((d) => d.uid == item.uid);
                                        final hasImage =
                                            item.profileImage?.isNotEmpty ==
                                            true;
                                        return InkWell(
                                          onTap: () {
                                            final current = List<Designer>.from(
                                              selectedDesigners,
                                            );
                                            if (isSelected) {
                                              current.removeWhere(
                                                (d) => d.uid == item.uid,
                                              );
                                            } else {
                                              current.add(item);
                                            }
                                            _selectedDesignersNotifier.value =
                                                current;
                                          },
                                          child: SizedBox(
                                            height: 64,
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  clipBehavior: Clip.antiAlias,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color:
                                                        context.iconSubstrate,
                                                    border: Border.all(
                                                      color: context.hairline,
                                                    ),
                                                  ),
                                                  child: CircleAvatar(
                                                    radius: 20,
                                                    backgroundColor:
                                                        context.iconSubstrate,
                                                    backgroundImage: hasImage
                                                        ? CachedNetworkImageProvider(
                                                            item.profileImage!,
                                                            errorListener:
                                                                (error) {},
                                                          )
                                                        : null,
                                                    child: hasImage
                                                        ? null
                                                        : DefaultProfileAvatar(
                                                            name: item.name,
                                                            size: 18 * 1.6,
                                                            uid: item.uid,
                                                          ),
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Row(
                                                        children: [
                                                          Flexible(
                                                            child: Text(
                                                              item.name,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: textTheme
                                                                  .bodyMedium
                                                                  ?.copyWith(
                                                                    fontSize:
                                                                        15,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: context
                                                                        .onCanvasText,
                                                                  ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            width: 8,
                                                          ),
                                                          RatingInputWidget(
                                                            initialRating:
                                                                item.averageRating ??
                                                                0,
                                                            color:
                                                                context.accent,
                                                            size: 14,
                                                            readOnly: true,
                                                          ),
                                                        ],
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        item.businessName
                                                            .toUpperCase(),
                                                        maxLines: 1,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: textTheme
                                                            .labelSmall
                                                            ?.copyWith(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w500,
                                                              letterSpacing:
                                                                  0.6,
                                                              color: context
                                                                  .secondaryLabel,
                                                            ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                _designerSelectionIndicator(
                                                  context,
                                                  isSelected,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 16),

                          // Note for the designers
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: context.canvasBackground,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: context.hairline),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextField(
                                  controller: commentTextFieldController,
                                  autofocus: true,
                                  minLines: 2,
                                  maxLines: 4,
                                  maxLength: 150,
                                  onChanged: (_) => setModalState(() {}),
                                  style: textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: context.onCanvasText,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    isCollapsed: true,
                                    fillColor: Colors.transparent,
                                    contentPadding: const EdgeInsets.all(0),
                                    border: InputBorder.none,
                                    hintText: 'Add a note for the designers...',
                                    hintStyle: textTheme.bodyMedium?.copyWith(
                                      fontSize: 14,
                                      color: context.placeholderText,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    '${commentTextFieldController.text.length}/150',
                                    style: textTheme.labelSmall?.copyWith(
                                      fontSize: 11,
                                      color: context.placeholderText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Share action
                          SizedBox(
                            height: 52,
                            width: double.infinity,
                            child: ValueListenableBuilder<List<Designer>>(
                              valueListenable: _selectedDesignersNotifier,
                              builder: (context, selected, _) {
                                return FilledButton(
                                  onPressed: () {
                                    if (commentTextFieldController.text
                                        .trim()
                                        .isEmpty) {
                                      AppToast.info(
                                        context,
                                        "Enter comment to proceed",
                                      );
                                      return;
                                    }

                                    if (_selectedDesignersNotifier
                                        .value
                                        .isEmpty) {
                                      AppToast.info(
                                        context,
                                        "Select a designer to proceed",
                                      );
                                      return;
                                    }
                                    workOrderRequest = workOrderRequest
                                        .copyWith(
                                          description:
                                              commentTextFieldController.text,
                                        );
                                    _shareWorkOrderRequest(
                                      context,
                                      workOrderRequest,
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    elevation: 0,
                                    backgroundColor: context.accent,
                                    foregroundColor: Colors.white,
                                    textStyle: textTheme.titleSmall?.copyWith(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  child: Text(
                                    selected.isEmpty
                                        ? 'Share with Selected'
                                        : 'Share with Selected (${selected.length})',
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  /// Circular tick shown on the right of a selected designer row.
  Widget _designerSelectionIndicator(BuildContext context, bool isSelected) {
    return isSelected
        ? Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: context.accent,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 14, color: Colors.white),
          )
        : Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.softBorder, width: 2),
            ),
          );
  }

  Future<void> _shareWorkOrderRequest(
    BuildContext context,
    WorkOrderModel workOrderRequest,
  ) async {
    try {
      final List<Designer> selectedDesigners = _selectedDesignersNotifier.value;

      final authorUser = AuthorModel.empty().copyWith(
        uid: _userBloc.state.uid,
        name: _userBloc.state.fullName,
        avatar: _userBloc.state.profileImage,
        mobileNumber: _userBloc.state.mobileNumber,
      );
      showLoadingDialog(context);

      int dateTime = DateTime.now().millisecondsSinceEpoch;

      final results = await Future.wait(
        selectedDesigners.map((designer) {
          final author = AuthorModel.empty().copyWith(
            uid: designer.uid,
            name: designer.name,
            avatar: designer.profileImage,
            mobileNumber: designer.mobileNumber,
          );
          workOrderRequest = workOrderRequest.copyWith(
            uid: Uuid().v4(),
            author: author,
            createdBy: designer.uid,
            createdAt: dateTime,
            updatedAt: dateTime,
          );
          return sl<FirebaseWorkOrderService>().createWorkOrder(
            workOrderRequest,
          );
        }),
      );

      // handle each result
      for (final result in results) {
        result.fold(
          (failure) {
            // handle failure
            debugPrint("Create failed: $failure");
          },
          (success) async {
            final notification = NotificationModel.empty().copyWith(
              uid: Uuid().v4(),
              title: "Work order request",
              description: "You have a new work order request",
              createdAt: DateTime.now().millisecondsSinceEpoch,
              type: 'workOrderRequest',
              refId: success.uid,
              refType: "work_order",
              from: _userBloc.state.uid,
              to: success.createdBy,
              author: authorUser,
              status: 'new',
            );

            await sl<FirebaseNotificationService>().createNotification(
              notification,
            );
            // handle success
            //debugPrint("Create success: $success");
          },
        );
      }

      _selectedDesignersNotifier.value = [];
      // close dialog
      if (!mounted) return;
      dismissLoadingDialog(context);
      // show success message
      AppToast.normal(context, "Work order request shared successfully");

      if (!mounted) return;
      Navigator.pop(context);
      context.pop();
    } on firebase_auth.FirebaseException catch (e) {
      debugPrint(e.message);
    }
  }
}
