import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../l10n/app_localizations.dart';

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

  String localizedLabel(AppLocalizations l10n) {
    switch (this) {
      case PressureLevel.veryLow:
        return l10n.pressureVeryLow;
      case PressureLevel.low:
        return l10n.pressureLow;
      case PressureLevel.medium:
        return l10n.pressureMedium;
      case PressureLevel.high:
        return l10n.pressureHigh;
      case PressureLevel.veryHigh:
        return l10n.pressureVeryHigh;
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
