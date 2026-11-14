import 'package:equatable/equatable.dart';
import 'package:fashionista/data/models/trends/report_trend_reason_model.dart';
import 'package:fashionista/data/models/trends/trend_report_result.dart';

class ReportTrendState extends Equatable {
  final List<ReportTrendReasonModel> reasons;
  final ReportTrendReasonModel? selectedReason;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final String? submissionError;
  final TrendReportResult? result;

  const ReportTrendState({
    this.reasons = const [],
    this.selectedReason,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.submissionError,
    this.result,
  });

  bool get canSubmit => selectedReason != null && !isLoading && !isSubmitting;

  ReportTrendState copyWith({
    List<ReportTrendReasonModel>? reasons,
    ReportTrendReasonModel? selectedReason,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    String? submissionError,
    TrendReportResult? result,
    bool clearSelectedReason = false,
    bool clearError = false,
    bool clearSubmissionError = false,
    bool clearResult = false,
  }) {
    return ReportTrendState(
      reasons: reasons ?? this.reasons,
      selectedReason: clearSelectedReason
          ? null
          : selectedReason ?? this.selectedReason,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
      submissionError: clearSubmissionError
          ? null
          : submissionError ?? this.submissionError,
      result: clearResult ? null : result ?? this.result,
    );
  }

  @override
  List<Object?> get props => [
    reasons,
    selectedReason,
    isLoading,
    isSubmitting,
    error,
    submissionError,
    result,
  ];
}
