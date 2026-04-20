import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mnemata/core/theme/app_theme.dart';

class ReaderSidePanel extends StatelessWidget {
  const ReaderSidePanel({
    super.key,
    required this.source,
    required this.readTime,
    required this.createdAt,
    required this.sectionLabels,
    required this.activeSection,
    required this.onSelectSection,
  });

  final String source;
  final String readTime;
  final DateTime createdAt;
  final List<String> sectionLabels;
  final int activeSection;
  final ValueChanged<int> onSelectSection;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      key: const Key('reader-side-panel'),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(MnemataRadii.lg),
        border: Border.all(color: cs.outline),
      ),
      padding: const EdgeInsets.all(16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minHeight = constraints.hasBoundedHeight
              ? constraints.maxHeight
              : 0.0;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: minHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reader', style: theme.textTheme.tracked(cs.secondary)),
                  const SizedBox(height: 8),
                  Text(
                    DateFormat('MMM d, yyyy').format(createdAt),
                    style: theme.textTheme.bodyMedium,
                  ),
                  if (source.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        source,
                        style: theme.textTheme.mono(
                          size: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  if (readTime.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        readTime,
                        style: theme.textTheme.mono(
                          size: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Divider(color: cs.outline),
                  const SizedBox(height: 12),
                  Text(
                    'Sections',
                    style: theme.textTheme.tracked(cs.secondary),
                  ),
                  const SizedBox(height: 8),
                  ...List<Widget>.generate(sectionLabels.length, (index) {
                    final isActive = index == activeSection;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: TextButton(
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          backgroundColor: isActive
                              ? cs.primary.withValues(alpha: 0.18)
                              : cs.surface,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              MnemataRadii.md,
                            ),
                            side: BorderSide(
                              color: isActive ? cs.primary : cs.outline,
                            ),
                          ),
                        ),
                        onPressed: () => onSelectSection(index),
                        child: Text(sectionLabels[index]),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
