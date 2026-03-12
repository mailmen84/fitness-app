String formatApiDate(DateTime date) {
  final normalizedDate = DateTime(date.year, date.month, date.day);
  final month = normalizedDate.month.toString().padLeft(2, '0');
  final day = normalizedDate.day.toString().padLeft(2, '0');
  return '${normalizedDate.year}-$month-$day';
}

String formatApiDateTime(DateTime dateTime) {
  return dateTime.toUtc().toIso8601String();
}
