import 'package:flutter/material.dart';
import 'package:mnemata/core/theme/app_theme.dart';

enum ReaderFontScale { compact, standard, roomy }

enum ReaderVisualTheme { light, sepia, dark }

class ReaderControlsBar extends StatelessWidget {
  const ReaderControlsBar({
    super.key,
    required this.sectionLabel,
    required this.fontScale,
    required this.visualTheme,
    required this.columnWidth,
    required this.canToggleSidePanel,
    required this.isSidePanelVisible,
    required this.onFontScaleChanged,
    required this.onVisualThemeChanged,
    required this.onColumnWidthChanged,
    required this.onOpenOriginal,
    required this.onShare,
    required this.onMore,
    this.onSidePanelToggled,
  });

  final String sectionLabel;
  final ReaderFontScale fontScale;
  final ReaderVisualTheme visualTheme;
  final double columnWidth;
  final bool canToggleSidePanel;
  final bool isSidePanelVisible;

  final ValueChanged<ReaderFontScale> onFontScaleChanged;
  final ValueChanged<ReaderVisualTheme> onVisualThemeChanged;
  final ValueChanged<double> onColumnWidthChanged;
  final ValueChanged<bool>? onSidePanelToggled;

  final VoidCallback onOpenOriginal;
  final VoidCallback onShare;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(MnemataRadii.lg),
        border: Border.all(color: cs.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  sectionLabel,
                  key: const Key('reader-section-indicator'),
                  style: theme.textTheme.mono(
                    size: 11,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Open original',
                icon: const Icon(Icons.open_in_new),
                onPressed: onOpenOriginal,
              ),
              IconButton(
                tooltip: 'Share',
                icon: const Icon(Icons.ios_share),
                onPressed: onShare,
              ),
              if (canToggleSidePanel)
                IconButton(
                  tooltip: isSidePanelVisible
                      ? 'Hide metadata panel'
                      : 'Show metadata panel',
                  icon: Icon(
                    isSidePanelVisible
                        ? Icons.view_sidebar_outlined
                        : Icons.view_sidebar,
                  ),
                  onPressed: () =>
                      onSidePanelToggled?.call(!isSidePanelVisible),
                ),
              IconButton(
                tooltip: 'More',
                icon: const Icon(Icons.more_horiz),
                onPressed: onMore,
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _OptionChip<ReaderFontScale>(
                  label: 'A-',
                  value: ReaderFontScale.compact,
                  groupValue: fontScale,
                  onSelected: onFontScaleChanged,
                ),
                const SizedBox(width: 8),
                _OptionChip<ReaderFontScale>(
                  label: 'A',
                  value: ReaderFontScale.standard,
                  groupValue: fontScale,
                  onSelected: onFontScaleChanged,
                ),
                const SizedBox(width: 8),
                _OptionChip<ReaderFontScale>(
                  label: 'A+',
                  value: ReaderFontScale.roomy,
                  groupValue: fontScale,
                  onSelected: onFontScaleChanged,
                ),
                const SizedBox(width: 16),
                _OptionChip<double>(
                  label: '640',
                  value: 640,
                  groupValue: columnWidth,
                  onSelected: onColumnWidthChanged,
                ),
                const SizedBox(width: 8),
                _OptionChip<double>(
                  label: '720',
                  value: 720,
                  groupValue: columnWidth,
                  onSelected: onColumnWidthChanged,
                ),
                const SizedBox(width: 8),
                _OptionChip<double>(
                  label: '840',
                  value: 840,
                  groupValue: columnWidth,
                  onSelected: onColumnWidthChanged,
                ),
                const SizedBox(width: 16),
                _OptionChip<ReaderVisualTheme>(
                  label: 'Light',
                  value: ReaderVisualTheme.light,
                  groupValue: visualTheme,
                  onSelected: onVisualThemeChanged,
                ),
                const SizedBox(width: 8),
                _OptionChip<ReaderVisualTheme>(
                  label: 'Sepia',
                  value: ReaderVisualTheme.sepia,
                  groupValue: visualTheme,
                  onSelected: onVisualThemeChanged,
                ),
                const SizedBox(width: 8),
                _OptionChip<ReaderVisualTheme>(
                  label: 'Dark',
                  value: ReaderVisualTheme.dark,
                  groupValue: visualTheme,
                  onSelected: onVisualThemeChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionChip<T> extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.value,
    required this.groupValue,
    required this.onSelected,
  });

  final String label;
  final T value;
  final T groupValue;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final selected = value == groupValue;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      shape: const StadiumBorder(),
      side: BorderSide(color: selected ? cs.primary : cs.outline),
      selectedColor: cs.primary.withValues(alpha: 0.18),
      backgroundColor: cs.surface,
      labelStyle: selected
          ? Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: cs.onSurface)
          : Theme.of(context).textTheme.labelMedium,
      onSelected: (_) => onSelected(value),
    );
  }
}
