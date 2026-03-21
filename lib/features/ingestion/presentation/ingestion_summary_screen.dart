import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:drift/drift.dart' as drift;
import 'package:mnemata/core/database/app_database.dart';

class IngestionSummaryScreen extends StatefulWidget {
  final String? title;
  final String? content;
  final String? url;
  final String? filePath;
  final String? thumbnailUrl;
  final String type; // 'url' or 'file'

  const IngestionSummaryScreen({
    super.key,
    this.title,
    this.content,
    this.url,
    this.filePath,
    this.thumbnailUrl,
    required this.type,
  });

  @override
  State<IngestionSummaryScreen> createState() => _IngestionSummaryScreenState();
}

class _IngestionSummaryScreenState extends State<IngestionSummaryScreen> {
  late TextEditingController _titleController;
  final Set<int> _selectedLabelIds = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final database = GetIt.instance<AppDatabase>();
    
    // 1. Insert the item
    final id = await database.insertItem(MnemataItemsCompanion.insert(
      title: drift.Value(_titleController.text),
      url: drift.Value(widget.url),
      filePath: drift.Value(widget.filePath),
      content: drift.Value(widget.content),
      thumbnailUrl: drift.Value(widget.thumbnailUrl),
      type: widget.type,
      createdAt: DateTime.now(),
    ));

    // 2. Assign selected labels
    for (final labelId in _selectedLabelIds) {
      await database.assignLabelToItem(id, labelId);
    }

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item saved successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final database = GetIt.instance<AppDatabase>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Item'),
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: const Text('SAVE', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.thumbnailUrl != null)
              Center(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.thumbnailUrl!,
                    height: 150,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                  ),
                ),
              ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            if (widget.url != null)
              Text(
                'Source: ${widget.url}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (widget.filePath != null)
              Text(
                'File: ${widget.filePath!.split('/').last}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 24),
            Text(
              'Assign Labels',
              style: Theme.of(context).textTheme.titleMedium,
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
                        label.isFolder ? Icons.folder : Icons.label,
                        size: 16,
                        color: label.color != null ? Color(label.color!) : null,
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
    );
  }
}
