import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/core/theme/app_theme.dart';
import 'package:mnemata/features/intelligence/presentation/annotation_list_panel.dart';
import 'package:mnemata/features/intelligence/presentation/reader_selection_actions.dart';
import 'package:mnemata/features/intelligence/presentation/summary_panel.dart';
import 'package:mnemata/features/intelligence/presentation/tag_suggestion_sheet.dart';
import 'package:mnemata/features/intelligence/services/annotation_service.dart';
import 'package:mnemata/features/intelligence/services/summary_service.dart';
import 'package:mnemata/features/intelligence/services/tag_suggestion_service.dart';
import 'package:mnemata/core/utils/share_utils.dart';
import 'package:mnemata/features/reader/presentation/widgets/reader_action_pill.dart';
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
  late final String _readTime;

  List<AnnotationRecord> _annotations = const <AnnotationRecord>[];

  @override
  void initState() {
    super.initState();
    _database = GetIt.instance<AppDatabase>();
    _annotationService = GetIt.instance<AnnotationService>();
    _plainContent = _extractPlainText(widget.item.content ?? '');
    _readTime = _estimateReadTime(_plainContent);
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
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasContent =
        widget.item.content != null && widget.item.content!.isNotEmpty;

    final source = _deriveSource();
    final metaTitle = [
      if (source.isNotEmpty) source,
      if (_readTime.isNotEmpty) _readTime,
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          metaTitle,
          style: theme.textTheme.mono(
            size: 10,
            letterSpacing: 1.0,
            color: cs.onSurfaceVariant,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_horiz),
            tooltip: 'More',
            onPressed: _openMoreMenu,
          ),
        ],
      ),
      body: hasContent
          ? Stack(
              children: [
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 36, 28, 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroHeader(
                          title: widget.item.title ?? '',
                          author: widget.item.author,
                          source: source,
                          createdAt: widget.item.createdAt,
                        ),
                        const SizedBox(height: 24),
                        _LabelsRow(
                          database: _database,
                          itemId: widget.item.id,
                        ),
                        _AnnotationsExpansion(
                          itemId: widget.item.id,
                          service: _annotationService,
                          onChanged: _reloadAnnotations,
                        ),
                        const SizedBox(height: 16),
                        SelectableText.rich(
                          _buildHighlightedContentSpan(context),
                          contextMenuBuilder:
                              (context, editableTextState) {
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
                                  _saveHighlightWithNoteFromSelection(
                                    selection,
                                  );
                                },
                              ),
                            );
                            return AdaptiveTextSelectionToolbar.buttonItems(
                              anchors: editableTextState.contextMenuAnchors,
                              buttonItems: items,
                            );
                          },
                          style: theme.textTheme.titleLarge,
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: MediaQuery.of(context).viewPadding.bottom + 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: ReaderActionPill(
                      onSummary: _openSummary,
                      onHighlight: _startHighlight,
                      onTag: _openTagSuggestions,
                      onShare: _shareItem,
                      onBookmark: _togglePin,
                    ),
                  ),
                ),
              ],
            )
          : SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.article_outlined,
                      size: 64,
                      color: cs.outlineVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No content extracted yet.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    if (widget.item.url != null) ...[
                      const SizedBox(height: 12),
                      FilledButton(
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

  Future<void> _openMoreMenu() async {
    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.item.url != null)
                ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: const Text('Open in Browser'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openItemUrl();
                  },
                ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: cs.error),
                title: Text(
                  'Delete',
                  style: TextStyle(color: cs.error),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmDelete();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  void _startHighlight() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Select text in the article to highlight it.'),
      ),
    );
  }

  void _togglePin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookmarks are not available yet.')),
    );
  }

  String _deriveSource() {
    final rawUrl = widget.item.url;
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return '';
    }
    return _safeHost(rawUrl);
  }

  String _estimateReadTime(String plainText) {
    if (plainText.trim().isEmpty) {
      return '';
    }
    final words = plainText.trim().split(RegExp(r'\s+')).length;
    final minutes = (words / 225).ceil().clamp(1, 999);
    return '$minutes min read';
  }

  TextSpan _buildHighlightedContentSpan(BuildContext context) {
    final baseStyle = Theme.of(context).textTheme.titleLarge;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final highlightColor = isDark
        ? MnemataColors.accentSoftDark
        : MnemataColors.accentSoft;
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
              backgroundColor: highlightColor,
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
    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
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
            style: TextButton.styleFrom(foregroundColor: cs.error),
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
    ).showSnackBar(const SnackBar(content: Text('Item moved to recycle bin')));
  }

  Future<void> _openSummary() async {
    final summaryService = GetIt.instance<SummaryService>();
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
          child: SummaryPanel(
            item: widget.item,
            summaryService: summaryService,
          ),
        ),
      ),
    );
  }

  Future<void> _shareItem() async {
    String? summaryText;
    if (GetIt.instance.isRegistered<SummaryService>()) {
      final summaryService = GetIt.instance<SummaryService>();
      final savedSummary = await summaryService.loadSavedSummary(widget.item);
      if (savedSummary != null && savedSummary.isSuccess) {
        summaryText = _summaryToShareText(savedSummary);
      }
    }

    if (!mounted) {
      return;
    }

    await ShareUtils.shareItem(
      context,
      widget.item,
      summaryText: summaryText,
    );
  }

  String _summaryToShareText(SummaryResult result) {
    final buffer = StringBuffer()
      ..writeln('*TL;DR*')
      ..writeln(result.tldr.trim());
    final points = result.keyPoints
        .map((point) => point.trim())
        .where((point) => point.isNotEmpty)
        .toList(growable: false);
    if (points.isNotEmpty) {
      buffer
        ..writeln('')
        ..writeln('*Key points*');
      for (final point in points) {
        buffer.writeln('- $point');
      }
    }
    final whyItMatters = result.whyItMatters.trim();
    if (whyItMatters.isNotEmpty) {
      buffer
        ..writeln('')
        ..writeln('*Why it matters*')
        ..writeln(whyItMatters);
    }
    return buffer.toString().trim();
  }

  Future<void> _openTagSuggestions() async {
    final suggestionService = GetIt.instance<TagSuggestionService>();
    await showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
          child: TagSuggestionSheet(
            item: widget.item,
            service: suggestionService,
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.title,
    required this.author,
    required this.source,
    required this.createdAt,
  });

  final String title;
  final String? author;
  final String source;
  final DateTime createdAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final kicker = source.isNotEmpty ? source : null;
    final formattedDate = DateFormat('MMM d, yyyy').format(createdAt);
    final trimmedAuthor = author?.trim();
    final metaText = [
      if (trimmedAuthor != null && trimmedAuthor.isNotEmpty) trimmedAuthor,
      formattedDate,
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (kicker != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              kicker.toUpperCase(),
              style: theme.textTheme.tracked(cs.secondary),
            ),
          ),
        Text(
          title,
          style: theme.textTheme.displaySmall!.copyWith(
            fontSize: 36,
            height: 1.08,
            letterSpacing: -0.9,
          ),
        ),
        const SizedBox(height: 28),
        const Divider(),
        const SizedBox(height: 18),
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [MnemataColors.tag1, MnemataColors.tag4],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                metaText,
                style: theme.textTheme.mono(
                  size: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LabelsRow extends StatelessWidget {
  const _LabelsRow({required this.database, required this.itemId});

  final AppDatabase database;
  final int itemId;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return StreamBuilder<List<Label>>(
      stream: database.watchLabelsForItem(itemId),
      builder: (context, snapshot) {
        final labels = snapshot.data ?? const <Label>[];
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
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    backgroundColor: label.color != null
                        ? Color(label.color!).withValues(alpha: 0.2)
                        : null,
                    side: BorderSide(
                      color: label.color != null
                          ? Color(label.color!)
                          : cs.outline,
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                )
                .toList(),
          ),
        );
      },
    );
  }
}

class _AnnotationsExpansion extends StatelessWidget {
  const _AnnotationsExpansion({
    required this.itemId,
    required this.service,
    required this.onChanged,
  });

  final int itemId;
  final AnnotationService service;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('Highlights & Notes'),
      children: [
        AnnotationListPanel(
          itemId: itemId,
          service: service,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _AnchorRange {
  const _AnchorRange({required this.start, required this.end});

  final int start;
  final int end;
}
