String moreErrorMessage(Object error) {
  final message = error.toString().trim();
  return message.startsWith('Exception: ')
      ? message.substring('Exception: '.length)
      : message;
}

String formatMoreNumber(double amount) {
  if (amount.truncateToDouble() == amount) {
    return amount.toStringAsFixed(0);
  }

  return amount
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '');
}

const _monthNames = <String>[
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String formatMoreLongDate(DateTime date) {
  final localDate = date.toLocal();
  return '${_monthNames[localDate.month - 1]} '
      '${localDate.day}, '
      '${localDate.year}';
}

String formatMoreOptionalDate(DateTime? date, {String fallback = 'Not set'}) {
  if (date == null) {
    return fallback;
  }
  return formatMoreLongDate(date);
}
