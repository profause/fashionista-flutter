import 'package:fashionista/data/models/settings/bloc/settings_bloc.dart';
import 'package:fashionista/data/models/settings/models/settings_model.dart';
import 'package:fashionista/presentation/widgets/appbar_title.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
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
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Display mode",
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                themeMode == ThemeMode.light
                                    ? 'Light'
                                    : themeMode == ThemeMode.dark
                                    ? 'Dark'
                                    : 'System',
                                style: textTheme.bodyLarge,
                                textAlign: TextAlign.start,
                              ),
                            ],
                          ),
                          const Spacer(), // Space between buttons
                          CustomIconButtonRounded(
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
                                    : Icons
                                          .wb_sunny_outlined, // sun for dark mode
                                key: ValueKey(themeMode),
                                //color: colorScheme.onPrimary, // important for AnimatedSwitcher to detect changes
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 0,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Auto play videos",
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                settings.autoPlayVideos == true ? 'Yes' : 'No',
                                style: textTheme.bodyLarge,
                                textAlign: TextAlign.start,
                              ),
                            ],
                          ),
                          const Spacer(),
                          Switch(
                            value: settings.autoPlayVideos ?? false,
                            onChanged: (value) {
                              final updatedSettings = settings.copyWith(
                                autoPlayVideos: value,
                              );
                              context.read<SettingsBloc>().add(
                                UpdateSettings(updatedSettings),
                              );
                            },
                          ), // Space between buttons
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
