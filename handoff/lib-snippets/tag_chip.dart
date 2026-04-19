// TagChip — Mnemata
// Copia a: lib/core/widgets/tag_chip.dart
//
// Un chip de tag editorial: punto de color + label.
// Dos estados visuales: default (fondo paper-2, texto ink-2) y
// active (fondo ink, texto paper).

import 'package:flutter/material.dart';

class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    required this.color,
    this.active = false,
    this.compact = false,
    this.onTap,
  });

  final String label;
  final Color color;
  final bool active;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final bg = active ? cs.onSurface : cs.surfaceContainerLow;
    final fg = active ? cs.surface : cs.onSurface.withValues(alpha: 0.75);
    final border = active ? cs.onSurface : cs.outline;

    final padH = compact ? 8.0 : 10.0;
    final padV = compact ? 3.0 : 5.0;
    final fs   = compact ? 11.0 : 12.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6, height: 6,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: fs,
                fontWeight: FontWeight.w500,
                color: fg,
                letterSpacing: -0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
