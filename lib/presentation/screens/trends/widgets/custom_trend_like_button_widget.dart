import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/social_interactions/social_interaction_model.dart';
import 'package:fashionista/domain/usecases/trends/is_liked_trend_usecase.dart';
import 'package:fashionista/domain/usecases/trends/like_or_unlike_trend_usecase.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomTrendLikeButtonWidget extends StatefulWidget {
  final String trendId;
  final ValueNotifier<LikeObject>? isLikedNotifier;
  const CustomTrendLikeButtonWidget({
    super.key,
    required this.trendId,
    this.isLikedNotifier,
  });

  @override
  State<CustomTrendLikeButtonWidget> createState() =>
      _CustomTrendLikeButtonWidgetState();
}

class _CustomTrendLikeButtonWidgetState
    extends State<CustomTrendLikeButtonWidget>
    with SingleTickerProviderStateMixin {
  late bool isLiked = false;
  late int count = 0;
  late AnimationController _controller;
  late UserBloc _userBloc;

  @override
  void initState() {
    _userBloc = context.read<UserBloc>();
    //widget.isLikedNotifier?.value = LikeObject(count: count, isLiked: isLiked);
    //getIsLiked();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    widget.isLikedNotifier!.addListener(() {
      if (widget.isLikedNotifier!.value.isLiked) {
        if (!mounted) return;
        _controller.forward(from: 0); // restart burst animation
      }
    });

    setState(() {
      isLiked = widget.isLikedNotifier!.value.isLiked;
      count = widget.isLikedNotifier!.value.count;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<LikeObject>(
      valueListenable: widget.isLikedNotifier!,
      builder: (_, isLikedObject, __) {
        //isLiked = isLikedObject.isLiked;
        return Row(
          children: [
            Text(
              '$count',
              style: Theme.of(
                context,
              ).textTheme.labelSmall!.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            CustomIconButtonRounded(
              size: 18,
              iconData: Icons.favorite,
              onPressed: () async {
                widget.isLikedNotifier!.value = LikeObject(
                  count: isLiked ? count + 1 : count - 1,
                  isLiked: !isLikedObject.isLiked,
                );
                if (!mounted) return;
                setState(() {
                  isLiked = !isLiked;
                  count = isLiked ? count + 1 : count - 1;
                });
                final author = AuthorModel.empty().copyWith(
                  uid: _userBloc.state.uid,
                  name: _userBloc.state.fullName,
                  avatar: _userBloc.state.profileImage,
                );
                final result = await sl<LikeOrUnlikeTrendUsecase>().call(
                  SocialInteractionModel.empty().copyWith(
                    refId: widget.trendId,
                    author: author,
                  ),
                );
                result.fold((l) {}, (r) {
                  widget.isLikedNotifier!.value = LikeObject(
                    count: count,
                    isLiked: r,
                  );
                  if (!mounted) return;
                  // setState(() {
                  //   isLiked = r;
                  //   count = r ? count + 1 : count - 1;
                  // });
                });
              },
              icon: AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(
                    scale: animation,
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Icon(
                  isLikedObject.isLiked
                      ? Icons.favorite
                      : Icons.favorite_border_outlined,
                  key: ValueKey(
                    isLikedObject.isLiked,
                  ), // important for switcher
                  color: isLikedObject.isLiked ? Colors.red : Colors.grey,
                  size: 18,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void getIsLiked() async {
    if (!mounted) return;
    isLiked = await sl<IsLikedTrendUsecase>().call(widget.trendId);

    widget.isLikedNotifier!.value = LikeObject(count: count, isLiked: isLiked);
  }
}

class LikeObject {
  final int count;
  final bool isLiked;
  const LikeObject({required this.count, required this.isLiked});
}
