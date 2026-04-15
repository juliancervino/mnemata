import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/intelligence/domain/intelligence_errors.dart';
import 'package:mnemata/features/intelligence/services/ai_plain_text.dart';
import 'package:mnemata/features/intelligence/services/ai_provider_client.dart';
import 'package:mnemata/features/intelligence/services/api_key_store.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';

enum SummaryStatus { success, unsupported, error }

class SummaryResult {
  const SummaryResult({
    required this.status,
    this.tldr = '',
    this.keyPoints = const <String>[],
    this.whyItMatters = '',
    this.fromCache = false,
    this.errorCode,
    this.guidance = '',
  });

  final SummaryStatus status;
  final String tldr;
  final List<String> keyPoints;
  final String whyItMatters;
  final bool fromCache;
  final IntelligenceErrorCode? errorCode;
  final String guidance;

  bool get isSuccess => status == SummaryStatus.success;
}

class SummaryService {
  SummaryService({
    required AppDatabase database,
    required ApiKeyStore apiKeyStore,
    required AIProviderClient providerClient,
    required SettingsService settingsService,
  }) : _database = database,
       _apiKeyStore = apiKeyStore,
       _providerClient = providerClient,
       _settingsService = settingsService;

  final AppDatabase _database;
  final ApiKeyStore _apiKeyStore;
  final AIProviderClient _providerClient;
  final SettingsService _settingsService;

  Future<SummaryResult?> loadSavedSummary(MnemataItem item) async {
    if (!_supportsSummary(item)) {
      return null;
    }

    final cached = await _database.getSummaryCache(
      itemId: item.id,
      contentHash: _contentHash(toAiPlainText(item.content!)),
    );
    if (cached == null) {
      return null;
    }

    return _toSummaryResult(cached);
  }

  Future<SummaryResult> generateSummary(
    MnemataItem item, {
    bool forceRefresh = false,
  }) async {
    final provider = _settingsService.aiProvider;
    if (!_supportsSummary(item)) {
      return const SummaryResult(
        status: SummaryStatus.unsupported,
        guidance:
            'Summaries are available only for URL items with extracted article content.',
      );
    }

    final content = toAiPlainText(item.content!);
    final contentHash = _contentHash(content);

    if (!forceRefresh) {
      final cached = await _database.getSummaryCache(
        itemId: item.id,
        contentHash: contentHash,
      );
      if (cached != null) {
        return _toSummaryResult(cached);
      }
    }

    final apiKey = await _apiKeyStore.readKeyForProvider(provider);
    if (apiKey == null) {
      return SummaryResult(
        status: SummaryStatus.error,
        errorCode: IntelligenceErrorCode.missingApiKey,
        guidance: 'Add your $provider API key in Settings > Intelligence.',
      );
    }

    try {
      final response = await _providerClient.runPrompt(
        apiKey: apiKey,
        prompt:
            '''
Resume este articulo en CASTELLANO.
Devuelve SOLO JSON valido con este formato exacto:
{"tldr":"...","keyPoints":["...","...","..."],"whyItMatters":"..."}

Requisitos:
- Todo el contenido de salida debe estar en castellano.
- keyPoints debe incluir entre 3 y 5 puntos.
- No incluyas markdown ni texto fuera del JSON.

Articulo:
$content
''',
        provider: parseProviderType(provider),
      );
      final parsed = _parseResponse(response);
      await _database.upsertSummaryCache(
        itemId: item.id,
        contentHash: contentHash,
        tldr: parsed.tldr,
        keyPoints: parsed.keyPoints,
        whyItMatters: parsed.whyItMatters,
      );
      return SummaryResult(
        status: SummaryStatus.success,
        tldr: parsed.tldr,
        keyPoints: parsed.keyPoints,
        whyItMatters: parsed.whyItMatters,
      );
    } on IntelligenceException catch (error) {
      return SummaryResult(
        status: SummaryStatus.error,
        errorCode: error.code,
        guidance: error.message,
      );
    }
  }

  bool _supportsSummary(MnemataItem item) {
    if (item.type != 'url' || item.content == null) {
      return false;
    }
    return toAiPlainText(item.content!).isNotEmpty;
  }

  String _contentHash(String content) {
    return sha256.convert(utf8.encode(content.trim())).toString();
  }

  SummaryResult _toSummaryResult(SummaryCache cached) {
    final keyPoints = cached.keyPointsJson
        .split('\n')
        .map((point) => point.trim())
        .where((point) => point.isNotEmpty)
        .toList(growable: false);
    return SummaryResult(
      status: SummaryStatus.success,
      tldr: cached.tldr,
      keyPoints: keyPoints,
      whyItMatters: cached.whyItMatters,
      fromCache: true,
    );
  }

  _ParsedSummary _parseResponse(Map<String, dynamic> response) {
    final rawTldr = (response['tldr'] ?? '').toString().trim();
    final rawWhyItMatters = (response['whyItMatters'] ?? '').toString().trim();
    final dynamic keyPointsRaw = response['keyPoints'];

    final List<String> keyPoints;
    if (keyPointsRaw is List) {
      keyPoints = keyPointsRaw
          .map((value) => value.toString().trim())
          .where((value) => value.isNotEmpty)
          .take(5)
          .toList(growable: false);
    } else {
      keyPoints = <String>[];
    }

    if (rawTldr.isEmpty || rawWhyItMatters.isEmpty || keyPoints.length < 3) {
      throw const IntelligenceException(
        code: IntelligenceErrorCode.invalidResponse,
        message: 'Provider summary response is incomplete.',
      );
    }

    return _ParsedSummary(
      tldr: rawTldr,
      keyPoints: keyPoints,
      whyItMatters: rawWhyItMatters,
    );
  }
}

class _ParsedSummary {
  const _ParsedSummary({
    required this.tldr,
    required this.keyPoints,
    required this.whyItMatters,
  });

  final String tldr;
  final List<String> keyPoints;
  final String whyItMatters;
}
