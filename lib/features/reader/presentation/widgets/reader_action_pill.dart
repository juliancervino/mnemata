// ReaderActionPill — Mnemata
//
// Pill flotante con 5 iconos que se muestra en la parte inferior del Reader.
// Puramente presentacional — recibe callbacks por parámetros nombrados.
//
// Spec: COMPONENTS.md §ReaderActionPill
//   - Fondo: cs.onSurface, iconos: cs.surface
//   - Shape: StadiumBorder
//   - Padding interno: 8, icon 40x40, gap 2
//   - Shadow: MnemataShadows.shFloat

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mnemata/core/theme/app_theme.dart';

class ReaderActionPill extends StatelessWidget {
  const ReaderActionPill({
    super.key,
    this.onSummary,
    this.onHighlight,
    this.onTag,
    this.onShare,
    this.isHighlightActive = false,
  });

  final VoidCallback? onSummary;
  final VoidCallback? onHighlight;
  final VoidCallback? onTag;
  final VoidCallback? onShare;
  final bool isHighlightActive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: ShapeDecoration(
        color: cs.onSurface,
        shape: const StadiumBorder(),
        shadows: isDark ? MnemataShadows.shFloatDark : MnemataShadows.shFloat,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PillAction(
            icon: Icons.auto_awesome,
            tooltip: 'Summary',
            onTap: onSummary,
            fg: cs.surface,
          ),
          if (kIsWeb) ...[
            const SizedBox(width: 2),
            _PillAction(
              icon: isHighlightActive ? Icons.brush : Icons.brush_outlined,
              tooltip: 'Highlight',
              onTap: onHighlight,
              fg: isHighlightActive ? MnemataColors.accent : cs.surface,
            ),
          ],
          const SizedBox(width: 2),
          _PillAction(
            icon: Icons.sell_outlined,
            tooltip: 'Tag',
            onTap: onTag,
            fg: cs.surface,
          ),
          const SizedBox(width: 2),
          _PillAction(
            icon: Icons.ios_share,
            tooltip: 'Share',
            onTap: onShare,
            fg: cs.surface,
          ),
        ],
      ),
    );
  }
}

class _PillAction extends StatelessWidget {
  const _PillAction({
    required this.icon,
    required this.tooltip,
    required this.fg,
    this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final Color fg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        tooltip: tooltip,
        onPressed: onTap,
        padding: EdgeInsets.zero,
        iconSize: 20,
        color: fg,
        icon: Icon(icon),
      ),
    );
  }
}
