import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'client_measurement_model.g.dart';

@JsonSerializable()
class ClientMeasurement extends Equatable {
  @JsonKey(name: 'body_part')
  final String bodyPart;

  @JsonKey(name: 'measured_value')
  final double measuredValue;

  @JsonKey(name: 'measuring_unit')
  final String measuringUnit;

  @JsonKey(name: 'updated_date')
  final DateTime? updatedDate;

  final String? notes;

  @JsonKey(name: 'previous_values')
  final List<double> previousValues;

  @JsonKey(name: 'tags')
  final String? tags;

  const ClientMeasurement({
    required this.bodyPart,
    required this.measuredValue,
    required this.measuringUnit,
    required this.updatedDate,
    this.notes,
    required this.previousValues,
    this.tags,
  });

  factory ClientMeasurement.fromJson(Map<String, dynamic> json) =>
      _$ClientMeasurementFromJson(json);

  Map<String, dynamic> toJson() => _$ClientMeasurementToJson(this);

  // static DateTime _fromTimestamp(dynamic ts) {
  //   if (ts is Timestamp) return ts.toDate();
  //   if (ts is DateTime) return ts;
  //   throw ArgumentError('Invalid timestamp value: $ts');
  // }

  //static Timestamp _toTimestamp(DateTime date) => Timestamp.fromDate(date);

  ClientMeasurement copyWith({
    String? bodyPart,
    double? measuredValue,
    String? measuringUnit,
    DateTime? updatedDate,
    String? notes,
    List<double>? previousValues,
    String? tags,
  }) {
    return ClientMeasurement(
      bodyPart: bodyPart ?? this.bodyPart,
      measuredValue: measuredValue ?? this.measuredValue,
      measuringUnit: measuringUnit ?? this.measuringUnit,
      updatedDate: updatedDate ?? this.updatedDate,
      notes: notes ?? this.notes,
      previousValues: previousValues ?? this.previousValues,
      tags: tags ?? this.tags,
    );
  }

  /// Empty constructor for initial state
  factory ClientMeasurement.empty() {
    return const ClientMeasurement(
      bodyPart: '',
      measuredValue: 0,
      measuringUnit: '',
      updatedDate: null,
      previousValues: [],
      tags: '',
    );
  }

  @override
  List<Object?> get props => [
    bodyPart,
    measuredValue,
    measuringUnit,
    updatedDate,
    notes,
    previousValues,
    tags,
  ];

  static const Set<String> maleMeasurementTemplate = {
    "Bust",
    "Across Back",
    "Sleeve Length",
    "Arm hole",
    "Arm size",
    "Shoulder to waist",
    "Thigh",
    "Top Length",
    "Trouser Length",
    "Calf",
  };

  static const Set<String> femaleMeasurementTemplate = {
    "Bust",
    "Hip",
    "High Hip",
    "Back waist Length",
    "Front waist Length",
    "Arm hole",
    "Arm size",
    "Slit Length",
    "Breast Dart",
    "Skirt Length",
    "Top Length",
    "Shoulder to waist",
    "Sleeve Length",
  };

  /// Returns the measurement template based on gender
  static Set<String> getMeasurementTemplate(String gender) {
    final g = gender.trim().toLowerCase();
    if (g == 'female') {
      return femaleMeasurementTemplate;
    } else if (g == 'male') {
      return maleMeasurementTemplate;
    } else {
      return {}; // return empty set for "Other" or invalid gender
    }
  }
}
