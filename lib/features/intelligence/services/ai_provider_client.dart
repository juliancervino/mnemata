import 'dart:async';
import 'dart:io';

import 'package:mnemata/features/intelligence/domain/intelligence_errors.dart';

class AIProviderRequest {
  const AIProviderRequest({
    required this.apiKey,
    required this.prompt,
  });

  final String apiKey;
  final String prompt;
}

typedef AIProviderExecutor = Future<Map<String, dynamic>> Function(
  AIProviderRequest request,
);

IntelligenceException mapProviderError(Object error) {
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
    required AIProviderExecutor executor,
    this.timeout = const Duration(seconds: 15),
  }) : _executor = executor;

  final AIProviderExecutor _executor;
  final Duration timeout;

  Future<Map<String, dynamic>> runPrompt({
    required String apiKey,
    required String prompt,
  }) async {
    if (apiKey.trim().isEmpty) {
      throw const IntelligenceException(
        code: IntelligenceErrorCode.missingApiKey,
        message: 'API key is required.',
      );
    }

    try {
      final response = await _executor(
        AIProviderRequest(apiKey: apiKey.trim(), prompt: prompt),
      ).timeout(timeout);
      return response;
    } catch (error) {
      throw mapProviderError(error);
    }
  }
}
