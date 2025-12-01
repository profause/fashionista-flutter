import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/widgets/bloc/button_loading_state_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AnimatedPrimaryButton extends StatefulWidget {
  final String text;
  final Future<void> Function() onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? elevation;

  const AnimatedPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.width = double.infinity,
    this.elevation = 2,
  });

  @override
  State<AnimatedPrimaryButton> createState() => _AnimatedPrimaryButtonState();
}

class _AnimatedPrimaryButtonState extends State<AnimatedPrimaryButton>
    with SingleTickerProviderStateMixin {
  bool _isPressed = false;
  bool _isLoading = false;

  late ButtonLoadingStateCubit _buttonLoadingStateCubit;

  @override
  void initState() {
    super.initState();
    if (mounted) {
      _buttonLoadingStateCubit = context.read<ButtonLoadingStateCubit>();
      _buttonLoadingStateCubit.setLoading(false);
    }
  }

  Future<void> _handlePress() async {
    if (_isLoading) return; // prevent double taps
    //_buttonLoadingStateCubit.setLoading(true);
    //setState(() => _isLoading = _buttonLoadingStateCubit.state);
    try {
      await widget.onPressed();
    } finally {}
  }

  @override
  void dispose() {
    super.dispose();
    if (mounted) {
      _buttonLoadingStateCubit.setLoading(false);
      //setState(() => _isLoading = _buttonLoadingStateCubit.state);
      //_buttonLoadingStateCubit.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocBuilder<ButtonLoadingStateCubit, bool>(
      builder: (context, isLoading) {
        _isLoading = isLoading;
        return GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) {
            setState(() => _isPressed = true);
            //_handlePress();
          },
          onTapCancel: () => setState(() => _isPressed = false),
          child: SizedBox(
            width: widget.width,
            child: AnimatedScale(
              scale: _isPressed ? 0.96 : 1.0,
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              child: AnimatedOpacity(
                opacity: _isPressed ? 0.85 : 1.0,
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        widget.backgroundColor ?? AppTheme.appIconColor,
                    foregroundColor:
                        widget.foregroundColor ?? colorScheme.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: _handlePress,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: _isLoading
                        ? SizedBox(
                            key: const ValueKey("spinner"),
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.foregroundColor ?? colorScheme.primary,
                              ),
                            ),
                          )
                        : Text(
                            widget.text,
                            key: const ValueKey("text"),
                            style: const TextStyle(fontSize: 18,
                            color: Colors.white
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
