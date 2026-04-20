import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<bool> fileExistsAtPath(String path) {
  return File(path).exists();
}

Future<String> copySharedFileToAppDocuments(
  String sourcePath,
  String fileName,
) async {
  final source = File(sourcePath);
  final appDir = await getApplicationDocumentsDirectory();
  final newPath = p.join(appDir.path, fileName);
  await source.copy(newPath);
  return newPath;
}