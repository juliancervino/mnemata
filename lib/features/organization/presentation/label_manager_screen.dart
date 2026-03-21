import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addLabel() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final database = GetIt.instance<AppDatabase>();
    database.insertLabel(LabelsCompanion.insert(
      name: name,
      isFolder: drift.Value(_isFolder),
    ));

    _nameController.clear();
    setState(() {
      _isFolder = false;
    });
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
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      hintText: 'New Label/Folder Name',
                    ),
                  ),
                ),
                Column(
                  children: [
                    const Text('Folder?'),
                    Switch(
                      value: _isFolder,
                      onChanged: (v) => setState(() => _isFolder = v),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.add),
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
                    return ListTile(
                      leading: Icon(
                        label.isFolder ? Icons.folder : Icons.label,
                        color: label.isFolder ? Colors.amber : Colors.blue,
                      ),
                      title: Text(label.name),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => database.deleteLabel(label.id),
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
