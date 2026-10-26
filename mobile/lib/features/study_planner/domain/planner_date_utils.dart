/// Date helpers ensuring weeks start on Monday and dates use device-local YYYY-MM-DD.
class PlannerDateUtils {
  PlannerDateUtils._();

  /// Returns the Monday of the given date's week with time stripped (midnight local).
  static DateTime getMondayOfWeek(DateTime date) {
    final localDate = DateTime(date.year, date.month, date.day);
    final daysToSubtract = (localDate.weekday - DateTime.monday) % 7;
    return localDate.subtract(Duration(days: daysToSubtract));
  }

  /// Formats a DateTime as device-local YYYY-MM-DD.
  static String formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Parses a YYYY-MM-DD string into a device-local midnight DateTime.
  static DateTime parseDate(String yyyyMmDd) {
    final parts = yyyyMmDd.split('-');
    if (parts.length != 3) {
      throw FormatException(
          'Invalid date format (expected YYYY-MM-DD): $yyyyMmDd');
    }
    final year = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final day = int.parse(parts[2]);
    return DateTime(year, month, day);
  }
}
