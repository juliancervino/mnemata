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
  final Set<int> _selectedLabelIds = <int>{};

  @override
  void initState() {
    super.initState();
    _generate();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AI Tag Suggestions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (_isLoading) const LinearProgressIndicator(),
            if (_result != null) ...[
              if (!_result!.isSuccess)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _result!.guidance,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _isLoading ? null : _generate,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                    ),
                  ],
                )
              else if (_result!.suggestedLabels.isEmpty)
                const Text('No matching existing tags found for this content.')
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select tags to apply',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _result!.suggestedLabels
                          .map((label) {
                            final isSelected = _selectedLabelIds.contains(
                              label.id,
                            );
                            return FilterChip(
                              label: Text(label.name),
                              selected: isSelected,
                              avatar: Icon(
                                Icons.label,
                                size: 16,
                                color: label.color != null
                                    ? Color(label.color!)
                                    : Colors.blue,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedLabelIds.add(label.id);
                                  } else {
                                    _selectedLabelIds.remove(label.id);
                                  }
                                });
                              },
                            );
                          })
                          .toList(growable: false),
                    ),
                  ],
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
                    onPressed:
                        (_result?.isSuccess == true &&
                            _selectedLabelIds.isNotEmpty)
                        ? _apply
                        : null,
                    child: Text('Apply (${_selectedLabelIds.length})'),
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
      _selectedLabelIds
        ..clear()
        ..addAll(result.suggestedLabels.map((label) => label.id));
    });
  }

  Future<void> _apply() async {
    final labels = (_result?.suggestedLabels ?? const <Label>[])
        .where((label) => _selectedLabelIds.contains(label.id))
        .toList(growable: false);
    await widget.service.applySuggestions(
      itemId: widget.item.id,
      labels: labels,
    );
    if (!mounted) {
      return;
    }
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Applied ${labels.length} existing tags.')),
    );
  }
}
