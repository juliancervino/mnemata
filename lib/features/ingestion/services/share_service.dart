import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/ingestion/presentation/archive_scraper_screen.dart';
import 'package:mnemata/features/ingestion/presentation/ingestion_summary_screen.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:mnemata/features/ingestion/services/pdf_extraction_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ShareService {
  final AppDatabase _database;
  final ExtractionService _extractionService;
  final PdfExtractionService _pdfExtractionService;
  final GlobalKey<NavigatorState> _navigatorKey;
  StreamSubscription? _intentDataStreamSubscription;

  bool _isInitialized = false;
  int _latestRequestId = 0;
  String? _lastProcessedPayloadKey;
  DateTime? _lastProcessedAt;
  static const Duration _dedupeWindow = Duration(seconds: 10);

  ShareService(
    this._database,
    this._extractionService,
    this._pdfExtractionService,
    this._navigatorKey,
  );

  void init() {
    if (_isInitialized) return;
    _isInitialized = true;

    _intentDataStreamSubscription =
        ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> value) async {
        try {
          await _handleSharedMedia(value);
        } finally {
          ReceiveSharingIntent.instance.reset();
        }
      },
      onError: (Object err) {
        debugPrint('getMediaStream error: $err');
      },
    );

    ReceiveSharingIntent.instance.getInitialMedia().then(
      (List<SharedMediaFile> value) async {
        try {
          await _handleSharedMedia(value);
        } finally {
          ReceiveSharingIntent.instance.reset();
        }
      },
    ).catchError((Object err) {
      debugPrint('getInitialMedia error: $err');
    });
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
    _isInitialized = false;
  }

  Future<void> _handleSharedMedia(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;

    final int requestId = ++_latestRequestId;

    for (final file in files) {
      if (requestId != _latestRequestId) return;

      final String payloadKey = _buildPayloadKey(file);
      final DateTime now = DateTime.now();
      if (_lastProcessedPayloadKey == payloadKey &&
          _lastProcessedAt != null &&
          now.difference(_lastProcessedAt!) < _dedupeWindow) {
        continue;
      }

      _lastProcessedPayloadKey = payloadKey;
      _lastProcessedAt = now;

      if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
        await _handleUrl(file.path, requestId);
      } else {
        await _handleFile(file, requestId);
      }
    }
  }

  Future<void> handleUrl(String? text) async {
    final int requestId = ++_latestRequestId;
    await _handleUrl(text, requestId);
  }

  Future<void> handleFile(SharedMediaFile sharedFile) async {
    final int requestId = ++_latestRequestId;
    await _handleFile(sharedFile, requestId);
  }

  Future<void> _handleUrl(String? text, int requestId) async {
    if (text == null || text.isEmpty) return;

    final urlRegex = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );

    final match = urlRegex.firstMatch(text);
    if (match == null) return;

    final trimmedUrl = match.group(0)!.trim();

    // 1. Duplicate detection
    final existingItem = await _database.getItemByUrl(trimmedUrl);
    if (existingItem != null && requestId == _latestRequestId) {
      final confirm = await _showDuplicateDialog(trimmedUrl);
      if (confirm != true) return;
    }

    _showLoadingOverlay('Processing content...');

    try {
      if (_isArchiveUrl(trimmedUrl)) {
        if (requestId != _latestRequestId) return;
        _hideLoadingOverlay();
        await _pushSummaryWhenNavigatorReady(
          requestId,
          (context) => ArchiveScraperScreen(url: trimmedUrl),
        );
        return;
      }

      final result = await _extractionService.extractContent(trimmedUrl);

      if (requestId != _latestRequestId) return;

      await _pushSummaryWhenNavigatorReady(
        requestId,
        (context) => IngestionSummaryScreen(
          type: 'url',
          url: trimmedUrl,
          title: result?.title,
          content: result?.content,
          thumbnailUrl: result?.thumbnailUrl,
        ),
      );
    } finally {
      _hideLoadingOverlay();
    }
  }

  Future<void> _handleFile(SharedMediaFile sharedFile, int requestId) async {
    final file = File(sharedFile.path);
    if (!await file.exists()) return;

    // 1. Duplicate detection
    final fileName = p.basename(sharedFile.path);
    final existingFile = await _database.getItemByFilePath(sharedFile.path);
    if (existingFile != null && requestId == _latestRequestId) {
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

      if (requestId != _latestRequestId) return;

      await _pushSummaryWhenNavigatorReady(
        requestId,
        (context) => IngestionSummaryScreen(
          type: 'file',
          filePath: newPath,
          title: fileName,
          content: extractedText,
        ),
      );
    } finally {
      _hideLoadingOverlay();
    }
  }

  Future<void> _pushSummaryWhenNavigatorReady(
    int requestId,
    WidgetBuilder builder,
  ) async {
    const int maxAttempts = 20;

    for (int attempt = 0; attempt < maxAttempts; attempt++) {
      if (requestId != _latestRequestId) return;

      final navigator = _navigatorKey.currentState;
      if (navigator != null) {
        navigator.push(MaterialPageRoute(builder: builder));
        return;
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
    if (context == null) return;

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
    );
  }

  void _hideLoadingOverlay() {
    final context = _navigatorKey.currentContext;
    if (context == null) return;

    final navigator = _navigatorKey.currentState;
    if (navigator != null) {
      navigator.popUntil((route) => route is! RawDialogRoute);
    }
  }
}
