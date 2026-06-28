import 'package:flutter/material.dart';

/// Aurelia royal-minimal palette.
/// Deep ink + parchment surfaces + restrained royal blue accent.
class AureliaColors {
  static const ink = Color(0xFF0B1220);
  static const inkSoft = Color(0xFF2A3245);
  static const muted = Color(0xFF6B7280);
  static const parchment = Color(0xFFF7F5EF);
  static const surface = Color(0xFFFFFFFF);
  static const hairline = Color(0xFFE6E2D6);
  static const royal = Color(0xFF1E3A8A);
  static const royalSoft = Color(0xFF3B5BDB);
  static const danger = Color(0xFFB91C1C);
  static const success = Color(0xFF15803D);
}

class AureliaTheme {
  static const _serif = 'serif';
  static const _sans = 'sans';

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = base.textTheme.copyWith(
      displayLarge: const TextStyle(
        fontFamily: _serif,
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: AureliaColors.ink,
      ),
      headlineMedium: const TextStyle(
        fontFamily: _serif,
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: AureliaColors.ink,
      ),
      titleLarge: const TextStyle(
        fontFamily: _sans,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AureliaColors.ink,
      ),
      bodyLarge: const TextStyle(
        fontFamily: _sans,
        fontSize: 15,
        color: AureliaColors.ink,
      ),
      bodyMedium: const TextStyle(
        fontFamily: _sans,
        fontSize: 14,
        color: AureliaColors.inkSoft,
      ),
      labelLarge: const TextStyle(
        fontFamily: _sans,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );

    return base.copyWith(
      scaffoldBackgroundColor: AureliaColors.parchment,
      colorScheme: const ColorScheme.light(
        primary: AureliaColors.royal,
        onPrimary: Colors.white,
        secondary: AureliaColors.royalSoft,
        surface: AureliaColors.surface,
        onSurface: AureliaColors.ink,
        error: AureliaColors.danger,
      ),
      textTheme: textTheme,
      appBarTheme: const AppBarTheme(
        backgroundColor: AureliaColors.parchment,
        foregroundColor: AureliaColors.ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _serif,
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AureliaColors.ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: AureliaColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AureliaColors.hairline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AureliaColors.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AureliaColors.hairline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AureliaColors.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AureliaColors.royal, width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AureliaColors.ink,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: _sans,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AureliaColors.hairline,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AureliaColors.surface,
        indicatorColor: AureliaColors.royal.withValues(alpha: 0.08),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(
            fontFamily: _sans,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  static ThemeData dark() => light();
}
