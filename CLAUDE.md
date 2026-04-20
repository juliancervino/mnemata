# Mnemata — Guía para agentes de IA

App Flutter de "guardar y leer". El diseño visual ya está unificado bajo un sistema de tokens; tu trabajo es **mantener esa coherencia** al añadir features o tocar pantallas existentes.

## Estado del rediseño

La migración visual está **terminada** en la rama `visual-redesign-poc`. No reejecutes las fases descritas en `handoff/README.md` — ese paquete es **referencia de diseño**, no un plan pendiente. Si vas a tocar UI, léelo como documentación, no como lista de tareas.

## Dónde vive cada cosa

- `lib/core/theme/app_theme.dart` — `MnemataTheme.light/.dark`, `MnemataColors`, `MnemataRadii`, extensiones `.mono()` y `.tracked()` sobre `TextTheme`.
- `lib/core/widgets/` — widgets compartidos: `TagChip`, `ItemCard`, `SectionLabel`.
- `lib/features/<feature>/presentation/` — pantallas y widgets específicos de cada feature.
- `assets/fonts/` — Geist (4 pesos, bundleado como asset local).
- `handoff/` — spec de diseño: tokens, tipografía, componentes, screens. **Consulta antes de diseñar algo nuevo.**

## Reglas al añadir/tocar UI

1. **Nunca hardcodees colores.** Usa `Theme.of(context).colorScheme.*` o `MnemataColors.*`. Prohibido `Colors.white/black/grey/red/…` en lib/features y lib/core/widgets.
2. **Nunca hardcodees tamaños de fuente.** Usa `Theme.of(context).textTheme.*`, y las extensiones `.mono(size: …)` / `.tracked(color)` para monospace.
3. **Radios desde el token.** Solo valores de `MnemataRadii`: `sm=6, md=10, lg=14, xl=22, full=999`. Nada de `BorderRadius.circular(20)` sueltos.
4. **Jerarquía tipográfica:** serif (Instrument Serif) para títulos y cuerpo editorial del Reader; sans (Geist) para UI y metadatos; mono (JetBrains Mono) para kickers uppercase tracked y datos tipo "source · read time".
5. **Widgets compartidos primero.** Si vas a mostrar tags → `TagChip`. Item en lista → `ItemCard`. Encabezado de grupo → `SectionLabel`. No los reescribas por feature.
6. **AppBar transparente.** No vuelvas a poner `backgroundColor: colorScheme.primary`. El theme ya hace transparente + plano.
7. **Bottom sheets:** radio xl arriba (viene del theme), drag handle en `cs.outlineVariant`, header con kicker `.tracked(cs.secondary)` + título serif.
8. **FAB y botones** heredan del theme (FAB circular ink, `FilledButton` stadium ink, `OutlinedButton` stadium paper-2). No los re-estilices.
9. **Dark mode importa.** La app usa `ThemeMode.system`. Antes de mergear: comprueba visualmente tu cambio en `xcrun simctl ui booted appearance dark` (iOS) y equivalente Android.

## Gotchas

- **Colisión `SectionLabel`.** Hay dos clases con ese nombre: la canónica en `lib/core/widgets/section_label.dart` y un helper interno dentro de `lib/core/widgets/item_card.dart`. **Importa siempre desde `section_label.dart`.** Si necesitas ambos módulos, usa prefijo de import en `item_card.dart` (`as item_card`).
- **Navegación hacia atrás.** Phase 6 dejó `settings_screen.dart`, `about_screen.dart`, `label_manager_screen.dart`, `recycle_bin_screen.dart` sin `AppBar` y sin `IconButton` de back visible — la vuelta solo funciona por gesto iOS. Al crear pantallas nuevas pushed, **añade siempre un `IconButton(Icons.arrow_back_ios_new, …)`** en la zona del header, no dependas del gesto.
- **HTML en Reader.** Actualmente no se usa `flutter_html`; el cuerpo se extrae a `plainContent` y se renderiza con `SelectableText.rich`. Si alguien vuelve a meter `flutter_html`, ver `handoff/SCREENS.md` §Reader §"Nota sobre HTML renderizado" para el mapa de `Style`.
- **Colores de tag** elegidos por el usuario pueden ser invisibles sobre `paperDark`. Si el dato es user-controlled, valida contraste o fuerza un alpha mínimo antes de renderizar.
- **`Colors.yellowAccent` en `reader_selection_actions.dart:29`** es un resto pendiente — se ve mal en dark. Si tocas ese archivo, swap a `cs.secondary.withValues(alpha: 0.25)` o similar.

## Qué NO tocar al añadir una feature visual

Lógica: servicios (`lib/features/*/services/`), `AppDatabase`, repositorios, stores, providers de `get_it`. El rediseño fue puramente visual y esa separación se mantiene. Si tu cambio visual necesita tocar lógica, plantéalo primero en un plan explícito.

## Antes de marcar "hecho"

- `flutter analyze lib/` no introduce errores nuevos.
- La pantalla se ve correcta en claro **y** en oscuro.
- No quedan `Colors.xxx`, `fontSize:`, ni `BorderRadius.circular(N)` fuera de tokens en los archivos que tocaste.
- Si añadiste una nueva screen pushed, tiene botón de back visible.

## Para profundizar

- Design tokens completos: `handoff/DESIGN_TOKENS.md`
- Tipografía: `handoff/TYPOGRAPHY.md`
- Specs de componentes: `handoff/COMPONENTS.md`
- Screens ya refactorizadas (referencia, no TODO): `handoff/SCREENS.md`
- Paleta oscura: `handoff/DARK_MODE.md`
