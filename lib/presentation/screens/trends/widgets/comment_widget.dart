import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/comment/comment_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8, top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
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
                child: widget.comment.author.avatar!.isNotEmpty
                    ? CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.lightGrey,
                        backgroundImage: CachedNetworkImageProvider(
                          widget.comment.author.avatar!,
                          errorListener: (error) {},
                        ),
                      )
                    : DefaultProfileAvatar(
                        name: null,
                        size: 18 * 1.8,
                        uid: widget.comment.author.uid!,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.comment.author.name!, style: textTheme.bodySmall),
                const SizedBox(height: 2),
                Text(widget.comment.text, style: textTheme.bodyMedium),
              ],
            ),
          ),
          if (userBloc.state.uid == widget.comment.author.uid) ...[
            IconButton(
              icon: Icon(Icons.delete, size: 20, color: colorScheme.error),
              onPressed: () async {
                widget.onDelete?.call(); // ✅ invoke callback
              },
            ),
          ],
        ],
      ),
    );
  }
}
