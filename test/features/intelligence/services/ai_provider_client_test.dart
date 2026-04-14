import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/intelligence/domain/intelligence_errors.dart';
import 'package:mnemata/features/intelligence/services/ai_provider_client.dart';
import 'package:sqlite3/open.dart';

void main() {
  group('AIProviderClient error mapping', () {
    test('maps timeout/auth/rate-limit/network/invalid failures deterministically', () {
      expect(
        mapProviderError(const TimeoutException('timeout')).code,
        IntelligenceErrorCode.timeout,
      );
      expect(
        mapProviderError(const IntelligenceProviderException.auth()).code,
        IntelligenceErrorCode.authenticationFailed,
      );
      expect(
        mapProviderError(const IntelligenceProviderException.rateLimited()).code,
        IntelligenceErrorCode.rateLimited,
      );
      expect(
        mapProviderError(const SocketException('offline')).code,
        IntelligenceErrorCode.providerUnavailable,
      );
      expect(
        mapProviderError(const FormatException('bad response')).code,
        IntelligenceErrorCode.invalidResponse,
      );
    });
  });

  group('AppDatabase intelligence persistence contracts', () {
    late AppDatabase database;

    setUpAll(() {
      if (Platform.isLinux) {
        open.overrideFor(
          OperatingSystem.linux,
          () => DynamicLibrary.open('libsqlite3.so.0'),
        );
      }
    });

    setUp(() {
      database = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await database.close();
    });

    test('summary cache uses content hash keying for idempotency checks', () async {
      final itemId = await database.insertItem(
        MnemataItemsCompanion.insert(type: 'url', createdAt: DateTime.now()),
      );

      await database.upsertSummaryCache(
        itemId: itemId,
        contentHash: 'hash-v1',
        tldr: 'TL;DR block',
        keyPoints: <String>['a', 'b', 'c'],
        whyItMatters: 'reason',
      );

      final cacheHit = await database.getSummaryCache(
        itemId: itemId,
        contentHash: 'hash-v1',
      );
      final cacheMiss = await database.getSummaryCache(
        itemId: itemId,
        contentHash: 'hash-v2',
      );

      expect(cacheHit, isNotNull);
      expect(cacheHit?.contentHash, 'hash-v1');
      expect(cacheMiss, isNull);
    });

    test('semantic metadata/chunks and annotations can be persisted', () async {
      final itemId = await database.insertItem(
        MnemataItemsCompanion.insert(type: 'url', createdAt: DateTime.now()),
      );

      await database.upsertSemanticIndexMetadata(
        itemId: itemId,
        contentHash: 'hash-v1',
        embeddingModel: 'test-model',
        chunkCount: 1,
      );
      await database.replaceSemanticChunks(
        itemId: itemId,
        chunks: <SemanticChunkInput>[
          const SemanticChunkInput(
            chunkIndex: 0,
            text: 'chunk text',
            embeddingVectorJson: '[0.1,0.2]',
          ),
        ],
      );

      final annotationId = await database.insertAnnotation(
        itemId: itemId,
        quoteText: 'quote',
        anchorJson: '{"start":1,"end":2}',
        note: 'note',
      );

      final chunks = await database.readSemanticChunks(itemId);
      final annotations = await database.listAnnotationsForItem(itemId);

      expect(chunks, hasLength(1));
      expect(annotations.any((a) => a.id == annotationId), isTrue);
    });
  });
}
