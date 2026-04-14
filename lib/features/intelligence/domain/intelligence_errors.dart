enum IntelligenceErrorCode {
  missingApiKey,
  timeout,
  authenticationFailed,
  rateLimited,
  providerUnavailable,
  invalidResponse,
}

class IntelligenceException implements Exception {
  const IntelligenceException({
    required this.code,
    required this.message,
  });

  final IntelligenceErrorCode code;
  final String message;

  @override
  String toString() => 'IntelligenceException(code: $code, message: $message)';
}

class IntelligenceProviderException implements Exception {
  const IntelligenceProviderException._({
    required this.code,
    required this.message,
  });

  const IntelligenceProviderException.auth()
      : this._(
          code: IntelligenceErrorCode.authenticationFailed,
          message: 'Provider authentication failed.',
        );

  const IntelligenceProviderException.rateLimited()
      : this._(
          code: IntelligenceErrorCode.rateLimited,
          message: 'Provider rate limit exceeded.',
        );

  const IntelligenceProviderException.unavailable()
      : this._(
          code: IntelligenceErrorCode.providerUnavailable,
          message: 'Provider is unavailable.',
        );

  final IntelligenceErrorCode code;
  final String message;
}
