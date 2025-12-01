import 'package:fashionista/data/models/settings/bloc/settings_bloc.dart';
import 'package:fashionista/data/models/settings/models/settings_model.dart';
import 'package:fashionista/presentation/widgets/appbar_title.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:fashionista/presentation/widgets/custom_icon_rounded.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return BlocBuilder<SettingsBloc, Settings>(
      builder: (context, settings) {
        ThemeMode themeMode = ThemeMode.values[settings.displayMode as int];
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            foregroundColor: colorScheme.primary,
            backgroundColor: colorScheme.onPrimary,
            title: const AppBarTitle(title: "Settings"),
            elevation: 0,
            //toolbarHeight: 0,
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.01),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(
                        "Display mode",
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        themeMode == ThemeMode.light
                            ? 'Light'
                            : themeMode == ThemeMode.dark
                            ? 'Dark'
                            : 'System',
                        textAlign: TextAlign.start,
                      ),
                      trailing: CustomIconButtonRounded(
                        onPressed: () {
                          //setState(() {
                          themeMode = themeMode == ThemeMode.light
                              ? ThemeMode.dark
                              : ThemeMode.light;
                          final updatedSettings = settings.copyWith(
                            displayMode: themeMode.index,
                          );
                          context.read<SettingsBloc>().add(
                            UpdateSettings(updatedSettings),
                          );
                          //});
                        },
                        iconData: Icons.brightness_2_outlined,
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 250),
                          transitionBuilder:
                              (Widget child, Animation<double> animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                          child: Icon(
                            themeMode == ThemeMode.light
                                ? Icons
                                      .brightness_2_outlined // moon for light mode
                                : Icons.wb_sunny_outlined, // sun for dark mode
                            key: ValueKey(themeMode),
                            //color: colorScheme.onPrimary, // important for AnimatedSwitcher to detect changes
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.01),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(
                        "Auto play videos",
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        settings.autoPlayVideos == true ? 'Yes' : 'No',
                        textAlign: TextAlign.start,
                      ),
                      trailing: Switch(
                        value: settings.autoPlayVideos ?? false,
                        onChanged: (value) {
                          final updatedSettings = settings.copyWith(
                            autoPlayVideos: value,
                          );
                          context.read<SettingsBloc>().add(
                            UpdateSettings(updatedSettings),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.onPrimary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.01),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(
                        "Image quality",
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        settings.imageQuality == 'SD'
                            ? 'Standard-Optimized for speed and good detail'
                            : 'High-Optimized for quality and sharpness',
                      ),
                      trailing: CustomIconRounded(
                        icon: settings.imageQuality == 'SD'
                            ? Icons.sd_outlined
                            : Icons.hd_outlined,
                      ),
                      onTap: () {
                        _showImageQualityBottomsheet(context, settings);
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showImageQualityBottomsheet(BuildContext context, Settings settings) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.onPrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String imageQuality = settings.imageQuality ?? 'SD';
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.3,
              minChildSize: 0.3,
              maxChildSize: 0.3,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// Handle bar
                        Center(
                          child: Container(
                            height: 4,
                            width: 40,
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.grey[400],
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Text(
                          "Image Quality",
                          style: textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          padding: const EdgeInsets.all(0),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text(
                                      "Standard Definition",
                                      style: textTheme.titleSmall!.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Radio<String>(
                                    value: "SD",
                                    groupValue: imageQuality,
                                    onChanged: (val) {
                                      // update parent too
                                      setModalState(() => imageQuality = val!);
                                      
                                      final updatedSettings = settings.copyWith(
                                        imageQuality: 'SD',
                                      );
                                      context.read<SettingsBloc>().add(
                                        UpdateSettings(updatedSettings),
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const Divider(height: .1, thickness: .1),
                              Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(left: 12),
                                    child: Text(
                                      "High Definition",
                                      style: textTheme.titleSmall!.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Radio<String>(
                                    value: "HD",
                                    groupValue: imageQuality,
                                    onChanged: (val) {
                                      setModalState(() => imageQuality = val!);
                                      
                                      final updatedSettings = settings.copyWith(
                                        imageQuality: 'HD',
                                      );
                                      context.read<SettingsBloc>().add(
                                        UpdateSettings(updatedSettings),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
