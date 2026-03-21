import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/ingestion/services/extraction_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ShareService {
  final AppDatabase _database;
  final ExtractionService _extractionService;
  StreamSubscription? _intentDataStreamSubscription;

  ShareService(this._database, this._extractionService);

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

  Future<void> handleUrl(String? url) async {
    if (url == null || url.isEmpty) return;

    // Basic URL validation/cleaning could be added here
    final trimmedUrl = url.trim();

    // Duplicate check
    final existing = await (_database.select(_database.mnemataItems)
          ..where((t) => t.url.equals(trimmedUrl)))
        .getSingleOrNull();

    if (existing != null) return;

    final id = await _database.insertItem(MnemataItemsCompanion.insert(
      url: Value(trimmedUrl),
      type: 'url',
      createdAt: DateTime.now(),
    ));

    // Trigger extraction asynchronously
    unawaited(processUrl(id, trimmedUrl));
  }

  Future<void> processUrl(int id, String url) async {
    try {
      final result = await _extractionService.extractContent(url);
      if (result != null) {
        await _database.updateItemContent(id, result.content, result.title);
      }
    } catch (e) {
      print("Error processing URL extraction: $e");
    }
  }

  Future<void> handleFile(SharedMediaFile sharedFile) async {
    final file = File(sharedFile.path);
    if (!await file.exists()) return;

    final appDir = await getApplicationDocumentsDirectory();
    final fileName = p.basename(sharedFile.path);
    final newPath = p.join(appDir.path, fileName);

    // Duplicate check based on path (simple check)
    final existing = await (_database.select(_database.mnemataItems)
          ..where((t) => t.filePath.equals(newPath)))
        .getSingleOrNull();

    if (existing != null) return;

    // Copy to permanent storage
    await file.copy(newPath);

    await _database.insertItem(MnemataItemsCompanion.insert(
      title: Value(fileName),
      filePath: Value(newPath),
      type: 'file',
      createdAt: DateTime.now(),
    ));
  }
}
