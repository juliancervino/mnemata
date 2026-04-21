import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/ingestion/presentation/archive_scraper_screen.dart';
import 'package:mnemata/features/ingestion/presentation/ingestion_failure_actions_sheet.dart';
import 'package:mnemata/features/ingestion/presentation/ingestion_summary_screen.dart';
import 'package:mnemata/features/ingestion/presentation/js_rendered_scraper_screen.dart';
import 'package:mnemata/features/reader/presentation/reader_screen.dart';
import 'package:open_filex/open_filex.dart';
import 'package:mnemata/features/ingestion/services/author_extraction_service.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:mnemata/features/ingestion/services/pdf_extraction_service.dart';
import 'package:mnemata/features/ingestion/services/shared_file_operations.dart';
import 'package:path/path.dart' as p;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:url_launcher/url_launcher.dart';

enum DuplicateResolution { openExistingItem, addDuplicateItem, keepCurrentItem }

class ShareService {
  final AppDatabase _database;
  final ExtractionService _extractionService;
  final AuthorExtractionService _authorExtractionService;
  final PdfExtractionService _pdfExtractionService;
  final GlobalKey<NavigatorState> _navigatorKey;
  final Future<bool?> Function(String identifier)? _duplicatePromptOverride;
  final Future<DuplicateResolution?> Function({
    required String identifier,
    required MnemataItem existingItem,
  })?
  _duplicateResolutionOverride;
  final Future<IngestionFailureAction> Function({
    required String sourceLabel,
    required bool canOpenOriginal,
  })?
  _failureActionOverride;
  StreamSubscription? _intentDataStreamSubscription;

  bool _isInitialized = false;
  bool _isLoadingShowing = false;
  bool _isProcessingIncomingShare = false;
  String? _activeIncomingFingerprint;
  (List<SharedMediaFile>, String)? _pendingIncomingShare;

  ShareService(
    this._database,
    this._extractionService,
    this._pdfExtractionService,
    this._navigatorKey, {
    AuthorExtractionService? authorExtractionService,
    Future<bool?> Function(String identifier)? duplicatePromptOverride,
    Future<DuplicateResolution?> Function({
      required String identifier,
      required MnemataItem existingItem,
    })?
    duplicateResolutionOverride,
    Future<IngestionFailureAction> Function({
      required String sourceLabel,
      required bool canOpenOriginal,
    })?
    failureActionOverride,
  }) : _authorExtractionService =
           authorExtractionService ?? AuthorExtractionService(),
       _duplicatePromptOverride = duplicatePromptOverride,
       _duplicateResolutionOverride = duplicateResolutionOverride,
       _failureActionOverride = failureActionOverride;

  void init() {
    if (_isInitialized) return;

    if (kIsWeb) {
      _isInitialized = true;
      return;
    }

    _isInitialized = true;

    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen(
          (List<SharedMediaFile> value) {
            unawaited(_processIncomingShare(value, source: 'stream'));
          },
          onError: (Object err) {
            debugPrint('getMediaStream error: $err');
            unawaited(_resetShareIntentBuffer());
          },
        );

    ReceiveSharingIntent.instance
        .getInitialMedia()
        .then((List<SharedMediaFile> value) {
          unawaited(_processIncomingShare(value, source: 'initial'));
        })
        .catchError((Object err) {
          debugPrint('getInitialMedia error: $err');
          unawaited(_resetShareIntentBuffer());
        });
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
    _isInitialized = false;
    _clearShareProcessingState();
  }

