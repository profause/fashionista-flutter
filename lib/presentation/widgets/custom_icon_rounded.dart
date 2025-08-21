import 'package:fashionista/data/models/settings/bloc/settings_bloc.dart';
import 'package:fashionista/data/models/settings/models/settings_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomIconRounded extends StatelessWidget {
  final IconData icon;
  final double? size;
  const CustomIconRounded({super.key, required this.icon, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, Settings>(
      builder: (context, settings) {
        ThemeMode themeMode = ThemeMode.values[settings.displayMode as int];
        return Material(
          color: themeMode == ThemeMode.light
              ? Colors.grey.shade200
              : Colors.black.withValues(alpha: 0.5), // background color
          shape: const CircleBorder(),
          // borderRadius: BorderRadius.circular(size! / 2), // makes it round
          child: InkWell(
            borderRadius: BorderRadius.circular(50), // ripple matches shape
            child: Padding(
              padding: EdgeInsets.all(6), // space around icon
              child: Icon(icon, size: size),
            ),
          ),
        );
      },
    );
  }
}
