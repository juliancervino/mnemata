import 'package:path/path.dart' as p;

class WebFileValidation {
  static const int maxFileSizeBytes = 25 * 1024 * 1024;

  static const String unsupportedFileTypeMessage =
      'Unsupported file type. Phase 19 supports PDF and image files.';

  static const String oversizeFileMessage =
      'File is too large. Maximum supported size is 25 MB.';

  static const String invalidUrlMessage = 'Enter a valid http(s) URL.';

  static const Set<String> supportedExtensions = <String>{
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'webp',
  };

  static String? validate({
    required String fileName,
    required int sizeInBytes,
  }) {
    final extension = _normalizedExtension(fileName);

    if (!supportedExtensions.contains(extension)) {
      return unsupportedFileTypeMessage;
    }

    if (sizeInBytes > maxFileSizeBytes) {
      return oversizeFileMessage;
    }

    return null;
  }

  static bool isSupportedUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null) {
      return false;
    }

    if ((uri.scheme != 'http' && uri.scheme != 'https') || uri.host.isEmpty) {
      return false;
    }

    return true;
  }

  static String _normalizedExtension(String fileName) {
    return p.extension(fileName).toLowerCase().replaceFirst('.', '');
  }
}