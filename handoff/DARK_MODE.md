# Dark mode — Mnemata

El rediseño es **claro por defecto**, pero el dark mode es de primera clase —
no es un afterthought ni un invert automático.

## Filosofía

"Tinta cálida sobre papel oscuro." No es un dark azulado de productividad;
es un dark con calidez — el fondo tiene el mismo cast cálido (hue ~70) que
el papel claro, sólo que con luminosidad baja.

## Activación

Ya definido en `lib-snippets/app_theme.dart`:

```dart
MaterialApp(
  theme: MnemataTheme.light,
  darkTheme: MnemataTheme.dark,
  themeMode: ThemeMode.system,  // o .light, .dark si añades toggle manual
)
```

## Paleta (ver `DESIGN_TOKENS.md` para tabla completa)

Claves:

- `paper` (bg) → `#201E1A` — casi negro, tono cálido
- `paper-2` → `#2A2824` — cards
- `paper-3` → `#35322D` — hover, chips
- `ink` (texto) → `#F3F0EB` — blanco cálido (no puro)
- `accent` → `#E3A870` — ámbar más claro que en modo claro

## Contraste

Auditado para:

| Par | Ratio | AA |
|---|---|---|
| `ink` / `paper` | ~14:1 | ✅ AAA |
| `ink-2` / `paper` | ~9:1 | ✅ AAA |
| `ink-3` / `paper` | ~5:1 | ✅ AA |
| `accent` / `paper` | ~7:1 | ✅ AA large, AAA normal |
| `accent-ink` / `paper` | ~8:1 | ✅ AAA |

## Puntos delicados

1. **Highlights** (`accentSoftDark` `#453625`): sobre `paper-2` quedan sutiles
   pero visibles. Verificar en pantalla OLED donde los oscuros se chupan.

2. **Thumbs**: los gradientes usan `tagN.withValues(alpha: 0.35–0.55)`.
   En oscuro se mezclan con el fondo — funcionan, pero revisar.

3. **Reader floating pill**: en oscuro el pill es `cs.onSurface` = blanco
   cálido, texto/iconos `cs.surface` = casi negro. Se ve bien.

4. **Dividers** (`rule`): `#3F3C37` — muy sutil. Correcto; en oscuro los
   dividers deben ser discretos.

## Preferencia manual (opcional)

Si quieres ofrecer override manual además de `ThemeMode.system`:

```dart
// en SettingsService
enum AppThemeMode { system, light, dark }

// en main
ValueListenableBuilder<AppThemeMode>(
  valueListenable: settings.themeModeNotifier,
  builder: (_, mode, __) => MaterialApp(
    theme: MnemataTheme.light,
    darkTheme: MnemataTheme.dark,
    themeMode: switch (mode) {
      AppThemeMode.system => ThemeMode.system,
      AppThemeMode.light  => ThemeMode.light,
      AppThemeMode.dark   => ThemeMode.dark,
    },
    ...
  ),
)
```

En la UI de settings, tu mock ya muestra el row "Theme · Light · auto at night"
— usar un `SegmentedButton` con los 3 modos.
