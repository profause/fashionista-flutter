import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User extends Equatable {
  @JsonKey(name: 'full_name')
  final String fullName;

  @JsonKey(name: 'user_name')
  final String userName;

  @JsonKey(name: 'profile_image')
  final String profileImage;

  @JsonKey(name: 'banner_image')
  final String? bannerImage;

  @JsonKey(name: 'account_type')
  final String accountType;

  final String gender;

  @JsonKey(name: 'mobile_number')
  final String mobileNumber;

  final String email;
  final String location;

  @JsonKey(name: 'date_of_birth')
  final DateTime? dateOfBirth;

  @JsonKey(name: 'joined_date')
  final DateTime? joinedDate;

  final String? uid;

  const User({
    required this.fullName,
    required this.userName,
    required this.profileImage,
    required this.accountType,
    required this.gender,
    required this.mobileNumber,
    required this.email,
    required this.location,
    this.dateOfBirth,
    this.joinedDate,
    this.uid,
    this.bannerImage
  });

  /// Empty constructor for initial state
  factory User.empty() {
    return const User(
      fullName: '',
      userName: '',
      profileImage: '',
      accountType: '',
      gender: '',
      mobileNumber: '',
      email: '',
      location: '',
      dateOfBirth: null,
      uid: '',
      joinedDate: null,
      bannerImage: ''
    );
  }

  /// JSON serialization
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  /// CopyWith method
  User copyWith({
    String? fullName,
    String? userName,
    String? profileImage,
    String? accountType,
    String? gender,
    String? mobileNumber,
    String? email,
    String? location,
    DateTime? dateOfBirth,
    String? uid,
    DateTime? joinedDate,
    String? bannerImage,
  }) {
    return User(
      fullName: fullName ?? this.fullName,
      userName: userName ?? this.userName,
      profileImage: profileImage ?? this.profileImage,
      accountType: accountType ?? this.accountType,
      gender: gender ?? this.gender,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      email: email ?? this.email,
      location: location ?? this.location,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      uid: uid ?? this.uid,
      joinedDate: joinedDate ?? this.joinedDate
      ,bannerImage: bannerImage ?? this.bannerImage
    );
  }

  @override
  List<Object?> get props => [
        fullName,
        userName,
        profileImage,
        accountType,
        gender,
        mobileNumber,
        email,
        location,
        dateOfBirth,
        uid,
        joinedDate,
        bannerImage,
      ];
}
