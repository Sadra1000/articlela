import 'package:flutter/material.dart';

enum GradientPreset {
  onboarding,
  home,
  keyword,
  results,
  about,
  settings,
  reader,
}

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF3A86FF);
  static const Color secondary = Color(0xFF9D4EDD);
  static const Color success = Color(0xFF2EC4B6);
  static const Color warning = Color(0xFFFFB703);
  static const Color error = Color(0xFFE63946);
  static const Color scaffoldDark = Color(0xFF101820);
  static const Color scaffoldLight = Color(0xFFF5F7FA);
  static const Color textPrimaryDark = Colors.white;
  static const Color textPrimaryLight = Color(0xFF101820);

  static Gradient gradient(GradientPreset preset) {
    switch (preset) {
      case GradientPreset.onboarding:
        return const LinearGradient(
          colors: [Color(0xFF3A86FF), Color(0xFF8338EC)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case GradientPreset.home:
        return const LinearGradient(
          colors: [Color(0xFF219EBC), Color(0xFF024730)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
      case GradientPreset.keyword:
        return const LinearGradient(
          colors: [Color.fromARGB(255, 9, 153, 21), Color(0xFF3A86FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case GradientPreset.results:
        return const LinearGradient(
          colors: [Color(0xFF457B9D), Color(0xFF1D3557)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case GradientPreset.about:
        return const LinearGradient(
          colors: [Color(0xFFff6f91), Color(0xFFff9671)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case GradientPreset.settings:
        return const LinearGradient(
          colors: [Color(0xFF06D6A0), Color(0xFF118AB2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case GradientPreset.reader:
        return const LinearGradient(
          colors: [Color(0xFF0C2340), Color(0xFF3A86FF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        );
    }
  }
}
