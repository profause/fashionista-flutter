import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/domain/usecases/design_collection/add_or_remove_design_collection_bookmark_usecase.dart';
import 'package:fashionista/domain/usecases/design_collection/is_bookmarked_usecase.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:flutter/material.dart';

class CustomBookmarkDesignCollectionIconButton extends StatefulWidget {
  final String designerCollectionId;
  final ValueNotifier<bool>? isBookmarkedNotifier;
  const CustomBookmarkDesignCollectionIconButton({
    super.key,
    required this.designerCollectionId,
    this.isBookmarkedNotifier,
  });

  @override
  State<CustomBookmarkDesignCollectionIconButton> createState() =>
      _CustomBookmarkDesignCollectionIconButtonState();
}

class _CustomBookmarkDesignCollectionIconButtonState
    extends State<CustomBookmarkDesignCollectionIconButton>
    with SingleTickerProviderStateMixin {
  late bool isBookmarked = false;
  late AnimationController _controller;
  //late Animation<double> _scale;

  @override
  initState() {
    //getIsBookmarked();
    //widget.isBookmarkedNotifier?.value = isBookmarked;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // _scale = Tween<double>(
    //   begin: 0.7,
    //   end: 1.2,
    // ).chain(CurveTween(curve: Curves.elasticOut)).animate(_controller);

    widget.isBookmarkedNotifier!.addListener(() {
      if (widget.isBookmarkedNotifier!.value) {
        if (!mounted) return;
        _controller.forward(from: 0); // restart burst animation
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isBookmarkedNotifier!,
      builder: (_, isBookmarked, __) {
        return CustomIconButtonRounded(
          iconData: Icons.bookmark_add_outlined,
          onPressed: () async {
            widget.isBookmarkedNotifier!.value = !isBookmarked;
            setState(() {
              isBookmarked = !isBookmarked;
            });
            final result = await sl<AddOrRemoveDesignCollectionBookmarkUsecase>().call(
              widget.designerCollectionId,
            );
            result.fold((l) {}, (r) {
              widget.isBookmarkedNotifier!.value = r;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    r == true
                        ? "✅ Added to bookmarks"
                        : "❌ Removed from bookmarks",
                  ),
                  duration: Duration(seconds: 2),
                ),
              );
              setState(() {
                isBookmarked = r;
              });
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
              isBookmarked
                  ? Icons.bookmark_remove
                  : Icons.bookmark_add_outlined,
              key: ValueKey(isBookmarked), // important for switcher
              color: isBookmarked ? Colors.red : Colors.grey,
              size: 20,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void getIsBookmarked() async {
    if (!mounted) return;
    isBookmarked = await sl<IsBookmarkedUsecase>().call(
      widget.designerCollectionId,
    );
    widget.isBookmarkedNotifier!.value = isBookmarked;
  }
}
