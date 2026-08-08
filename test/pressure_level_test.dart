import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_budget/features/transactions/presentation/models/pressure_level.dart';

void main() {
  test('pressure levels map budget ratios to five stable bands', () {
    expect(PressureLevelDetails.fromRatio(0), PressureLevel.veryLow);
    expect(PressureLevelDetails.fromRatio(0.25), PressureLevel.low);
    expect(PressureLevelDetails.fromRatio(0.5), PressureLevel.medium);
    expect(PressureLevelDetails.fromRatio(0.75), PressureLevel.high);
    expect(PressureLevelDetails.fromRatio(1), PressureLevel.high);
    expect(PressureLevelDetails.fromRatio(1.01), PressureLevel.veryHigh);
  });

  test('each pressure level exposes the matching legend label and color', () {
    expect(PressureLevelDetails.values.map((level) => level.label), ['很低', '偏低', '适中', '偏高', '过高']);
    expect(PressureLevelDetails.values.map((level) => level.color.toARGB32()), hasLength(5));
  });
}