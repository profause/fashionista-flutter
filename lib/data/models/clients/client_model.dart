import 'package:equatable/equatable.dart';
import 'package:fashionista/core/models/hive/client_model_hive_type.dart';
import 'package:fashionista/data/models/clients/client_measurement_model.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:fashionista/core/models/hive/hive_type.dart' as hive;
import 'package:hive/hive.dart';

part 'client_model.g.dart';

@JsonSerializable(explicitToJson: true)
@HiveType(typeId: hive.HiveType.clientType)
class Client extends Equatable {
  @HiveField(ClientModelHiveType.uid)
  final String uid;

  @HiveField(ClientModelHiveType.createdBy)
  @JsonKey(name: 'created_by')
  final String createdBy;

  @JsonKey(name: 'full_name')
  @HiveField(ClientModelHiveType.fullName)
  final String fullName;

  @JsonKey(name: 'mobile_number')
  @HiveField(ClientModelHiveType.mobileNumber)
  final String mobileNumber;

  @JsonKey(name: 'image_url')
  @HiveField(ClientModelHiveType.imageUrl)
  final String? imageUrl;

  @HiveField(ClientModelHiveType.gender)
  final String gender;

  @JsonKey(name: 'created_date')
  @HiveField(ClientModelHiveType.createdDate)
  final DateTime? createdDate;

  @HiveField(ClientModelHiveType.measurements)
  final List<ClientMeasurement> measurements;

  const Client({
    required this.uid,
    required this.createdBy,
    required this.fullName,
    required this.mobileNumber,
    this.imageUrl,
    required this.gender,
    required this.createdDate,
    required this.measurements,
  });

  factory Client.fromJson(Map<String, dynamic> json) => _$ClientFromJson(json);

  Map<String, dynamic> toJson() => _$ClientToJson(this);

  // static DateTime _fromTimestamp(dynamic ts) {
  //   if (ts is Timestamp) return ts.toDate();
  //   if (ts is DateTime) return ts;
  //   throw ArgumentError('Invalid timestamp value: $ts');
  // }

  //static Timestamp _toTimestamp(DateTime date) => Timestamp.fromDate(date);

  Client copyWith({
    String? uid,
    String? createdBy,
    String? fullName,
    String? mobileNumber,
    String? imageUrl,
    String? gender,
    DateTime? createdDate,
    List<ClientMeasurement>? measurements,
  }) {
    return Client(
      uid: uid ?? this.uid,
      createdBy: createdBy ?? this.createdBy,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      imageUrl: imageUrl ?? this.imageUrl,
      gender: gender ?? this.gender,
      createdDate: createdDate ?? this.createdDate,
      measurements: measurements ?? this.measurements,
    );
  }

  /// Empty constructor for initial state
  factory Client.empty() {
    return const Client(
      uid: '',
      createdBy: '',
      fullName: '',
      mobileNumber: '',
      gender: '',
      createdDate: null,
      measurements: [],
    );
  }

  @override
  List<Object?> get props => [
    uid,
    createdBy,
    fullName,
    mobileNumber,
    imageUrl,
    gender,
    createdDate,
    measurements,
  ];
}
