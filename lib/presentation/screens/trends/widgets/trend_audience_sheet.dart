import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/trends/trend_audience.dart';
import 'package:flutter/material.dart';

/// Asks who may see the post. Returns the picked audience, or `null` when the
/// sheet was dismissed without a choice.
Future<TrendAudience?> showTrendAudienceSheet(
  BuildContext context, {
  required TrendAudience current,
}) {
  return showModalBottomSheet<TrendAudience>(
    context: context,
    backgroundColor: Theme.of(context).cardTheme.color ?? Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => TrendAudienceSheet(current: current),
  );
}

class TrendAudienceSheet extends StatelessWidget {
  final TrendAudience current;

  const TrendAudienceSheet({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 40,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Who can see this?',
                  style: textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: context.onCanvasText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Public posts appear in the Trends feed. A draft is only '
                  'visible to you.',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.mutedText,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          // A tap applies the choice and closes: two options do not need a
          // separate confirm step. The row is the tap target so re-picking the
          // current value still closes the sheet.
          RadioGroup<TrendAudience>(
            groupValue: current,
            onChanged: (_) {},
            child: Column(
              children: [
                for (final audience in TrendAudience.values)
                  ListTile(
                    onTap: () => Navigator.of(context).pop(audience),
                    selected: audience == current,
                    selectedTileColor: context.iconSubstrate,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                    leading: Icon(
                      audience == TrendAudience.draft
                          ? Icons.lock_outline
                          : Icons.public,
                      size: 20,
                      color: context.secondaryLabel,
                    ),
                    title: Text(
                      audience.label,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.onCanvasText,
                      ),
                    ),
                    subtitle: Text(
                      audience.description,
                      style: TextStyle(fontSize: 13, color: context.mutedText),
                    ),
                    trailing: IgnorePointer(
                      child: Radio<TrendAudience>(
                        value: audience,
                        activeColor: context.accent,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
