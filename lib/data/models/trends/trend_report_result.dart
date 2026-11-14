import 'package:equatable/equatable.dart';

/// Result of the `reportTrend` callable.
class TrendReportResult extends Equatable {
  /// True when this report pushed the trend over the threshold and it is now
  /// hidden from public surfaces.
  final bool hidden;

  /// True when the signed-in user had already reported this trend.
  final bool alreadyReported;

  /// Unique reporters recorded for the trend after this call.
  final int numberOfReports;

  const TrendReportResult({
    this.hidden = false,
    this.alreadyReported = false,
    this.numberOfReports = 0,
  });

  factory TrendReportResult.fromMap(Map<String, dynamic> map) {
    return TrendReportResult(
      hidden: map['hidden'] == true,
      alreadyReported: map['alreadyReported'] == true,
      numberOfReports: (map['numberOfReports'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [hidden, alreadyReported, numberOfReports];
}