  Future<void> _processIncomingShare(
    List<SharedMediaFile> files, {
    required String source,
  }) async {
    final List<SharedMediaFile> snapshot = List<SharedMediaFile>.from(files);

    if (snapshot.isEmpty) {
      debugPrint('ShareService: received empty $source payload');
      await _resetShareIntentBuffer();
      _clearShareProcessingState();
      return;
    }

    if (_isProcessingIncomingShare) {
      _pendingIncomingShare = (snapshot, source);
      debugPrint(
        'ShareService: queued latest $source payload while another is active',
      );
      await _resetShareIntentBuffer();
      return;
    }

    _isProcessingIncomingShare = true;
    _activeIncomingFingerprint = _buildBatchFingerprint(snapshot);
    debugPrint(
      'ShareService: received $source payload fingerprint=$_activeIncomingFingerprint size=${snapshot.length}',
    );

    // Clear plugin state immediately so stale payloads are not replayed later.
    await _resetShareIntentBuffer();

    try {
      await _handleSharedMedia(snapshot);
    } finally {
      debugPrint(
        'ShareService: cleanup payload fingerprint=$_activeIncomingFingerprint',
      );
      _clearShareProcessingState();
      await _resetShareIntentBuffer();

      final pending = _pendingIncomingShare;
      if (pending != null) {
        _pendingIncomingShare = null;
        unawaited(_processIncomingShare(pending.$1, source: pending.$2));
      }
    }
  }

  void _clearShareProcessingState() {
    _isProcessingIncomingShare = false;
    _activeIncomingFingerprint = null;
  }

  String _buildBatchFingerprint(List<SharedMediaFile> files) {
    final keys = files.map(_buildPayloadKey).toList()..sort();
    return keys.join('|');
  }

  Future<void> _resetShareIntentBuffer() async {
    try {
      await ReceiveSharingIntent.instance.reset();
    } catch (err) {
      debugPrint('resetShareIntent error: $err');
    }
  }

  Future<void> _handleSharedMedia(List<SharedMediaFile> files) async {
    if (files.isEmpty) {
      return;
    }

    final Set<String> batchProcessedKeys = <String>{};

    for (final file in files) {
      // Temporal dedupe only suppresses duplicate payloads in this batch.
      final String payloadKey = _buildPayloadKey(file);
      if (batchProcessedKeys.contains(payloadKey)) {
        continue;
      }
      batchProcessedKeys.add(payloadKey);

      if (file.type == SharedMediaType.text ||
          file.type == SharedMediaType.url) {
        await _handleUrl(file.path);
      } else {
        await _handleFile(file);
      }
    }
  }

  Future<void> handleUrl(String? text) async {
    await _handleUrl(text);
  }

  Future<void> handleFile(SharedMediaFile sharedFile) async {
    await _handleFile(sharedFile);
  }

