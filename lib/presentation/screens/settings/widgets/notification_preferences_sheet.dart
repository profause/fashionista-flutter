import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/notification/bloc/notification_preferences_cubit.dart';
import 'package:fashionista/data/models/notification/bloc/notification_preferences_state.dart';
import 'package:fashionista/data/models/notification/notification_preferences.dart';
import 'package:fashionista/presentation/widgets/round_toggle.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Opens the notification preferences sheet above the settings screen.
Future<void> showNotificationPreferencesSheet(BuildContext context) {
  final cubit = context.read<NotificationPreferencesCubit>();
  // Reload on open so another device's change is picked up.
  cubit.load(force: true);

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardTheme.color ?? Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => BlocProvider<NotificationPreferencesCubit>.value(
      value: cubit,
      child: const NotificationPreferencesSheet(),
    ),
  );
}

/// Sections of toggles controlling which push notifications a user receives.
///
/// Only keys with a producer are rendered ([NotificationPreferenceKey.visible]);
/// the dormant ones stay in the stored document with their default.
class NotificationPreferencesSheet extends StatelessWidget {
  const NotificationPreferencesSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return BlocBuilder<NotificationPreferencesCubit,
            NotificationPreferencesState>(
          builder: (context, state) {
            return Column(
              children: [
                _DragHandle(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Notifications',
                        style: textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Choose what you want to be notified about. '
                        'Turning a category off stops push alerts; '
                        'your in-app activity feed keeps everything.',
                        style: TextStyle(
                          fontSize: 13,
                          color: context.mutedText,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.error != null)
                  _ErrorBanner(
                    message: state.error!,
                    onRetry: () => context
                        .read<NotificationPreferencesCubit>()
                        .load(force: true),
                  ),
                Expanded(child: _body(context, state, scrollController)),
              ],
            );
          },
        );
      },
    );
  }

  Widget _body(
    BuildContext context,
    NotificationPreferencesState state,
    ScrollController controller,
  ) {
    if (state.isLoading && !state.hasPreferences) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!state.hasPreferences) {
      return ListView(
        controller: controller,
        children: [
          const SizedBox(height: 48),
          Center(
            child: Text(
              'Unable to load your preferences.',
              style: TextStyle(fontSize: 14, color: context.mutedText),
            ),
          ),
          // `_ErrorBanner` already offers a retry; do not duplicate it.
          if (state.error == null) ...[
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: () => context
                    .read<NotificationPreferencesCubit>()
                    .load(force: true),
                child: const Text('Retry'),
              ),
            ),
          ],
        ],
      );
    }

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      children: [
        for (final section in NotificationPreferenceSection.values)
          if (section.keys.isNotEmpty) ...[
            const SizedBox(height: 16),
            _SectionHeader(title: section.title),
            const SizedBox(height: 8),
            _SettingsCard(
              children: [
                for (var index = 0; index < section.keys.length; index++) ...[
                  if (index > 0) const Divider(height: 0.1, thickness: 0.1),
                  _PreferenceRow(
                    preferenceKey: section.keys[index],
                    enabled: state.isEnabled(section.keys[index]),
                    saving: state.isSaving(section.keys[index]),
                    onChanged: (value) => context
                        .read<NotificationPreferencesCubit>()
                        .setPreference(section.keys[index], value),
                  ),
                ],
              ],
            ),
          ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _PreferenceRow extends StatelessWidget {
  final NotificationPreferenceKey preferenceKey;
  final bool enabled;
  final bool saving;
  final ValueChanged<bool> onChanged;

  const _PreferenceRow({
    required this.preferenceKey,
    required this.enabled,
    required this.saving,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  preferenceKey.label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: context.onCanvasText,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  preferenceKey.description,
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
          if (saving)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: context.accent,
                ),
              ),
            ),
          RoundToggle(value: enabled, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        height: 4,
        width: 40,
        margin: const EdgeInsets.only(top: 12, bottom: 16),
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
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
    return Container(
      decoration: BoxDecoration(
        color: context.canvasBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: children),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.appIconColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 18, color: AppTheme.appIconColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(fontSize: 13, color: context.onCanvasText),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
