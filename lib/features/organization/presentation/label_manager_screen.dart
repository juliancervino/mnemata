import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get_it/get_it.dart';
import 'package:drift/drift.dart' as drift;
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/core/theme/app_theme.dart';
import 'package:mnemata/core/widgets/section_label.dart';
import 'package:mnemata/core/widgets/tag_chip.dart';

class LabelManagerScreen extends StatefulWidget {
  const LabelManagerScreen({super.key});

  @override
  State<LabelManagerScreen> createState() => _LabelManagerScreenState();
}

class _LabelManagerScreenState extends State<LabelManagerScreen> {
  final _nameController = TextEditingController();
  bool _isFolder = false;
  Color _selectedColor = MnemataColors.tag1;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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

  void _addLabel() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final database = GetIt.instance<AppDatabase>();
    database.insertLabel(LabelsCompanion.insert(
      name: name,
      color: drift.Value(_selectedColor.toARGB32()),
      isFolder: drift.Value(_isFolder),
    ));

    _nameController.clear();
    setState(() {
      _isFolder = false;
      _selectedColor = MnemataColors.tag1;
    });
  }

  void _editLabel(Label label) {
    final nameController = TextEditingController(text: label.name);
    Color editColor =
        label.color != null ? Color(label.color!) : MnemataColors.tag1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Label'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Color'),
                trailing: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(shape: BoxShape.circle, color: editColor),
                ),
                onTap: () => _pickColor(context, editColor, (color) {
                  setDialogState(() => editColor = color);
                }),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () {
                final database = GetIt.instance<AppDatabase>();
                database.updateLabel(LabelsCompanion(
                  id: drift.Value(label.id),
                  name: drift.Value(nameController.text.trim()),
                  color: drift.Value(editColor.toARGB32()),
                ));
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final database = GetIt.instance<AppDatabase>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 8),
                    child: SectionLabel('Organization'),
                  ),
                  Text(
                    'Labels',
                    style: theme.textTheme.displaySmall,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(MnemataRadii.lg),
                  border: Border.all(color: cs.outline, width: 0.5),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _pickColor(context, _selectedColor, (color) {
                        setState(() => _selectedColor = color);
                      }),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedColor,
                          border: Border.all(color: cs.outline, width: 0.5),
                        ),
                        child: Icon(
                          Icons.palette,
                          size: 16,
                          color: cs.surface,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: theme.textTheme.bodyLarge,
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'New label name',
                          isDense: true,
                          filled: false,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add label',
                      icon: const Icon(Icons.add_circle_outline),
                      color: cs.onSurface,
                      onPressed: _addLabel,
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: SectionLabel('All labels'),
            ),
            Expanded(
              child: StreamBuilder<List<Label>>(
                stream: database.watchAllLabels(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final labels = snapshot.data!;
                  if (labels.isEmpty) {
                    return Center(
                      child: Text(
                        'No labels created yet.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(MnemataRadii.lg),
                      child: Container(
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLow,
                          borderRadius:
                              BorderRadius.circular(MnemataRadii.lg),
                          border:
                              Border.all(color: cs.outline, width: 0.5),
                        ),
                        child: ListView.separated(
                          itemCount: labels.length,
                          separatorBuilder: (_, _) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final label = labels[index];
                            final color = label.color != null
                                ? Color(label.color!)
                                : MnemataColors.tag1;

                            return _LabelRow(
                              label: label,
                              color: color,
                              onEdit: () => _editLabel(label),
                              onDelete: () =>
                                  database.deleteLabel(label.id),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  const _LabelRow({
    required this.label,
    required this.color,
    required this.onEdit,
    required this.onDelete,
  });

  final Label label;
  final Color color;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                TagChip(label: label.name, color: color, compact: true),
                const SizedBox(width: 12),
                if (label.isFolder)
                  Text(
                    'folder',
                    style: theme.textTheme.mono(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit label',
            icon: const Icon(Icons.edit_outlined),
            color: cs.onSurfaceVariant,
            onPressed: onEdit,
          ),
          IconButton(
            tooltip: 'Delete label',
            icon: const Icon(Icons.delete_outline),
            color: cs.error,
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
