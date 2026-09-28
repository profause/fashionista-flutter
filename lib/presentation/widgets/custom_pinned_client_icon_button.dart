import 'dart:async';

import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/clients/bloc/client_bloc.dart';
import 'package:fashionista/data/models/clients/bloc/client_event.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/domain/usecases/clients/pin_or_unpin_client_usecase.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomPinnedClientIconButton extends StatefulWidget {
  final Client client;
  const CustomPinnedClientIconButton({super.key, required this.client});

  @override
  State<CustomPinnedClientIconButton> createState() =>
      _CustomPinnedClientIconButtonState();
}

class _CustomPinnedClientIconButtonState
    extends State<CustomPinnedClientIconButton>
    with SingleTickerProviderStateMixin {
  late bool isPinned = false;
  late AnimationController _controller;
  late ValueNotifier<bool> isPinnedNotifier;

  Timer? _debounce; // 👈 debounce timer
  @override
  initState() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    isPinnedNotifier = ValueNotifier(widget.client.isPinned!);
    isPinnedNotifier.addListener(() {
      if (isPinnedNotifier.value) {
        if (!mounted) return;
        _controller.forward(from: 0); // restart burst animation
      }
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: isPinnedNotifier,
      builder: (_, isPinned, _) {
        return CustomIconButtonRounded(
          iconData: Icons.push_pin_outlined,
          onPressed: () async {
            isPinnedNotifier.value = !isPinned;
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
              //color: isPinned ? Colors.red : Colors.grey,
              size: 18,
            ),
          ),
        );
      },
    );
  }

  void _debouncePinOrUnpin() {
    _debounce?.cancel(); // cancel previous timer
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final result = await sl<PinOrUnpinClientUsecase>().call(
        widget.client.uid,
      );
      result.fold((l) {}, (r) {
        isPinnedNotifier.value = r;
        final updateClient = widget.client.copyWith(isPinned: r);
        context.read<ClientBloc>().add(UpdateClient(updateClient));
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}
