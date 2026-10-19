import 'package:flutter/material.dart';

// Foundit uses three colour families only:
//   Teal  = found and trusted (brand, main buttons, Found, Matched, Approved)
//   Amber = lost and needs attention (Lost, warnings, Pending)
//   Ink   = structure and text (all text, borders, greys as tints of ink)
const _teal = Color(0xFF0A6B66);
const _tealTint = Color(0xFFE2F3F1);
const _amber = Color(0xFF8F4A03);
const _amberTint = Color(0xFFFDF1D9);
const _ink = Color(0xFF142030);

Color _inkTint(double alpha) =>
    Color.alphaBlend(_ink.withValues(alpha: alpha), Colors.white);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;

  final ColorScheme cs = dark
      ? const ColorScheme(
          brightness: Brightness.dark,
          primary: Color(0xFF3CC2B9),
          onPrimary: Color(0xFF06201E),
          primaryContainer: Color(0xFF0F3330),
          onPrimaryContainer: Color(0xFFE8EDF2),
          secondary: Color(0xFFF0B35C),
          onSecondary: Color(0xFF2A1A00),
          secondaryContainer: Color(0xFF3A2A0C),
          onSecondaryContainer: Color(0xFFE8EDF2),
          error: Color(0xFFE8EDF2),
          onError: Color(0xFF151C25),
          surface: Color(0xFF151C25),
          onSurface: Color(0xFFE8EDF2),
          onSurfaceVariant: Color(0xFF9AA7B5),
          surfaceContainerHighest: Color(0xFF1B2430),
          outline: Color(0xFF263241),
          outlineVariant: Color(0xFF263241),
        )
      : ColorScheme(
          brightness: Brightness.light,
          primary: _teal,
          onPrimary: Colors.white,
          primaryContainer: _tealTint,
          onPrimaryContainer: _ink,
          secondary: _amber,
          onSecondary: Colors.white,
          secondaryContainer: _amberTint,
          onSecondaryContainer: _ink,
          error: _ink,
          onError: Colors.white,
          surface: Colors.white,
          onSurface: _ink,
          onSurfaceVariant: _inkTint(0.70),
          surfaceContainerHighest: _inkTint(0.05),
          outline: _inkTint(0.18),
          outlineVariant: _inkTint(0.14),
        );

  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  return ThemeData(
    useMaterial3: true,
    colorScheme: cs,
    scaffoldBackgroundColor: cs.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: cs.surface,
      foregroundColor: cs.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w700,
        color: cs.onSurface,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: shape,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: shape,
        side: BorderSide(color: cs.outline),
        foregroundColor: cs.onSurface,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: cs.outline),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: cs.surface,
      indicatorColor: cs.primaryContainer,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? cs.primaryContainer : null,
        ),
        foregroundColor: WidgetStatePropertyAll(cs.onSurface),
      ),
    ),
    dividerTheme: DividerThemeData(color: cs.outlineVariant),
  );
}
