import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/utils/get_relative_time.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Comment rendered as a left aligned chat bubble (avatar, bubble with the
/// author name + text, and a muted meta row with time and delete action).
class CommentWidget extends StatefulWidget {
  final Function()? onDelete;
  final CommentModel comment;
  const CommentWidget({super.key, this.onDelete, required this.comment});

  @override
  State<CommentWidget> createState() => _CommentWidgetState();
}

class _CommentWidgetState extends State<CommentWidget> {
  late UserBloc userBloc;

  @override
  void initState() {
    userBloc = context.read<UserBloc>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final String avatar = widget.comment.author.avatar ?? '';
    final String name = widget.comment.author.name ?? '';
    final bool isOwn = userBloc.state.uid == widget.comment.author.uid;
    final int? createdAt = widget.comment.createdAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: context.hairline),
            ),
            child: avatar.isEmpty
                ? DefaultProfileAvatar(
                    name: name,
                    size: 32,
                    uid: widget.comment.author.uid ?? '',
                  )
                : CachedNetworkImage(
                    imageUrl: avatar,
                    fit: BoxFit.cover,
                    errorListener: (error) {},
                    placeholder: (_, _) => DefaultProfileAvatar(
                      name: name,
                      size: 32,
                      uid: widget.comment.author.uid ?? '',
                    ),
                    errorWidget: (_, _, _) => DefaultProfileAvatar(
                      name: name,
                      size: 32,
                      uid: widget.comment.author.uid ?? '',
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.92,
                        ),
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                          decoration: BoxDecoration(
                            color: context.cardSurface,
                            border: Border.all(color: context.hairline),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(4),
                              topRight: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                              bottomRight: Radius.circular(16),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                widget.comment.text,
                                style: textTheme.bodyMedium?.copyWith(
                                  fontSize: 14,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (createdAt != null)
                      Text(
                        formatRelativeTime(createdAt),
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0,
                          color: context.mutedText,
                        ),
                      ),
                    if (createdAt != null && isOwn)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Text(
                          '•',
                          style: textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            color: context.mutedText,
                          ),
                        ),
                      ),
                    if (isOwn)
                      InkWell(
                        onTap: () => widget.onDelete?.call(),
                        borderRadius: BorderRadius.circular(6),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.delete_outline,
                                size: 13,
                                color: context.mutedText,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Delete',
                                style: textTheme.labelSmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0,
                                  color: context.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
