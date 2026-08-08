class MonthPeriod {
  final int year;
  final int month;

  MonthPeriod(this.year, this.month) : assert(month >= 1 && month <= 12);

  factory MonthPeriod.fromDate(DateTime date) => MonthPeriod(date.year, date.month);

  factory MonthPeriod.parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})$').firstMatch(value);
    if (match == null) throw FormatException('Invalid month period: $value');
    return MonthPeriod(int.parse(match.group(1)!), int.parse(match.group(2)!));
  }

  String get key => '$year-${month.toString().padLeft(2, '0')}';

  DateTime get start => DateTime(year, month);

  DateTime get end => DateTime(year, month + 1);

  int get daysInMonth => end.difference(start).inDays;

  bool contains(DateTime date) => !date.isBefore(start) && date.isBefore(end);

  bool get isCurrent {
    final now = DateTime.now();
    return year == now.year && month == now.month;
  }

  bool get isPast => end.isBefore(DateTime(DateTime.now().year, DateTime.now().month));

  bool get isFuture => start.isAfter(DateTime(DateTime.now().year, DateTime.now().month));

  @override
  bool operator ==(Object other) => other is MonthPeriod && other.year == year && other.month == month;

  @override
  int get hashCode => Object.hash(year, month);

  @override
  String toString() => key;
}