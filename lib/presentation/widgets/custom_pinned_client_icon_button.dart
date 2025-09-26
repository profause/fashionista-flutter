import 'dart:async';

import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/domain/usecases/clients/pin_or_unpin_client_usecase.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:flutter/material.dart';

class CustomPinnedClientIconButton extends StatefulWidget {
  final String clientId;
  final ValueNotifier<bool>? isPinnedNotifier;
  const CustomPinnedClientIconButton({
    super.key,
    required this.clientId,
    this.isPinnedNotifier,
  });

  @override
  State<CustomPinnedClientIconButton> createState() =>
      _CustomPinnedClientIconButtonState();
}

class _CustomPinnedClientIconButtonState
    extends State<CustomPinnedClientIconButton>
    with SingleTickerProviderStateMixin {
  late bool isPinned = false;
  late AnimationController _controller;
  Timer? _debounce; // 👈 debounce timer
  @override
  initState() {
    //getIsPinned();
    //widget.isPinnedNotifier?.value = isPinned;

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // _scale = Tween<double>(
    //   begin: 0.7,
    //   end: 1.2,
    // ).chain(CurveTween(curve: Curves.elasticOut)).animate(_controller);

    widget.isPinnedNotifier!.addListener(() {
      if (widget.isPinnedNotifier!.value) {
        if (!mounted) return;
        _controller.forward(from: 0); // restart burst animation
      }
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: widget.isPinnedNotifier!,
      builder: (_, isPinned, __) {
        return CustomIconButtonRounded(
          iconData: Icons.push_pin_outlined,
          onPressed: () async {
            widget.isPinnedNotifier!.value = !isPinned;
            setState(() {
              isPinned = !isPinned;
            });
            _debouncePinOrUnpin();
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
              isPinned ? Icons.push_pin : Icons.push_pin_outlined,
              key: ValueKey(isPinned), // important for switcher
              color: isPinned ? Colors.red : Colors.grey,
              size: 20,
            ),
          ),
        );
      },
    );
  }

  void _debouncePinOrUnpin() {
    _debounce?.cancel(); // cancel previous timer
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final result = await sl<PinOrUnpinClientUsecase>().call(widget.clientId);
      result.fold((l) {}, (r) {
        widget.isPinnedNotifier!.value = r;
        // setState(() {
        //   isPinned = r;
        // });
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // void getIsPinned() async {
  //   if (!mounted) return;
  //   isPinned = await sl<IsPinnedClientUsecase>().call(
  //     widget.clientId,
  //   );
  //   widget.isPinnedNotifier!.value = isPinned;
  // }
}
