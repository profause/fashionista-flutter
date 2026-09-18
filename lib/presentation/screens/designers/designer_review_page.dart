import 'package:fashionista/core/service_locator/app_toast.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';
import 'package:fashionista/data/models/designers/bloc/designer_review_bloc.dart';
import 'package:fashionista/data/models/designers/bloc/designer_review_bloc_event.dart';
import 'package:fashionista/data/models/designers/bloc/designer_review_bloc_state.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/models/designers/designer_review_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/firebase/firebase_designers_service.dart';
import 'package:fashionista/presentation/screens/designers/widgets/designer_rating_list_widget.dart';
import 'package:fashionista/presentation/screens/trends/widgets/designer_review_widget.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:fashionista/presentation/widgets/rating_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class DesignerReviewPage extends StatefulWidget {
  final Designer designer;
  const DesignerReviewPage({super.key, required this.designer});

  @override
  State<DesignerReviewPage> createState() => _DesignerReviewPageState();
}

class _DesignerReviewPageState extends State<DesignerReviewPage> {
  final userId = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
  late bool addReviewLoading = false;

  @override
  void initState() {
    context.read<DesignerReviewBloc>().add(
      LoadDesignerReviewCacheFirstThenNetwork(widget.designer.uid),
    );
    //WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.cardSurface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.hairline),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: DesignerRatingListWidget(
                    ratings: widget.designer.ratings!,
                    totalRating: widget.designer.totalRating!,
                  ),
                ),
                const SizedBox(width: 18),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '${widget.designer.averageRating ?? 0.0}',
                      style: textTheme.headlineMedium!.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RatingInputWidget(
                      initialRating: widget.designer.averageRating ?? 0,
                      color: context.accent,
                      size: 16,
                      readOnly: true,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.designer.reviewCount ?? 0} Reviews',
                      style: textTheme.bodySmall!.copyWith(
                        color: context.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (userId != widget.designer.uid) ...[
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  DesignerReviewModel designerReviewModel =
                      DesignerReviewModel.empty();
                  //show review bottomsheet
                  _showReviewBottomsheet(
                    context,
                    (review) => _onSaveReview(review),
                    designerReviewModel,
                  );
                },
                icon: Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: context.accent,
                ),
                label: Text('Write a Review'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.onCanvasText,
                  backgroundColor: context.cardSurface,
                  side: BorderSide(color: context.hairline),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: textTheme.titleSmall!.copyWith(
                    color: context.onCanvasText,
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          BlocBuilder<DesignerReviewBloc, DesignerReviewBlocState>(
            builder: (context, state) {
              switch (state) {
                case DesignerReviewLoading():
                  return const Center(
                    child: SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(),
                    ),
                  );
                case DesignerReviewError(:final message):
                  //debugPrint(message);
                  return Center(child: Text("Error: $message"));
                case DesignerReviewsLoaded(:final reviews):
                  return ListView.separated(
                    scrollDirection: Axis.vertical,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.zero, //
                    itemCount: reviews.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      thickness: 1,
                      color: context.hairline,
                    ),
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return DesignerReviewWidget(
                        designerReviewModel: review,
                        onDelete: () async {
                          final canDelete = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Review'),
                              content: const Text(
                                'Are you sure you want to delete this review?',
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
                            _deleteReview(review);
                          }
                        },
                        onEdit: () {
                          _showReviewBottomsheet(
                            context,
                            (review) => _onSaveReview(review),
                            review,
                          );
                        },
                      );
                    },
                  );
                case DesignerReviewEmpty():
                  return Center(
                    child: PageEmptyWidget(
                      title: "No reviews yet",
                      subtitle: "Add review to see them here.",
                      icon: Icons.reviews_outlined,
                      iconSize: 48,
                      fontSize: 16,
                    ),
                  );
                default:
                  return Center(
                    child: PageEmptyWidget(
                      title: "No reviews yet",
                      subtitle: "Add review to see them here.",
                      icon: Icons.reviews_outlined,
                      iconSize: 48,
                      fontSize: 16,
                    ),
                  );
              }
            },
          ),
        ],
      ),
    );
  }

  void _showReviewBottomsheet(
    BuildContext context,
    Function(DesignerReviewModel review) onSave,
    DesignerReviewModel designerReviewModel,
  ) {
    //final textTheme = Theme.of(context).textTheme;
    //final colorScheme = Theme.of(context).colorScheme;

    final TextEditingController commentTextFieldController =
        TextEditingController();

    double rating = 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cardSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        commentTextFieldController.text = designerReviewModel.comment.text;
        rating = designerReviewModel.rating!.toDouble();

        // FocusNode for auto-focus and scroll control
        //final focusNode = FocusNode();

        return Padding(
          // 👇 ensures bottom sheet shifts up when keyboard appears
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              final textTheme = Theme.of(context).textTheme;
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.5,
                minChildSize: 0.5,
                maxChildSize: 0.9,
                builder: (context, scrollController) {
                  return GestureDetector(
                    // Tap outside text field to dismiss keyboard
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Top drag handle
                          Center(
                            child: Container(
                              height: 6,
                              width: 36,
                              margin: const EdgeInsets.only(top: 10, bottom: 6),
                              decoration: BoxDecoration(
                                color: context.softBorder,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                          ),

                          // Header with close action
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 10, 20, 0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "Write a Review",
                                    style: textTheme.titleLarge!.copyWith(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 17,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      Navigator.of(context).pop(),
                                  icon: const Icon(Icons.close),
                                  iconSize: 18,
                                  color: context.onCanvasText,
                                  style: IconButton.styleFrom(
                                    minimumSize: const Size(28, 28),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    padding: EdgeInsets.zero,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ⭐ Rating input
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                              child: RatingInputWidget(
                                initialRating: rating,
                                color: context.accent,
                                size: 32,
                                readOnly: false,
                                onChanged: (r) =>
                                    setModalState(() => rating = r),
                              ),
                            ),
                          ),

                          // 💬 Comment input (auto-focus + scrolls above keyboard)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                            child: Focus(
                              onFocusChange: (hasFocus) {
                                if (hasFocus) {
                                  // slight delay to ensure keyboard opens first
                                  Future.delayed(
                                    const Duration(milliseconds: 300),
                                  ).then((_) {
                                    if (scrollController.hasClients) {
                                      scrollController.animateTo(
                                        scrollController
                                            .position
                                            .maxScrollExtent,
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOut,
                                      );
                                    }
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  12,
                                  14,
                                  8,
                                ),
                                decoration: BoxDecoration(
                                  color: context.isDarkTheme
                                      ? context.secondaryButtonBg
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: context.isDarkTheme
                                        ? context.softBorder
                                        : const Color(0xFFE2E8F0),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    TextField(
                                      onChanged: (_) {
                                        setModalState(() {});
                                      },
                                      autofocus: true,
                                      //focusNode: focusNode,
                                      controller: commentTextFieldController,
                                      minLines: 3,
                                      maxLines: 5,
                                      maxLength: 150,
                                      style: textTheme.bodyLarge!.copyWith(
                                        fontSize: 15,
                                      ),
                                      decoration: InputDecoration(
                                        hintText:
                                            'Share details of your experience with this designer',
                                        hintStyle: textTheme.bodyMedium!
                                            .copyWith(
                                              color: context.placeholderText,
                                            ),
                                        border: InputBorder.none,
                                        isDense: true,
                                        counterText: '',
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              vertical: 0,
                                            ),
                                      ),
                                    ),
                                    Align(
                                      alignment: Alignment.bottomRight,
                                      child: Text(
                                        '${commentTextFieldController.text.length}/150',
                                        style: textTheme.bodySmall!.copyWith(
                                          color: context.mutedText,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // 💾 Save button
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                            child: SizedBox(
                              height: 50,
                              width: double.infinity,
                              child: FilledButton(
                                onPressed: () {
                                  if (commentTextFieldController.text
                                      .trim()
                                      .isEmpty) {
                                    // ScaffoldMessenger.of(context).showSnackBar(
                                    //   const SnackBar(
                                    //     content: Text('Enter review to proceed'),
                                    //   ),
                                    // );
                                    AppToast.info(
                                      context,
                                      "Enter review to proceed",
                                    );
                                    return;
                                  }

                                  UserBloc userBloc =
                                      context.read<UserBloc>();
                                  User user = userBloc.state;
                                  final uid =
                                      designerReviewModel.uid!.isEmpty
                                      ? Uuid().v4()
                                      : designerReviewModel.uid;
                                  final author =
                                      AuthorModel.empty().copyWith(
                                        uid: user.uid,
                                        name: user.fullName,
                                        avatar: user.profileImage,
                                      );
                                  final comment =
                                      CommentModel.empty().copyWith(
                                        uid: uid,
                                        refId: widget.designer.uid,
                                        text: commentTextFieldController
                                            .text,
                                        createdAt: DateTime.now()
                                            .millisecondsSinceEpoch,
                                        author: author,
                                      );
                                  final review =
                                      designerReviewModel.copyWith(
                                        comment: comment,
                                        refId: widget.designer.uid,
                                        uid: uid,
                                        rating: rating.toInt(),
                                        createdAt: comment.createdAt,
                                      );
                                  onSave(review);
                                },
                                style: FilledButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  backgroundColor: context.accent,
                                  foregroundColor: Colors.white,
                                  shadowColor: context.accent.withValues(
                                    alpha: 0.25,
                                  ),
                                  elevation: 4,
                                ),
                                child: const Text('Save Review'),
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
          ),
        );
      },
    );
  }

  void _onSaveReview(DesignerReviewModel review) async {
    try {
      // Show progress dialog
      showLoadingDialog(context);

      final result = await sl<FirebaseDesignersService>().addDesignerReview(
        review,
      );

      result.fold(
        (failure) {
          if (mounted) {
            dismissLoadingDialog(context);
          }
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure)));
        },
        (review) {
          dismissLoadingDialog(context);
          Navigator.pop(context);
          context.read<DesignerReviewBloc>().add(
            LoadDesignerReviewCacheFirstThenNetwork(widget.designer.uid),
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

  Future<void> _deleteReview(DesignerReviewModel review) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final result = await sl<FirebaseDesignersService>().deleteDesignerReview(
        review,
      );
      // Show progress dialog
      result.fold(
        (failure) {
          if (mounted) {
            Navigator.of(context).pop();
          }
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure)));
        },
        (s) {
          context.read<DesignerReviewBloc>().add(DeleteDesignerReview(review));
          if (!mounted) return;
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ review deleted successfully!")),
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

  @override
  void dispose() {
    super.dispose();
  }
}
