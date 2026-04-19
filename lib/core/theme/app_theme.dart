// Mnemata — Theme data
// Copia este archivo a: lib/core/theme/app_theme.dart
// Requiere en pubspec.yaml:
//   google_fonts: ^6.2.1

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MnemataColors {
  // ── Claro ───────────────────────────────────────────────────
  static const paper    = Color(0xFFFBF9F4);
  static const paper2   = Color(0xFFF3EFE8);
  static const paper3   = Color(0xFFEAE5DB);
  static const ink      = Color(0xFF241F17);
  static const ink2     = Color(0xFF514A3F);
  static const ink3     = Color(0xFF8A8273);
  static const ink4     = Color(0xFFBDB5A3);
  static const rule     = Color(0xFFDDD6C6);

  static const accent     = Color(0xFFD18648);
  static const accentInk  = Color(0xFF7A4818);
  static const accentSoft = Color(0xFFF3E5CC);

  static const danger  = Color(0xFFB43828);
  static const success = Color(0xFF4A7E4A);

  // Tag palette
  static const tag1 = Color(0xFFB07445);
  static const tag2 = Color(0xFF568F8E);
  static const tag3 = Color(0xFF7A80B8);
  static const tag4 = Color(0xFFB36F8A);
  static const tag5 = Color(0xFF7D9361);
  static const tag6 = Color(0xFF7D6D5C);

  // ── Oscuro ──────────────────────────────────────────────────
  static const paperDark    = Color(0xFF201E1A);
  static const paper2Dark   = Color(0xFF2A2824);
  static const paper3Dark   = Color(0xFF35322D);
  static const inkDark      = Color(0xFFF3F0EB);
  static const ink2Dark     = Color(0xFFC9C3B8);
  static const ink3Dark     = Color(0xFF958F83);
  static const ink4Dark     = Color(0xFF605B51);
  static const ruleDark     = Color(0xFF3F3C37);
  static const accentDark     = Color(0xFFE3A870);
  static const accentInkDark  = Color(0xFFE8B680);
  static const accentSoftDark = Color(0xFF453625);
}

class MnemataRadii {
  static const sm = 6.0;
  static const md = 10.0;
  static const lg = 14.0;
  static const xl = 22.0;
  static const full = 999.0;
}

class MnemataShadows {
  static const sh1 = [
    BoxShadow(color: Color(0x0A1E190F), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const sh2 = [
    BoxShadow(color: Color(0x0F1E190F), offset: Offset(0, 2), blurRadius: 8),
    BoxShadow(color: Color(0x0A1E190F), offset: Offset(0, 1), blurRadius: 2),
  ];
  static const shFloat = [
    BoxShadow(color: Color(0x141E190F), offset: Offset(0, 20), blurRadius: 40),
    BoxShadow(color: Color(0x0F1E190F), offset: Offset(0, 6),  blurRadius: 16),
  ];
  // Dark
  static const shFloatDark = [
    BoxShadow(color: Color(0x80000000), offset: Offset(0, 24), blurRadius: 48),
    BoxShadow(color: Color(0x591E190F), offset: Offset(0, 8),  blurRadius: 20),
  ];
}

class MnemataTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark  => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;

    final cs = isDark
        ? const ColorScheme.dark(
            brightness: Brightness.dark,
            primary:           MnemataColors.accentDark,
            onPrimary:         MnemataColors.paperDark,
            secondary:         MnemataColors.accentInkDark,
            onSecondary:       MnemataColors.paperDark,
            surface:           MnemataColors.paperDark,
            onSurface:         MnemataColors.inkDark,
            surfaceContainerLowest:  MnemataColors.paperDark,
            surfaceContainerLow:     MnemataColors.paper2Dark,
            surfaceContainer:        MnemataColors.paper2Dark,
            surfaceContainerHigh:    MnemataColors.paper3Dark,
            surfaceContainerHighest: MnemataColors.paper3Dark,
            onSurfaceVariant:  MnemataColors.ink3Dark,
            outline:           MnemataColors.ruleDark,
            outlineVariant:    MnemataColors.ink4Dark,
            error:             MnemataColors.danger,
            onError:           MnemataColors.paperDark,
          )
        : const ColorScheme.light(
            brightness: Brightness.light,
            primary:           MnemataColors.accent,
            onPrimary:         MnemataColors.paper,
            secondary:         MnemataColors.accentInk,
            onSecondary:       MnemataColors.paper,
            surface:           MnemataColors.paper,
            onSurface:         MnemataColors.ink,
            surfaceContainerLowest:  MnemataColors.paper,
            surfaceContainerLow:     MnemataColors.paper2,
            surfaceContainer:        MnemataColors.paper2,
            surfaceContainerHigh:    MnemataColors.paper3,
            surfaceContainerHighest: MnemataColors.paper3,
            onSurfaceVariant:  MnemataColors.ink3,
            outline:           MnemataColors.rule,
            outlineVariant:    MnemataColors.ink4,
            error:             MnemataColors.danger,
            onError:           MnemataColors.paper,
          );

    final textTheme = _textTheme(cs);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      colorScheme: cs,
      scaffoldBackgroundColor: cs.surface,
      canvasColor: cs.surface,
      textTheme: textTheme,

      // AppBar — plano, transparente, sin tintado M3
      appBarTheme: AppBarTheme(
        backgroundColor: cs.surface,
        foregroundColor: cs.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleMedium,
      ),

      cardTheme: CardThemeData(
        color: cs.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MnemataRadii.lg),
          side: BorderSide(color: cs.outline, width: 0.5),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: cs.outline,
        thickness: 0.5,
        space: 0,
      ),

