import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackupStorageService {
  BackupStorageService({Directory? stagingRootDirectory})
      : _stagingRootDirectory = stagingRootDirectory;

  final Directory? _stagingRootDirectory;

  Future<Directory> createStagingDir() async {
    final root = _stagingRootDirectory ?? await _resolveStagingRootDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final stagingDir = Directory(p.join(root.path, 'backup_staging_$timestamp'));
    return stagingDir.create(recursive: true);
  }

  Future<Directory> _resolveStagingRootDirectory() async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Backup staging requires local filesystem access, which is not available on web runtime.',
      );
    }

    try {
      return await getTemporaryDirectory();
    } on MissingPluginException {
      return _resolveApplicationSupportDirectory();
    } on UnsupportedError {
      return _resolveApplicationSupportDirectory();
    }
  }

  Future<Directory> _resolveApplicationSupportDirectory() async {
    try {
      return await getApplicationSupportDirectory();
    } on MissingPluginException {
      throw UnsupportedError(
        'No filesystem directory provider is available for backup staging on this platform.',
      );
    } on UnsupportedError {
      throw UnsupportedError(
        'No filesystem directory provider is available for backup staging on this platform.',
      );
    }
  }

  Future<void> cleanupStagingDir(String stagingPath) async {
    final directory = Directory(stagingPath);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }
}
