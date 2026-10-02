import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

@JsonSerializable(explicitToJson: true)
class ClientMeasurementRelationship extends Equatable {
  @JsonKey(name: 'client_id')
  final String clientId;

  @JsonKey(name: 'is_default')
  final bool isDefault;

  const ClientMeasurementRelationship({
    required this.clientId,
    required this.isDefault,
  });

  factory ClientMeasurementRelationship.fromJson(Map<String, dynamic> json) {
    return ClientMeasurementRelationship(
      clientId: (json['client_id'] ?? '').toString(),
      isDefault: json['is_default'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'client_id': clientId,
        'is_default': isDefault,
      };

  ClientMeasurementRelationship copyWith({
    String? clientId,
    bool? isDefault,
  }) {
    return ClientMeasurementRelationship(
      clientId: clientId ?? this.clientId,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  @override
  List<Object?> get props => [clientId, isDefault];
}
