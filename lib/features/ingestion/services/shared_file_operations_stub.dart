Future<bool> fileExistsAtPath(String path) async => false;

Future<String> copySharedFileToAppDocuments(
  String sourcePath,
  String fileName,
) {
  throw UnsupportedError(
    'Shared file copy is not supported on this platform.',
  );
}