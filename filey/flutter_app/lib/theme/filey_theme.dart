import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────
//  Filey colour palette  –  dark industrial, amber accent
// ─────────────────────────────────────────────────────────────────
class FileyColors {
  FileyColors._();

  // Backgrounds
  static const bg0 = Color(0xFF0D0D0F); // deepest bg
  static const bg1 = Color(0xFF141416); // panel bg
  static const bg2 = Color(0xFF1C1C20); // card / input bg
  static const bg3 = Color(0xFF252529); // hover / selected

  // Borders
  static const border  = Color(0xFF2E2E34);
  static const borderL = Color(0xFF3E3E46);

  // Text
  static const textPrimary   = Color(0xFFEEEEF0);
  static const textSecondary = Color(0xFF8A8A96);
  static const textMuted     = Color(0xFF55555E);

  // Accent – amber / ochre
  static const accent     = Color(0xFFF5A623);
  static const accentDim  = Color(0xFF9B6714);
  static const accentGlow = Color(0x33F5A623);

  // Semantic
  static const success = Color(0xFF4CAF72);
  static const danger  = Color(0xFFE05252);
  static const info    = Color(0xFF4A9EFF);

  // Node palette (auto-assigned round-robin when colorTag == 0)
  static const nodePalette = [
    Color(0xFFF5A623), // amber
    Color(0xFF4A9EFF), // blue
    Color(0xFF4CAF72), // green
    Color(0xFFB06EF0), // violet
    Color(0xFFE05252), // red
    Color(0xFF26C6DA), // cyan
  ];

  static Color nodeColor(int index) =>
      nodePalette[index % nodePalette.length];
}

// ─────────────────────────────────────────────────────────────────
//  FileyTheme
// ─────────────────────────────────────────────────────────────────
class FileyTheme {
  FileyTheme._();

  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: FileyColors.bg0,
      colorScheme: const ColorScheme.dark(
        surface:   FileyColors.bg1,
        primary:   FileyColors.accent,
        secondary: FileyColors.accentDim,
        error:     FileyColors.danger,
        onSurface: FileyColors.textPrimary,
        onPrimary: FileyColors.bg0,
      ),
      textTheme: GoogleFonts.ibmPlexMonoTextTheme(base.textTheme).copyWith(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 32, fontWeight: FontWeight.w700, color: FileyColors.textPrimary,
          letterSpacing: -1,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 24, fontWeight: FontWeight.w600, color: FileyColors.textPrimary,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 16, fontWeight: FontWeight.w600, color: FileyColors.textPrimary,
          letterSpacing: 0.2,
        ),
        titleMedium: GoogleFonts.ibmPlexMono(
          fontSize: 13, fontWeight: FontWeight.w500, color: FileyColors.textSecondary,
        ),
        bodyMedium: GoogleFonts.ibmPlexMono(
          fontSize: 13, color: FileyColors.textPrimary,
        ),
        bodySmall: GoogleFonts.ibmPlexMono(
          fontSize: 11, color: FileyColors.textSecondary,
        ),
        labelSmall: GoogleFonts.ibmPlexMono(
          fontSize: 10, letterSpacing: 1.2, color: FileyColors.textMuted,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: FileyColors.border, thickness: 1, space: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: FileyColors.bg2,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: FileyColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: FileyColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: FileyColors.accent, width: 1.5),
        ),
        hintStyle: const TextStyle(color: FileyColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: FileyColors.accent,
          foregroundColor: FileyColors.bg0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: GoogleFonts.ibmPlexMono(
            fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.4,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: FileyColors.accent,
          textStyle: GoogleFonts.ibmPlexMono(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: FileyColors.bg3,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: FileyColors.border),
        ),
        textStyle: GoogleFonts.ibmPlexMono(
          fontSize: 11, color: FileyColors.textSecondary,
        ),
      ),
    );
  }
}
