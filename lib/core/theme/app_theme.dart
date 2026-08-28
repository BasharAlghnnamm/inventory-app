import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Blue-based light and dark themes with a Cairo font family.
class AppTheme {
  AppTheme._();

  static const Color _blue = Color(0xFF1E88E5);

  static const String fontFamily = 'Cairo';

  static ThemeData light() => _build(
        brightness: Brightness.light,
        scheme: ColorScheme.fromSeed(
          seedColor: _blue,
          brightness: Brightness.light,
        ),
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        scheme: ColorScheme.fromSeed(
          seedColor: _blue,
          brightness: Brightness.dark,
        ),
      );

  static ThemeData _build({
    required Brightness brightness,
    required ColorScheme scheme,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: scheme.surface,
        elevation: 0,
        systemOverlayStyle: brightness == Brightness.light
            ? SystemUiOverlayStyle.dark
            : SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        isDense: true,
      ),
    );
  }
}
