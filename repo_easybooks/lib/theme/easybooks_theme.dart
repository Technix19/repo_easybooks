import 'package:flutter/material.dart';

/// A shared visual foundation for EasyBooks' bookkeeping workspace.
class EasyBooksTheme {
  static const background = Color(0xFF111719);
  static const sidebar = Color(0xFF151E20);
  static const surface = Color(0xFF1C2729);
  static const elevatedSurface = Color(0xFF233033);
  static const border = Color(0xFF334044);
  static const accent = Color(0xFF02D39A);
  static const text = Color(0xFFF0F5F3);
  static const muted = Color(0xFFA6B7B4);
  static const error = Color(0xFFFF827F);

  static ThemeData get data => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: background,
        colorScheme: const ColorScheme.dark(
          primary: accent,
          onPrimary: background,
          secondary: accent,
          surface: surface,
          onSurface: text,
          error: error,
        ),
        dividerColor: border,
        appBarTheme: const AppBarTheme(
          backgroundColor: background,
          foregroundColor: text,
          elevation: 0,
          centerTitle: false,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: background,
          labelStyle: const TextStyle(color: muted),
          floatingLabelStyle: const TextStyle(color: accent),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: accent, width: 1.5),
          ),
        ),
      );
}
