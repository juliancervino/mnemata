import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/intelligence/services/api_key_store.dart';

typedef EmbeddingGenerator = Future<List<double>> Function(String text);

class SemanticIndexerService {
  SemanticIndexerService({
    required AppDatabase database,
    required ApiKeyStore apiKeyStore,
    required EmbeddingGenerator embeddingGenerator,
    this.embeddingModel = 'mock-embedding-v1',
  }) : _database = database,
       _apiKeyStore = apiKeyStore,
       _embeddingGenerator = embeddingGenerator;

  final AppDatabase _database;
  final ApiKeyStore _apiKeyStore;
  final EmbeddingGenerator _embeddingGenerator;
  final String embeddingModel;

  final List<Future<void>> _pending = <Future<void>>[];

  Future<void> enqueueIndexing(MnemataItem item) async {
    final content = item.content?.trim() ?? '';
    if (item.type != 'url' || content.isEmpty) {
      return;
    }
    if (!await _apiKeyStore.hasKey()) {
      return;
    }

    final future = _indexNow(item.id, content);
    _pending.add(future);
    unawaited(future.whenComplete(() => _pending.remove(future)));
  }

  Future<void> flushPending() async {
    while (_pending.isNotEmpty) {
      await Future.wait(_pending.toList(growable: false));
    }
  }

  Future<void> _indexNow(int itemId, String content) async {
    final chunks = _chunkContent(content);
    final chunkInputs = <SemanticChunkInput>[];
    for (var i = 0; i < chunks.length; i++) {
      final vector = await _embeddingGenerator(chunks[i]);
      chunkInputs.add(
        SemanticChunkInput(
          chunkIndex: i,
          text: chunks[i],
          embeddingVectorJson: jsonEncode(vector),
        ),
      );
    }

    await _database.replaceSemanticChunks(itemId: itemId, chunks: chunkInputs);
    await _database.upsertSemanticIndexMetadata(
      itemId: itemId,
      contentHash: sha256.convert(utf8.encode(content)).toString(),
      embeddingModel: embeddingModel,
      chunkCount: chunkInputs.length,
    );
  }

  List<String> _chunkContent(String content) {
    final normalized = content.replaceAll('\n', ' ').trim();
    if (normalized.isEmpty) {
      return const <String>[];
    }

    const maxLen = 400;
    final chunks = <String>[];
    for (var i = 0; i < normalized.length; i += maxLen) {
      final end = (i + maxLen < normalized.length) ? i + maxLen : normalized.length;
      chunks.add(normalized.substring(i, end));
    }
    return chunks;
  }
}
