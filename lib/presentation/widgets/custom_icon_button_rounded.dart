import 'package:fashionista/data/models/settings/bloc/settings_bloc.dart';
import 'package:fashionista/data/models/settings/models/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomIconButtonRounded extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData iconData;
  final double? size;
  final Widget? icon;
  final Color? backgroundColor;
  const CustomIconButtonRounded({
    super.key,
    required this.onPressed,
    this.icon,
    this.size = 24,
    required this.iconData,
    this.backgroundColor = Colors.transparent,
  });

  @override
  Widget build(BuildContext context) {
    //final iconTheme = Theme.of(context).iconTheme;
    //final colorScheme = Theme.of(context).colorScheme;
    return BlocBuilder<SettingsBloc, Settings>(
      builder: (context, settings) {
        ThemeMode themeMode = ThemeMode.values[settings.displayMode as int];
        return Material(
          color: backgroundColor != Colors.transparent
              ? (themeMode == ThemeMode.light
                    ? Colors.grey.shade200
                    : Colors.black.withValues(alpha: 0.4))
              : backgroundColor,
          //colorScheme.onSurface, // background color
          shape: const CircleBorder(),
          // borderRadius: BorderRadius.circular(size! / 2), // makes it round
          child: InkWell(
            borderRadius: BorderRadius.circular(50), // ripple matches shape
            onTap: onPressed,
            child: Padding(
              padding: EdgeInsets.all(6), // space around icon
              child: icon ?? Icon(iconData, size: size),
            ),
          ),
        );
      },
    );
  }
}
