# Pantalla por pantalla — Mnemata

Mapeo de cada pantalla del rediseño al archivo real de tu codebase.

> Los paths parten de `mnemata/`. Las pantallas que no aparecen aquí se
> benefician automáticamente del nuevo `ThemeData` sin refactor.

---

## FASE 1 — Tema global

**Archivos:**
- `pubspec.yaml` — añadir `google_fonts: ^6.2.1`
- `lib/core/theme/app_theme.dart` — **nuevo**, copiar de `lib-snippets/`
- `lib/main.dart` — usar el nuevo tema

### `main.dart` — cambio

```dart
// antes
MaterialApp(
  theme: ThemeData(
    useMaterial3: true,
    colorSchemeSeed: const Color(0xFF2E7D32),
  ),
  ...
)

// después
import 'core/theme/app_theme.dart';

MaterialApp(
  title: 'Mnemata',
  theme: MnemataTheme.light,
  darkTheme: MnemataTheme.dark,
  themeMode: ThemeMode.system,
  ...
)
```

**Resultado:** toda la app pasa de verde+Material You a neutros cálidos
+ serif editorial sin tocar ninguna pantalla. Primer commit.

---

## FASE 3 — Reader (hero)

**Archivo:** `lib/features/reader/presentation/reader_screen.dart`

### Qué cambia

**AppBar** — de esto:
```dart
AppBar(
  title: Text(widget.item.title ?? 'Article'),
  backgroundColor: Theme.of(context).colorScheme.primary,
  foregroundColor: Theme.of(context).colorScheme.onPrimary,
  actions: [IconButton(...), IconButton(...), ...],
)
```

A esto:
```dart
AppBar(
  backgroundColor: Colors.transparent,
  elevation: 0,
  scrolledUnderElevation: 0,
  leading: IconButton(
    icon: const Icon(Icons.arrow_back, size: 20),
    onPressed: () => Navigator.pop(context),
  ),
  title: Text(
    '${widget.item.source ?? ''} · ${widget.item.readTime ?? ''}',
    style: theme.textTheme.mono(size: 10, letterSpacing: 1.0, color: cs.onSurfaceVariant),
  ),
  centerTitle: true,
  actions: [
    // solo 1 icono de "more" ahora — las acciones van al pill
    IconButton(icon: const Icon(Icons.more_horiz), onPressed: _openMenu),
  ],
),
```

**Cuerpo del artículo** — reemplazar el `ListView`/`Text` actual por:

```dart
SafeArea(
  child: SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(28, 36, 28, 120),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Kicker — categoría en uppercase mono ámbar
        if (kicker != null) Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Text(
            kicker!.toUpperCase(),
            style: theme.textTheme.tracked(cs.secondary),
          ),
        ),
        // Título — serif displaySmall
        Text(
          widget.item.title ?? '',
          style: theme.textTheme.displaySmall!.copyWith(
            fontSize: 36, height: 1.08, letterSpacing: -0.9,
          ),
        ),
        // Subtítulo en serif itálico (si existe)
        if (widget.item.description != null) Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(
            widget.item.description!,
            style: theme.textTheme.titleLarge!.copyWith(
              fontStyle: FontStyle.italic,
              color: cs.onSurfaceVariant,
              fontSize: 18,
            ),
          ),
        ),
        // Meta: autor + fecha
        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 18),
        Row(children: [
          // avatar placeholder
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: [MnemataColors.tag1, MnemataColors.tag4]),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${author ?? ''} · ${formattedDate}',
            style: theme.textTheme.mono(size: 11, color: cs.onSurfaceVariant),
          ),
        ]),
        const SizedBox(height: 32),
        // Body — serif 19pt line-height 1.55 (= titleLarge del theme)
        Text(plainContent, style: theme.textTheme.titleLarge),
      ],
    ),
  ),
),
```

**Floating action pill** — componer como `Stack` con el scroll view de fondo:

```dart
Scaffold(
  body: Stack(
    children: [
      // el SingleChildScrollView de arriba
      ReaderBody(...),
      // pill
      Positioned(
        bottom: MediaQuery.of(context).viewPadding.bottom + 16,
        left: 0, right: 0,
        child: Center(child: ReaderActionPill(
          onSummary: _openSummary,
          onHighlight: _startHighlight,
          onTag: _openTagSuggestions,
          onShare: _shareItem,
          onBookmark: _togglePin,
        )),
      ),
    ],
  ),
)
```

### Nota sobre HTML renderizado

Tu Reader actualmente extrae `plainContent` con un helper interno. Si renderizas
HTML con `flutter_html`, añade un `Style` custom para respetar el nuevo theme:

```dart
Html(
  data: htmlContent,
  style: {
    'body': Style(
      fontFamily: 'InstrumentSerif',
      fontSize: FontSize(19),
      lineHeight: const LineHeight(1.55),
      color: cs.onSurface,
      margin: Margins.zero,
    ),
    'p': Style(margin: Margins.only(bottom: 22)),
    'blockquote': Style(
      border: Border(left: BorderSide(color: cs.primary, width: 2)),
      padding: HtmlPaddings.only(left: 24),
      fontStyle: FontStyle.italic,
      fontSize: FontSize(22),
      color: cs.onSurface,
    ),
    'a': Style(color: cs.secondary, textDecoration: TextDecoration.underline),
    'mark': Style(
      backgroundColor: MnemataColors.accentSoft,
      padding: HtmlPaddings.symmetric(horizontal: 4),
    ),
  },
)
```

