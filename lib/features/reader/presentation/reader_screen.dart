import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/intelligence/presentation/annotation_list_panel.dart';
import 'package:mnemata/features/intelligence/presentation/reader_selection_actions.dart';
import 'package:mnemata/features/intelligence/presentation/summary_panel.dart';
import 'package:mnemata/features/intelligence/presentation/tag_suggestion_sheet.dart';
import 'package:mnemata/features/intelligence/services/annotation_service.dart';
import 'package:mnemata/features/intelligence/services/summary_service.dart';
import 'package:mnemata/features/intelligence/services/tag_suggestion_service.dart';
import 'package:mnemata/core/utils/share_utils.dart';
import 'package:url_launcher/url_launcher.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.item});

  final MnemataItem item;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final AppDatabase _database;
  late final AnnotationService _annotationService;
  late final String _plainContent;

  List<AnnotationRecord> _annotations = const <AnnotationRecord>[];

  @override
  void initState() {
    super.initState();
    _database = GetIt.instance<AppDatabase>();
    _annotationService = GetIt.instance<AnnotationService>();
    _plainContent = _extractPlainText(widget.item.content ?? '');
    _reloadAnnotations();
  }

  Future<void> _reloadAnnotations() async {
    final records = await _annotationService.listForItem(widget.item.id);
    if (!mounted) {
      return;
    }
    setState(() {
      _annotations = records;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.item.title ?? 'Article'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (widget.item.url != null)
            IconButton(
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Open in Browser',
              onPressed: _openItemUrl,
            ),
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Rich Content',
            onPressed: () => ShareUtils.shareItem(context, widget.item),
          ),
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'AI Summary',
            onPressed: () {
              final summaryService = GetIt.instance<SummaryService>();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => SummaryPanel(
                  item: widget.item,
                  summaryService: summaryService,
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.label_outline),
            tooltip: 'AI Tag Suggestions',
            onPressed: () {
              final suggestionService = GetIt.instance<TagSuggestionService>();
              showModalBottomSheet<void>(
                context: context,
                isScrollControlled: true,
                useSafeArea: true,
                builder: (_) => TagSuggestionSheet(
                  item: widget.item,
                  service: suggestionService,
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                await _confirmDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: widget.item.content != null && widget.item.content!.isNotEmpty
            ? Scrollbar(
                thickness: 4,
                radius: const Radius.circular(8),
                thumbVisibility: true,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (widget.item.title != null) ...[
                        Text(
                          widget.item.title!,
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                      ],
                      StreamBuilder<List<Label>>(
                        stream: _database.watchLabelsForItem(widget.item.id),
                        builder: (context, snapshot) {
                          final labels = snapshot.data ?? [];
                          if (labels.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: labels
                                  .map(
                                    (label) => Chip(
                                      label: Text(
                                        label.name,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      backgroundColor: label.color != null
                                          ? Color(
                                              label.color!,
                                            ).withValues(alpha: 0.2)
                                          : null,
                                      side: BorderSide(
                                        color: label.color != null
                                            ? Color(label.color!)
                                            : Colors.blue,
                                      ),
                                      visualDensity: VisualDensity.compact,
                                      padding: EdgeInsets.zero,
                                    ),
                                  )
                                  .toList(),
                            ),
                          );
                        },
                      ),
                      if (widget.item.url != null) ...[
                        Text(
                          _safeHost(widget.item.url!),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Highlights & Notes'),
                        children: [
                          AnnotationListPanel(
                            itemId: widget.item.id,
                            service: _annotationService,
                            onChanged: _reloadAnnotations,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 16),
                      SelectableText.rich(
                        _buildHighlightedContentSpan(context),
                        contextMenuBuilder: (context, editableTextState) {
                          final items =
                              editableTextState.contextMenuButtonItems;
                          items.insert(
                            0,
                            ContextMenuButtonItem(
                              label: 'Highlight',
                              onPressed: () {
                                final selection = editableTextState
                                    .textEditingValue
                                    .selection;
                                editableTextState.hideToolbar();
                                _saveHighlightOnlyFromSelection(selection);
                              },
                            ),
                          );
                          items.insert(
                            1,
                            ContextMenuButtonItem(
                              label: 'Highlight + note',
                              onPressed: () {
                                final selection = editableTextState
                                    .textEditingValue
                                    .selection;
                                editableTextState.hideToolbar();
                                _saveHighlightWithNoteFromSelection(selection);
                              },
                            ),
                          );
                          return AdaptiveTextSelectionToolbar.buttonItems(
                            anchors: editableTextState.contextMenuAnchors,
                            buttonItems: items,
                          );
                        },
                        style: Theme.of(
                          context,
                        ).textTheme.bodyLarge?.copyWith(height: 1.6),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.article_outlined,
                      size: 64,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text('No content extracted yet.'),
                    if (widget.item.url != null) ...[
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: _openItemUrl,
                        child: const Text('Open in Browser'),
                      ),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  TextSpan _buildHighlightedContentSpan(BuildContext context) {
    final baseStyle = Theme.of(
      context,
    ).textTheme.bodyLarge?.copyWith(height: 1.6);
    if (_annotations.isEmpty || _plainContent.isEmpty) {
      return TextSpan(text: _plainContent, style: baseStyle);
    }

    final ranges =
        _annotations
            .map(_toRange)
            .where((range) => range != null)
            .cast<_AnchorRange>()
            .toList()
          ..sort((a, b) => a.start.compareTo(b.start));

    if (ranges.isEmpty) {
      return TextSpan(text: _plainContent, style: baseStyle);
    }

    final spans = <InlineSpan>[];
    var cursor = 0;

    for (final range in ranges) {
      if (range.start > cursor) {
        spans.add(
          TextSpan(
            text: _plainContent.substring(cursor, range.start),
            style: baseStyle,
          ),
        );
      }

      final start = range.start.clamp(0, _plainContent.length);
      final end = range.end.clamp(start, _plainContent.length);
      if (end > start) {
        spans.add(
          TextSpan(
            text: _plainContent.substring(start, end),
            style: baseStyle?.copyWith(
              backgroundColor: Colors.yellowAccent.withValues(alpha: 0.65),
            ),
          ),
        );
      }
      cursor = end;
    }

    if (cursor < _plainContent.length) {
      spans.add(
        TextSpan(text: _plainContent.substring(cursor), style: baseStyle),
      );
    }

    return TextSpan(children: spans, style: baseStyle);
  }

  _AnchorRange? _toRange(AnnotationRecord record) {
    try {
      final decoded = jsonDecode(record.anchorJson);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }
      final start = (decoded['start'] as num?)?.toInt();
      final end = (decoded['end'] as num?)?.toInt();
      if (start == null || end == null || end <= start) {
        return null;
      }
      return _AnchorRange(start: start, end: end);
    } catch (_) {
      return null;
    }
  }

  String _extractPlainText(String raw) {
    var text = raw
        .replaceAll(
          RegExp(r'<script[\s\S]*?<\/script>', caseSensitive: false),
          ' ',
        )
        .replaceAll(
          RegExp(r'<style[\s\S]*?<\/style>', caseSensitive: false),
          ' ',
        )
        .replaceAll(RegExp(r'<[^>]+>'), ' ');

    const entities = <String, String>{
      '&nbsp;': ' ',
      '&amp;': '&',
      '&lt;': '<',
      '&gt;': '>',
      '&quot;': '"',
      '&#39;': "'",
    };
    entities.forEach((key, value) {
      text = text.replaceAll(key, value);
    });

    return text.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  Future<void> _saveHighlightOnlyFromSelection(TextSelection selection) async {
    if (!_isSelectionInBounds(selection)) {
      return;
    }

    await _saveHighlightFromOffsets(selection.start, selection.end);
  }

  Future<void> _saveHighlightFromOffsets(int start, int end) async {
    final quote = _plainContent.substring(start, end).trim();
    if (quote.isEmpty) {
      return;
    }

    await _annotationService.createAnnotation(
      itemId: widget.item.id,
      quoteText: quote,
      anchorJson: jsonEncode(<String, int>{'start': start, 'end': end}),
    );

    if (!mounted) {
      return;
    }
    await _reloadAnnotations();
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Highlight saved.')));
    }
  }

  Future<void> _saveHighlightWithNoteFromSelection(
    TextSelection selection,
  ) async {
    if (!_isSelectionInBounds(selection)) {
      return;
    }

    final selectedText = _plainContent
        .substring(selection.start, selection.end)
        .trim();
    if (selectedText.isEmpty) {
      return;
    }

    await ReaderSelectionActions.promptAddAnnotationFromSelection(
      context,
      service: _annotationService,
      itemId: widget.item.id,
      selectedText: selectedText,
      selectionStart: selection.start,
      selectionEnd: selection.end,
    );

    if (!mounted) {
      return;
    }
    await _reloadAnnotations();
  }

  bool _isSelectionInBounds(TextSelection selection) {
    return selection.start >= 0 &&
        selection.end > selection.start &&
        selection.end <= _plainContent.length;
  }

  String _safeHost(String rawUrl) {
    final uri = _parseLaunchableUri(rawUrl);
    if (uri == null || uri.host.isEmpty) {
      return rawUrl;
    }
    return uri.host;
  }

  Uri? _parseLaunchableUri(String rawUrl) {
    final trimmed = rawUrl.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final direct = Uri.tryParse(trimmed);
    if (direct != null && direct.hasScheme) {
      return direct;
    }

    return Uri.tryParse('https://$trimmed');
  }

  Future<void> _openItemUrl() async {
    final rawUrl = widget.item.url;
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return;
    }

    final uri = _parseLaunchableUri(rawUrl);
    if (uri == null) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid URL')));
      }
      return;
    }

    await _database.updateLastOpenedAt(widget.item.id);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open in browser')),
      );
    }
  }

  Future<void> _confirmDelete() async {
    final confirm = await showDialog<bool>(
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm != true) {
      return;
    }

    await _database.deleteItem(widget.item.id);
    if (!mounted) {
      return;
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Item deleted')));
  }
}

class _AnchorRange {
  const _AnchorRange({required this.start, required this.end});

  final int start;
  final int end;
}
