/// Helpers for the `yyyy-MM-dd` designer-local date keys used as Firestore
/// document ids and on booking documents.
class DateKey {
  DateKey._();

  static String fromDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  /// Returns `null` when [value] is not a valid `yyyy-MM-dd` date.
  static DateTime? tryParse(String? value) {
    if (value == null) return null;
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final year = int.parse(match.group(1)!);
    final month = int.parse(match.group(2)!);
    final day = int.parse(match.group(3)!);
    final parsed = DateTime(year, month, day);
    if (parsed.year != year || parsed.month != month || parsed.day != day) {
      return null;
    }
    return parsed;
  }

  static DateTime parse(String value) {
    final parsed = tryParse(value);
    if (parsed == null) {
      throw FormatException('Invalid yyyy-MM-dd date', value);
    }
    return parsed;
  }

  /// `yyyyMMdd`, used inside reservation ids.
  static String compact(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }
}
