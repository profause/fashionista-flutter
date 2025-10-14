import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/get_relative_time.dart';
import 'package:fashionista/data/models/designers/designer_review_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:fashionista/presentation/widgets/rating_input_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DesignerReviewWidget extends StatefulWidget {
  final Function()? onDelete;
  final Function()? onEdit;
  final DesignerReviewModel designerReviewModel;
  const DesignerReviewWidget({
    super.key,
    required this.designerReviewModel,
    this.onDelete,
    this.onEdit,
  });

  @override
  State<DesignerReviewWidget> createState() => _DesignerReviewWidgetState();
}

class _DesignerReviewWidgetState extends State<DesignerReviewWidget> {
  late UserBloc userBloc;

  @override
  void initState() {
    userBloc = context.read<UserBloc>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(14),
      color: colorScheme.onPrimary,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    child:
                        widget
                            .designerReviewModel
                            .comment
                            .author
                            .avatar!
                            .isNotEmpty
                        ? CircleAvatar(
                            radius: 18,
                            backgroundColor: AppTheme.lightGrey,
                            backgroundImage: CachedNetworkImageProvider(
                              widget.designerReviewModel.comment.author.avatar!,
                              errorListener: (error) {},
                            ),
                          )
                        : DefaultProfileAvatar(
                            name: null,
                            size: 18 * 1.8,
                            uid: widget.designerReviewModel.comment.author.uid!,
                          ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.designerReviewModel.comment.author.name!,
                  style: textTheme.bodyMedium!.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                formatRelativeTime(widget.designerReviewModel.createdAt!),
                style: textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: RatingInputWidget(
              initialRating: widget.designerReviewModel.rating!.toDouble(),
              color: colorScheme.primary,
              size: 18,
              readOnly: true,
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: Text(
              widget.designerReviewModel.comment.text,
              style: textTheme.bodyLarge!.copyWith(fontSize: 15),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (userBloc.state.uid ==
                  widget.designerReviewModel.comment.author.uid!) ...[
                const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    CustomIconButtonRounded(
                      backgroundColor: Colors.transparent,
                      onPressed: widget.onEdit!,
                      iconData: Icons.edit,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    CustomIconButtonRounded(
                      backgroundColor: Colors.transparent,
                      onPressed: widget.onDelete!,
                      iconData: Icons.delete,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