  Future<void> handleWebFile({
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    if (!kIsWeb) {
      return;
    }

    final normalizedName = fileName.trim();
    if (normalizedName.isEmpty || bytes.isEmpty) {
      return;
    }

    final existingFile = await _database.getItemByFilePath(normalizedName);
    if (existingFile != null) {
      final resolution = await _showDuplicateDialog(
        normalizedName,
        existingItem: existingFile,
      );
      _trackDuplicateDecision(source: normalizedName, resolution: resolution);

      if (resolution == DuplicateResolution.openExistingItem) {
        await _openExistingItem(existingFile);
        return;
      }

      if (resolution == DuplicateResolution.keepCurrentItem) {
        return;
      }
    }

    _showLoadingOverlay('Preparing file...');

    try {
      _hideLoadingOverlay();
      final resultFromSummary = await _pushSummaryWhenNavigatorReady(
        (context) => IngestionSummaryScreen(
          type: 'file',
          filePath: normalizedName,
          title: normalizedName,
        ),
      );
      _handleSummaryOutcome(resultFromSummary, source: normalizedName);
      debugPrint(
        'ShareService: web file ingest mimeType=$mimeType bytes=${bytes.lengthInBytes}',
      );
    } finally {
      _hideLoadingOverlay();
    }
  }

  Future<void> _handleUrl(String? text) async {
    if (text == null || text.isEmpty) return;

    final urlRegex = RegExp(r'https?://[^\s]+', caseSensitive: false);

    final match = urlRegex.firstMatch(text);
    if (match == null) return;

    final trimmedUrl = match.group(0)!.trim();
    // 1. Duplicate detection
    final existingItem = await _database.getItemByCanonicalUrl(trimmedUrl);

    if (existingItem != null) {
      final resolution = await _showDuplicateDialog(
        trimmedUrl,
        existingItem: existingItem,
      );
      _trackDuplicateDecision(source: trimmedUrl, resolution: resolution);

      if (resolution == DuplicateResolution.openExistingItem) {
        await _openExistingItem(existingItem);
        return;
      }

      if (resolution == DuplicateResolution.keepCurrentItem) {
        return;
      }
    }

    if (!kIsWeb && _isArchiveUrl(trimmedUrl)) {
      await _pushSummaryWhenNavigatorReady(
        (context) => ArchiveScraperScreen(url: trimmedUrl),
      );
      return;
    }

    while (true) {
      _showLoadingOverlay('Processing content...');

      ({String title, String content, String? thumbnailUrl})? result;
      String? author;
      try {
        result = await _extractionService.extractContent(trimmedUrl);
        if (result != null) {
          try {
            author = await _authorExtractionService.extractAuthor(
              url: trimmedUrl,
              metadata: <String, String>{
                if (result.title.trim().isNotEmpty) 'title': result.title,
              },
            );
          } catch (e) {
            // Author extraction is additive and must never block ingestion.
            debugPrint('Author extraction failed for $trimmedUrl: $e');
          }
        }
      } finally {
        _hideLoadingOverlay();
      }

      if (!kIsWeb &&
          _looksLikeJsRequiredContent(result?.content, result?.title)) {
        await _pushSummaryWhenNavigatorReady(
          (context) => JsRenderedScraperScreen(url: trimmedUrl),
        );
        return;
      }

      if (result != null) {
        final resultFromSummary = await _pushSummaryWhenNavigatorReady(
          (context) => IngestionSummaryScreen(
            type: 'url',
            url: trimmedUrl,
            title: result?.title,
            content: result?.content,
            author: author,
            thumbnailUrl: result?.thumbnailUrl,
          ),
        );
        _handleSummaryOutcome(resultFromSummary, source: trimmedUrl);
        return;
      }

      final action = await _showExtractionFailureActions(
        sourceLabel: trimmedUrl,
        canOpenOriginal: true,
      );

      debugPrint(
        'ShareService: extraction failure action source=$trimmedUrl action=$action',
      );

      if (action == IngestionFailureAction.retryExtraction) {
        continue;
      }

      if (action == IngestionFailureAction.openOriginal) {
        await _openOriginalUrl(trimmedUrl);
        return;
      }

      if (action == IngestionFailureAction.reportIssue) {
        _showInfoSnackBar('Please report this issue from Settings > About.');
        return;
      }

      return;
    }
  }

  Future<void> _handleFile(SharedMediaFile sharedFile) async {
    if (kIsWeb) {
      debugPrint('ShareService: file-share intents are not supported on web.');
      return;
    }

    if (!await fileExistsAtPath(sharedFile.path)) return;

    // 1. Duplicate detection
    final fileName = p.basename(sharedFile.path);
    final existingFile = await _database.getItemByFilePath(sharedFile.path);
    if (existingFile != null) {
      final resolution = await _showDuplicateDialog(
        fileName,
        existingItem: existingFile,
      );
      _trackDuplicateDecision(source: fileName, resolution: resolution);

      if (resolution == DuplicateResolution.openExistingItem) {
        await _openExistingItem(existingFile);
        return;
      }

      if (resolution == DuplicateResolution.keepCurrentItem) {
        return;
      }
    }

    _showLoadingOverlay('Saving file...');

    try {
      final newPath = await copySharedFileToAppDocuments(
        sharedFile.path,
        fileName,
      );

      String? extractedText;
      if (fileName.toLowerCase().endsWith('.pdf')) {
        while (true) {
          extractedText = await _pdfExtractionService.extractText(newPath);
          if ((extractedText ?? '').trim().isNotEmpty) {
            break;
          }

          _hideLoadingOverlay();
          final action = await _showExtractionFailureActions(
            sourceLabel: fileName,
            canOpenOriginal: true,
          );

          debugPrint(
            'ShareService: extraction failure action source=$fileName action=$action',
          );

          if (action == IngestionFailureAction.retryExtraction) {
            _showLoadingOverlay('Saving file...');
            continue;
          }

          if (action == IngestionFailureAction.openOriginal) {
            await _openOriginalFile(newPath);
            return;
          }

          if (action == IngestionFailureAction.reportIssue) {
            _showInfoSnackBar(
              'Please report this issue from Settings > About.',
            );
          }

          return;
        }
      }

      _hideLoadingOverlay();
      final resultFromSummary = await _pushSummaryWhenNavigatorReady(
        (context) => IngestionSummaryScreen(
          type: 'file',
          filePath: newPath,
          title: fileName,
          content: extractedText,
        ),
      );
      _handleSummaryOutcome(resultFromSummary, source: fileName);
    } finally {
      _hideLoadingOverlay();
    }
  }

  Future<Object?> _pushSummaryWhenNavigatorReady(WidgetBuilder builder) async {
    const int maxAttempts = 20;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      final navigator = _navigatorKey.currentState;
      if (navigator != null) {
        return navigator.push<dynamic>(
          MaterialPageRoute<dynamic>(builder: builder),
        );
      }

      final completer = Completer<void>();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });
      await completer.future;
    }

    debugPrint('ShareService: navigator not ready, skipping share navigation.');
    return null;
  }

  bool _isArchiveUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final archiveDomains = [
        'archive.ph',
        'archive.today',
        'archive.is',
        'archive.li',
        'archive.vn',
        'archive.fo',
        'archive.md',
        'archive.moe',
      ];
      return archiveDomains.any(
        (domain) => uri.host == domain || uri.host.endsWith('.$domain'),
      );
    } catch (_) {
      return false;
    }
  }

  bool _looksLikeJsRequiredContent(String? content, String? title) {
    final lowerContent = (content ?? '').toLowerCase();
    final lowerTitle = (title ?? '').toLowerCase();

    const blockers = [
      'please enable js',
      'enable javascript',
      'disable any ad blocker',
      'disable your ad blocker',
      'javascript is disabled',
      'turn on javascript',
    ];

    final hasBlockerMessage = blockers.any(
      (k) => lowerContent.contains(k) || lowerTitle.contains(k),
    );

    // Heuristic: blocker pages are usually short and repetitive.
    final contentLength = (content ?? '').trim().length;
    return hasBlockerMessage && contentLength < 2500;
  }

  String _buildPayloadKey(SharedMediaFile file) {
    if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
      final extracted = _extractFirstUrl(file.path);
      if (extracted != null) {
        final normalized = _normalizeUrlKey(extracted);
        return 'url:$normalized';
      }
    }

    return '${file.type.name}:${file.path.trim()}';
  }

  String? _extractFirstUrl(String? text) {
    if (text == null || text.trim().isEmpty) return null;

    final urlRegex = RegExp(r'https?://[^\s]+', caseSensitive: false);

    final match = urlRegex.firstMatch(text);
    return match?.group(0)?.trim();
  }

  String _normalizeUrlKey(String rawUrl) {
    final parsed = Uri.tryParse(rawUrl);
    if (parsed == null) return rawUrl.toLowerCase();

    final scheme = parsed.scheme.toLowerCase();
    final host = parsed.host.toLowerCase();
    final path = parsed.path.isEmpty ? '/' : parsed.path;
    final query = parsed.hasQuery ? '?${parsed.query}' : '';
    return '$scheme://$host$path$query';
  }

  Future<DuplicateResolution> _showDuplicateDialog(
    String identifier, {
    required MnemataItem existingItem,
  }) async {
    final duplicateResolutionOverride = _duplicateResolutionOverride;
    if (duplicateResolutionOverride != null) {
      return await duplicateResolutionOverride(
            identifier: identifier,
            existingItem: existingItem,
          ) ??
          DuplicateResolution.keepCurrentItem;
    }

    final duplicatePromptOverride = _duplicatePromptOverride;
    if (duplicatePromptOverride != null) {
      final addDuplicate = await duplicatePromptOverride(identifier);
      return addDuplicate == true
          ? DuplicateResolution.addDuplicateItem
          : DuplicateResolution.keepCurrentItem;
    }

    final context = _navigatorKey.currentContext;
    if (context == null) {
      return DuplicateResolution.addDuplicateItem;
    }

    return (await showDialog<DuplicateResolution>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Duplicate Detected'),
            content: Text('This item is already in your list:\n\n$identifier'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  DuplicateResolution.openExistingItem,
                ),
                child: const Text('Open Existing Item'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(
                  context,
                  DuplicateResolution.addDuplicateItem,
                ),
                child: const Text('Add Duplicate Item'),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.pop(context, DuplicateResolution.keepCurrentItem),
                child: const Text('Keep Current Item'),
              ),
            ],
          ),
        )) ??
        DuplicateResolution.keepCurrentItem;
  }

  Future<void> _openExistingItem(MnemataItem existingItem) async {
    await _pushSummaryWhenNavigatorReady(
      (context) => ReaderScreen(item: existingItem),
    );
  }

  Future<IngestionFailureAction> _showExtractionFailureActions({
    required String sourceLabel,
    required bool canOpenOriginal,
  }) async {
    final failureActionOverride = _failureActionOverride;
    if (failureActionOverride != null) {
      return failureActionOverride(
        sourceLabel: sourceLabel,
        canOpenOriginal: canOpenOriginal,
      );
    }

    final context = _navigatorKey.currentContext;
    if (context == null) {
      return IngestionFailureAction.dismiss;
    }

    return IngestionFailureActionsSheet.show(
      context,
      sourceLabel: sourceLabel,
      canOpenOriginal: canOpenOriginal,
    );
  }

  Future<void> _openOriginalUrl(String rawUrl) async {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) {
      _showInfoSnackBar('Could not open original URL.');
      return;
    }

    try {
      final launched = await launchUrl(uri);
      if (!launched) {
        _showInfoSnackBar('Could not open original URL.');
      }
    } catch (_) {
      _showInfoSnackBar('Could not open original URL.');
    }
  }

  Future<void> _openOriginalFile(String path) async {
    if (kIsWeb) {
      return;
    }

    try {
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        _showInfoSnackBar('Could not open original file.');
      }
    } catch (_) {
      _showInfoSnackBar('Could not open original file.');
    }
  }

  void _showInfoSnackBar(String message) {
    final context = _navigatorKey.currentContext;
    if (context == null) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _trackDuplicateDecision({
    required String source,
    required DuplicateResolution resolution,
  }) {
    debugPrint(
      'ShareService: duplicate decision source=$source resolution=$resolution',
    );
  }

  void _handleSummaryOutcome(Object? result, {required String source}) {
    if (result == IngestionSummaryResult.saved) {
      debugPrint('ShareService: summary saved source=$source');
      return;
    }

    if (result == IngestionSummaryResult.discarded) {
      _hideLoadingOverlay();
      debugPrint('ShareService: summary discarded source=$source');
      return;
    }

    debugPrint('ShareService: summary closed source=$source result=$result');
  }

  void _showLoadingOverlay(String message) {
    final context = _navigatorKey.currentContext;
    if (context == null || _isLoadingShowing) return;

    _isLoadingShowing = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(message),
            ],
          ),
        ),
      ),
    ).then((_) => _isLoadingShowing = false);
  }

  void _hideLoadingOverlay() {
    if (!_isLoadingShowing) return;

    final navigator = _navigatorKey.currentState;
    if (navigator != null) {
      _isLoadingShowing = false;
      navigator.pop();
    }
  }
}
