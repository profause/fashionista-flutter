import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/trends/report_trend_reason_model.dart';

abstract class ReportTrendEvent extends Equatable {
  const ReportTrendEvent();

  @override
  List<Object?> get props => [];
}

class LoadReportTrendReasons extends ReportTrendEvent {
  const LoadReportTrendReasons();
}

class SelectReportTrendReason extends ReportTrendEvent {
  final ReportTrendReasonModel reason;

  const SelectReportTrendReason(this.reason);

  @override
  List<Object?> get props => [reason];
}

class SubmitReportTrend extends ReportTrendEvent {
  const SubmitReportTrend();
}

class PrepareReportSubmission extends ReportTrendEvent {
  const PrepareReportSubmission();
}

class ResetReportTrend extends ReportTrendEvent {
  const ResetReportTrend();
}
