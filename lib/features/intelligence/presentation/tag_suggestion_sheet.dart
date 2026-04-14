import 'package:flutter/material.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/intelligence/services/tag_suggestion_service.dart';

class TagSuggestionSheet extends StatefulWidget {
  const TagSuggestionSheet({
    super.key,
    required this.item,
    required this.service,
  });

  final MnemataItem item;
  final TagSuggestionService service;

  @override
  State<TagSuggestionSheet> createState() => _TagSuggestionSheetState();
}

class _TagSuggestionSheetState extends State<TagSuggestionSheet> {
  bool _isLoading = false;
  TagSuggestionResult? _result;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Tag Suggestions', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _isLoading ? null : _generate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Suggest from existing tags'),
            ),
            const SizedBox(height: 12),
            if (_isLoading) const LinearProgressIndicator(),
            if (_result != null) ...[
              if (!_result!.isSuccess)
                Text(
                  _result!.guidance,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                )
              else if (_result!.suggestedLabels.isEmpty)
                const Text('No matching existing tags found for this content.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _result!.suggestedLabels
                      .map((label) => Chip(label: Text(label.name)))
                      .toList(growable: false),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Ignore'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: (_result?.isSuccess == true &&
                            (_result?.suggestedLabels.isNotEmpty ?? false))
                        ? _apply
                        : null,
                    child: const Text('Apply'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _generate() async {
    setState(() => _isLoading = true);
    final result = await widget.service.suggestForItem(widget.item);
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
      _result = result;
    });
  }

  Future<void> _apply() async {
    final labels = _result?.suggestedLabels ?? const <Label>[];
    await widget.service.applySuggestions(itemId: widget.item.id, labels: labels);
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Applied ${labels.length} existing tags.')),
    );
  }
}
