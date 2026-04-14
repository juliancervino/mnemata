import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/intelligence/domain/intelligence_errors.dart';
import 'package:mnemata/features/intelligence/services/ai_provider_client.dart';
import 'package:mnemata/features/intelligence/services/api_key_store.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';

enum TagSuggestionStatus { success, unsupported, error }

class TagSuggestionResult {
  const TagSuggestionResult({
    required this.status,
    this.suggestedLabels = const <Label>[],
    this.errorCode,
    this.guidance = '',
  });

  final TagSuggestionStatus status;
  final List<Label> suggestedLabels;
  final IntelligenceErrorCode? errorCode;
  final String guidance;

  bool get isSuccess => status == TagSuggestionStatus.success;
}

class TagSuggestionService {
  TagSuggestionService({
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

  Future<TagSuggestionResult> suggestForItem(MnemataItem item) async {
    final provider = _settingsService.aiProvider;
    final apiKey = await _apiKeyStore.readKeyForProvider(provider);
    if (apiKey == null) {
      return TagSuggestionResult(
        status: TagSuggestionStatus.error,
        errorCode: IntelligenceErrorCode.missingApiKey,
        guidance: 'Add your $provider API key in Settings > Intelligence.',
      );
    }

    final content = item.content?.trim() ?? '';
    if (content.isEmpty) {
      return const TagSuggestionResult(
        status: TagSuggestionStatus.unsupported,
        guidance: 'Tag suggestions require extracted article content.',
      );
    }

    final labels = await _database.watchAllLabels().first;
    if (labels.isEmpty) {
      return const TagSuggestionResult(
        status: TagSuggestionStatus.success,
        suggestedLabels: <Label>[],
      );
    }

    final prompt = StringBuffer()
      ..writeln('Suggest existing labels only from this allowed set:')
      ..writeln(labels.map((label) => label.name).join(', '))
      ..writeln('Title: ${item.title ?? ''}')
      ..writeln(
        'Content excerpt: ${content.length > 1200 ? content.substring(0, 1200) : content}',
      )
      ..writeln('Return JSON: {"tagNames": ["name1", "name2"]}');

    try {
      final response = await _providerClient.runPrompt(
        apiKey: apiKey,
        prompt: prompt.toString(),
        provider: parseProviderType(provider),
      );
      final dynamic raw = response['tagNames'];
      final requestedNames = raw is List
          ? raw.map((e) => e.toString()).toList(growable: false)
          : const <String>[];
      final allowedByName = <String, Label>{
        for (final label in labels) label.name.toLowerCase(): label,
      };

      final selected = <Label>[];
      final seenIds = <int>{};
      for (final name in requestedNames) {
        final match = allowedByName[name.trim().toLowerCase()];
        if (match == null || seenIds.contains(match.id)) {
          continue;
        }
        selected.add(match);
        seenIds.add(match.id);
      }

      return TagSuggestionResult(
        status: TagSuggestionStatus.success,
        suggestedLabels: selected,
      );
    } on IntelligenceException catch (error) {
      return TagSuggestionResult(
        status: TagSuggestionStatus.error,
        errorCode: error.code,
        guidance: error.message,
      );
    }
  }

  Future<void> applySuggestions({
    required int itemId,
    required List<Label> labels,
  }) async {
    for (final label in labels) {
      await _database.assignLabelToItem(itemId, label.id);
    }
  }
}
