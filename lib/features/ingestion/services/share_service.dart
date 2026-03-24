import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mnemata/core/database/app_database.dart';
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

  ShareService(this._database, this._extractionService, this._pdfExtractionService, this._navigatorKey);

  void init() {
    // For sharing while the app is in memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream()
        .listen((List<SharedMediaFile> value) {
      _handleSharedMedia(value);
    }, onError: (err) {
      print("getMediaStream error: $err");
    });

    // For sharing while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      _handleSharedMedia(value);
      ReceiveSharingIntent.instance.reset();
    });
  }

  void dispose() {
    _intentDataStreamSubscription?.cancel();
  }

  Future<void> _handleSharedMedia(List<SharedMediaFile> files) async {
    for (final file in files) {
      if (file.type == SharedMediaType.text || file.type == SharedMediaType.url) {
        await handleUrl(file.path);
      } else {
        await handleFile(file);
      }
    }
  }

  Future<void> handleUrl(String? text) async {
    if (text == null || text.isEmpty) return;
    
    // Regex to find the first URL in the text
    final urlRegex = RegExp(
      r'https?://[^\s]+',
      caseSensitive: false,
    );
    
    final match = urlRegex.firstMatch(text);
    if (match == null) return;
    
    final trimmedUrl = match.group(0)!.trim();

    // Perform extraction first
    final result = await _extractionService.extractContent(trimmedUrl);
    
    // Navigate to summary screen
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => IngestionSummaryScreen(
          type: 'url',
          url: trimmedUrl,
          title: result?.title,
          content: result?.content,
          thumbnailUrl: result?.thumbnailUrl,
        ),
      ),
    );
  }

  Future<void> handleFile(SharedMediaFile sharedFile) async {
    final file = File(sharedFile.path);
    if (!await file.exists()) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(sharedFile.path);
    final newPath = p.join(appDir.path, fileName);

    // Copy to permanent storage
    await file.copy(newPath);

    String? extractedText;
    if (fileName.toLowerCase().endsWith('.pdf')) {
      extractedText = await _pdfExtractionService.extractText(newPath);
    }

    // Navigate to summary screen
    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (context) => IngestionSummaryScreen(
          type: 'file',
          filePath: newPath,
          title: fileName,
          content: extractedText,
        ),
      ),
    );
  }
}
