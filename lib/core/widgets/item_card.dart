// ItemCard — Mnemata
// Copia a: lib/core/widgets/item_card.dart
//
// Fila de item en la lista cronológica:
//   thumb | [source mono · read time]  título serif  [tag dots]

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ItemCardData {
  final String title;
  final String source;
  final String readTime;
  final List<({String label, Color color})> tags;
  final Color thumbTone;   // tono dominante para el placeholder
  final String? thumbUrl;  // si hay imagen real
  final String typeGlyph;  // 'A' article, 'pdf', '◦' image

  const ItemCardData({
    required this.title,
    required this.source,
    required this.readTime,
    required this.tags,
    required this.thumbTone,
    this.thumbUrl,
    this.typeGlyph = 'A',
  });
}

class ItemCard extends StatelessWidget {
  const ItemCard({
    super.key,
    required this.data,
    this.active = false,
    this.compact = false,
    this.onTap,
  });

  final ItemCardData data;
  final bool active;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final thumbSize = compact ? 44.0 : 58.0;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 24 : 20,
          vertical: compact ? 12 : 14,
        ),
        decoration: BoxDecoration(
          color: active ? cs.surfaceContainerLow : Colors.transparent,
          border: active
              ? Border(left: BorderSide(color: cs.primary, width: 2))
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Thumb(size: thumbSize, tone: data.thumbTone, glyph: data.typeGlyph),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta row
                  Row(
                    children: [
                      Text(
                        data.source,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: cs.onSurfaceVariant,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        width: 2, height: 2,
                        decoration: BoxDecoration(
                          color: cs.outlineVariant,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        data.readTime,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 10,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Title — serif
                  Text(
                    data.title,
                    style: theme.textTheme.titleLarge!.copyWith(
                      fontSize: compact ? 15 : 18,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  // Tag dots
                  Wrap(
                    spacing: 10,
                    runSpacing: 4,
                    children: data.tags.map((t) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5, height: 5,
                          decoration: BoxDecoration(
                            color: t.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          t.label,
                          style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ],
                    )).toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({required this.size, required this.tone, required this.glyph});
  final double size;
  final Color tone;
  final String glyph;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [tone.withValues(alpha: 0.35), tone.withValues(alpha: 0.55)],
        ),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: cs.outline, width: 0.5),
      ),
      alignment: Alignment.center,
      child: Text(
        glyph,
        style: TextStyle(
          fontFamily: 'serif',
          fontStyle: FontStyle.italic,
          fontSize: size * 0.32,
          color: cs.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

/// Section label: "TODAY · APR 16"
class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.jetBrainsMono(
          fontSize: 10,
          letterSpacing: 1.2,
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