---

## FASE 4 — Item List

**Archivo:** `lib/features/chronological_list/presentation/item_list_screen.dart`

Archivo grande (1192 líneas) — sugiero extraer widgets a `widgets/` dentro
del feature antes de refactor visual, si aún no está.

### Qué cambia (sólo visual)

1. **Top bar:** quitar AppBar con fondo primary. Usar un `SliverAppBar` o un
   header custom:
   ```
   Monogram + spacer + IconButton(search) + IconButton(more)
   ```

2. **Large title:** debajo del top bar, en el `SliverToBoxAdapter`:
   ```dart
   Padding(
     padding: const EdgeInsets.fromLTRB(20, 28, 20, 4),
     child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
       Text('Your library · ${items.length} items'.toUpperCase(),
            style: theme.textTheme.tracked(cs.onSurfaceVariant)),
       const SizedBox(height: 10),
       Text.rich(TextSpan(children: [
         const TextSpan(text: 'Everything '),
         TextSpan(
           text: 'worth',
           style: TextStyle(fontStyle: FontStyle.italic, color: cs.secondary),
         ),
         const TextSpan(text: '\nremembering.'),
       ]), style: theme.textTheme.displayMedium),
     ]),
   )
   ```

3. **Tag filter row** — sustituir chips actuales por `TagChip` custom.
   Mantén la lógica de `_selectedLabelIds` intacta.

4. **List rows** — sustituir el row actual por `ItemCard`:
   ```dart
   ItemCard(
     data: ItemCardData(
       title: item.title ?? '',
       source: Uri.parse(item.url ?? '').host,
       readTime: _estimateReadTime(item),
       tags: labels.map((l) => (label: l.name, color: _tagColorFor(l))).toList(),
       thumbTone: _toneFor(item),
       thumbUrl: item.thumbnailUrl,
     ),
     onTap: () => _openItem(item),
   )
   ```

5. **Group by date**: agrupa `items` por relativo ("Today", "Earlier this week",
   "Apr 04 – Apr 02") y pon un `SectionLabel` antes de cada grupo.
   Helper sugerido:
   ```dart
   String _groupLabel(DateTime d) {
     final now = DateTime.now();
     final diff = now.difference(d).inDays;
     if (diff == 0) return 'Today · ${DateFormat('MMM d').format(d)}';
     if (diff < 7)  return 'Earlier this week';
     if (diff < 30) return 'Apr 04 – Apr 02'; // rango real del grupo
     return DateFormat('MMMM yyyy').format(d);
   }
   ```

6. **FAB:** el `FloatingActionButton` hereda el nuevo theme (negro, círculo).
   No hay que tocar nada si ya usas `FloatingActionButton`.

7. **Slidable actions:** mantener la lógica, sólo ajustar colores a
   `cs.primary` / `cs.error` en lugar de los verdes actuales.

### Importante: NO tocar

- `_loadSearchHistory`, `_saveSearchToHistory`
- `_semanticMode`, `_loadSemanticAvailability`
- Multi-select mode
- Drag & drop reorder

Todo eso es lógica — el rediseño es puramente visual.

---

## FASE 5 — Bottom sheets

**Archivos:**
- `lib/features/intelligence/presentation/summary_panel.dart` — usar `SummarySheet`
- `lib/features/intelligence/presentation/tag_suggestion_sheet.dart`
- `lib/features/organization/presentation/label_selector_sheet.dart`
- Save/ingest sheet (buscar en `features/ingestion/`)

Todos con:
- `showModalBottomSheet` con `shape` ya definido en theme (radio xl arriba)
- Drag handle al top
- Header: kicker en ámbar + título serif
- Botones inferiores: un `FilledButton` primario (ink) + `OutlinedButton` secundario

---

## FASE 6 — Settings + About + Recycle Bin + Label Manager

**Archivos:**
- `lib/features/settings/presentation/settings_screen.dart`
- `lib/features/settings/presentation/about_screen.dart`
- `lib/features/chronological_list/presentation/recycle_bin_screen.dart`
- `lib/features/organization/presentation/label_manager_screen.dart`

Patrón: grupos de settings en `Container` con `cs.surfaceContainerLow` +
borde + radius lg, separados por `SectionLabel` uppercase mono.

Switches: el theme ya pone el accent cuando están on.

---

## FASE 7 — Dark mode

**Archivos:**
- `lib/main.dart` — `themeMode: ThemeMode.system`

Verificar manualmente:
- Reader en oscuro: el serif sobre `paperDark` (`#201E1A`) debe tener contraste AA.
  La paleta está calibrada para eso pero revisa en dispositivo real.
- Highlights (`accentSoftDark`): que no desaparezcan sobre el fondo oscuro.
- Thumbs: los gradientes generados desde `tagN` siguen viéndose — son iguales
  en ambos modos por diseño.

---

## Pantallas NO incluidas en el rediseño inicial

Heredan del tema nuevo sin refactor dedicado:

- Item editor (`item_editor_screen.dart`)
- Search screen (si es pantalla separada)
- Annotation list panel
- Recycle bin (reutiliza `ItemCard`)

Si alguna necesita ajuste, añadir como Fase 8.
