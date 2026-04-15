import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mnemata/features/intelligence/domain/intelligence_errors.dart';

enum AIProviderType { gemini, openai, claude }

AIProviderType parseProviderType(String raw) {
  switch (raw.trim().toLowerCase()) {
    case 'openai':
      return AIProviderType.openai;
    case 'claude':
      return AIProviderType.claude;
    case 'gemini':
    default:
      return AIProviderType.gemini;
  }
}

class AIProviderRequest {
  const AIProviderRequest({
    required this.apiKey,
    required this.prompt,
    required this.provider,
  });

  final String apiKey;
  final String prompt;
  final AIProviderType provider;
}

typedef AIProviderExecutor =
    Future<Map<String, dynamic>> Function(AIProviderRequest request);

IntelligenceException mapProviderError(Object error) {
  if (error is IntelligenceException) {
    return error;
  }
  if (error is IntelligenceProviderException) {
    return IntelligenceException(code: error.code, message: error.message);
  }
  if (error is TimeoutException) {
    return const IntelligenceException(
      code: IntelligenceErrorCode.timeout,
      message: 'Provider request timed out.',
    );
  }
  if (error is SocketException) {
    return const IntelligenceException(
      code: IntelligenceErrorCode.providerUnavailable,
      message: 'Network unavailable while contacting provider.',
    );
  }
  if (error is FormatException) {
    return const IntelligenceException(
      code: IntelligenceErrorCode.invalidResponse,
      message: 'Provider response format is invalid.',
    );
  }

  return const IntelligenceException(
    code: IntelligenceErrorCode.providerUnavailable,
    message: 'Provider request failed.',
  );
}

