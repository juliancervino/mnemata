import 'package:flutter/material.dart';

class SemanticModeToggle extends StatelessWidget {
  const SemanticModeToggle({
    super.key,
    required this.enabled,
    required this.semanticSelected,
    required this.onChanged,
  });

  final bool enabled;
  final bool semanticSelected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<bool>(
      segments: const <ButtonSegment<bool>>[
        ButtonSegment<bool>(value: false, label: Text('Keyword')),
        ButtonSegment<bool>(value: true, label: Text('Semantic')),
      ],
      selected: <bool>{semanticSelected},
      onSelectionChanged: (selection) {
        final next = selection.first;
        if (next && !enabled) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Semantic mode needs an API key in Settings > Intelligence.',
              ),
            ),
          );
          return;
        }
        onChanged(next);
      },
    );
  }
}
