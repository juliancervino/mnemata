# Componentes — Mnemata

Widgets reutilizables que hay que crear en `lib/core/widgets/`. Dos ya están
escritos en `lib-snippets/`; el resto son specs para que Claude Code los
genere con el mismo estilo.

---

## TagChip ✅ (ver `lib-snippets/tag_chip.dart`)

Punto de color + label. Estados `default` y `active`. Tamaño `md`/`sm`.

Uso:
```dart
TagChip(label: 'essays', color: MnemataColors.tag1)
TagChip(label: 'all', color: MnemataColors.ink3, active: true)
TagChip(label: 'pkm', color: MnemataColors.tag2, compact: true)
```

---

## ItemCard + SectionLabel ✅ (ver `lib-snippets/item_card.dart`)

Fila de la lista cronológica. Agrupar con `SectionLabel` arriba.

---

## ReaderActionPill

Pill flotante con 5 iconos — pieza central del Reader.

**Specs:**
- Fondo: `cs.onSurface` (negro/paper inverso)
- Color iconos: `cs.surface`
- Shape: `StadiumBorder`
- Padding interno: 8px
- Tamaño cada icon button: 40×40
- Gap entre botones: 2px
- Posición: `Positioned(bottom: 32, left: 0, right: 0)` + centrado
- Shadow: `MnemataShadows.shFloat`
- Safe area: respetar `MediaQuery.viewPadding.bottom + 16`

**Iconos (Material Symbols Outlined):**
1. `auto_awesome` → summary
2. `format_ink_highlighter` → highlight
3. `sell_outlined` → tag
4. `ios_share` → share
5. `bookmark_outline` → bookmark

---

## Monogram / Wordmark

Marca de Mnemata — se usa en top-bar, onboarding, settings header.

**Monogram (solo "m·"):**
```dart
class Monogram extends StatelessWidget {
  final double size;
  const Monogram({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.end, children: [
      Text('m', style: TextStyle(
        fontFamily: 'InstrumentSerif',
        fontStyle: FontStyle.italic,
        fontSize: size, height: 1, color: cs.onSurface,
      )),
      SizedBox(width: size * 0.04),
      Container(
        margin: EdgeInsets.only(bottom: size * 0.08),
        width: size * 0.22, height: size * 0.22,
        decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
      ),
    ]);
  }
}
```

**Wordmark completo ("mnemata·"):** igual pero con `'mnemata'` en lugar de `'m'`.

---

## SummarySheet (bottom sheet para AI Summary)

Estructura:
```
╭─ drag handle ──────╮
│                    │
│ ⚡ SUMMARY · CLAUDE │
│                    │
│ Three key ideas,   │  ← headlineMedium serif
│ in sixty seconds.  │
│                    │
│ 01  — idea 1       │  ← titleLarge serif
│ ──────────────     │
│ 02  — idea 2       │
│ ──────────────     │
│ 03  — idea 3       │
│                    │
│ [Save summary] [Regenerate]
│                    │
╰────────────────────╯
```

- Drag handle: 36×4, `cs.outlineVariant`, margen superior 14
- Kicker: `textTheme.labelSmall` ámbar (`cs.secondary`) con icono `auto_awesome` a la izquierda
- Título: `headlineMedium`
- Cada idea es row con:
  - índice en mono ámbar (`01`, `02`…)
  - texto en serif 17pt

---

## Implementación sugerida

Orden para Claude Code:

1. `lib/core/widgets/monogram.dart`
2. `lib/core/widgets/tag_chip.dart` (del snippet)
3. `lib/core/widgets/item_card.dart` (del snippet)
4. `lib/core/widgets/section_label.dart` (del snippet — está en `item_card.dart`, puedes extraerlo)
5. `lib/core/widgets/reader_action_pill.dart`
6. `lib/core/widgets/summary_sheet.dart`

Ninguno depende de lógica — son puramente visuales. Pueden entrar en un PR
de "Fase 2" independiente.