class AIProviderClient {
  AIProviderClient({
    AIProviderExecutor? executor,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 15),
    this.geminiModel = 'gemini-2.5-flash-lite',
    this.openAiModel = 'gpt-5-nano',
    this.claudeModel = 'claude-haiku-4-5-20251001',
  }) : _executor = executor,
       _httpClient = httpClient;

  final AIProviderExecutor? _executor;
  final http.Client? _httpClient;
  final Duration timeout;
  final String geminiModel;
  final String openAiModel;
  final String claudeModel;

  Future<Map<String, dynamic>> runPrompt({
    required String apiKey,
    required String prompt,
    AIProviderType provider = AIProviderType.gemini,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw const IntelligenceException(
        code: IntelligenceErrorCode.missingApiKey,
        message: 'API key is required.',
      );
    }

    try {
      if (_executor != null) {
        final response = await _executor(
          AIProviderRequest(
            apiKey: apiKey.trim(),
            prompt: prompt,
            provider: provider,
          ),
        ).timeout(timeout);
        return response;
      }

      final response = await _runHttpProvider(
        provider: provider,
        apiKey: apiKey.trim(),
        prompt: prompt,
      ).timeout(timeout);
      return response;
    } catch (error) {
      throw mapProviderError(error);
    }
  }

  Future<Map<String, dynamic>> _runHttpProvider({
    required AIProviderType provider,
    required String apiKey,
    required String prompt,
  }) async {
    final client = _httpClient ?? http.Client();
    try {
      switch (provider) {
        case AIProviderType.gemini:
          return _runGemini(client, apiKey: apiKey, prompt: prompt);
        case AIProviderType.openai:
          return _runOpenAi(client, apiKey: apiKey, prompt: prompt);
        case AIProviderType.claude:
          return _runClaude(client, apiKey: apiKey, prompt: prompt);
      }
    } finally {
      if (_httpClient == null) {
        client.close();
      }
    }
  }

  Future<Map<String, dynamic>> _runGemini(
    http.Client client, {
    required String apiKey,
    required String prompt,
  }) async {
    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$geminiModel:generateContent?key=$apiKey',
    );
    final response = await client.post(
      uri,
      headers: <String, String>{'Content-Type': 'application/json'},
      body: jsonEncode(<String, dynamic>{
        'contents': <Map<String, dynamic>>[
          <String, dynamic>{
            'parts': <Map<String, String>>[
              <String, String>{'text': prompt},
            ],
          },
        ],
      }),
    );

    _throwIfFailed(response.statusCode, response.body);
    final payload = _decodeObject(response.body);
    final candidates = payload['candidates'];
    if (candidates is! List || candidates.isEmpty) {
      throw const FormatException('Gemini response missing candidates.');
    }
    final first = candidates.first;
    if (first is! Map<String, dynamic>) {
      throw const FormatException('Gemini candidate payload invalid.');
    }
    final content = first['content'];
    if (content is! Map<String, dynamic>) {
      throw const FormatException('Gemini content payload invalid.');
    }
    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) {
      throw const FormatException('Gemini parts payload invalid.');
    }
    final part = parts.first;
    if (part is! Map<String, dynamic>) {
      throw const FormatException('Gemini part payload invalid.');
    }

    final text = (part['text'] ?? '').toString();
    return _decodeJsonObjectFromText(text);
  }

  Future<Map<String, dynamic>> _runOpenAi(
    http.Client client, {
    required String apiKey,
    required String prompt,
  }) async {
    const endpoint = 'https://api.openai.com/v1/chat/completions';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(<String, dynamic>{
        'model': openAiModel,
        'messages': <Map<String, String>>[
          <String, String>{'role': 'user', 'content': prompt},
        ],
      }),
    );

    _throwIfFailed(response.statusCode, response.body);
    final payload = _decodeObject(response.body);
    final choices = payload['choices'];
    if (choices is! List || choices.isEmpty) {
      throw const FormatException('OpenAI response missing choices.');
    }
    final first = choices.first;
    if (first is! Map<String, dynamic>) {
      throw const FormatException('OpenAI choice payload invalid.');
    }
    final message = first['message'];
    if (message is! Map<String, dynamic>) {
      throw const FormatException('OpenAI message payload invalid.');
    }
    final text = (message['content'] ?? '').toString();
    return _decodeJsonObjectFromText(text);
  }

  Future<Map<String, dynamic>> _runClaude(
    http.Client client, {
    required String apiKey,
    required String prompt,
  }) async {
    const endpoint = 'https://api.anthropic.com/v1/messages';
    final response = await client.post(
      Uri.parse(endpoint),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode(<String, dynamic>{
        'model': claudeModel,
        'max_tokens': 800,
        'messages': <Map<String, String>>[
          <String, String>{'role': 'user', 'content': prompt},
        ],
      }),
    );

    _throwIfFailed(response.statusCode, response.body);
    final payload = _decodeObject(response.body);
    final content = payload['content'];
    if (content is! List || content.isEmpty) {
      throw const FormatException('Claude response missing content.');
    }
    final first = content.first;
    if (first is! Map<String, dynamic>) {
      throw const FormatException('Claude content item invalid.');
    }
    final text = (first['text'] ?? '').toString();
    return _decodeJsonObjectFromText(text);
  }

  Map<String, dynamic> _decodeObject(String rawBody) {
    final decoded = jsonDecode(rawBody);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Provider response is not a JSON object.');
    }
    return decoded;
  }

  Map<String, dynamic> _decodeJsonObjectFromText(String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Provider response text is empty.');
    }

    final direct = _tryDecodeAsMap(trimmed);
    if (direct != null) {
      return direct;
    }

    final match = RegExp(r'\{[\s\S]*\}').firstMatch(trimmed);
    if (match != null) {
      final candidate = trimmed.substring(match.start, match.end);
      final extracted = _tryDecodeAsMap(candidate);
      if (extracted != null) {
        return extracted;
      }
    }

    throw const FormatException(
      'Provider response did not contain valid JSON object.',
    );
  }

  Map<String, dynamic>? _tryDecodeAsMap(String raw) {
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  void _throwIfFailed(int statusCode, String body) {
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }

    final details = _extractProviderErrorMessage(body);
    if (statusCode == 401 || statusCode == 403) {
      throw IntelligenceException(
        code: IntelligenceErrorCode.authenticationFailed,
        message: details.isEmpty ? 'Provider authentication failed.' : details,
      );
    }
    if (statusCode == 429) {
      throw IntelligenceException(
        code: IntelligenceErrorCode.rateLimited,
        message: details.isEmpty ? 'Provider rate limit exceeded.' : details,
      );
    }
    if (statusCode >= 400 && statusCode < 500) {
      throw IntelligenceException(
        code: IntelligenceErrorCode.invalidResponse,
        message: details.isEmpty
            ? 'Provider request was rejected (HTTP $statusCode).'
            : details,
      );
    }
    throw IntelligenceException(
      code: IntelligenceErrorCode.providerUnavailable,
      message: details.isEmpty
          ? 'Provider is unavailable (HTTP $statusCode).'
          : details,
    );
  }

  String _extractProviderErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }

        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      // Best effort.
    }

    return '';
  }
}
