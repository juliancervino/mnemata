import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/core/theme/app_theme.dart';
import 'package:mnemata/core/utils/share_utils.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:mnemata/features/intelligence/presentation/annotation_list_panel.dart';
import 'package:mnemata/features/intelligence/presentation/reader_selection_actions.dart';
import 'package:mnemata/features/intelligence/presentation/summary_panel.dart';
import 'package:mnemata/features/intelligence/presentation/tag_suggestion_sheet.dart';
import 'package:mnemata/features/intelligence/services/annotation_service.dart';
import 'package:mnemata/features/intelligence/services/summary_service.dart';
import 'package:mnemata/features/intelligence/services/tag_suggestion_service.dart';
import 'package:mnemata/features/reader/presentation/reader_controls_bar.dart';
import 'package:mnemata/features/reader/presentation/reader_pdf_view.dart';
import 'package:mnemata/features/reader/presentation/reader_side_panel.dart';
import 'package:mnemata/features/reader/presentation/widgets/reader_action_pill.dart';
import 'package:mnemata/features/reader/services/reader_position_store.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({super.key, required this.item});

  final MnemataItem item;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  static const double _desktopBreakpoint = 1024;
  static const double _sidePanelWidth = 312;
  static const int _wordsPerSectionBucket = 120;

  late final AppDatabase _database;
  late final AnnotationService _annotationService;
  late final ReaderPositionStore _positionStore;
  late String _plainContent;
  late String _readTime;

  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _annotationKeys = {};

  List<AnnotationRecord> _annotations = const <AnnotationRecord>[];
  ReaderFontScale _fontScale = ReaderFontScale.standard;
  ReaderVisualTheme _visualTheme = ReaderVisualTheme.light;
  bool _isHighlightModeActive = false;
  String? _pendingSelectionText;
  double _columnWidth = 720;
  bool _showSidePanel = true;
  int _activeSectionBucket = 0;
  Timer? _persistBucketTimer;

  @override
  void initState() {
    super.initState();
    _database = GetIt.instance<AppDatabase>();
    _annotationService = GetIt.instance<AnnotationService>();
    _positionStore = GetIt.instance.isRegistered<ReaderPositionStore>()
        ? GetIt.instance<ReaderPositionStore>()
        : SharedPrefsReaderPositionStore();
    _plainContent = _extractPlainText(widget.item.content ?? '');
    _readTime = _estimateReadTime(_plainContent);
    _scrollController.addListener(_handleScrollCheckpoint);
    _reloadAnnotations();
    _restoreSectionBucket();
  }

  @override
  void dispose() {
    _persistBucketTimer?.cancel();
    _scrollController
      ..removeListener(_handleScrollCheckpoint)
      ..dispose();
    super.dispose();
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

  void _scrollToAnnotation(AnnotationRecord record) {
    final key = _annotationKeys[record.id];
    if (key != null && key.currentContext != null) {
      Scrollable.ensureVisible(
        key.currentContext!,
        alignment: 0.1, // Align near the top of the viewport
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final source = _deriveSource();
    final hasContent = _plainContent.trim().isNotEmpty || _isPdfItem;

    final metaTitle = [
      if (source.isNotEmpty) source,
      if (_readTime.isNotEmpty) _readTime,
    ].join(' · ');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: cs.surface.withValues(alpha: 0),
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          metaTitle,
          style: theme.textTheme.mono(
            size: 10,
            letterSpacing: 1,
            color: cs.onSurfaceVariant,
          ),
        ),
        centerTitle: true,
        actions: kIsWeb
            ? null
            : [
                IconButton(
                  icon: const Icon(Icons.open_in_browser),
                  tooltip: 'Open Original',
                  onPressed: _openOriginal,
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  tooltip: 'Share',
                  onPressed: _shareItem,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'More options',
                  onPressed: _openMoreMenu,
                ),
              ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= _desktopBreakpoint;
          final canToggleSidePanel = isDesktop && hasContent;
          final showSidePanel = canToggleSidePanel && _showSidePanel;
          final shellWidth = showSidePanel
              ? _columnWidth + _sidePanelWidth + 24
              : _columnWidth;

          return Stack(
            children: [
              Positioned.fill(
                child: hasContent
                    ? _buildReadableSurface(
                        context,
                        source: source,
                        showSidePanel: showSidePanel,
                      )
                    : _buildNoContentState(context),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: shellWidth),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: kIsWeb
                            ? ReaderControlsBar(
                                sectionLabel: _buildSectionLabel(),
                                fontScale: _fontScale,
                                visualTheme: _visualTheme,
                                columnWidth: _columnWidth,
                                canToggleSidePanel: canToggleSidePanel,
                                isSidePanelVisible: _showSidePanel,
                                onFontScaleChanged: (value) {
                                  setState(() {
                                    _fontScale = value;
                                  });
                                },
                                onVisualThemeChanged: (value) {
                                  setState(() {
                                    _visualTheme = value;
                                  });
                                },
                                onColumnWidthChanged: (value) {
                                  setState(() {
                                    _columnWidth = value;
                                  });
                                },
                                onSidePanelToggled: (value) {
                                  setState(() {
                                    _showSidePanel = value;
                                  });
                                },
                                onOpenOriginal: _openOriginal,
                                onShare: _shareItem,
                                onMore: _openMoreMenu,
                              )
                            : const SizedBox.shrink(),
                      ),
                    ),
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
                    isHighlightActive: _isHighlightModeActive,
                    onTag: _openTagSuggestions,
                    onShare: _shareItem,
                    onBookmark: _togglePin,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReadableSurface(
    BuildContext context, {
    required String source,
    required bool showSidePanel,
  }) {
    final tone = _bodyToneFor(context);
    final sectionLabels = _isPdfItem ? const <String>['PDF'] : _sectionLabels();

    final mainPane = _isPdfItem
        ? _buildPdfBody(context)
        : _buildScrollableBody(context, source: source, tone: tone);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: showSidePanel
                ? _columnWidth + _sidePanelWidth + 24
                : _columnWidth,
          ),
          child: showSidePanel
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: _columnWidth, child: mainPane),
                    const SizedBox(width: 24),
                    SizedBox(
                      width: _sidePanelWidth,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 132, bottom: 24),
                        child: ReaderSidePanel(
                          source: source,
                          readTime: _readTime,
                          createdAt: widget.item.createdAt,
                          sectionLabels: sectionLabels,
                          activeSection: _isPdfItem ? 0 : _activeSectionBucket,
                          onSelectSection: _jumpToSection,
                        ),
                      ),
                    ),
                  ],
                )
              : ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: _columnWidth),
                  child: mainPane,
                ),
        ),
      ),
    );
  }

  Widget _buildPdfBody(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(0, kIsWeb ? 132 : 16, 0, 140),
      child: ReaderPdfView(
        sourceUri: _pdfSourceUri,
        onOpenOriginal: _openOriginal,
        onRetryExtraction: _retryExtraction,
        onReportIssue: _reportIssue,
      ),
    );
  }

  Widget _buildScrollableBody(
    BuildContext context, {
    required String source,
    required _ReaderBodyTone tone,
  }) {
    return SingleChildScrollView(
      controller: _scrollController,
      key: const Key('reader-scroll-view'),
      padding: EdgeInsets.fromLTRB(0, kIsWeb ? 132 : 16, 0, 140),
      child: Container(
        key: const Key('reader-content-container'),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        decoration: BoxDecoration(
          color: tone.surfaceColor,
          borderRadius: BorderRadius.circular(MnemataRadii.lg),
          border: Border.all(color: tone.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroHeader(
              title: widget.item.title ?? '',
              author: widget.item.author,
              source: source,
              createdAt: widget.item.createdAt,
              textColor: tone.textColor,
              mutedTextColor: tone.mutedTextColor,
            ),
            const SizedBox(height: 24),
            _LabelsRow(database: _database, itemId: widget.item.id),
            _AnnotationsExpansion(
              itemId: widget.item.id,
              service: _annotationService,
              onChanged: _reloadAnnotations,
              onNavigate: _scrollToAnnotation,
            ),
            const SizedBox(height: 16),
            _buildMainContent(context, tone),
          ],
        ),
      ),
    );
  }

  Widget _buildMainContent(BuildContext context, _ReaderBodyTone tone) {
    final content = widget.item.content ?? '';
    final isMarkdown = _looksLikeMarkdown(content);
    final theme = Theme.of(context);
    final textStyle = _contentTextStyle(theme, tone.textColor);

    if (kIsWeb && isMarkdown) {
      // Simple Markdown to HTML conversion for rendering with HtmlWidget
      // This handles basic Obsidian-style markings and respects line breaks
      var htmlContent = _convertMarkdownToHtml(content);
      
      // Inject highlights into HTML
      htmlContent = _applyHighlightsToHtml(htmlContent, tone);

      return Listener(
        onPointerUp: (_) {
          if (_isHighlightModeActive && _pendingSelectionText != null) {
            final text = _pendingSelectionText!.trim();
            if (text.isNotEmpty) {
              _saveHighlightFromText(text);
              _pendingSelectionText = null;
            }
          }
        },
        child: SelectionArea(
          onSelectionChanged: (selection) {
            if (_isHighlightModeActive) {
              _pendingSelectionText = selection?.plainText;
            }
          },
          child: HtmlWidget(
            htmlContent,
            textStyle: textStyle,
            customWidgetBuilder: (element) {
              if (element.localName == 'anchor') {
                final idStr = element.attributes['id'];
                if (idStr != null) {
                  final id = int.tryParse(idStr);
                  if (id != null) {
                    return SizedBox(key: _annotationKeys[id], width: 0, height: 0);
                  }
                }
              }
              return null;
            },
            customStylesBuilder: (element) {
              if (element.localName == 'p') {
                return {'margin-bottom': '1.2em'};
              }
              if (element.localName == 'mark') {
                final colorHex = '#${tone.highlightColor.toARGB32().toRadixString(16).substring(2)}';
                return {'background-color': colorHex};
              }
              return null;
            },
          ),
        ),
      );
    }

    return SelectableText.rich(
      _buildHighlightedContentSpan(context),
      key: const Key('reader-body-text'),
      contextMenuBuilder: (context, editableTextState) {
        final items = editableTextState.contextMenuButtonItems.toList();
        items.insert(
          0,
          ContextMenuButtonItem(
            label: 'Highlight',
            onPressed: () {
              final selection =
                  editableTextState.textEditingValue.selection;
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
              final selection =
                  editableTextState.textEditingValue.selection;
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
      style: textStyle,
    );
  }

  bool _looksLikeMarkdown(String text) {
    if (text.isEmpty) return false;
    // Common Markdown patterns
    final hasHeaders = RegExp(r'^#+\s+', multiLine: true).hasMatch(text);
    final hasBold = RegExp(r'\*\*[\s\S]*?\*\*').hasMatch(text);
    final hasLists = RegExp(r'^[*-]\s+', multiLine: true).hasMatch(text);
    final hasFrontmatter = text.startsWith('---');
    
    return hasHeaders || hasBold || hasLists || hasFrontmatter;
  }

  String _convertMarkdownToHtml(String markdown) {
    var html = markdown.trim();
    
    // Remove frontmatter if present
    if (html.startsWith('---')) {
      final parts = html.split('---');
      if (parts.length >= 3) {
        html = parts.sublist(2).join('---').trim();
      }
    }

    // Very basic markdown to HTML converter that respects \n\n as paragraphs
    // and handles basic marks found in clippings
    
    // Standardize newlines
    html = html.replaceAll('\r\n', '\n');

    // Headers
    html = html.replaceAllMapped(RegExp(r'^(#+)\s+(.+)$', multiLine: true), (Match match) {
      final level = match.group(1)!.length;
      final text = match.group(2)!;
      return '<h$level>$text</h$level>';
    });

    // Bold
    html = html.replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (Match match) {
      return '<strong>${match.group(1)}</strong>';
    });

    // Italic
    html = html.replaceAllMapped(RegExp(r'\*(.+?)\*'), (Match match) {
      return '<em>${match.group(1)}</em>';
    });

    // Lists
    html = html.replaceAllMapped(RegExp(r'^[*-]\s+(.+)$', multiLine: true), (Match match) {
      return '<li>${match.group(1)}</li>';
    });
    // Wrap consecutive <li> in <ul> (simple approximation)
    html = html.replaceAllMapped(RegExp(r'(<li>.*?</li>)+', dotAll: true), (Match match) {
      return '<ul>${match.group(0)}</ul>';
    });

    // Paragraphs (double newlines)
    final paragraphs = html.split('\n\n');
    html = paragraphs.map((p) {
      if (p.trim().isEmpty) return '';
      if (p.trim().startsWith('<h') || p.trim().startsWith('<ul>')) return p;
      return '<p>${p.replaceAll('\n', '<br>')}</p>';
    }).join('\n');

    return html;
  }

  String _applyHighlightsToHtml(String html, _ReaderBodyTone tone) {
    if (_annotations.isEmpty) return html;

    var result = html;
    // We sort annotations by length (descending) to avoid partial matches
    // ruining later replacements of longer strings
    final sortedAnnotations = List<AnnotationRecord>.from(_annotations)
      ..sort((a, b) => b.quoteText.length.compareTo(a.quoteText.length));

    for (final annotation in sortedAnnotations) {
      final quote = annotation.quoteText;
      if (quote.isEmpty) continue;

      _annotationKeys.putIfAbsent(annotation.id, () => GlobalKey());

      // We use a simple string replacement for HTML.
      // We wrap it in <mark> and prepend an <anchor> for precise scrolling to the start
      // We escape the quote to ensure safe rendering in case it contains HTML characters
      final escapedQuote = htmlEscape.convert(quote);
      result = result.replaceFirst(
        quote,
        '<anchor id="${annotation.id}"></anchor><mark>$escapedQuote</mark>',
      );
    }
    return result;
  }
  Widget _buildNoContentState(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return SafeArea(
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 640),
          margin: const EdgeInsets.fromLTRB(16, 132, 16, 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(MnemataRadii.lg),
            border: Border.all(color: cs.outline),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.article_outlined,
                size: 48,
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'Could not load readable content.',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Use one of the guided actions below to recover this reader state.',
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton(
                    onPressed: _retryExtraction,
                    child: const Text('Retry Extraction'),
                  ),
                  OutlinedButton(
                    onPressed: _openOriginal,
                    child: const Text('Open Original'),
                  ),
                  TextButton(
                    onPressed: _reportIssue,
                    child: const Text('Report Issue'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  _ReaderBodyTone _bodyToneFor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDarkAppTheme = Theme.of(context).brightness == Brightness.dark;

    switch (_visualTheme) {
      case ReaderVisualTheme.light:
        return _ReaderBodyTone(
          surfaceColor: cs.surface,
          borderColor: cs.outline,
          textColor: cs.onSurface,
          mutedTextColor: cs.onSurfaceVariant,
          highlightColor: isDarkAppTheme
              ? MnemataColors.accentSoftDark
              : MnemataColors.accentSoft,
        );
      case ReaderVisualTheme.sepia:
        return _ReaderBodyTone(
          surfaceColor: isDarkAppTheme
              ? MnemataColors.accentSoftDark
              : MnemataColors.accentSoft,
          borderColor: cs.outline,
          textColor: cs.onSurface,
          mutedTextColor: cs.onSurfaceVariant,
          highlightColor: cs.primary.withValues(alpha: 0.2),
        );
      case ReaderVisualTheme.dark:
        return _ReaderBodyTone(
          surfaceColor: MnemataColors.paperDark,
          borderColor: MnemataColors.ruleDark,
          textColor: MnemataColors.inkDark,
          mutedTextColor: MnemataColors.ink3Dark,
          highlightColor: MnemataColors.accentSoftDark,
        );
    }
  }

  TextStyle? _contentTextStyle(ThemeData theme, Color textColor) {
    final baseStyle = theme.textTheme.titleLarge;
    if (baseStyle == null) {
      return null;
    }

    final scale = switch (_fontScale) {
      ReaderFontScale.compact => 0.92,
      ReaderFontScale.standard => 1.0,
      ReaderFontScale.roomy => 1.1,
    };

    final scaledSize = baseStyle.fontSize == null
        ? null
        : baseStyle.fontSize! * scale;

    return baseStyle.copyWith(fontSize: scaledSize, color: textColor);
  }

  String _buildSectionLabel() {
    if (_isPdfItem) {
      return 'PDF preview';
    }

    final count = _sectionCount();
    final clamped = _activeSectionBucket.clamp(0, count - 1);
    return 'Section ${clamped + 1} of $count';
  }

  List<String> _sectionLabels() {
    final count = _sectionCount();
    return List<String>.generate(count, (index) => 'Section ${index + 1}');
  }

  int _sectionCount() {
    if (_isPdfItem) {
      return 1;
    }

    final words = _plainContent.trim().isEmpty
        ? 0
        : _plainContent.trim().split(RegExp(r'\s+')).length;
    if (words == 0) {
      return 1;
    }
    return (words / _wordsPerSectionBucket).ceil().clamp(1, 32);
  }

  void _handleScrollCheckpoint() {
    if (_isPdfItem || !_scrollController.hasClients) {
      return;
    }

    final nextBucket = _bucketForOffset(_scrollController.offset);
    if (nextBucket != _activeSectionBucket && mounted) {
      setState(() {
        _activeSectionBucket = nextBucket;
      });
      _schedulePersistBucket();
    }
  }

  Future<void> _restoreSectionBucket() async {
    if (_isPdfItem || _plainContent.trim().isEmpty) {
      return;
    }

    final storedBucket = await _positionStore.readBucket(widget.item.id);
    if (!mounted || storedBucket == null) {
      return;
    }

    final clampedBucket = storedBucket.clamp(0, _sectionCount() - 1);
    setState(() {
      _activeSectionBucket = clampedBucket;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }
      _scrollController.jumpTo(_offsetForBucket(clampedBucket));
    });
  }

  void _schedulePersistBucket() {
    _persistBucketTimer?.cancel();
    _persistBucketTimer = Timer(const Duration(milliseconds: 220), () {
      if (!mounted || _isPdfItem) {
        return;
      }
      unawaited(
        _positionStore.writeBucket(widget.item.id, _activeSectionBucket),
      );
    });
  }

  int _bucketForOffset(double offset) {
    if (!_scrollController.hasClients) {
      return 0;
    }

    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) {
      return 0;
    }

    final count = _sectionCount();
    final ratio = (offset / maxExtent).clamp(0.0, 1.0);
    return (ratio * (count - 1)).round().clamp(0, count - 1);
  }

  double _offsetForBucket(int bucket) {
    if (!_scrollController.hasClients) {
      return 0;
    }

    final maxExtent = _scrollController.position.maxScrollExtent;
    if (maxExtent <= 0) {
      return 0;
    }

    final count = _sectionCount();
    final normalized = bucket.clamp(0, count - 1);
    final ratio = count == 1 ? 0.0 : normalized / (count - 1);
    return maxExtent * ratio;
  }

  Future<void> _jumpToSection(int bucket) async {
    if (_isPdfItem || !_scrollController.hasClients) {
      return;
    }

    final target = _offsetForBucket(bucket);
    if (mounted) {
      setState(() {
        _activeSectionBucket = bucket.clamp(0, _sectionCount() - 1);
      });
    }

    await _scrollController.animateTo(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
    _schedulePersistBucket();
  }

  Future<void> _openMoreMenu() async {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_canOpenOriginal)
                ListTile(
                  leading: const Icon(Icons.open_in_new),
                  title: const Text('Open Original'),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openOriginal();
                  },
                ),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: const Text('Retry Extraction'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _retryExtraction();
                },
              ),
              ListTile(
                leading: const Icon(Icons.bug_report_outlined),
                title: const Text('Report Issue'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _reportIssue();
                },
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: cs.error),
                title: Text(
                  'Delete',
                  style: theme.textTheme.bodyLarge?.copyWith(color: cs.error),
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
    setState(() {
      _isHighlightModeActive = !_isHighlightModeActive;
    });
    
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isHighlightModeActive 
          ? 'Highlight mode active. Selected text will be marked.' 
          : 'Highlight mode disabled.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _togglePin() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Bookmarks are not available yet.')),
    );
  }

  bool get _isPdfItem {
    final url = widget.item.url?.toLowerCase() ?? '';
    final filePath = widget.item.filePath?.toLowerCase() ?? '';
    return url.endsWith('.pdf') || filePath.endsWith('.pdf');
  }

  Uri? get _pdfSourceUri {
    final rawUrl = widget.item.url?.trim();
    if (rawUrl != null && rawUrl.isNotEmpty) {
      final urlUri = _parseLaunchableUri(rawUrl);
      if (urlUri != null && urlUri.toString().toLowerCase().contains('.pdf')) {
        return urlUri;
      }
    }

    final rawFilePath = widget.item.filePath?.trim();
    if (rawFilePath == null || rawFilePath.isEmpty) {
      return null;
    }

    final fileUri = Uri.tryParse(rawFilePath);
    if (fileUri != null &&
        fileUri.hasScheme &&
        fileUri.toString().toLowerCase().contains('.pdf')) {
      return fileUri;
    }
    return null;
  }

  Future<void> _retryExtraction() async {
    final rawUrl = widget.item.url;
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      _reportIssue(message: 'Retry extraction is unavailable for this item.');
      return;
    }

    if (!GetIt.instance.isRegistered<ExtractionService>()) {
      _reportIssue(message: 'Extraction service is unavailable.');
      return;
    }

    final extractionService = GetIt.instance<ExtractionService>();

    try {
      final extracted = await extractionService.extractContent(rawUrl.trim());
      if (extracted == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Retry extraction returned no readable content.'),
            ),
          );
        }
        return;
      }

      await _database.updateItemContent(
        widget.item.id,
        extracted.content,
        extracted.title,
        extracted.thumbnailUrl,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _plainContent = _extractPlainText(extracted.content);
        _readTime = _estimateReadTime(_plainContent);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Extraction retried successfully.')),
      );
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Retry extraction failed. Open original or report issue.',
          ),
        ),
      );
    }
  }

  void _reportIssue({String? message}) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message ??
              'Issue report noted. Please share the source URL and item title with support.',
        ),
      ),
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
    final tone = _bodyToneFor(context);
    final baseStyle = _contentTextStyle(Theme.of(context), tone.textColor);
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

      _annotationKeys.putIfAbsent(range.id, () => GlobalKey());
      spans.add(
        WidgetSpan(
          child: SizedBox(
            key: _annotationKeys[range.id],
            width: 0,
            height: 0,
          ),
        ),
      );

      final start = range.start.clamp(0, _plainContent.length);
      final end = range.end.clamp(start, _plainContent.length);
      if (end > start) {
        spans.add(
          TextSpan(
            text: _plainContent.substring(start, end),
            style: baseStyle?.copyWith(backgroundColor: tone.highlightColor),
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
      return _AnchorRange(start: start, end: end, id: record.id);
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

  Future<void> _saveHighlightFromText(String quote) async {
    if (quote.isEmpty) return;
    
    // Check if we already have this highlight to avoid duplicates
    if (_annotations.any((a) => a.quoteText == quote)) return;

    // Try to find the range in plain text for semantic consistency
    final startIndex = _plainContent.indexOf(quote);
    final range = startIndex != -1 
      ? {'start': startIndex, 'end': startIndex + quote.length}
      : null;

    await _annotationService.createAnnotation(
      itemId: widget.item.id,
      quoteText: quote,
      anchorJson: jsonEncode(range ?? {}),
    );

    await _reloadAnnotations();
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

  bool get _canOpenOriginal {
    final hasUrl =
        widget.item.url != null && widget.item.url!.trim().isNotEmpty;
    final hasFilePath =
        widget.item.filePath != null && widget.item.filePath!.trim().isNotEmpty;
    return hasUrl || hasFilePath;
  }

  Future<void> _openOriginal() async {
    final rawUrl = widget.item.url;
    if (rawUrl != null && rawUrl.trim().isNotEmpty) {
      await _openItemUrl();
      return;
    }

    final filePath = widget.item.filePath;
    if (filePath != null && filePath.trim().isNotEmpty) {
      await _openFilePath(filePath);
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No original source found.')),
      );
    }
  }

  Future<void> _openFilePath(String filePath) async {
    if (kIsWeb) {
      final parsed = Uri.tryParse(filePath);
      if (parsed != null && parsed.hasScheme) {
        final opened = await launchUrl(parsed);
        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not open original source')),
          );
        }
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Open original is unavailable for this imported file.',
            ),
          ),
        );
      }
      return;
    }

    final result = await OpenFilex.open(filePath);
    if (result.type != ResultType.done && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open original source')),
      );
    }
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

    await ShareUtils.shareItem(context, widget.item, summaryText: summaryText);
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

