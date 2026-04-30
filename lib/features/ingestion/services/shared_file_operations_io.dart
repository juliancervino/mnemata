import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

Future<bool> fileExistsAtPath(String path) {
  return File(path).exists();
}

Future<Uint8List> readFileBytes(String path) {
  return File(path).readAsBytes();
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