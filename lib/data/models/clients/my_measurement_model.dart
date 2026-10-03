import 'package:equatable/equatable.dart';
import 'package:fashionista/core/models/hive/hive_type.dart' as hive;
import 'package:fashionista/core/models/hive/my_measurement_model_hive_type.dart';
import 'package:fashionista/data/models/clients/client_measurement_model.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'my_measurement_model.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: hive.HiveType.myMeasurementType)
class MyMeasurement extends Equatable {
  @HiveField(MyMeasurementModelHiveType.uid)
  @JsonKey(defaultValue: '')
  final String uid;

  @HiveField(MyMeasurementModelHiveType.designer)
  @JsonKey(name: 'designer', fromJson: MyMeasurement._designerFromJson)
  final Designer designer;

  @HiveField(MyMeasurementModelHiveType.measurements)
  @JsonKey(
    name: 'measurements',
    defaultValue: <ClientMeasurement>[],
    fromJson: MyMeasurement._measurementsFromJson,
  )
  final List<ClientMeasurement> measurements;

  @HiveField(MyMeasurementModelHiveType.isDefault)
  @JsonKey(name: 'is_default', defaultValue: false)
  final bool isDefault;

  const MyMeasurement({
    required this.uid,
    required this.designer,
    required this.measurements,
    required this.isDefault,
  });

  static List<ClientMeasurement> _measurementsFromJson(dynamic value) {
    if (value == null) {
      return const <ClientMeasurement>[];
    }

    if (value is! List) {
      return const <ClientMeasurement>[];
    }

    return value.map((item) {
      if (item is Map<String, dynamic>) {
        return ClientMeasurement.fromJson(item);
      }
      if (item is Map) {
        return ClientMeasurement.fromJson(Map<String, dynamic>.from(item));
      }
      return ClientMeasurement.empty();
    }).toList();
  }

  factory MyMeasurement.fromJson(Map<String, dynamic> json) =>
      _$MyMeasurementFromJson(json);

  Map<String, dynamic> toJson() => _$MyMeasurementToJson(this);

  static Designer _designerFromJson(dynamic value) {
    if (value is Map<String, dynamic>) {
      return Designer.fromJson(value);
    }

    if (value is Map) {
      return Designer.fromJson(Map<String, dynamic>.from(value));
    }

    return const Designer(
      uid: '',
      name: '',
      location: '',
      mobileNumber: '',
      tags: '',
      businessName: '',
      profileImage: '',
    );
  }

  MyMeasurement copyWith({
    String? uid,
    Designer? designer,
    List<ClientMeasurement>? measurements,
    bool? isDefault,
  }) => MyMeasurement(
    uid: uid ?? this.uid,
    designer: designer ?? this.designer,
    measurements: measurements ?? this.measurements,
    isDefault: isDefault ?? this.isDefault,
  );

  /// Empty constructor for initial state
  factory MyMeasurement.empty() {
    return const MyMeasurement(
      uid: '',
      designer: Designer(
        uid: '',
        name: '',
        location: '',
        mobileNumber: '',
        tags: '',
        businessName: '',
        profileImage: '',
      ),
      measurements: [],
      isDefault: false,
    );
  }

  @override
  List<Object?> get props => [uid, designer, measurements, isDefault];
}
