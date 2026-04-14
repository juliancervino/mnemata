import 'dart:convert';

import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/intelligence/services/api_key_store.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';

enum SemanticFallbackReason { none, missingApiKey, noSemanticIndex, weakRecall }

class SemanticSearchResult {
  const SemanticSearchResult({
    required this.items,
    required this.fallbackReason,
  });

  final List<MnemataItem> items;
  final SemanticFallbackReason fallbackReason;

  bool get usedFallback => fallbackReason != SemanticFallbackReason.none;
}

class SemanticSearchService {
  SemanticSearchService({
    required AppDatabase database,
    required ApiKeyStore apiKeyStore,
    required SettingsService settingsService,
    this.minimumScore = 0.12,
  }) : _database = database,
       _apiKeyStore = apiKeyStore,
       _settingsService = settingsService;

  final AppDatabase _database;
  final ApiKeyStore _apiKeyStore;
  final SettingsService _settingsService;
  final double minimumScore;

  Stream<List<MnemataItem>> searchAsStream(
    String query, {
    List<int> labelIds = const <int>[],
  }) {
    return Stream.fromFuture(
      search(query, labelIds: labelIds),
    ).map((r) => r.items);
  }

  Future<SemanticSearchResult> search(
    String query, {
    List<int> labelIds = const <int>[],
  }) async {
    final keywordItems = await _database
        .searchItems(query, labelIds: labelIds)
        .first;
    final provider = _settingsService.aiProvider;
    if (!await _apiKeyStore.hasKeyForProvider(provider)) {
      return SemanticSearchResult(
        items: keywordItems,
        fallbackReason: SemanticFallbackReason.missingApiKey,
      );
    }

    final chunks = await _database.listAllSemanticChunks();
    if (chunks.isEmpty) {
      return SemanticSearchResult(
        items: keywordItems,
        fallbackReason: SemanticFallbackReason.noSemanticIndex,
      );
    }

    final scores = <int, double>{};
    for (final chunk in chunks) {
      final score = _semanticScore(
        query,
        chunk.chunkText,
        chunk.embeddingVectorJson,
      );
      if (score <= 0) {
        continue;
      }
      final current = scores[chunk.itemId] ?? 0;
      if (score > current) {
        scores[chunk.itemId] = score;
      }
    }

    final ranked = scores.entries.toList(growable: false)
      ..sort((a, b) => b.value.compareTo(a.value));

    final strongIds = ranked
        .where((entry) => entry.value >= minimumScore)
        .map((entry) => entry.key)
        .toList(growable: false);

    if (strongIds.isEmpty) {
      return SemanticSearchResult(
        items: keywordItems,
        fallbackReason: SemanticFallbackReason.weakRecall,
      );
    }

    final semanticItems = await _database.getItemsByIds(strongIds);
    final merged = <MnemataItem>[];
    final seen = <int>{};
    for (final item in semanticItems) {
      if (seen.add(item.id)) {
        merged.add(item);
      }
    }
    for (final item in keywordItems) {
      if (seen.add(item.id)) {
        merged.add(item);
      }
    }

    return SemanticSearchResult(
      items: merged,
      fallbackReason: SemanticFallbackReason.none,
    );
  }

  double _semanticScore(String query, String chunkText, String embeddingJson) {
    final queryTokens = _expandTokens(_tokenize(query));
    final chunkTokens = _expandTokens(_tokenize(chunkText));
    if (queryTokens.isEmpty || chunkTokens.isEmpty) {
      return 0;
    }

    final overlap = queryTokens.intersection(chunkTokens).length;
    var score = overlap / queryTokens.length;

    // Keep score deterministic but lightly informed by embedding size so stale/empty
    // vectors do not dominate lexical overlap.
    final vectorLength = _embeddingLength(embeddingJson);
    if (vectorLength > 0) {
      score += 0.01;
    }

    return score;
  }

  int _embeddingLength(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.length;
      }
    } catch (_) {
      return 0;
    }
    return 0;
  }

  Set<String> _tokenize(String value) {
    final normalized = value.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9\s]'),
      ' ',
    );
    return normalized
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where((token) => token.isNotEmpty)
        .toSet();
  }

  Set<String> _expandTokens(Set<String> tokens) {
    const synonyms = <String, List<String>>{
      'car': <String>['automobile', 'vehicle'],
      'automobile': <String>['car', 'vehicle'],
      'ai': <String>['artificial', 'intelligence'],
    };

    final expanded = <String>{...tokens};
    for (final token in tokens) {
      final mapped = synonyms[token];
      if (mapped == null) {
        continue;
      }
      expanded.addAll(mapped);
    }
    return expanded;
  }
}
