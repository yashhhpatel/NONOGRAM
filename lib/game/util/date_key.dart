/// Date helpers using a stable `yyyy-MM-dd` key, independent of locale.
class DateKey {
  const DateKey._();

  static String of(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static String today() => of(DateTime.now());

  static String yesterday() =>
      of(DateTime.now().subtract(const Duration(days: 1)));

  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
