import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/utils/get_relative_time.dart';
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
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_text_input_field_widget.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:fashionista/presentation/widgets/rating_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_bloc/flutter_bloc.dart';

class DesignerReviewPage extends StatefulWidget {
  final Designer designer;
  const DesignerReviewPage({super.key, required this.designer});

  @override
  State<DesignerReviewPage> createState() => _DesignerReviewPageState();
}

class _DesignerReviewPageState extends State<DesignerReviewPage>
    with WidgetsBindingObserver {
  final userId = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
  late bool addReviewLoading = false;

  @override
  void initState() {
    context.read<DesignerReviewBloc>().add(
      LoadDesignerReviewCacheFirstThenNetwork(widget.designer.uid),
    );
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 2),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: colorScheme.onPrimary,
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          DesignerRatingListWidget(
                            ratings: widget.designer.ratings!,
                            totalRating: widget.designer.totalRating!,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          '${widget.designer.averageRating ?? 0.0}',
                          style: textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        RatingInputWidget(
                          initialRating: widget.designer.averageRating ?? 0,
                          color: colorScheme.primary,
                          size: 18,
                          readOnly: true,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.designer.reviewCount ?? 0} Reviews',
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FilledButton(
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
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    backgroundColor:
                        colorScheme.surface, // solid grey background
                    foregroundColor: colorScheme.onSurface, // text/icon color
                  ),
                  child: Text('Write a Review'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
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
                    separatorBuilder: (context, index) =>
                        const Divider(height: .1, thickness: .1),
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
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final TextEditingController commentTextFieldController =
        TextEditingController();

    double rating = 0.0;

    showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  backgroundColor: Theme.of(context).colorScheme.onPrimary,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
  ),
  builder: (context) {
    commentTextFieldController.text = designerReviewModel.comment.text;
    rating = designerReviewModel.rating!.toDouble();

    // FocusNode for auto-focus and scroll control
    final focusNode = FocusNode();

    return Padding(
      // 👇 ensures bottom sheet shifts up when keyboard appears
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: StatefulBuilder(
        builder: (context, setModalState) {
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
                  padding: const EdgeInsets.all(16),
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

                      Text(
                        "Write a Review",
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 32),

                      // ⭐ Rating input
                      RatingInputWidget(
                        initialRating: rating,
                        color: Theme.of(context).colorScheme.primary,
                        size: 32,
                        readOnly: false,
                        onChanged: (r) => setModalState(() => rating = r),
                      ),
                      const SizedBox(height: 8),

                      // 💬 Comment input (auto-focus + scrolls above keyboard)
                      Focus(
                        onFocusChange: (hasFocus) {
                          if (hasFocus) {
                            // slight delay to ensure keyboard opens first
                            Future.delayed(const Duration(milliseconds: 300))
                                .then((_) {
                              if (scrollController.hasClients) {
                                scrollController.animateTo(
                                  scrollController.position.maxScrollExtent,
                                  duration:
                                      const Duration(milliseconds: 300),
                                  curve: Curves.easeOut,
                                );
                              }
                            });
                          }
                        },
                        child: CustomTextInputFieldWidget(
                          autofocus: true,
                          //focusNode: focusNode,
                          controller: commentTextFieldController,
                          hint:
                              'Share details of your experience with this designer',
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

                      // 💾 Save button
                      SizedBox(
                        height: 48,
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: () {
                            if (commentTextFieldController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Enter comment to proceed'),
                                ),
                              );
                              return;
                            }

                            UserBloc userBloc = context.read<UserBloc>();
                            User user = userBloc.state;
                            final uid = user.uid;
                            final author = AuthorModel.empty().copyWith(
                              uid: user.uid,
                              name: user.fullName,
                              avatar: user.profileImage,
                            );
                            final comment = CommentModel.empty().copyWith(
                              uid: uid,
                              refId: widget.designer.uid,
                              text: commentTextFieldController.text,
                              createdAt:
                                  DateTime.now().millisecondsSinceEpoch,
                              author: author,
                            );
                            final review = designerReviewModel.copyWith(
                              comment: comment,
                              refId: widget.designer.uid,
                              uid: uid,
                              rating: rating.toInt(),
                            );
                            onSave(review);
                          },
                          style: FilledButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            backgroundColor:
                                Theme.of(context).colorScheme.surface,
                            foregroundColor:
                                Theme.of(context).colorScheme.onSurface,
                          ),
                          child: const Text('Save'),
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
      setState(() {
        addReviewLoading = true;
      });
      // Show progress dialog
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final result = await sl<FirebaseDesignersService>().addDesignerReview(
        review,
      );

      result.fold(
        (failure) {
          if (mounted) {
            Navigator.of(context).pop();
          }
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure)));
          setState(() {
            addReviewLoading = false;
          });
        },
        (review) {
          Navigator.pop(context);
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
        (review) {
          context.read<DesignerReviewBloc>().add(
            LoadDesignerReviewCacheFirstThenNetwork(widget.designer.uid),
          );
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
}
