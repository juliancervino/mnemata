# Mnemata — Paquete de handoff del rediseño visual

Este paquete traduce el rediseño visual presentado en `Mnemata Redesign.html` a
instrucciones concretas para tu codebase Flutter (`mnemata/`).

El rediseño es un cambio **puramente visual** — no toca lógica, base de datos,
servicios de IA, scrapers, ni el modelo de datos. Sólo:

- `ThemeData` global (color, tipografía, radios, elevaciones)
- Widgets de presentación en cada `*_screen.dart`
- Un par de widgets reutilizables nuevos (`TagChip`, `ItemCard`, `ReaderActionPill`)

---

## Cómo usar esto con Claude Code

Desde la raíz del repo `mnemata/`, arranca Claude Code y dale este prompt inicial:

> Lee `../<ruta-a-este-paquete>/handoff/README.md` entero y todos los archivos
> linkados desde él antes de empezar. Vamos a aplicar un rediseño visual en
> varias fases. No toques lógica ni servicios — sólo tema y widgets de
> presentación. Al terminar cada fase, páramelo y muéstrame un diff resumido
> antes de continuar.
>
> Empieza por **Fase 1** de `SCREENS.md`.

Si prefieres copiar el paquete dentro del repo:

```bash
cp -r handoff mnemata/handoff
cd mnemata
claude
```

Y luego: *"Lee `handoff/README.md` y empieza por la Fase 1."*

---

## Archivos en este paquete

| Archivo | Para qué |
|---|---|
| `README.md` | Este índice. Plan de fases. |
| `DESIGN_TOKENS.md` | Tokens crudos (color, type, spacing, radios, shadows) |
| `TYPOGRAPHY.md` | Fuentes, cómo cargarlas, mapping a `TextTheme` |
| `DARK_MODE.md` | Paleta oscura y cómo activarla |
| `COMPONENTS.md` | Specs de componentes (TagChip, ItemCard, ReaderPill…) |
| `SCREENS.md` | Qué cambiar pantalla por pantalla, con archivos concretos |
| `lib-snippets/app_theme.dart` | Archivo Dart **ya escrito** — copiar a `lib/core/theme/` |
| `lib-snippets/tag_chip.dart` | Widget reutilizable |
| `lib-snippets/item_card.dart` | Widget reutilizable |
| `screenshots/` | PNGs de referencia (uno por pantalla) |

---

## Plan de migración en fases

Cada fase es independiente y dejable a medio — la app sigue funcionando entre
fases. Sugiero un PR por fase.

### Fase 1 — Tema global (riesgo: bajo, impacto: alto)

1. Añadir dependencia `google_fonts: ^6.2.1` a `pubspec.yaml` (ver `TYPOGRAPHY.md`)
2. Copiar `lib-snippets/app_theme.dart` → `lib/core/theme/app_theme.dart`
3. En `main.dart`, sustituir el `ThemeData.light(...)` actual por
   `MnemataTheme.light` / `MnemataTheme.dark` y `ThemeMode.system`
4. Correr la app — toda la app cambia de look sin tocar una pantalla

**Entregable:** la app sigue siendo funcionalmente idéntica pero con paleta
cálida, serif editorial en titulares y sin violetas de Material You.

### Fase 2 — Widgets compartidos (riesgo: bajo)

Crear en `lib/core/widgets/`:

- `tag_chip.dart` (ver `lib-snippets/`)
- `item_card.dart` (ver `lib-snippets/`)
- `section_label.dart` — el `mn-tracked` uppercase mono

No sustituyas aún los usos antiguos — sólo añade los widgets.

### Fase 3 — Reader (hero) (riesgo: medio, impacto: alto)

Reescribir `lib/features/reader/presentation/reader_screen.dart`:

- Quitar el `AppBar` coloreado con `colorScheme.primary` — ahora es transparente
  con sólo una fila de iconos pequeños arriba
- Título como `Text` serif grande (Instrument Serif 36–52pt, line-height 1.08)
- Kicker `ESSAYS` uppercase mono arriba del título
- Subtítulo en serif itálico
- Cuerpo del artículo en Instrument Serif 19pt, line-height 1.55
- `BottomAppBar` reemplazada por un **pill flotante** centrado abajo con
  los iconos: sparkle (summary), highlight, tag, share, bookmark
- Ver `SCREENS.md` sección **Reader**

### Fase 4 — Item List (riesgo: medio, impacto: alto)

Refactor de `lib/features/chronological_list/presentation/item_list_screen.dart`:

- Top bar minimal con monograma `m.` + icono search
- Título grande serif ("Everything worth remembering.")
- Chips de tag con dot de color (usar `TagChip`)
- Filas agrupadas por sección de fecha con `SectionLabel`
- `ItemCard` como fila con thumb + source mono + título serif + tag dots
- FAB: círculo negro `Ink` con `+` blanco, no el M3 elevated FAB

### Fase 5 — Bottom sheets (summary, ingest, tag selector) (riesgo: bajo)

- Radio superior 24dp
- Drag handle en gris medio
- Header: ícono sparkle + "SUMMARY · CLAUDE" uppercase mono en ámbar
- Contenido en serif

### Fase 6 — Settings + About + Recycle Bin + Label Manager (riesgo: bajo)

- Grupos con card `paper-2` y rows con divider fino
- Switches con color `accent` (no primary de M3 default)

### Fase 7 — Dark mode (riesgo: bajo)

- Ya está en el `ThemeData.dark` del snippet
- `MaterialApp.themeMode: ThemeMode.system`
- Verificar legibilidad en Reader (es el caso más delicado)

---

## Checklist post-migración

- [ ] No queda ningún `Colors.xxx` hardcodeado — todo viene de `Theme.of(context)`
- [ ] No queda ningún `fontSize:` hardcodeado en widgets — usar `Theme.of(context).textTheme`
- [ ] `BorderRadius.circular(...)` usa los radios del token (`6, 10, 14, 22, 999`)
- [ ] Funciona bien en claro, oscuro y auto
- [ ] Reader sigue siendo accesible (contraste AA en ambos modos)
- [ ] Nada en la lógica (servicios, DB, repositorios, AI) se ha tocado

---

## Preguntas abiertas para el equipo

1. **Instrument Serif** no viene con todos los pesos — sólo regular e italic.
   Para títulos muy grandes puede verse fino. Alternativas con más cuerpo:
   *Fraunces, Source Serif 4, Lora*. Decidir antes de Fase 1.
2. **Geist** requiere `google_fonts ^6.2.1`. Si ya tienes otra fuente sans
   corporativa, sustituir en `TYPOGRAPHY.md`.
3. **Tag colors**: ahora mismo las 6 asignadas en `DESIGN_TOKENS.md` son
   candidatos. Si ya tienes un mapping tag→color en BD, respétalo.