      // Botón primario negro (ink), no el ámbar
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cs.onSurface,
          foregroundColor: cs.surface,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),

      // Secondary
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: cs.surfaceContainerLow,
          foregroundColor: cs.onSurface,
          side: BorderSide(color: cs.outline),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
          shape: const StadiumBorder(),
          textStyle: textTheme.labelLarge,
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cs.secondary,
          textStyle: textTheme.labelLarge,
        ),
      ),

      // FAB — negro, círculo, sin elevación M3
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: cs.onSurface,
        foregroundColor: cs.surface,
        elevation: 6,
        shape: const CircleBorder(),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cs.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MnemataRadii.md),
          borderSide: BorderSide(color: cs.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MnemataRadii.md),
          borderSide: BorderSide(color: cs.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MnemataRadii.md),
          borderSide: BorderSide(color: cs.secondary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),

      // Chip por defecto — para TagChip usa nuestro widget
      chipTheme: ChipThemeData(
        backgroundColor: cs.surfaceContainerLow,
        selectedColor: cs.onSurface,
        side: BorderSide(color: cs.outline),
        labelStyle: textTheme.labelMedium!,
        secondaryLabelStyle: textTheme.labelMedium!.copyWith(color: cs.surface),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: const StadiumBorder(),
      ),

      // Bottom sheets — radio xl arriba, paper color
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        modalElevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(MnemataRadii.xl)),
        ),
      ),

      // Switch — accent cuando on
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) return cs.primary;
          return cs.outlineVariant;
        }),
        thumbColor: WidgetStateProperty.all(cs.surface),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
      ),

      // Ripple sutil
      splashFactory: InkSparkle.splashFactory,
      splashColor: cs.onSurface.withValues(alpha: 0.04),
      highlightColor: cs.onSurface.withValues(alpha: 0.02),

      // Iconos
      iconTheme: IconThemeData(color: cs.onSurfaceVariant, size: 20),
    );
  }

  static TextTheme _textTheme(ColorScheme cs) {
    final serif = GoogleFonts.instrumentSerifTextTheme();
    // NOTE: google_fonts 6.3.3 does not ship Geist. Substituted with Inter Tight
    // (closest visual analog). If Geist is needed, bundle it as a local asset
    // per TYPOGRAPHY.md and swap this call for a manually-built TextTheme.
    final sans  = GoogleFonts.interTightTextTheme();

    return TextTheme(
      // Display & headlines — serif
      displayLarge:   serif.displayLarge!.copyWith(
        fontSize: 64, height: 1.02, letterSpacing: -1.9, color: cs.onSurface,
      ),
      displayMedium:  serif.displayMedium!.copyWith(
        fontSize: 44, height: 1.04, letterSpacing: -1.3, color: cs.onSurface,
      ),
      displaySmall:   serif.displaySmall!.copyWith(
        fontSize: 32, height: 1.08, letterSpacing: -0.6, color: cs.onSurface,
      ),
      headlineLarge:  serif.headlineLarge!.copyWith(
        fontSize: 28, height: 1.15, letterSpacing: -0.4, color: cs.onSurface,
      ),
      headlineMedium: serif.headlineMedium!.copyWith(
        fontSize: 24, height: 1.2, letterSpacing: -0.3, color: cs.onSurface,
      ),
      headlineSmall:  serif.headlineSmall!.copyWith(
        fontSize: 20, height: 1.25, letterSpacing: -0.2, color: cs.onSurface,
      ),

      // Title L — serif, usado para el cuerpo del Reader (19pt)
      titleLarge:  serif.titleLarge!.copyWith(
        fontSize: 19, height: 1.55, letterSpacing: -0.05, color: cs.onSurface,
      ),

      // UI — sans
      titleMedium: sans.titleMedium!.copyWith(
        fontSize: 15, height: 1.4, fontWeight: FontWeight.w500, color: cs.onSurface,
      ),
      titleSmall:  sans.titleSmall!.copyWith(
        fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: cs.onSurface,
      ),
      bodyLarge:   sans.bodyLarge!.copyWith(
        fontSize: 15, height: 1.5, color: cs.onSurface,
      ),
      bodyMedium:  sans.bodyMedium!.copyWith(
        fontSize: 13, height: 1.5, color: cs.onSurfaceVariant,
      ),
      bodySmall:   sans.bodySmall!.copyWith(
        fontSize: 12, height: 1.4, color: cs.onSurfaceVariant,
      ),
      labelLarge:  sans.labelLarge!.copyWith(
        fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface,
      ),
      labelMedium: sans.labelMedium!.copyWith(
        fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant,
      ),
      labelSmall:  sans.labelSmall!.copyWith(
        fontSize: 11, fontWeight: FontWeight.w500,
        letterSpacing: 1.2, color: cs.onSurfaceVariant,
      ),
    );
  }
}

/// Helpers de estilo — monospace para metadatos.
extension MnemataMono on TextTheme {
  TextStyle mono({double size = 11, Color? color, double letterSpacing = 1.0, FontWeight weight = FontWeight.w500}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      letterSpacing: letterSpacing,
      color: color,
      fontWeight: weight,
    );
  }

  /// Uppercase mono "tracked" — para section labels tipo "TODAY · APR 16"
  TextStyle tracked(Color? color) => GoogleFonts.jetBrainsMono(
    fontSize: 11,
    letterSpacing: 1.3,
    fontWeight: FontWeight.w500,
    color: color,
  );
}
