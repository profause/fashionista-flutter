import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/trends/bloc/report_trend_event.dart';
import 'package:fashionista/data/models/trends/bloc/report_trend_state.dart';
import 'package:fashionista/domain/usecases/trends/fetch_report_trend_reasons_usecase.dart';
import 'package:fashionista/domain/usecases/trends/submit_trend_report_usecase.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ReportTrendBloc extends Bloc<ReportTrendEvent, ReportTrendState> {
  ReportTrendBloc() : super(const ReportTrendState()) {
    on<LoadReportTrendReasons>(_onLoadReasons);
    on<SelectReportTrendReason>(_onSelectReason);
    on<PrepareReportSubmission>(_onPrepareSubmission);
    on<SubmitReportTrend>(_onSubmit);
    on<ResetReportTrend>((event, emit) {
      _trendId = null;
      emit(const ReportTrendState());
    });
  }

  String? _trendId;

  /// The screen tells the bloc which trend is being reported before loading.
  void setTrendId(String trendId) {
    _trendId = trendId;
  }

  /// Clears a previous failure before the confirmation sheet is reopened.
  void prepareSubmission() {
    if (isClosed) return;
    add(const PrepareReportSubmission());
  }

  void _onPrepareSubmission(
    PrepareReportSubmission event,
    Emitter<ReportTrendState> emit,
  ) {
    emit(state.copyWith(clearSubmissionError: true, clearResult: true));
  }

  Future<void> _onLoadReasons(
    LoadReportTrendReasons event,
    Emitter<ReportTrendState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearSubmissionError: true,
        clearResult: true,
      ),
    );

    final result = await sl<FetchReportTrendReasonsUsecase>().call('');
    result.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, error: failure.toString())),
      (reasons) => emit(
        state.copyWith(
          isLoading: false,
          reasons: List.of(reasons),
          clearError: true,
        ),
      ),
    );
  }

  void _onSelectReason(
    SelectReportTrendReason event,
    Emitter<ReportTrendState> emit,
  ) {
    emit(
      state.copyWith(
        selectedReason: event.reason,
        clearSubmissionError: true,
        clearResult: true,
      ),
    );
  }

  Future<void> _onSubmit(
    SubmitReportTrend event,
    Emitter<ReportTrendState> emit,
  ) async {
    final reason = state.selectedReason;
    final trendId = _trendId;
    if (reason == null || trendId == null || state.isSubmitting) return;

    emit(
      state.copyWith(
        isSubmitting: true,
        clearSubmissionError: true,
        clearResult: true,
      ),
    );

    final result = await sl<SubmitTrendReportUsecase>().call(
      SubmitTrendReportParams(trendId: trendId, reasonId: reason.uid ?? ''),
    );

    result.fold(
      (failure) => emit(
        state.copyWith(
          isSubmitting: false,
          submissionError: failure.toString(),
        ),
      ),
      (value) => emit(state.copyWith(isSubmitting: false, result: value)),
    );
  }
}
