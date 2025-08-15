import 'package:fashionista/data/models/settings/bloc/settings_bloc.dart';
import 'package:fashionista/data/models/settings/models/settings_model.dart';
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
            backgroundColor: colorScheme.surface,
            title: Text(
              'Settings',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Card(
                    color: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    elevation: 1,
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
                                  color: Colors.grey[700],
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
                          IconButton(
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
                                key: ValueKey(
                                  themeMode,
                                ), // important for AnimatedSwitcher to detect changes
                              ),
                            ),
                          ),
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
