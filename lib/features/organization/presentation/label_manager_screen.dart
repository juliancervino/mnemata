import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:get_it/get_it.dart';
import 'package:drift/drift.dart' as drift;
import 'package:mnemata/core/database/app_database.dart';

class LabelManagerScreen extends StatefulWidget {
  const LabelManagerScreen({super.key});

  @override
  State<LabelManagerScreen> createState() => _LabelManagerScreenState();
}

class _LabelManagerScreenState extends State<LabelManagerScreen> {
  final _nameController = TextEditingController();
  bool _isFolder = false;
  Color _selectedColor = Colors.blue;

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
      color: drift.Value(_selectedColor.value),
      isFolder: drift.Value(_isFolder),
    ));

    _nameController.clear();
    setState(() {
      _isFolder = false;
      _selectedColor = Colors.blue;
    });
  }

  void _editLabel(Label label) {
    final nameController = TextEditingController(text: label.name);
    Color editColor = label.color != null ? Color(label.color!) : (label.isFolder ? Colors.amber : Colors.blue);

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
                  color: drift.Value(editColor.value),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Labels'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _pickColor(context, _selectedColor, (color) {
                    setState(() => _selectedColor = color);
                  }),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _selectedColor,
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: const Icon(Icons.palette, size: 18, color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'New Label/Folder Name',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    const Text('Folder?', style: TextStyle(fontSize: 10)),
                    Switch(
                      value: _isFolder,
                      onChanged: (v) => setState(() => _isFolder = v),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.blue, size: 32),
                  onPressed: _addLabel,
                ),
              ],
            ),
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<Label>>(
              stream: database.watchAllLabels(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final labels = snapshot.data!;
                if (labels.isEmpty) {
                  return const Center(child: Text('No labels created yet.'));
                }

                return ListView.builder(
                  itemCount: labels.length,
                  itemBuilder: (context, index) {
                    final label = labels[index];
                    final color = label.color != null ? Color(label.color!) : (label.isFolder ? Colors.amber : Colors.blue);
                    
                    return ListTile(
                      leading: Icon(
                        label.isFolder ? Icons.folder : Icons.label,
                        color: color,
                      ),
                      title: Text(label.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () => _editLabel(label),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () => database.deleteLabel(label.id),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
