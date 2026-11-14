import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'report_trend_reason_model.g.dart';

/// One selectable reason from the `report_trend_content` collection.
@JsonSerializable(explicitToJson: true)
class ReportTrendReasonModel extends Equatable {
  final String? uid;

  @JsonKey(defaultValue: '')
  final String title;

  @JsonKey(defaultValue: '')
  final String description;

  /// Markdown shown in the confirmation sheet.
  @JsonKey(defaultValue: '')
  final String content;

  @JsonKey(name: 'updated_at')
  final int? updatedAt;

  /// Display order; missing values sort last.
  final int? order;

  @JsonKey(name: 'is_active')
  final bool? isActive;

  const ReportTrendReasonModel({
    this.uid,
    this.title = '',
    this.description = '',
    this.content = '',
    this.updatedAt,
    this.order,
    this.isActive,
  });

  factory ReportTrendReasonModel.fromJson(Map<String, dynamic> json) =>
      _$ReportTrendReasonModelFromJson(json);

  Map<String, dynamic> toJson() => _$ReportTrendReasonModelToJson(this);

  bool get isEnabled => isActive ?? true;

  int get sortOrder => order ?? 999;

  @override
  List<Object?> get props => [
    uid,
    title,
    description,
    content,
    updatedAt,
    order,
    isActive,
  ];
}
