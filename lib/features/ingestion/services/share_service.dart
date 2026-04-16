import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/ingestion/presentation/archive_scraper_screen.dart';
import 'package:mnemata/features/ingestion/presentation/ingestion_summary_screen.dart';
import 'package:mnemata/features/ingestion/presentation/js_rendered_scraper_screen.dart';
import 'package:mnemata/features/ingestion/services/author_extraction_service.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:mnemata/features/ingestion/services/pdf_extraction_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ShareService {
  final AppDatabase _database;
  final ExtractionService _extractionService;
  final AuthorExtractionService _authorExtractionService;
  final PdfExtractionService _pdfExtractionService;
  final GlobalKey<NavigatorState> _navigatorKey;
  final Future<bool?> Function(String identifier)? _duplicatePromptOverride;
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
    this._navigatorKey,
    {
    AuthorExtractionService? authorExtractionService,
    Future<bool?> Function(String identifier)? duplicatePromptOverride,
  })  : _authorExtractionService = authorExtractionService ?? AuthorExtractionService(),
        _duplicatePromptOverride = duplicatePromptOverride;

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    _intentDataStreamSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) {
        unawaited(_processIncomingShare(value, source: 'stream'));
      },
      onError: (Object err) {
        debugPrint('getMediaStream error: $err');
        unawaited(_resetShareIntentBuffer());
      },
    );

    ReceiveSharingIntent.instance.getInitialMedia().then(
      (List<SharedMediaFile> value) {
        unawaited(_processIncomingShare(value, source: 'initial'));
      },
    ).catchError((Object err) {
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
      debugPrint('ShareService: queued latest $source payload while another is active');
      await _resetShareIntentBuffer();
      return;
    }

    _isProcessingIncomingShare = true;
    _activeIncomingFingerprint = _buildBatchFingerprint(snapshot);
    debugPrint('ShareService: received $source payload fingerprint=$_activeIncomingFingerprint size=${snapshot.length}');

    // Clear plugin state immediately so stale payloads are not replayed later.
    await _resetShareIntentBuffer();

    try {
      await _handleSharedMedia(snapshot);
    } finally {
      debugPrint('ShareService: cleanup payload fingerprint=$_activeIncomingFingerprint');
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

      if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
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

  Future<void> _handleUrl(String? text) async {
    if (text == null || text.isEmpty) return;

    final urlRegex = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );

    final match = urlRegex.firstMatch(text);
    if (match == null) return;

    final trimmedUrl = match.group(0)!.trim();
    // 1. Duplicate detection
    final existingItem = await _database.getItemByCanonicalUrl(trimmedUrl);

    if (existingItem != null) {
      final confirm = await _showDuplicateDialog(trimmedUrl);
      if (confirm != true) return;
    }

    _showLoadingOverlay('Processing content...');

    try {
      if (_isArchiveUrl(trimmedUrl)) {
        _hideLoadingOverlay();
        await _pushSummaryWhenNavigatorReady(
          (context) => ArchiveScraperScreen(url: trimmedUrl),
        );
        return;
      }

      final result = await _extractionService.extractContent(trimmedUrl);
      String? author;
      try {
        author = await _authorExtractionService.extractAuthor(
          url: trimmedUrl,
          metadata: <String, String>{
            if ((result?.title ?? '').trim().isNotEmpty) 'title': result!.title,
          },
        );
      } catch (e) {
        // Author extraction is additive and must never block ingestion.
        debugPrint('Author extraction failed for $trimmedUrl: $e');
      }

      if (_looksLikeJsRequiredContent(result?.content, result?.title)) {
        _hideLoadingOverlay();
        await _pushSummaryWhenNavigatorReady(
          (context) => JsRenderedScraperScreen(url: trimmedUrl),
        );
        return;
      }

      _hideLoadingOverlay();
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
      debugPrint('ShareService: url summary closed with result=$resultFromSummary');
    } finally {
      _hideLoadingOverlay();
    }
  }

  Future<void> _handleFile(SharedMediaFile sharedFile) async {
    final file = File(sharedFile.path);
    if (!await file.exists()) return;

    // 1. Duplicate detection
    final fileName = p.basename(sharedFile.path);
    final existingFile = await _database.getItemByFilePath(sharedFile.path);
    if (existingFile != null) {
      final confirm = await _showDuplicateDialog(fileName);
      if (confirm != true) return;
    }

    _showLoadingOverlay('Saving file...');

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final newPath = p.join(appDir.path, fileName);

      await file.copy(newPath);

      String? extractedText;
      if (fileName.toLowerCase().endsWith('.pdf')) {
        extractedText = await _pdfExtractionService.extractText(newPath);
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
      debugPrint('ShareService: file summary closed with result=$resultFromSummary');
    } finally {
      _hideLoadingOverlay();
    }
  }

  Future<Object?> _pushSummaryWhenNavigatorReady(
    WidgetBuilder builder,
  ) async {
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
        'archive.moe'
      ];
      return archiveDomains
          .any((domain) => uri.host == domain || uri.host.endsWith('.$domain'));
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

    final hasBlockerMessage = blockers.any((k) =>
        lowerContent.contains(k) || lowerTitle.contains(k));

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

    final urlRegex = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );

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

  Future<bool?> _showDuplicateDialog(String identifier) async {
    final duplicatePromptOverride = _duplicatePromptOverride;
    if (duplicatePromptOverride != null) {
      return duplicatePromptOverride(identifier);
    }

    final context = _navigatorKey.currentContext;
    if (context == null) return true;

    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Duplicate Detected'),
        content: Text('This item seems to be already in your list:\n\n$identifier\n\nDo you want to add it again?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('DISCARD'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ADD AGAIN'),
          ),
        ],
      ),
    );
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
