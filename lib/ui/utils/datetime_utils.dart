class DatetimeUtils {
  static bool isValidDate(int year, int month, int day) {
    try {
      final date = DateTime(year, month, day);
      // DateTime은 유효하지 않은 날짜를 자동으로 보정하므로, 비교 필요
      return date.year == year && date.month == month && date.day == day;
    } catch (e) {
      return false;
    }
  }
}
