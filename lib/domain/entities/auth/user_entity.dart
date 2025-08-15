class UserEntity {
  String? uid;
  String? fullName;
  String? email;
  String? userName;
  String? profileImage;
  String? accountType;
  String? gender;
  String? mobileNumber;
  String? location;
  DateTime? dateOfBirth;
  UserEntity({
    this.uid,
    this.fullName,
    this.email,
    this.userName,
    this.profileImage,
    this.accountType,
    this.gender,
    required this.mobileNumber,
    this.location,
    this.dateOfBirth,
  });
}
