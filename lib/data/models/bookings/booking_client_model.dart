import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'booking_client_model.g.dart';

/// Snapshot of the client who requested an appointment.
///
/// Denormalised onto the booking so the designer's appointment list can render
/// the client's name, avatar and phone number without extra reads, and so the
/// card keeps working if the client record is later renamed or removed.
@JsonSerializable(explicitToJson: true)
class BookingClient extends Equatable {
  /// The designer-scoped client record id.
  @JsonKey(name: 'id', defaultValue: '')
  final String id;

  @JsonKey(name: 'name', defaultValue: '')
  final String name;

  /// Profile image URL. Empty when the client has no picture.
  @JsonKey(name: 'avatar')
  final String? avatar;

  @JsonKey(name: 'mobile_number', defaultValue: '')
  final String mobileNumber;

  const BookingClient({
    this.id = '',
    this.name = '',
    this.avatar,
    this.mobileNumber = '',
  });

  factory BookingClient.fromJson(Map<String, dynamic> json) =>
      _$BookingClientFromJson(json);

  Map<String, dynamic> toJson() => _$BookingClientToJson(this);

  bool get hasAvatar => (avatar ?? '').trim().isNotEmpty;

  /// Best available label for the card.
  String get displayName =>
      name.trim().isNotEmpty ? name.trim() : 'Client';

  BookingClient copyWith({
    String? id,
    String? name,
    String? avatar,
    String? mobileNumber,
  }) {
    return BookingClient(
      id: id ?? this.id,
      name: name ?? this.name,
      avatar: avatar ?? this.avatar,
      mobileNumber: mobileNumber ?? this.mobileNumber,
    );
  }

  @override
  List<Object?> get props => [id, name, avatar, mobileNumber];
}
