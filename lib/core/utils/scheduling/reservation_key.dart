/// Builds the deterministic Firestore document id that locks one slot.
///
/// The same designer + date + start time must always produce the same id so a
/// transaction conflict (not a query) is what prevents double booking.
class ReservationKey {
  ReservationKey._();

  /// `designerId_yyyyMMdd_HHmm`, e.g. `designer123_20261116_0830`.
  static String forSlot({
    required String designerId,
    required String date,
    required String startTime,
  }) {
    final safeDesignerId = designerId.trim().replaceAll('/', '_');
    final compactDate = date.replaceAll(RegExp(r'[^0-9]'), '');
    final compactTime = startTime.replaceAll(RegExp(r'[^0-9]'), '');
    return '${safeDesignerId}_${compactDate}_$compactTime';
  }

  /// `HHmm` form of an `HH:mm` time, used when deriving firestore paths.
  static String compactTime(String startTime) {
    return startTime.replaceAll(RegExp(r'[^0-9]'), '');
  }
}
