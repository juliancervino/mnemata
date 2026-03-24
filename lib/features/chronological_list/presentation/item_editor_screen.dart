import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get_it/get_it.dart';
import 'package:drift/drift.dart' as drift;
import 'package:mnemata/core/database/app_database.dart';

class ItemEditorScreen extends StatefulWidget {
  final MnemataItem item;

  const ItemEditorScreen({super.key, required this.item});

  @override
  State<ItemEditorScreen> createState() => _ItemEditorScreenState();
}

class _ItemEditorScreenState extends State<ItemEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _urlController;
  final Set<int> _selectedLabelIds = {};
  bool _isLoadingLabels = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _urlController = TextEditingController(text: widget.item.url);
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
    super.dispose();
  }

  Future<void> _handleSave({bool pop = true}) async {
    final database = GetIt.instance<AppDatabase>();
    
    // 1. Update basic details
    await database.updateItemDetails(
      widget.item.id,
      _titleController.text.trim(),
      _urlController.text.trim().isEmpty ? null : _urlController.text.trim(),
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
        content: const Text('Are you sure you want to delete this item?'),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item deleted')),
        );
      }
    }
  }

  void _pickColor(BuildContext context, Color initialColor, Function(Color) onColorChanged) {
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
                  decoration: BoxDecoration(shape: BoxShape.circle, color: selectedColor),
                ),
                onTap: () => _pickColor(context, selectedColor, (color) {
                  setDialogState(() => selectedColor = color);
                }),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
            TextButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isNotEmpty) {
                  final id = await database.insertLabel(LabelsCompanion.insert(
                    name: name,
                    color: drift.Value(selectedColor.value),
                  ));
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

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) async {
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Labels',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  TextButton.icon(
                    onPressed: () => _showAddTagDialog(context, database),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Tag'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              StreamBuilder<List<Label>>(
                stream: database.watchAllLabels(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final labels = snapshot.data!;
                  if (labels.isEmpty) return const Text('No labels created yet.');

                  return Wrap(
                    spacing: 8,
                    children: labels.map((label) {
                      final isSelected = _selectedLabelIds.contains(label.id);
                      return FilterChip(
                        label: Text(label.name),
                        selected: isSelected,
                        avatar: Icon(
                          Icons.label,
                          size: 16,
                          color: label.color != null ? Color(label.color!) : Colors.blue,
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
