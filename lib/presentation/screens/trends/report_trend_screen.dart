import 'package:fashionista/core/service_locator/app_toast.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/trends/bloc/report_trend_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/report_trend_event.dart';
import 'package:fashionista/data/models/trends/bloc/report_trend_state.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc.dart';
import 'package:fashionista/data/models/trends/bloc/trend_bloc_event.dart';
import 'package:fashionista/data/models/trends/report_trend_reason_model.dart';
import 'package:fashionista/data/models/trends/trend_feed_model.dart';
import 'package:fashionista/data/models/trends/trend_report_result.dart';
import 'package:fashionista/data/services/hive/hive_trend_service.dart';
import 'package:fashionista/presentation/screens/trends/widgets/report_confirmation_sheet.dart';
import 'package:fashionista/presentation/widgets/appbar_title.dart';
import 'package:fashionista/presentation/widgets/page_empty_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ReportTrendScreen extends StatefulWidget {
  final String trendId;

  const ReportTrendScreen({super.key, required this.trendId});

  @override
  State<ReportTrendScreen> createState() => _ReportTrendScreenState();
}

class _ReportTrendScreenState extends State<ReportTrendScreen> {
  late final ReportTrendBloc _bloc;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<ReportTrendBloc>()
      ..setTrendId(widget.trendId)
      ..add(const LoadReportTrendReasons());
  }

  @override
  void dispose() {
    _bloc.add(const ResetReportTrend());
    super.dispose();
  }

  Future<void> _continue() async {
    final reason = _bloc.state.selectedReason;
    if (reason == null) return;

    _bloc.prepareSubmission();
    final result = await showReportConfirmationSheet(context, reason: reason);
    if (result == null || !mounted) return;
    await _handleResult(result);
  }

  Future<void> _handleResult(TrendReportResult result) async {
    if (result.hidden) {
      final cached = await sl<HiveTrendService>().getItem(widget.trendId);
      if (cached.uid != null && mounted) {
        context.read<TrendBloc>().add(
          UpdateTrend(cached.copyWith(status: TrendFeedModel.statusReported)),
        );
      }
    }

    if (!mounted) return;

    if (result.alreadyReported) {
      AppToast.info(context, 'You already reported this trend.');
    } else if (result.hidden) {
      AppToast.success(
        context,
        'Report received. This trend is now hidden while we review it.',
      );
    } else {
      AppToast.success(
        context,
        'Thanks for reporting. We usually review reports within 48 hours.',
      );
    }

    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasBackground,
      appBar: AppBar(
        backgroundColor: context.canvasBackground,
        foregroundColor: context.onCanvasText,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: Border(bottom: BorderSide(color: context.hairline)),
        title: const AppBarTitle(title: 'Report trend'),
      ),
      body: SafeArea(
        child: BlocBuilder<ReportTrendBloc, ReportTrendState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Why are you reporting this trend?',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Your report is anonymous. We usually review reports '
                        'within 48 hours and won\'t notify this account.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: context.mutedText,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(child: _buildContent(state)),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: BlocBuilder<ReportTrendBloc, ReportTrendState>(
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: state.canSubmit ? _continue : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: context.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Continue'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildContent(ReportTrendState state) {
    if (state.isLoading && state.reasons.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.reasons.isEmpty) {
      return _buildMessage(
        title: 'Could not load report reasons',
        subtitle: state.error!,
        action: TextButton(
          onPressed: () => _bloc.add(const LoadReportTrendReasons()),
          child: const Text('Retry'),
        ),
      );
    }

    if (state.reasons.isEmpty) {
      return _buildMessage(
        title: 'Reporting is unavailable',
        subtitle: 'There are no report reasons available right now.',
        action: TextButton(
          onPressed: () => _bloc.add(const LoadReportTrendReasons()),
          child: const Text('Refresh'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      itemCount: state.reasons.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final reason = state.reasons[index];
        return _ReasonTile(
          reason: reason,
          selected: state.selectedReason?.uid == reason.uid,
          onTap: () => _bloc.add(SelectReportTrendReason(reason)),
        );
      },
    );
  }

  Widget _buildMessage({
    required String title,
    required String subtitle,
    required Widget action,
  }) {
    return ListView(
      padding: const EdgeInsets.only(top: 56),
      children: [
        PageEmptyWidget(
          title: title,
          subtitle: subtitle,
          icon: Icons.flag_outlined,
        ),
        const SizedBox(height: 8),
        Center(child: action),
      ],
    );
  }
}

class _ReasonTile extends StatelessWidget {
  final ReportTrendReasonModel reason;
  final bool selected;
  final VoidCallback onTap;

  const _ReasonTile({
    required this.reason,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: selected ? context.iconSubstrate : context.cardSurface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? context.accent : context.hairline,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reason.title,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: context.onCanvasText,
                      ),
                    ),
                    if (reason.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reason.description,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: context.mutedText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                size: 22,
                color: selected ? context.accent : context.placeholderText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
