import 'dart:typed_data';

Future<bool> fileExistsAtPath(String path) async => false;

Future<Uint8List> readFileBytes(String path) {
  throw UnsupportedError('Read file bytes is not supported on this platform.');
}

Future<String> copySharedFileToAppDocuments(
  String sourcePath,
  String fileName,
) {
  throw UnsupportedError(
    'Shared file copy is not supported on this platform.',
  );
}