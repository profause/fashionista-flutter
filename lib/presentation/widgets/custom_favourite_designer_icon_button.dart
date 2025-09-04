import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/domain/usecases/designers/add_or_remove_favourite_usecase.dart';
import 'package:fashionista/domain/usecases/designers/is_favourite_usecase.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:flutter/material.dart';

class CustomFavouriteDesignerIconButton extends StatefulWidget {
  final String designerId;
  final ValueNotifier<bool>? isFavouriteNotifier;
  const CustomFavouriteDesignerIconButton({
    super.key,
    required this.designerId,
    this.isFavouriteNotifier,
  });

  @override
  State<CustomFavouriteDesignerIconButton> createState() =>
      _CustomFavouriteDesignerIconButtonState();
}

class _CustomFavouriteDesignerIconButtonState
    extends State<CustomFavouriteDesignerIconButton>
    with SingleTickerProviderStateMixin {
  late bool isFavourite = false;
  late AnimationController _controller;
  //late Animation<double> _scale;

  @override
  initState() {
    getIsFavourite();
    widget.isFavouriteNotifier?.value = isFavourite;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // _scale = Tween<double>(
    //   begin: 0.7,
    //   end: 1.2,
    // ).chain(CurveTween(curve: Curves.elasticOut)).animate(_controller);

    widget.isFavouriteNotifier!.addListener(() {
      if (widget.isFavouriteNotifier!.value) {
        if (!mounted) return;
        _controller.forward(from: 0); // restart burst animation
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isFavouriteNotifier!,
      builder: (_, isFavourite, __) {
        return CustomIconButtonRounded(
          iconData: Icons.favorite,
          onPressed: () async {
            widget.isFavouriteNotifier!.value = !isFavourite;
            setState(() {
              isFavourite = !isFavourite;
            });
            final result = await sl<AddOrRemoveFavouriteUsecase>().call(
              widget.designerId,
            );
            result.fold((l) {}, (r) {
              widget.isFavouriteNotifier!.value = r;
              setState(() {
                isFavourite = r;
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
              isFavourite ? Icons.favorite : Icons.favorite_border,
              key: ValueKey(isFavourite), // important for switcher
              color: isFavourite ? Colors.red : Colors.grey,
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

  void getIsFavourite() async {
    if (!mounted) return;
    isFavourite = await sl<IsFavouriteUsecase>().call(widget.designerId);

    widget.isFavouriteNotifier!.value = isFavourite;
  }
}
