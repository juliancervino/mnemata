# Tipografía — Mnemata

## Familias

| Familia | Rol | Pesos usados |
|---|---|---|
| Instrument Serif | Editorial (headlines, artículo, marca) | 400, 400 italic |
| Geist | Interfaz (UI labels, buttons, body UI) | 300, 400, 500, 600 |
| JetBrains Mono | Metadato (timestamps, sources, keybinds) | 400, 500 |

## Instalación vía `google_fonts`

1. Añade a `pubspec.yaml`:

```yaml
dependencies:
  google_fonts: ^6.2.1
```

2. `flutter pub get`

3. En `app_theme.dart` (ver snippet completo en `lib-snippets/app_theme.dart`):

```dart
import 'package:google_fonts/google_fonts.dart';

TextTheme _buildTextTheme(ColorScheme cs) {
  final serif = GoogleFonts.instrumentSerifTextTheme();
  final sans = GoogleFonts.geistTextTheme();

  return TextTheme(
    // Display / headlines — serif
    displayLarge:  serif.displayLarge!.copyWith(fontSize: 64, height: 1.02, letterSpacing: -1.9, color: cs.onSurface),
    displayMedium: serif.displayMedium!.copyWith(fontSize: 44, height: 1.04, letterSpacing: -1.3, color: cs.onSurface),
    displaySmall:  serif.displaySmall!.copyWith(fontSize: 32, height: 1.08, letterSpacing: -0.6, color: cs.onSurface),

    // Títulos — serif medios
    headlineLarge:  serif.headlineLarge!.copyWith(fontSize: 28, height: 1.15, letterSpacing: -0.4, color: cs.onSurface),
    headlineMedium: serif.headlineMedium!.copyWith(fontSize: 24, height: 1.2, letterSpacing: -0.3, color: cs.onSurface),
    headlineSmall:  serif.headlineSmall!.copyWith(fontSize: 20, height: 1.25, letterSpacing: -0.2, color: cs.onSurface),

    // Body de artículo — serif
    // (ojo: estos son los que usa el Reader; el body UI general viene más abajo)
    titleLarge:  serif.titleLarge!.copyWith(fontSize: 18, height: 1.3, letterSpacing: -0.1, color: cs.onSurface),

    // UI body — sans
    titleMedium: sans.titleMedium!.copyWith(fontSize: 15, height: 1.4, fontWeight: FontWeight.w500, color: cs.onSurface),
    titleSmall:  sans.titleSmall!.copyWith(fontSize: 13, height: 1.4, fontWeight: FontWeight.w500, color: cs.onSurface),
    bodyLarge:   sans.bodyLarge!.copyWith(fontSize: 15, height: 1.5, color: cs.onSurface),
    bodyMedium:  sans.bodyMedium!.copyWith(fontSize: 13, height: 1.5, color: cs.onSurfaceVariant),
    bodySmall:   sans.bodySmall!.copyWith(fontSize: 12, height: 1.4, color: cs.onSurfaceVariant),

    // Labels — sans, más ajustado
    labelLarge:  sans.labelLarge!.copyWith(fontSize: 14, fontWeight: FontWeight.w500, color: cs.onSurface),
    labelMedium: sans.labelMedium!.copyWith(fontSize: 12, fontWeight: FontWeight.w500, color: cs.onSurfaceVariant),
    labelSmall:  sans.labelSmall!.copyWith(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 1.2, color: cs.onSurfaceVariant),
  );
}
```

### Mono (para metadatos)

`google_fonts` no lo pone en `TextTheme` global porque es de uso específico.
Úsalo puntualmente:

```dart
Text(
  'APR 16 · 8 MIN',
  style: GoogleFonts.jetBrainsMono(
    fontSize: 11,
    letterSpacing: 1.0,
    color: theme.colorScheme.onSurfaceVariant,
    fontWeight: FontWeight.w500,
  ),
)
```

O crea un extension helper en `lib/core/theme/text_styles.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

extension MnemataTextStyles on TextTheme {
  TextStyle mono({double size = 11, Color? color, double letterSpacing = 1.0}) {
    return GoogleFonts.jetBrainsMono(
      fontSize: size,
      letterSpacing: letterSpacing,
      color: color,
      fontWeight: FontWeight.w500,
    );
  }

  /// Uppercase mono tracked — "SECTION LABELS"
  TextStyle get tracked => GoogleFonts.jetBrainsMono(
    fontSize: 11,
    letterSpacing: 1.3,
    fontWeight: FontWeight.w500,
  );
}
```

---

## Migración a assets locales (recomendado para producción offline)

Cuando quieras quitar la dependencia online del primer arranque:

1. Descargar los TTF/OTF:
   - Instrument Serif: https://fonts.google.com/specimen/Instrument+Serif
   - Geist: https://vercel.com/font
   - JetBrains Mono: https://www.jetbrains.com/lp/mono/

2. Ponerlos en `assets/fonts/`:

```
assets/fonts/
  InstrumentSerif-Regular.ttf
  InstrumentSerif-Italic.ttf
  Geist-Light.ttf
  Geist-Regular.ttf
  Geist-Medium.ttf
  Geist-SemiBold.ttf
  JetBrainsMono-Regular.ttf
  JetBrainsMono-Medium.ttf
```

3. En `pubspec.yaml`:

```yaml
flutter:
  fonts:
    - family: InstrumentSerif
      fonts:
        - asset: assets/fonts/InstrumentSerif-Regular.ttf
        - asset: assets/fonts/InstrumentSerif-Italic.ttf
          style: italic
    - family: Geist
      fonts:
        - asset: assets/fonts/Geist-Light.ttf
          weight: 300
        - asset: assets/fonts/Geist-Regular.ttf
          weight: 400
        - asset: assets/fonts/Geist-Medium.ttf
          weight: 500
        - asset: assets/fonts/Geist-SemiBold.ttf
          weight: 600
    - family: JetBrainsMono
      fonts:
        - asset: assets/fonts/JetBrainsMono-Regular.ttf
          weight: 400
        - asset: assets/fonts/JetBrainsMono-Medium.ttf
          weight: 500
```

4. Sustituir `GoogleFonts.xxxTextTheme()` por `TextTheme` a mano con
   `fontFamily: 'InstrumentSerif'` / `'Geist'` / `'JetBrainsMono'`.

---

## Alternativa: si Instrument Serif se ve demasiado fino

Para headlines muy grandes (>48pt) Instrument Serif puede verse frágil.
Alternativas con más cuerpo:

- **Fraunces** — moderno, muchos pesos, MUY usado (puede sentirse a moda)
- **Source Serif 4** — robusta, buena para tamaños grandes y pequeños
- **Lora** — cálida, bien en cuerpo de texto

Si cambias, sustituye sólo en `display*` (headlines) y deja los body
(`titleLarge` = artículo) con Instrument Serif; o cambia las dos.
