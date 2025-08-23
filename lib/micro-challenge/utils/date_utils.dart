bool isMonday() {
  final now = DateTime.now();
  return now.weekday == DateTime.monday;
}

DateTime getStartOfWeek() {
  final now = DateTime.now();
  return now.subtract(Duration(days: now.weekday - 1));
}
