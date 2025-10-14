import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/service_locator/app_toast.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_event.dart';
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
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_text_input_field_widget.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:fashionista/presentation/widgets/featured_media_widget.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dartz/dartz.dart' as dartz;
import 'package:uuid/uuid.dart';

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

class _TrendDetailsScreenState extends State<TrendDetailsScreen>
    with WidgetsBindingObserver {
  final userId = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
    _userBloc = context.read<UserBloc>();
    context.read<TrendCommentBloc>().add(
      LoadTrendCommentsCacheFirstThenNetwork(widget.trendInfo.uid!),
    );
    WidgetsBinding.instance.addObserver(this);
    _selectedDesignersNotifier = ValueNotifier<List<Designer>>([]);
    _loadFashionDesigners();
    super.initState();
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: Text(
          'Trend',
          style: textTheme.titleMedium!.copyWith(
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
                  _deleteTrend(widget.trendInfo);
                }
              },
              icon: Icon(Icons.delete),
              color: colorScheme.primary,
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          //padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                color: colorScheme.onPrimary,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Material(
                          color: Colors.white,
                          borderOnForeground: true,
                          borderRadius: BorderRadius.circular(48),
                          child: Padding(
                            padding: const EdgeInsets.all(3.0),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () {},
                              child: widget.trendInfo.author.avatar!.isNotEmpty
                                  ? CircleAvatar(
                                      radius: 20,
                                      backgroundColor: AppTheme.lightGrey,
                                      backgroundImage:
                                          CachedNetworkImageProvider(
                                            widget.trendInfo.author.avatar!,
                                            errorListener: (error) {},
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
                          style: textTheme.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.trendInfo.description.trim(),
                      style: textTheme.bodyLarge,
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 16),
                    if (widget.trendInfo.featuredMedia.isNotEmpty) ...[
                      FeaturedMediaWidget(
                        featuredMedia: widget.trendInfo.featuredMedia,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Icon(
                                    Icons.comment_outlined,
                                    color: colorScheme.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.trendInfo.numberOfComments
                                        .toString(),
                                    style: textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(width: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  CustomTrendLikeButtonWidget(
                                    trendId: widget.trendInfo.uid!,
                                    isLikedNotifier: ValueNotifier(
                                      LikeObject(
                                        count:
                                            widget.trendInfo.numberOfLikes ==
                                                null
                                            ? 0
                                            : widget.trendInfo.numberOfLikes!,
                                        isLiked: widget.trendInfo.isLiked!,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Spacer(),
                          CustomIconButtonRounded(
                            onPressed: () {
                              //show bottomsheet
                              _showOptionsBottomsheet(context);
                            },
                            iconData: Icons.more_horiz_outlined,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 4),
              Container(
                color: colorScheme.onPrimary,
                //padding: EdgeInsets.all(12),
                child: BlocBuilder<TrendCommentBloc, TrendCommentBlocState>(
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
                          ),
                          itemBuilder: (context, index) {
                            final comment = comments[index];
                            return CommentWidget(
                              comment: comment,
                              onDelete: () async {
                                debugPrint("Delete comment");
                                _deleteComment(comment);
                              },
                            );
                          },
                        );
                      case TrendCommentsEmpty():
                        return Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Center(
                            child: PageEmptyWidget(
                              title: "No comments yet",
                              subtitle: "Add new comments to see them here.",
                              icon: Icons.comment_outlined,
                              iconSize: 48,
                              fontSize: 16,
                            ),
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
              ),
              //comment
            ],
          ),
        ),
      ),

      /// 🟢 WhatsApp-style input
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                    style: textTheme.bodyLarge,
                    decoration: const InputDecoration(
                      hintText: "Add a comment...",
                      border: InputBorder.none,
                    ),
                  ),
                ),
                addCommentLoading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : CustomIconButtonRounded(
                        backgroundColor: colorScheme.primary.withValues(
                          alpha: 0,
                        ),
                        size: 24,
                        onPressed: _addComment,
                        iconData: Icons.send_rounded,
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
            LoadTrendCommentsCacheFirstThenNetwork(widget.trendInfo.uid!),
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
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
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
      Navigator.pop(context);
      // context.read<ClosetItemBloc>().add(
      //   LoadClosetItemsCacheFirstThenNetwork(''),
      // );

      context.read<TrendBloc>().add(DeleteTrend(trend));

      Navigator.pop(context, true);
    } on firebase_auth.FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
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
    WidgetsBinding.instance.removeObserver(this);
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _showOptionsBottomsheet(BuildContext context) {
    //final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.onPrimary,
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
                          color: Colors.grey[400],
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
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.surface,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onSurface,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Icon(Icons.share_outlined, size: 18),
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
    final colorScheme = Theme.of(context).colorScheme;
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
      title: widget.trendInfo.description,
      status: 'REQUEST',
      workOrderType: 'REQUEST',
      featuredMedia: widget.trendInfo.featuredMedia,
      tags: widget.trendInfo.tags,
      client: client,
    );
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.onPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              builder: (context, scrollController) {
                return GestureDetector(
                  // Tap outside text field to dismiss keyboard
                  onTap: () => FocusScope.of(context).unfocus(),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: const EdgeInsets.only(top: 16, bottom: 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top handle
                        Center(
                          child: Container(
                            height: 4,
                            width: 40,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),

                        Center(
                          child: Text(
                            "Share this trend with your favorite designers",
                            style: Theme.of(context).textTheme.bodyMedium!
                                .copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 12, right: 12),
                          child: TextField(
                            controller: designerSearchTextFieldController,
                            decoration: InputDecoration(
                              hintText: "Search designer's name",
                              hintStyle: textTheme.bodyMedium!.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                              prefixIcon: Icon(
                                Icons.search,
                                color: colorScheme.primary,
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerHighest,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 0,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                            onChanged: (value) {
                              setModalState(() => searchText = value);
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.only(
                            left: 12,
                            right: 12,
                            top: 0,
                            bottom: 8,
                          ),
                          child: ValueListenableBuilder<List<Designer>>(
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
                                    child: Container(
                                      clipBehavior: Clip.antiAlias,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: ListView.separated(
                                        padding: EdgeInsets.zero,
                                        itemCount: filteredDesigners.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(height: 0.5),
                                        itemBuilder: (context, index) {
                                          final item = filteredDesigners[index];
                                          final isSelected = selectedDesigners
                                              .any((d) => d.uid == item.uid);
                                          return InkWell(
                                            onTap: () {
                                              final current =
                                                  List<Designer>.from(
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
                                            child: Container(
                                              padding: EdgeInsets.only(
                                                left: 4,
                                                right: 4,
                                              ),
                                              color: isSelected
                                                  ? colorScheme.primary
                                                        .withValues(alpha: 0.05)
                                                  : Colors.transparent,
                                              child: ListTile(
                                                dense: true,
                                                contentPadding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 0,
                                                    ),
                                                horizontalTitleGap: 6,
                                                minLeadingWidth: 24,
                                                leading: CircleAvatar(
                                                  radius: 18,
                                                  backgroundColor:
                                                      AppTheme.lightGrey,
                                                  backgroundImage:
                                                      item
                                                              .profileImage
                                                              ?.isNotEmpty ==
                                                          true
                                                      ? CachedNetworkImageProvider(
                                                          item.profileImage!,
                                                          errorListener: (error) {},
                                                        )
                                                      : null,
                                                  child:
                                                      item
                                                              .profileImage
                                                              ?.isEmpty ==
                                                          true
                                                      ? DefaultProfileAvatar(
                                                          name: null,
                                                          size: 18 * 1.6,
                                                          uid: widget
                                                              .trendInfo
                                                              .author
                                                              .uid!,
                                                        )
                                                      : null,
                                                ),
                                                title: Text(
                                                  item.name,
                                                  style: textTheme.bodyMedium,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                subtitle: Text(
                                                  item.businessName,
                                                  style: textTheme.bodySmall,
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                trailing: isSelected
                                                    ? Icon(
                                                        Icons.check_circle,
                                                        size: 18,
                                                        color:
                                                            colorScheme.primary,
                                                      )
                                                    : null,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        Divider(height: 0.5, color: colorScheme.surface),
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0, right: 10),
                          child: CustomTextInputFieldWidget(
                            onChanged: (_) {
                              setModalState(() {});
                            },
                            autofocus: true,
                            //focusNode: focusNode,
                            controller: commentTextFieldController,
                            hint: 'Add your comment...',
                            minLines: 2,
                            maxLength: 150,
                            validator: (value) {
                              if ((value ?? "").isEmpty) {
                                return 'Enter comment to proceed...';
                              }
                              return null;
                            },
                          ),
                        ),

                        const SizedBox(height: 12),
                        Padding(
                          padding: const EdgeInsets.only(left: 12.0, right: 12),
                          child: SizedBox(
                            height: 48,
                            width: double.infinity,
                            child: FilledButton(
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

                                if (_selectedDesignersNotifier.value.isEmpty) {
                                  AppToast.info(
                                    context,
                                    "Select a designer to proceed",
                                  );
                                  return;
                                }
                                workOrderRequest = workOrderRequest.copyWith(
                                  description: commentTextFieldController.text,
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
                                backgroundColor: colorScheme.surface,
                                foregroundColor: colorScheme.onSurface,
                              ),
                              child: const Text('Share'),
                            ),
                          ),
                        ),
                      ],
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
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

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
      Navigator.pop(context);

      // show success message
      AppToast.normal(context, "Work order request shared successfully");

      if (!mounted) return;
      Navigator.pop(context);
    } on firebase_auth.FirebaseException catch (e) {
      debugPrint(e.message);
    }
  }
}
