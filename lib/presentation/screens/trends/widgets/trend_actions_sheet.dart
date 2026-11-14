import 'package:fashionista/core/service_locator/app_toast.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/data/services/media/trend_media_download_service.dart';
import 'package:fashionista/data/services/media/trend_share_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

enum TrendAction { download, share, report }

/// Shows the long-press actions for a trend. The caller performs the returned
/// action so a dismissed sheet is a no-op.
Future<TrendAction?> showTrendActionsSheet(
  BuildContext context, {
  required TrendFeedModel trend,
  required bool canReport,
}) {
  return showModalBottomSheet<TrendAction>(
    context: context,
    backgroundColor: context.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _TrendActionsSheet(trend: trend, canReport: canReport),
  );
}

/// Routes or runs the side effect for [action].
Future<void> performTrendAction(
  BuildContext context,
  TrendFeedModel trend,
  TrendAction action, {
  Rect? sharePositionOrigin,
}) async {
  switch (action) {
    case TrendAction.report:
      if (trend.uid == null) return;
      context.push('/trends/${trend.uid}/report');
      return;
    case TrendAction.download:
      AppToast.info(context, 'Saving this trend to your gallery…');
      final result = await sl<TrendMediaDownloadService>().download(trend);
      if (!context.mounted) return;
      result.fold(
        (failure) => AppToast.error(context, failure.toString()),
        (_) => AppToast.success(context, 'Saved to your gallery.'),
      );
      return;
    case TrendAction.share:
      final result = await sl<TrendShareService>().shareTrend(
        trend,
        sharePositionOrigin: sharePositionOrigin,
      );
      if (!context.mounted) return;
      result.fold(
        (failure) => AppToast.error(context, failure.toString()),
        (_) {},
      );
      return;
  }
}

/// A stable popover anchor for the iPad share sheet.
Rect? shareOriginFor(BuildContext context) {
  final renderObject = context.findRenderObject();
  if (renderObject is! RenderBox || !renderObject.hasSize) return null;
  return renderObject.localToGlobal(Offset.zero) & renderObject.size;
}

class _TrendActionsSheet extends StatelessWidget {
  final TrendFeedModel trend;
  final bool canReport;

  const _TrendActionsSheet({required this.trend, required this.canReport});

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
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: context.softBorder,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Trend options',
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: context.onCanvasText,
                    ),
                  ),
                ),
                if ((trend.author.name ?? '').isNotEmpty)
                  Flexible(
                    child: Text(
                      '@${trend.author.name}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: context.mutedText),
                    ),
                  ),
              ],
            ),
          ),
          _ActionTile(
            icon: Icons.download_outlined,
            label: 'Download',
            subtitle: 'Save the media to your gallery',
            onTap: () => Navigator.of(context).pop(TrendAction.download),
          ),
          _ActionTile(
            icon: Icons.ios_share,
            label: 'Share',
            subtitle: 'Send this trend to someone',
            onTap: () => Navigator.of(context).pop(TrendAction.share),
          ),
          if (canReport)
            _ActionTile(
              icon: Icons.flag_outlined,
              label: 'Report',
              subtitle: 'Tell us why this trend should be reviewed',
              isDestructive: true,
              onTap: () => Navigator.of(context).pop(TrendAction.report),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final tint = isDestructive ? context.accent : context.secondaryLabel;

    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        height: 40,
        width: 40,
        decoration: BoxDecoration(
          color: context.iconSubstrate,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 20, color: tint),
      ),
      title: Text(
        label,
        style: textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: context.onCanvasText,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: context.mutedText),
      ),
      trailing: Icon(
        Icons.chevron_right,
        size: 18,
        color: context.placeholderText,
      ),
    );
  }
}
