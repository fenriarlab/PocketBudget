import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

enum PressureLevel { veryLow, low, medium, high, veryHigh }

extension PressureLevelDetails on PressureLevel {
  String get label {
    switch (this) {
      case PressureLevel.veryLow:
        return '很低';
      case PressureLevel.low:
        return '偏低';
      case PressureLevel.medium:
        return '适中';
      case PressureLevel.high:
        return '偏高';
      case PressureLevel.veryHigh:
        return '过高';
    }
  }

  Color get color {
    switch (this) {
      case PressureLevel.veryLow:
        return AppColors.pressureVeryLow;
      case PressureLevel.low:
        return AppColors.pressureLow;
      case PressureLevel.medium:
        return AppColors.pressureMedium;
      case PressureLevel.high:
        return AppColors.pressureHigh;
      case PressureLevel.veryHigh:
        return AppColors.pressureVeryHigh;
    }
  }

  static const values = PressureLevel.values;

  static PressureLevel fromRatio(double ratio) {
    if (ratio < 0.25) return PressureLevel.veryLow;
    if (ratio < 0.5) return PressureLevel.low;
    if (ratio < 0.75) return PressureLevel.medium;
    if (ratio <= 1) return PressureLevel.high;
    return PressureLevel.veryHigh;
  }
}