import 'package:google_sign_in/google_sign_in.dart';

enum GoogleDriveAuthErrorCode {
  notSignedIn,
  tokenUnavailable,
  cancelled,
  unknown,
}

class GoogleDriveAuthException implements Exception {
  const GoogleDriveAuthException({
    required this.code,
    required this.message,
    this.cause,
  });

  final GoogleDriveAuthErrorCode code;
  final String message;
  final Object? cause;

  @override
  String toString() =>
      'GoogleDriveAuthException(code: $code, message: $message)';
}

class GoogleDriveAuthClient {
  GoogleDriveAuthClient({
    Future<String> Function()? accessTokenProvider,
    Future<String> Function()? refreshTokenProvider,
    GoogleSignIn? googleSignIn,
    DateTime Function()? clock,
    Duration? expirySkew,
    Duration? tokenTtl,
  }) : _clock = clock ?? DateTime.now,
       _expirySkew = expirySkew ?? const Duration(minutes: 2),
       _tokenTtl = tokenTtl ?? const Duration(minutes: 50),
       _googleSignIn =
           googleSignIn ??
           GoogleSignIn.standard(
             scopes: const <String>[
               'email',
               'https://www.googleapis.com/auth/drive.file',
             ],
           ),
       _accessTokenProvider = accessTokenProvider,
       _refreshTokenProvider = refreshTokenProvider;

  final DateTime Function() _clock;
  final Duration _expirySkew;
  final Duration _tokenTtl;
  final GoogleSignIn _googleSignIn;
  final Future<String> Function()? _accessTokenProvider;
  final Future<String> Function()? _refreshTokenProvider;

  String? _cachedAccessToken;
  DateTime? _cachedExpiryUtc;

  Future<String> getAccessToken() async {
    if (_hasValidToken()) {
      return _cachedAccessToken!;
    }

    final token = await _resolveAccessToken();
    _cacheToken(token);
    return token;
  }

  Future<String> refreshIfNeeded() async {
    if (_hasValidToken()) {
      return _cachedAccessToken!;
    }

    final token = await _resolveRefreshedToken();
    _cacheToken(token);
    return token;
  }

  bool _hasValidToken() {
    final token = _cachedAccessToken;
    final expiry = _cachedExpiryUtc;
    if (token == null || token.isEmpty || expiry == null) {
      return false;
    }

    final remaining = expiry.difference(_clock().toUtc());
    return remaining > _expirySkew;
  }

  Future<String> _resolveAccessToken() async {
    final provider = _accessTokenProvider;
    if (provider != null) {
      return _requireToken(await provider(), context: 'access token provider');
    }

    return _resolveTokenFromGoogleSignIn(interactive: true);
  }

  Future<String> _resolveRefreshedToken() async {
    final provider = _refreshTokenProvider;
    if (provider != null) {
      return _requireToken(await provider(), context: 'refresh token provider');
    }

    return _resolveTokenFromGoogleSignIn(interactive: false);
  }

  Future<String> _resolveTokenFromGoogleSignIn({
    required bool interactive,
  }) async {
    try {
      GoogleSignInAccount? account = _googleSignIn.currentUser;
      account ??= await _googleSignIn.signInSilently();
      if (account == null && interactive) {
        account = await _googleSignIn.signIn();
      }

      if (account == null) {
        throw const GoogleDriveAuthException(
          code: GoogleDriveAuthErrorCode.notSignedIn,
          message: 'Google sign-in is required before Drive backup.',
        );
      }

      final auth = await account.authentication;
      final accessToken = auth.accessToken;
      return _requireToken(
        accessToken,
        context: 'Google Sign-In authentication',
      );
    } on GoogleDriveAuthException {
      rethrow;
    } catch (error) {
      throw GoogleDriveAuthException(
        code: GoogleDriveAuthErrorCode.unknown,
        message: 'Unable to resolve Google Drive access token.',
        cause: error,
      );
    }
  }

  String _requireToken(String? token, {required String context}) {
    final normalized = token?.trim();
    if (normalized == null || normalized.isEmpty) {
      throw GoogleDriveAuthException(
        code: GoogleDriveAuthErrorCode.tokenUnavailable,
        message: 'No access token returned from $context.',
      );
    }

    return normalized;
  }

  void _cacheToken(String token) {
    _cachedAccessToken = token;
    _cachedExpiryUtc = _clock().toUtc().add(_tokenTtl);
  }
}
