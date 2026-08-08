import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_budget/core/utils/month_period.dart';

void main() {
  test('formats and parses month periods with calendar boundaries', () {
    final period = MonthPeriod.parse('2026-02');

    expect(period.key, '2026-02');
    expect(period.start, DateTime(2026, 2, 1));
    expect(period.end, DateTime(2026, 3, 1));
    expect(period.daysInMonth, 28);
    expect(period.contains(DateTime(2026, 2, 28)), isTrue);
    expect(period.contains(DateTime(2026, 3, 1)), isFalse);
  });

  test('handles leap years and year rollover', () {
    expect(MonthPeriod(2024, 2).daysInMonth, 29);
    expect(MonthPeriod(2026, 12).end, DateTime(2027, 1, 1));
  });

  test('rejects malformed periods', () {
    expect(() => MonthPeriod.parse('2026/08'), throwsFormatException);
    expect(() => MonthPeriod.parse('2026-13'), throwsA(isA<AssertionError>()));
  });
}