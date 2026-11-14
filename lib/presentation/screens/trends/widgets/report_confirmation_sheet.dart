import 'dart:async';

import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/trends/bloc/report_trend_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/report_trend_event.dart';
import 'package:fashionista/data/models/trends/bloc/report_trend_state.dart';
import 'package:fashionista/data/models/trends/report_trend_reason_model.dart';
import 'package:fashionista/data/models/trends/trend_report_result.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows the selected reason's Markdown and submits only after confirmation.
/// Returns the server result, or `null` when the user cancels.
Future<TrendReportResult?> showReportConfirmationSheet(
  BuildContext context, {
  required ReportTrendReasonModel reason,
}) {
  return showModalBottomSheet<TrendReportResult>(
    context: context,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: context.cardSurface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => ReportConfirmationSheet(reason: reason),
  );
}

class ReportConfirmationSheet extends StatelessWidget {
  final ReportTrendReasonModel reason;

  const ReportConfirmationSheet({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: BlocConsumer<ReportTrendBloc, ReportTrendState>(
        listenWhen: (previous, current) =>
            current.result != null && previous.result != current.result,
        listener: (context, state) {
          Navigator.of(context).pop(state.result);
        },
        builder: (context, state) {
          final isSubmitting = state.isSubmitting;
          final maxHeight = MediaQuery.sizeOf(context).height * 0.78;

          return PopScope(
            canPop: !isSubmitting,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Confirm report',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reason.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: context.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                      child: MarkdownBody(
                        data: reason.content,
                        styleSheet:
                            MarkdownStyleSheet.fromTheme(
                              Theme.of(context),
                            ).copyWith(
                              p: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: context.descriptionText,
                              ),
                              listBullet: TextStyle(
                                fontSize: 14,
                                height: 1.5,
                                color: context.descriptionText,
                              ),
                            ),
                        onTapLink: (text, href, title) {
                          if (href == null) return;
                          final uri = Uri.tryParse(href);
                          if (uri != null &&
                              (uri.scheme == 'https' ||
                                  uri.scheme == 'mailto')) {
                            unawaited(launchUrl(uri));
                          }
                        },
                      ),
                    ),
                  ),
                  if (state.submissionError != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                      child: Text(
                        state.submissionError!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: isSubmitting
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: isSubmitting
                                ? null
                                : () => context.read<ReportTrendBloc>().add(
                                    const SubmitReportTrend(),
                                  ),
                            style: FilledButton.styleFrom(
                              backgroundColor: context.accent,
                              foregroundColor: Colors.white,
                            ),
                            child: isSubmitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Confirm report'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
