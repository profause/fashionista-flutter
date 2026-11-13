import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/fashion_interests/fashion_interest_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Full-width interest catalogue shown under the composer.
///
/// Rows are tappable: selecting one inserts the matching `#hashtag` into the
/// description and closes the panel.
class FashionInterestPanel extends StatelessWidget {
  final List<FashionInterestModel> interests;
  final bool isLoading;
  final String? error;
  final String query;
  final ValueChanged<FashionInterestModel> onInterestTap;
  final VoidCallback? onRetry;

  const FashionInterestPanel({
    super.key,
    required this.interests,
    required this.onInterestTap,
    this.isLoading = false,
    this.error,
    this.query = '',
    this.onRetry,
  });

  static final NumberFormat _countFormat = NumberFormat.compact();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    if (isLoading && interests.isEmpty) {
      return _message(
        context,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'Loading interests…',
              style: textTheme.bodySmall?.copyWith(color: context.mutedText),
            ),
          ],
        ),
      );
    }

    if (error != null && interests.isEmpty) {
      return _message(
        context,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Could not load interests',
              style: textTheme.bodySmall?.copyWith(color: context.mutedText),
            ),
            if (onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (interests.isEmpty) {
      return _message(
        context,
        child: Text(
          query.isEmpty
              ? 'No interests available'
              : 'No interests match "$query"',
          style: textTheme.bodySmall?.copyWith(color: context.mutedText),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(context, textTheme),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: ListView.separated(
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            itemCount: interests.length,
            separatorBuilder: (_, _) =>
                Divider(height: 1, thickness: 1, color: context.hairline),
            itemBuilder: (context, index) {
              final interest = interests[index];
              return InkWell(
                key: ValueKey('fashion-interest-${interest.name}'),
                onTap: () => onInterestTap(interest),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          interest.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodyMedium?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: context.onCanvasText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${_countFormat.format(interest.numberOfPosts)} posts',
                        style: textTheme.labelSmall?.copyWith(
                          fontSize: 12,
                          color: context.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, TextTheme textTheme) {
    final label = query.isEmpty ? 'All interests' : 'Matching "$query"';

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelSmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: context.mutedText,
              ),
            ),
          ),
          Text(
            'Tap to add',
            style: textTheme.labelSmall?.copyWith(
              fontSize: 11,
              color: context.placeholderText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _message(BuildContext context, {required Widget child}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
      child: Center(child: child),
    );
  }
}
