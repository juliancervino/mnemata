import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:get_it/get_it.dart';
import 'package:drift/drift.dart' as drift;
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/core/theme/app_theme.dart';
import 'package:mnemata/features/intelligence/services/ai_plain_text.dart';
import 'package:mnemata/features/intelligence/services/semantic_indexer_service.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';

enum IngestionSummaryResult { saved, discarded }

class IngestionSummaryScreen extends StatefulWidget {
  final String? title;
  final String? content;
  final String? author;
  final String? url;
  final String? originalUrl;
  final String? filePath;
  final String? thumbnailUrl;
  final String type; // 'url' or 'file'
  final List<String> initialHighlights;

  const IngestionSummaryScreen({
    super.key,
    this.title,
    this.content,
    this.author,
    this.url,
    this.originalUrl,
    this.filePath,
    this.thumbnailUrl,
    required this.type,
    this.initialHighlights = const [],
  });

  @override
  State<IngestionSummaryScreen> createState() => _IngestionSummaryScreenState();
}

class _IngestionSummaryScreenState extends State<IngestionSummaryScreen> {
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  final Set<int> _selectedLabelIds = {};
  bool _isClosing = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.title);
    _authorController = TextEditingController(text: widget.author);
    _initializeAutoTags();
  }

  Future<void> _initializeAutoTags() async {
    final database = GetIt.instance<AppDatabase>();
    final settingsService = GetIt.instance<SettingsService>();

    if (settingsService.autoTagYear) {
      final yearStr = DateTime.now().year.toString();
      final yearTagId = await database.getOrCreateLabel(
        yearStr,
        color: MnemataColors.tag6.toARGB32(),
      );
      if (mounted) setState(() => _selectedLabelIds.add(yearTagId));
    }

    if (settingsService.autoTagDomain) {
      final tagUrl = widget.originalUrl ?? widget.url;
      if (tagUrl != null) {
        try {
          final uri = Uri.parse(tagUrl);
          if (uri.host.isNotEmpty) {
            final hostStr = uri.host.replaceFirst('www.', '');
            final domainTagId = await database.getOrCreateLabel(
              hostStr,
              color: MnemataColors.tag2.toARGB32(),
            );
            if (mounted) setState(() => _selectedLabelIds.add(domainTagId));
          }
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    final database = GetIt.instance<AppDatabase>();
    final semanticIndexer = GetIt.instance<SemanticIndexerService>();

    // 1. Insert the item
    final id = await database.insertItem(
      MnemataItemsCompanion.insert(
        title: drift.Value(_titleController.text),
        url: drift.Value(widget.url),
        filePath: drift.Value(widget.filePath),
        content: drift.Value(widget.content),
        author: drift.Value(
          _authorController.text.trim().isEmpty
              ? null
              : _authorController.text.trim(),
        ),
        thumbnailUrl: drift.Value(widget.thumbnailUrl),
        type: widget.type,
        createdAt: DateTime.now(),
      ),
    );

    // 2. Assign selected labels (this now includes auto-tags if selected)
    for (final labelId in _selectedLabelIds) {
      await database.assignLabelToItem(id, labelId);
    }

    // 3. Save auto-extracted highlights if any
    if (widget.initialHighlights.isNotEmpty && widget.content != null) {
      for (final quote in widget.initialHighlights) {
        final startIndex = widget.content!.indexOf(quote);
        if (startIndex != -1) {
          final range = {
            'start': startIndex,
            'end': startIndex + quote.length,
          };
          await database.insertAnnotation(
            itemId: id,
            quoteText: quote,
            anchorJson: jsonEncode(range),
          );
        }
      }
    }

    final savedItem = (await database.watchAllItems().first).firstWhere(
      (item) => item.id == id,
    );
    unawaited(semanticIndexer.enqueueIndexing(savedItem));

    if (mounted) {
      _isClosing = true;
      Navigator.of(context).pop(IngestionSummaryResult.saved);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Item saved successfully')));
    }
  }

  void _handleDiscard() {
    if (!mounted || _isClosing) return;
    _isClosing = true;
    Navigator.of(context).pop(IngestionSummaryResult.discarded);
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
    Color selectedColor = Theme.of(context).colorScheme.primary;

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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final database = GetIt.instance<AppDatabase>();

    final sourceLabel = widget.type == 'file' ? 'FILE' : 'URL';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _handleDiscard();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleDiscard,
          ),
          title: const Text('New Item'),
          actions: [
            TextButton(
              onPressed: _handleSave,
              child: const Text('SAVE'),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kicker
                Text(
                  'SAVE \u00B7 $sourceLabel',
                  style: theme.textTheme.tracked(cs.secondary),
                ),
                const SizedBox(height: 8),
                // Title
                Text(
                  'New item',
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 20),
                if (widget.thumbnailUrl != null)
                  Center(
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(MnemataRadii.lg),
                      child: Image.network(
                        widget.thumbnailUrl!,
                        height: 150,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _authorController,
                  decoration: const InputDecoration(
                    labelText: 'Author (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                if (widget.url != null)
                  Text(
                    'Source: ${widget.url}',
                    style: theme.textTheme.bodySmall,
                  ),
                if (widget.filePath != null)
                  Text(
                    'File: ${widget.filePath!.split('/').last}',
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ASSIGN LABELS',
                      style: theme.textTheme.tracked(cs.onSurfaceVariant),
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
                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }
                    final labels = snapshot.data!
                        .where(
                          (label) =>
                              _selectedLabelIds.contains(label.id) ||
                              !looksLikeDomainLabel(label.name),
                        )
                        .toList(growable: false);
                    if (labels.isEmpty) {
                      return Text(
                        'No labels created yet.',
                        style: theme.textTheme.bodyMedium,
                      );
                    }

                    return Wrap(
                      spacing: 8,
                      children: labels.map((label) {
                        final isSelected =
                            _selectedLabelIds.contains(label.id);
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
                const SizedBox(height: 24),
                if (widget.content != null && widget.content!.isNotEmpty) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'CONTENT PREVIEW',
                        style:
                            theme.textTheme.tracked(cs.onSurfaceVariant),
                      ),
                      Text(
                        'Length: ${widget.content!.length} chars',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Raw Snippet: ${widget.content!.substring(0, widget.content!.length > 100 ? 100 : widget.content!.length)}...',
                    style: theme.textTheme.bodySmall!.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      border: Border.all(color: cs.outline),
                      borderRadius:
                          BorderRadius.circular(MnemataRadii.lg),
                    ),
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: SingleChildScrollView(
                      child: HtmlWidget(
                        widget.content!,
                        textStyle: theme.textTheme.bodyLarge,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _handleDiscard,
                        child: const Text('Discard'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _handleSave,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16), // Padding for system buttons
              ],
            ),
          ),
        ),
      ),
    );
  }
}
