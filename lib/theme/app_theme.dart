import 'package:flutter/material.dart';

class AppTheme {
  static const _blue = Color(0xFF1A365D);
  static const _blueGrey = Color(0xFF34495E);

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue).copyWith(
      primary: Colors.blue,
      secondary: Colors.cyan,
    ),
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: _blue,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: _blue, fontSize: 15, fontWeight: FontWeight.w600),
    ),
    textTheme: const TextTheme(
      bodySmall: TextStyle(fontSize: 12, color: _blueGrey),
      bodyMedium: TextStyle(fontSize: 13, color: _blueGrey),
      titleMedium: TextStyle(fontSize: 15, color: _blueGrey, fontWeight: FontWeight.w500),
      titleLarge: TextStyle(fontSize: 17, color: _blueGrey, fontWeight: FontWeight.w600),
    ),
  );

  static final ThemeData dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue, brightness: Brightness.dark).copyWith(
      primary: Colors.blue,
      secondary: Colors.cyan,
    ),
    scaffoldBackgroundColor: const Color(0xFF0B1220),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF0B1220),
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600),
    ),
    textTheme: const TextTheme(
      bodySmall: TextStyle(fontSize: 12, color: Colors.white70),
      bodyMedium: TextStyle(fontSize: 13, color: Colors.white70),
      titleMedium: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500),
      titleLarge: TextStyle(fontSize: 17, color: Colors.white, fontWeight: FontWeight.w600),
    ),
  );
}
