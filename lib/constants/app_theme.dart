import 'package:flutter/material.dart';
import 'app_colors.dart';

/// App-wide ThemeData, built from AppColors so the palette stays in one
/// place. Import this into main.dart instead of building theme inline.
class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.light,
    ),
  );

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.seed,
      brightness: Brightness.dark,
    ),
  );
}
