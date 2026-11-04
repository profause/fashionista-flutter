import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'availability_session_model.g.dart';

/// A single availability window inside a day, stored as local wall-clock time.
@JsonSerializable(explicitToJson: true)
class AvailabilitySession extends Equatable {
  @JsonKey(name: 'start_time', defaultValue: '')
  final String startTime;

  @JsonKey(name: 'end_time', defaultValue: '')
  final String endTime;

  const AvailabilitySession({required this.startTime, required this.endTime});

  factory AvailabilitySession.fromJson(Map<String, dynamic> json) =>
      _$AvailabilitySessionFromJson(json);

  Map<String, dynamic> toJson() => _$AvailabilitySessionToJson(this);

  AvailabilitySession copyWith({String? startTime, String? endTime}) {
    return AvailabilitySession(
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
    );
  }

  String get label => '$startTime - $endTime';

  @override
  List<Object?> get props => [startTime, endTime];
}
