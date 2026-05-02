import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/core/theme/app_theme.dart';
import 'package:mnemata/features/intelligence/services/tag_suggestion_service.dart';

class _SheetDragHandle extends StatelessWidget {
  const _SheetDragHandle();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12, bottom: 16),
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: cs.outlineVariant,
          borderRadius: BorderRadius.circular(MnemataRadii.sm),
        ),
      ),
    );
  }
}

class LabelSelectorSheet extends StatefulWidget {
  final MnemataItem item;
  final TagSuggestionService? suggestionService;

  const LabelSelectorSheet({
    super.key,
    required this.item,
    this.suggestionService,
  });

  static Future<void> show(
    BuildContext context,
    MnemataItem item, {
    TagSuggestionService? suggestionService,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => LabelSelectorSheet(
        item: item,
        suggestionService: suggestionService,
      ),
    );
  }

  @override
  State<LabelSelectorSheet> createState() => _LabelSelectorSheetState();
}

class _LabelSelectorSheetState extends State<LabelSelectorSheet> {
  bool _isLoadingSuggestions = false;
  TagSuggestionResult? _suggestions;
  final Set<int> _selectedSuggestedIds = {};

  Future<void> _generateSuggestions() async {
    if (widget.suggestionService == null) return;
    setState(() {
      _isLoadingSuggestions = true;
      _selectedSuggestedIds.clear();
    });
    try {
      final result = await widget.suggestionService!.suggestForItem(widget.item);
      if (mounted) {
        setState(() {
          _suggestions = result;
          _isLoadingSuggestions = false;
          if (result.isSuccess) {
            _selectedSuggestedIds.addAll(result.suggestedLabels.map((l) => l.id));
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingSuggestions = false;
          _suggestions = const TagSuggestionResult(
            status: TagSuggestionStatus.error,
            suggestedLabels: [],
            guidance: 'Failed to generate suggestions. Please try again.',
          );
        });
      }
    }
  }

  Future<void> _applySuggestions(AppDatabase database) async {
    if (_suggestions == null || !_suggestions!.isSuccess) return;
    final labelsToApply = _suggestions!.suggestedLabels
        .where((l) => _selectedSuggestedIds.contains(l.id))
        .toList();
    
    for (final label in labelsToApply) {
      await database.assignLabelToItem(widget.item.id, label.id);
    }
    
    if (mounted) {
      setState(() {
        _suggestions = null;
        _selectedSuggestedIds.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Applied ${labelsToApply.length} suggestions')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final database = GetIt.instance<AppDatabase>();
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetDragHandle(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'LABELS \u00B7 MANAGE',
                  style: theme.textTheme.tracked(cs.secondary),
                ),
                if (widget.suggestionService != null && _suggestions == null)
                  TextButton.icon(
                    onPressed: _isLoadingSuggestions ? null : _generateSuggestions,
                    icon: _isLoadingSuggestions 
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.auto_awesome, size: 16),
                    label: const Text('AI Suggestions'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Manage Labels',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            
            if (_suggestions != null) ...[
              Text(
                'AI SUGGESTIONS',
                style: theme.textTheme.tracked(cs.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              if (!_suggestions!.isSuccess)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_suggestions!.guidance, style: TextStyle(color: cs.error)),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _generateSuggestions,
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Retry'),
                    ),
                  ],
                )
              else if (_suggestions!.suggestedLabels.isEmpty)
                const Text('No suggestions found for this content.')
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _suggestions!.suggestedLabels.map((label) {
                    final isSelected = _selectedSuggestedIds.contains(label.id);
                    return FilterChip(
                      label: Text(label.name),
                      selected: isSelected,
                      onSelected: (val) {
                        setState(() {
                          if (val) _selectedSuggestedIds.add(label.id);
                          else _selectedSuggestedIds.remove(label.id);
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      _suggestions = null;
                      _selectedSuggestedIds.clear();
                    }),
                    child: const Text('CANCEL'),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _selectedSuggestedIds.isEmpty ? null : () => _applySuggestions(database),
                    child: const Text('APPLY'),
                  ),
                ],
              ),
              const Divider(height: 32),
            ],

            Flexible(
              child: StreamBuilder<List<Label>>(
                stream: database.watchAllLabels(),
                builder: (context, allLabelsSnapshot) {
                  if (!allLabelsSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allLabels = allLabelsSnapshot.data!;
                  if (allLabels.isEmpty) {
                    return Center(
                      child: Text(
                        'No labels created yet. Go to Label Manager to add some.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }

                  return StreamBuilder<List<Label>>(
                    stream: database.watchLabelsForItem(widget.item.id),
                    builder: (context, itemLabelsSnapshot) {
                      final assignedLabelIds = (itemLabelsSnapshot.data ?? [])
                          .map((l) => l.id)
                          .toSet();

                      return ListView.builder(
                        shrinkWrap: true,
                        itemCount: allLabels.length,
                        itemBuilder: (context, index) {
                          final label = allLabels[index];
                          final isAssigned =
                              assignedLabelIds.contains(label.id);

                          return CheckboxListTile(
                            title: Text(
                              label.name,
                              style: theme.textTheme.bodyLarge,
                            ),
                            secondary: Icon(
                              Icons.label,
                              color: label.color != null
                                  ? Color(label.color!)
                                  : cs.primary,
                            ),
                            value: isAssigned,
                            onChanged: (bool? value) {
                              if (value == true) {
                                database.assignLabelToItem(widget.item.id, label.id);
                              } else {
                                database.removeLabelFromItem(
                                    widget.item.id, label.id);
                              }
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BulkLabelSelectorSheet extends StatelessWidget {
  final List<int> itemIds;

  const BulkLabelSelectorSheet({super.key, required this.itemIds});

  static Future<void> show(BuildContext context, List<int> itemIds) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => BulkLabelSelectorSheet(itemIds: itemIds),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final database = GetIt.instance<AppDatabase>();
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SheetDragHandle(),
            Text(
              'LABELS \u00B7 BULK ASSIGN',
              style: theme.textTheme.tracked(cs.secondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Assign Labels to ${itemIds.length} items',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: StreamBuilder<List<Label>>(
                stream: database.watchAllLabels(),
                builder: (context, allLabelsSnapshot) {
                  if (!allLabelsSnapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final allLabels = allLabelsSnapshot.data!;
                  if (allLabels.isEmpty) {
                    return Center(
                      child: Text(
                        'No labels created yet. Go to Label Manager to add some.',
                        style: theme.textTheme.bodyMedium,
                      ),
                    );
                  }

                  // In bulk mode, we might not easily show "mixed" state natively without
                  // complex querying. Let's just show a clean list. If a user checks it,
                  // it adds to all. If they uncheck it, it removes from all.
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: allLabels.length,
                    itemBuilder: (context, index) {
                      final label = allLabels[index];

                      return ListTile(
                        title: Text(
                          label.name,
                          style: theme.textTheme.bodyLarge,
                        ),
                        leading: Icon(
                          Icons.label,
                          color: label.color != null
                              ? Color(label.color!)
                              : cs.primary,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(
                                Icons.add_circle_outline,
                                color: cs.primary,
                              ),
                              onPressed: () {
                                database.assignLabelToItems(
                                    itemIds, label.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Added label to items'),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                Icons.remove_circle_outline,
                                color: cs.error,
                              ),
                              onPressed: () {
                                database.removeLabelFromItems(
                                    itemIds, label.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        'Removed label from items'),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
