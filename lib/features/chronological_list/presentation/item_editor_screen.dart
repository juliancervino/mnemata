import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get_it/get_it.dart';
import 'package:drift/drift.dart' as drift;
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/core/theme/app_theme.dart';
import 'package:mnemata/features/intelligence/services/ai_plain_text.dart';
import 'package:mnemata/features/intelligence/services/tag_suggestion_service.dart';

class ItemEditorScreen extends StatefulWidget {
  final MnemataItem item;

  const ItemEditorScreen({super.key, required this.item});

  @override
  State<ItemEditorScreen> createState() => _ItemEditorScreenState();
}

class _ItemEditorScreenState extends State<ItemEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _urlController;
  late TextEditingController _authorController;
  final Set<int> _selectedLabelIds = {};
  bool _isLoadingLabels = true;

  // AI Suggestions state
  bool _isLoadingAI = false;
  TagSuggestionResult? _aiSuggestions;
  final Set<int> _selectedAIIds = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _urlController = TextEditingController(text: widget.item.url);
    _authorController = TextEditingController(text: widget.item.author);
    _loadInitialLabels();
  }

  Future<void> _loadInitialLabels() async {
    final database = GetIt.instance<AppDatabase>();
    final labels = await database.watchLabelsForItem(widget.item.id).first;
    setState(() {
      _selectedLabelIds.addAll(labels.map((l) => l.id));
      _isLoadingLabels = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _urlController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _generateAISuggestions() async {
    final service = GetIt.instance<TagSuggestionService>();
    setState(() {
      _isLoadingAI = true;
      _selectedAIIds.clear();
    });
    try {
      final result = await service.suggestForItem(widget.item);
      if (mounted) {
        setState(() {
          _aiSuggestions = result;
          _isLoadingAI = false;
          if (result.isSuccess) {
            _selectedAIIds.addAll(result.suggestedLabels.map((l) => l.id));
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoadingAI = false;
          _aiSuggestions = const TagSuggestionResult(
            status: TagSuggestionStatus.error,
            suggestedLabels: [],
            guidance: 'Failed to generate suggestions. Please try again.',
          );
        });
      }
    }
  }

  void _applyAISuggestions() {
    if (_aiSuggestions == null || !_aiSuggestions!.isSuccess) return;
    setState(() {
      _selectedLabelIds.addAll(_selectedAIIds);
      _aiSuggestions = null;
      _selectedAIIds.clear();
    });
  }

  Future<void> _handleSave({bool pop = true}) async {
    final database = GetIt.instance<AppDatabase>();

    // 1. Update basic details
    await database.updateItemDetails(
      widget.item.id,
      _titleController.text.trim(),
      _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
      _authorController.text.trim().isEmpty
          ? null
          : _authorController.text.trim(),
    );

    // 2. Update labels (Clear and re-assign)
    await database.clearLabelsForItem(widget.item.id);
    for (final labelId in _selectedLabelIds) {
      await database.assignLabelToItem(widget.item.id, labelId);
    }

    if (pop && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated successfully')),
      );
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Item'),
        content: const Text(
          'Move this item to the recycle bin? You can restore it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final database = GetIt.instance<AppDatabase>();
      await database.deleteItem(widget.item.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          const SnackBar(content: Text('Item moved to recycle bin')),
        );
      }
    }
  }

  void _pickColor(
    BuildContext context,
    Color initialColor,
    Function(Color) onColorChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          child: BlockPicker(
            pickerColor: initialColor,
            onColorChanged: (color) {
              onColorChanged(color);
              Navigator.of(context).pop();
            },
          ),
        ),
      ),
    );
  }

  void _showAddTagDialog(BuildContext context, AppDatabase database) {
    final nameController = TextEditingController();
    Color selectedColor = Colors.blue;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add New Tag'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Tag Name'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Color'),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selectedColor,
                  ),
                ),
                onTap: () => _pickColor(context, selectedColor, (color) {
                  setDialogState(() => selectedColor = color);
                }),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCEL'),
            ),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final id = await database.insertLabel(
                    LabelsCompanion.insert(
                      name: name,
                      color: drift.Value(selectedColor.toARGB32()),
                    ),
                  );
                  setState(() {
                    _selectedLabelIds.add(id);
                  });
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('ADD'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final database = GetIt.instance<AppDatabase>();
    final cs = Theme.of(context).colorScheme;

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) {
          await _handleSave(pop: false);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Item'),
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _handleDelete,
            ),
          ],
        ),
        body: _isLoadingLabels
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'URL (optional)',
                        border: OutlineInputBorder(),
                      ),
                      enabled: widget.item.type == 'url',
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _authorController,
                      decoration: const InputDecoration(
                        labelText: 'Author (optional)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Labels',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Row(
                          children: [
                            if (_aiSuggestions == null)
                              TextButton.icon(
                                onPressed: _isLoadingAI ? null : _generateAISuggestions,
                                icon: _isLoadingAI 
                                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                  : const Icon(Icons.auto_awesome, size: 16),
                                label: const Text('AI Suggestions'),
                              ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: () => _showAddTagDialog(context, database),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add Tag'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    if (_aiSuggestions != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(MnemataRadii.md),
                          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('AI SUGGESTIONS', style: Theme.of(context).textTheme.labelSmall?.copyWith(letterSpacing: 1)),
                            const SizedBox(height: 8),
                            if (!_aiSuggestions!.isSuccess)
                              Text(_aiSuggestions!.guidance, style: TextStyle(color: Theme.of(context).colorScheme.error))
                            else if (_aiSuggestions!.suggestedLabels.isEmpty)
                              const Text('No suggestions found.')
                            else
                              Builder(
                                builder: (context) {
                                  final newSuggestions = _aiSuggestions!.suggestedLabels
                                      .where((l) => !_selectedLabelIds.contains(l.id))
                                      .toList();
                                  if (newSuggestions.isEmpty) {
                                    return const Text('All suggested labels are already applied.');
                                  }
                                  return Wrap(
                                    spacing: 8,
                                    children: newSuggestions.map((l) {
                                      final isSelected = _selectedAIIds.contains(l.id);
                                      return FilterChip(
                                        label: Text(l.name),
                                        selected: isSelected,
                                        onSelected: (val) {
                                          setState(() {
                                            if (val) _selectedAIIds.add(l.id);
                                            else _selectedAIIds.remove(l.id);
                                          });
                                        },
                                      );
                                    }).toList(),
                                  );
                                },
                              ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(onPressed: () => setState(() => _aiSuggestions = null), child: const Text('CANCEL')),
                                const SizedBox(width: 8),
                                FilledButton(
                                  onPressed: _selectedAIIds.isEmpty ? null : _applyAISuggestions, 
                                  child: const Text('APPLY'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    StreamBuilder<List<Label>>(
                      stream: database.watchAllLabels(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final allLabels = snapshot.data!;
                        final filteredLabels = allLabels
                            .where(
                              (label) =>
                                  _selectedLabelIds.contains(label.id) ||
                                  !looksLikeDomainLabel(label.name),
                            )
                            .toList();
                        
                        final assignedLabels = filteredLabels.where((l) => _selectedLabelIds.contains(l.id)).toList()
                          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                        final unassignedLabels = filteredLabels.where((l) => !_selectedLabelIds.contains(l.id)).toList()
                          ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
                        
                        final sortedLabels = [...assignedLabels, ...unassignedLabels];

                        if (sortedLabels.isEmpty) {
                          return const Text('No labels created yet.');
                        }

                        return Wrap(
                          spacing: 8,
                          children: sortedLabels.map((label) {
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
                                    : cs.primary,
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
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
