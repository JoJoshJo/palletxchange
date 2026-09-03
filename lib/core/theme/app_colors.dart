import 'package:flutter/material.dart';

/// Brand color tokens for PalletXchange (BRAIN §11).
/// Hybrid theme: light content surfaces, navy chrome, orange as the single
/// primary action, green for positive/verified.
abstract final class AppColors {
  static const Color orange = Color(0xFFE97B35);
  static const Color orangeBright = Color(0xFFEE7D49);
  static const Color navy = Color(0xFF101729);
  static const Color navyCard = Color(0xFF1A2233);
  static const Color green = Color(0xFF3C9066);
  static const Color teal = Color(0xFF3C807A);

  static const Color bg = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF9FAFC);
  static const Color border = Color(0xFFE2E8F0);

  static const Color textPrimary = Color(0xFF101729);
  static const Color textMuted = Color(0xFF686D79);

  static const Color onDark = Color(0xFFFFFFFF);
  static const Color onDarkMuted = Color(0xFF94A3B8);

  static const Color slate = Color(0xFF222838);
}
