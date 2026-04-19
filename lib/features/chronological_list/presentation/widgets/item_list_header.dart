// Visual presentation helpers for the Item List screen.
//
// These widgets are purely presentational — they hold no state and never
// touch repositories, providers, or services. The parent screen owns all
// callbacks (search, overflow menu, etc.). See
// `lib/features/chronological_list/presentation/item_list_screen.dart`.

import 'package:flutter/material.dart';

import 'package:mnemata/core/theme/app_theme.dart';

/// Custom top-of-screen header: `m.` monogram, spacer, icon buttons.
///
/// Replaces the old primary-colored [AppBar]. The spec for this row lives in
/// `handoff/SCREENS.md` — section "FASE 4 — Item List" and
/// `handoff/COMPONENTS.md` — section "Monogram / Wordmark".
class ItemListHeader extends StatelessWidget {
  const ItemListHeader({
    super.key,
    required this.onSearchPressed,
    required this.onMorePressed,
    this.onMonogramPressed,
    this.leading,
    this.trailing,
  });

  final VoidCallback onSearchPressed;
  final VoidCallback onMorePressed;
  final VoidCallback? onMonogramPressed;

  /// Optional leading widget — when non-null, replaces the monogram. Used by
  /// the search field mode to render an in-place text input.
  final Widget? leading;

  /// Optional trailing override — when non-null, replaces the default
  /// search + more icon cluster. Used by the search field mode.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 6),
      child: Row(
        children: [
          if (leading != null)
            Expanded(child: leading!)
          else ...[
            _Monogram(onTap: onMonogramPressed),
            const Spacer(),
          ],
          if (trailing != null)
            trailing!
          else ...[
            IconButton(
              icon: const Icon(Icons.search),
              tooltip: 'Search',
              onPressed: onSearchPressed,
            ),
            IconButton(
              icon: const Icon(Icons.more_horiz),
              tooltip: 'More',
              onPressed: onMorePressed,
            ),
          ],
        ],
      ),
    );
  }
}

class _Monogram extends StatelessWidget {
  const _Monogram({this.onTap});

  static const double size = 28;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final child = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          'm',
          style: TextStyle(
            fontFamily: 'InstrumentSerif',
            fontStyle: FontStyle.italic,
            fontSize: size,
            height: 1,
            color: cs.onSurface,
          ),
        ),
        SizedBox(width: size * 0.04),
        Container(
          margin: EdgeInsets.only(bottom: size * 0.08),
          width: size * 0.22,
          height: size * 0.22,
          decoration: BoxDecoration(color: cs.primary, shape: BoxShape.circle),
        ),
      ],
    );

    if (onTap == null) {
      return child;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(MnemataRadii.sm),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: child,
      ),
    );
  }
}

/// Large serif title block shown below the top header.
///
/// Spec (handoff/SCREENS.md — FASE 4):
///   [Your library · N items]  ← tracked uppercase mono
///   Everything worth          ← displayMedium serif, "worth" italic secondary
///   remembering.
class LibraryTitleBlock extends StatelessWidget {
  const LibraryTitleBlock({
    super.key,
    required this.itemCount,
    this.kickerOverride,
  });

  final int itemCount;

  /// When non-null, replaces the default "YOUR LIBRARY · N ITEMS" kicker.
  /// Used for history / filtered contexts.
  final String? kickerOverride;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final kicker =
        kickerOverride ?? 'Your library · $itemCount items';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            kicker.toUpperCase(),
            style: theme.textTheme.tracked(cs.onSurfaceVariant),
          ),
          const SizedBox(height: 10),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(text: 'Everything '),
                TextSpan(
                  text: 'worth',
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: cs.secondary,
                  ),
                ),
                const TextSpan(text: '\nremembering.'),
              ],
            ),
            style: theme.textTheme.displayMedium,
          ),
        ],
      ),
    );
  }
}
