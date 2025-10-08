import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/models/designers/designer_review_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/firebase/firebase_designers_service.dart';
import 'package:fashionista/presentation/screens/designers/widgets/designer_rating_list_widget.dart';
import 'package:fashionista/presentation/widgets/custom_text_input_field_widget.dart';
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

class _DesignerReviewPageState extends State<DesignerReviewPage>
    with WidgetsBindingObserver {
  final userId = firebase_auth.FirebaseAuth.instance.currentUser!.uid;
  late bool addReviewLoading = false;

  @override
  void initState() {
    // context.read<DesignerFeedbackBloc>().add(
    //   LoadDesignerFeedback(widget.designer.uid),
    // );
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
      backgroundColor: colorScheme.onPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),

      builder: (context) {
        commentTextFieldController.text = designerReviewModel.comment.text;
        rating = designerReviewModel.rating!.toDouble();
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.5,
              minChildSize: 0.5,
              maxChildSize: 0.5,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),

                    child: Column(
                      mainAxisSize: MainAxisSize.min,
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
                        Text(
                          "Write a Review",
                          style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 32),
                        RatingInputWidget(
                          initialRating: rating,
                          color: colorScheme.primary,
                          size: 32,
                          readOnly: false,
                          onChanged: (rating) {
                            setModalState(() {
                              rating = rating;
                            });
                          },
                        ),

                        const SizedBox(height: 4),
                        CustomTextInputFieldWidget(
                          autofocus: true,
                          controller: commentTextFieldController,
                          hint:
                              'Share details of your experience with this designer',
                          minLines: 2,
                          maxLength: 150,
                          validator: (value) {
                            if ((value ?? "").isEmpty) {
                              return 'Enter comment to get proceed...';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: () {
                              if (commentTextFieldController.text
                                  .trim()
                                  .isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Enter comment to get proceed',
                                    ),
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
                                  colorScheme.surface, // solid grey background
                              foregroundColor:
                                  colorScheme.onSurface, // text/icon color
                            ),
                            child: Text('Save'),
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
          setState(() {
            addReviewLoading = false;
          });
        },
        (comment) {
          // context.read<DesignerFeedbackBloc>().add(
          //   LoadDesignerFeedback(widget.designer.uid),
          // );
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
