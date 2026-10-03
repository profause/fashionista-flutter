import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable(explicitToJson: true)
class ClientMeasurementRelationship extends Equatable {
  @JsonKey(name: 'client_id')
  final String clientId;

  @JsonKey(name: 'is_default')
  final bool isDefault;

  @JsonKey(name: 'designer_id')
  final String designerId;

  const ClientMeasurementRelationship({
    required this.clientId,
    required this.isDefault,
    required this.designerId,
  });

  factory ClientMeasurementRelationship.fromJson(Map<String, dynamic> json) {
    return ClientMeasurementRelationship(
      clientId: (json['client_id'] ?? '').toString(),
      isDefault: json['is_default'] == true,
      designerId: (json['designer_id'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'client_id': clientId,
        'is_default': isDefault,
        'designer_id': designerId,
      };

  ClientMeasurementRelationship copyWith({
    String? clientId,
    bool? isDefault,
    String? designerId,
  }) {
    return ClientMeasurementRelationship(
      clientId: clientId ?? this.clientId,
      isDefault: isDefault ?? this.isDefault,
      designerId: designerId ?? this.designerId,
    );
  }

  @override
  List<Object?> get props => [clientId, isDefault, designerId];
}
