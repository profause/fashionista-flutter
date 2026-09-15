import 'package:fashionista/core/theme/app.theme.dart';
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
    return BlocBuilder<SettingsBloc, Settings>(
      builder: (context, settings) {
        ThemeMode themeMode = ThemeMode.values[settings.displayMode as int];
        String imageQuality = settings.imageQuality ?? 'SD';
        return Scaffold(
          backgroundColor: context.canvasBackground,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            foregroundColor: context.onCanvasText,
            elevation: 0,
            scrolledUnderElevation: 0,
            centerTitle: true,
            leading: const SizedBox(
              width: 32,
              height: 32,
              child: _NavBackButton(),
            ),
            title: Text(
              'Settings',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: context.onCanvasText,
              ),
            ),
            actions: const [
              SizedBox(
                width: 32,
                height: 32,
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: SizedBox(
                height: 1,
                child: ColoredBox(color: context.hairline),
              ),
            ),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              children: [
                const _SectionHeader('Media & Display'),
                const SizedBox(height: 8),
                _SettingsCard(
                  children: [
                    SettingsRow(
                      title: 'Display mode',
                      subtitle: 'Choose app appearance',
                      onTap: () {
                        themeMode = themeMode == ThemeMode.light
                            ? ThemeMode.dark
                            : themeMode == ThemeMode.dark
                            ? ThemeMode.light
                            : ThemeMode.light;
                        final updatedSettings = settings.copyWith(
                          displayMode: themeMode.index,
                        );
                        context.read<SettingsBloc>().add(
                          UpdateSettings(updatedSettings),
                        );
                      },
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            themeMode == ThemeMode.light
                                ? 'Light'
                                : themeMode == ThemeMode.dark
                                ? 'Dark'
                                : 'System',
                            style: TextStyle(
                              fontSize: 14,
                              color: context.mutedText,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const _Chevron(),
                        ],
                      ),
                    ),
                    SettingsRow(
                      title: 'Auto play videos',
                      subtitle: 'Play videos automatically when scrolling',
                      trailing: _RoundToggle(
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
                    SettingsRow(
                      title: 'Image quality',
                      subtitle: imageQuality == 'SD'
                          ? 'Standard - Optimized for speed and data saver'
                          : 'High - Optimized for quality and sharpness',
                      onTap: () {
                        _showImageQualityBottomsheet(context, settings);
                      },
                      trailing: const _Chevron(),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const _SectionHeader('Account & Privacy'),
                const SizedBox(height: 8),
                _SettingsCard(
                  children: [
                    SettingsRow(
                      title: 'Notifications',
                      subtitle: 'Order updates, style drops, and alerts',
                      onTap: () => _comingSoon(context),
                      trailing: const _Chevron(),
                    ),
                    SettingsRow(
                      title: 'Data & Storage',
                      subtitle: 'Network usage and media caching',
                      onTap: () => _comingSoon(context),
                      trailing: const _Chevron(),
                    ),
                    SettingsRow(
                      title: 'Clear Cache',
                      subtitle: 'Free up temporary device storage',
                      onTap: () => _comingSoon(context),
                      trailing: Text(
                        '24.5 MB',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: context.mutedText,
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 20),
                  child: Text(
                    'Fashionista v2.4.0 • Build 1420',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: context.placeholderText,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }

  void _showImageQualityBottomsheet(BuildContext context, Settings settings) {
    final textTheme = Theme.of(context).textTheme;

    String imageQuality = settings.imageQuality ?? 'SD'; // <-- MOVED HERE

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardTheme.color ?? Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
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
                            color: Theme.of(context).scaffoldBackgroundColor,
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
                                      setModalState(() => imageQuality = val!);

                                      context.read<SettingsBloc>().add(
                                        UpdateSettings(
                                          settings.copyWith(imageQuality: "SD"),
                                        ),
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

                                      context.read<SettingsBloc>().add(
                                        UpdateSettings(
                                          settings.copyWith(imageQuality: "HD"),
                                        ),
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

class _NavBackButton extends StatelessWidget {
  const _NavBackButton();

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.chevron_left, size: 26, color: context.onCanvasText),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onPressed: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 1,
          color: context.mutedText,
        ),
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ));
      }
      rows.add(children[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A1A1C1E),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: rows,
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget trailing;
  final VoidCallback? onTap;

  const SettingsRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 72),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: context.onCanvasText,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.mutedText,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            trailing,
          ],
        ),
      ),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron();

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.chevron_right,
      size: 16,
      color: context.placeholderText,
    );
  }
}

class _RoundToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _RoundToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        width: 44,
        height: 24,
        padding: const EdgeInsets.all(2),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: BoxDecoration(
          color: value ? context.accent : context.softBorder,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Container(
          width: 20,
          height: 20,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 2,
                offset: Offset(0, 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}