/// A local calendar date, without a time or a UTC conversion.
DateTime calendarDate(DateTime value) =>
    DateTime(value.year, value.month, value.day);

DateTime? parseCalendarDate(String value, {required bool iso}) {
  final match =
      (iso
              ? RegExp(r'^(\d{4})-(\d{2})-(\d{2})$')
              : RegExp(r'^(\d{2})/(\d{2})/(\d{4})$'))
          .firstMatch(value.trim());
  if (match == null) return null;
  final year = int.parse(match.group(iso ? 1 : 3)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(iso ? 3 : 1)!);
  if (year < 1 || year > 9999 || month < 1 || month > 12 || day < 1) {
    return null;
  }
  final date = DateTime(year, month, day);
  // DateTime normalizes invalid dates, so verify every component explicitly.
  return date.year == year && date.month == month && date.day == day
      ? date
      : null;
}

String formatCalendarDate(DateTime value, {required bool iso}) {
  final year = value.year.toString().padLeft(4, '0');
  final month = value.month.toString().padLeft(2, '0');
  final day = value.day.toString().padLeft(2, '0');
  return iso ? '$year-$month-$day' : '$day/$month/$year';
}

int ageOn(DateTime birthDate, DateTime today) {
  final birthdayNotReached =
      today.month < birthDate.month ||
      (today.month == birthDate.month && today.day < birthDate.day);
  return today.year - birthDate.year - (birthdayNotReached ? 1 : 0);
}
