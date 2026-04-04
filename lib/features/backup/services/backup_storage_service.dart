import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackupStorageService {
  BackupStorageService({Directory? stagingRootDirectory})
      : _stagingRootDirectory = stagingRootDirectory;

  final Directory? _stagingRootDirectory;

  Future<Directory> createStagingDir() async {
    final root = _stagingRootDirectory ?? await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final stagingDir = Directory(p.join(root.path, 'backup_staging_$timestamp'));
    return stagingDir.create(recursive: true);
  }

  Future<void> cleanupStagingDir(String stagingPath) async {
    final directory = Directory(stagingPath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