class _ReaderBodyTone {
  const _ReaderBodyTone({
    required this.surfaceColor,
    required this.borderColor,
    required this.textColor,
    required this.mutedTextColor,
    required this.highlightColor,
  });

  final Color surfaceColor;
  final Color borderColor;
  final Color textColor;
  final Color mutedTextColor;
  final Color highlightColor;
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.title,
    required this.author,
    required this.source,
    required this.createdAt,
    required this.textColor,
    required this.mutedTextColor,
  });

  final String title;
  final String? author;
  final String source;
  final DateTime createdAt;
  final Color textColor;
  final Color mutedTextColor;

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
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              kicker.toUpperCase(),
              style: theme.textTheme.tracked(cs.secondary),
            ),
          ),
        Text(
          title,
          style: theme.textTheme.displaySmall?.copyWith(color: textColor),
        ),
        const SizedBox(height: 24),
        Divider(color: cs.outline),
        const SizedBox(height: 16),
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
                style: theme.textTheme.mono(size: 11, color: mutedTextColor),
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
    this.onNavigate,
  });

  final int itemId;
  final AnnotationService service;
  final VoidCallback onChanged;
  final ValueChanged<AnnotationRecord>? onNavigate;

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
          onNavigate: onNavigate,
        ),
      ],
    );
  }
}

class _AnchorRange {
  const _AnchorRange({required this.start, required this.end, required this.id});

  final int start;
  final int end;
  final int id;
}
