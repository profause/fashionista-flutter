import 'package:equatable/equatable.dart';
import 'package:fashionista/core/utils/firestore_timestamp_converter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'slot_reservation_model.g.dart';

enum SlotReservationStatus { reserved, released }

/// The lock that keeps two clients from booking the same slot.
///
/// Stored at `slot_reservations/{designerId}_{yyyyMMdd}_{HHmm}` so the
/// document id itself encodes the slot. `user_id` is denormalised so Firestore
/// rules can validate ownership without an extra read.
@JsonSerializable(explicitToJson: true)
class SlotReservation extends Equatable {
  @JsonKey(name: 'designer_id', defaultValue: '')
  final String designerId;

  @JsonKey(name: 'user_id', defaultValue: '')
  final String userId;

  @JsonKey(name: 'booking_id', defaultValue: '')
  final String bookingId;

  @FirestoreTimestampConverter()
  @JsonKey(name: 'start_at')
  final DateTime? startAt;

  @FirestoreTimestampConverter()
  @JsonKey(name: 'end_at')
  final DateTime? endAt;

  @JsonKey(name: 'status', defaultValue: SlotReservationStatus.reserved)
  final SlotReservationStatus status;

  @FirestoreTimestampConverter()
  @JsonKey(name: 'expires_at')
  final DateTime? expiresAt;

  @FirestoreTimestampConverter()
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;

  const SlotReservation({
    required this.designerId,
    this.userId = '',
    this.bookingId = '',
    this.startAt,
    this.endAt,
    this.status = SlotReservationStatus.reserved,
    this.expiresAt,
    this.createdAt,
  });

  factory SlotReservation.fromJson(Map<String, dynamic> json) =>
      _$SlotReservationFromJson(json);

  Map<String, dynamic> toJson() => _$SlotReservationToJson(this);

  bool get isReserved => status == SlotReservationStatus.reserved;

  /// A reservation is reclaimable once it has been released or has expired.
  ///
  /// Expired documents are never deleted by the app; they are simply ignored.
  bool isActiveAt(DateTime now) {
    if (!isReserved) return false;
    final expiry = expiresAt;
    return expiry == null || expiry.isAfter(now);
  }

  SlotReservation copyWith({
    String? designerId,
    String? userId,
    String? bookingId,
    DateTime? startAt,
    DateTime? endAt,
    SlotReservationStatus? status,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return SlotReservation(
      designerId: designerId ?? this.designerId,
      userId: userId ?? this.userId,
      bookingId: bookingId ?? this.bookingId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      status: status ?? this.status,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
    designerId,
    userId,
    bookingId,
    startAt,
    endAt,
    status,
    expiresAt,
    createdAt,
  ];
}
