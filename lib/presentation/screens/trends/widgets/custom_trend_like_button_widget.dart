import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
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
  final Function(bool isLiked)? onPressed;

  /// Optional visual overrides (defaults keep the original tile look).
  final double iconSize;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? likedIconColor;

  const CustomTrendLikeButtonWidget({
    super.key,
    required this.trendId,
    this.isLikedNotifier,
    this.onPressed,
    this.iconSize = 18,
    this.backgroundColor,
    this.iconColor,
    this.likedIconColor,
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
      builder: (_, isLikedObject, _) {
        final bool liked = isLikedObject.isLiked;
        final Color tint = liked
            ? (widget.likedIconColor ?? context.accent)
            : (widget.iconColor ?? context.secondaryLabel);

        return Row(
          children: [
            CustomIconButtonRounded(
              size: widget.iconSize,
              iconData: Icons.favorite,
              backgroundColor: widget.backgroundColor,
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
                  widget.onPressed?.call(r);
                  widget.isLikedNotifier!.value = LikeObject(
                    count: count,
                    isLiked: r,
                  );
                  if (!mounted) return;
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
                  liked ? Icons.favorite : Icons.favorite_border_outlined,
                  key: ValueKey(liked), // important for switcher
                  color: tint,
                  size: widget.iconSize,
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
