import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/presentation/screens/designers/widgets/designer_rating_list_widget.dart';
import 'package:fashionista/presentation/widgets/rating_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class DesignerReviewPage extends StatefulWidget {
  final Designer designer;
  const DesignerReviewPage({super.key, required this.designer});

  @override
  State<DesignerReviewPage> createState() => _DesignerReviewPageState();
}

class _DesignerReviewPageState extends State<DesignerReviewPage>
    with WidgetsBindingObserver {
  final userId = firebase_auth.FirebaseAuth.instance.currentUser!.uid;

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
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18,),
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
                    //show review bottomsheet
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
}
