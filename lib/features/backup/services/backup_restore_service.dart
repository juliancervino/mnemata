import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:mnemata/features/backup/domain/backup_manifest.dart';
import 'package:mnemata/features/backup/services/backup_archive_service.dart';
import 'package:mnemata/features/backup/services/backup_storage_service.dart';
import 'package:path/path.dart' as p;

enum RestoreErrorCode {
  confirmationRequired,
  missingRequiredEntries,
  invalidManifest,
  checksumMismatch,
  applyFailed,
}

class RestorePreview {
  const RestorePreview({
    required this.appVersion,
    required this.createdAtIso,
    required this.archiveSizeBytes,
    required this.missingRequiredEntries,
    required this.checksumMismatches,
    required this.fileCount,
    required this.archiveEntryCount,
  });

  final String appVersion;
  final String createdAtIso;
  final int archiveSizeBytes;
  final List<String> missingRequiredEntries;
  final List<String> checksumMismatches;
  final int fileCount;
  final int archiveEntryCount;

  bool get validationPassed =>
      missingRequiredEntries.isEmpty && checksumMismatches.isEmpty;
}

class RestoreApplyResult {
  const RestoreApplyResult({
    required this.applied,
    this.errorCode,
    this.errorMessage,
    this.missingRequiredEntries = const <String>[],
    this.checksumMismatches = const <String>[],
  });

  final bool applied;
  final RestoreErrorCode? errorCode;
  final String? errorMessage;
  final List<String> missingRequiredEntries;
  final List<String> checksumMismatches;
}

class BackupRestoreService {
  BackupRestoreService({
    required BackupArchiveService archiveService,
    required BackupStorageService storageService,
    Future<void> Function(String stagedRestorePath)? applyStagedRestore,
    Future<String> Function()? liveDatabasePathProvider,
    Future<String?> Function()? liveAttachmentsDirectoryPathProvider,
    Future<void> Function(Map<String, dynamic> json)? settingsImporter,
  })  : _archiveService = archiveService,
        _storageService = storageService,
        _applyStagedRestore = applyStagedRestore,
        _liveDatabasePathProvider = liveDatabasePathProvider,
        _liveAttachmentsDirectoryPathProvider = liveAttachmentsDirectoryPathProvider,
        _settingsImporter = settingsImporter;

  final BackupArchiveService _archiveService;
  final BackupStorageService _storageService;
  final Future<void> Function(String stagedRestorePath)? _applyStagedRestore;
  final Future<String> Function()? _liveDatabasePathProvider;
  final Future<String?> Function()? _liveAttachmentsDirectoryPathProvider;
  final Future<void> Function(Map<String, dynamic> json)? _settingsImporter;

  Future<String> stageDownloadedArchive(
    Uint8List archiveBytes, {
    required String backupId,
  }) async {
    final stagingDir = await _storageService.createStagingDir();
    final safeBackupId = backupId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    final stagedPath = p.join(stagingDir.path, 'cloud_restore_$safeBackupId.zip');
    final stagedFile = File(stagedPath);
    await stagedFile.parent.create(recursive: true);
    await stagedFile.writeAsBytes(archiveBytes, flush: true);
    return stagedPath;
  }

  Future<RestorePreview> previewBackup(String archivePath) async {
    final missingRequiredEntries =
        await _archiveService.inspectArchiveRequiredEntries(archivePath);

    final stagingDir = await _storageService.createStagingDir();
    try {
      await _extractArchive(archivePath, stagingDir.path);
      final manifest = await _readManifest(stagingDir.path);
      final artifactBytesById = await _collectArtifactBytesById(stagingDir.path);
      final checksumMismatches = manifest.checksumMismatches(artifactBytesById);

      return RestorePreview(
        appVersion: manifest.appVersion,
        createdAtIso: manifest.createdAtIso,
        archiveSizeBytes: await File(archivePath).length(),
        missingRequiredEntries: missingRequiredEntries,
        checksumMismatches: checksumMismatches,
        fileCount: await _countExtractedFiles(stagingDir.path),
        archiveEntryCount: manifest.entries.length,
      );
    } finally {
      await _storageService.cleanupStagingDir(stagingDir.path);
    }
  }

  Future<RestoreApplyResult> applyRestore(
    String archivePath, {
    required bool confirmed,
  }) async {
    if (!confirmed) {
      return const RestoreApplyResult(
        applied: false,
        errorCode: RestoreErrorCode.confirmationRequired,
        errorMessage: 'Explicit confirmation is required before restore apply.',
      );
    }

    final missingRequiredEntries =
        await _archiveService.inspectArchiveRequiredEntries(archivePath);
    if (missingRequiredEntries.isNotEmpty) {
      return RestoreApplyResult(
        applied: false,
        errorCode: RestoreErrorCode.missingRequiredEntries,
        missingRequiredEntries: missingRequiredEntries,
        errorMessage: 'Backup archive is missing required entries.',
      );
    }

    final stagingDir = await _storageService.createStagingDir();
    try {
      await _extractArchive(archivePath, stagingDir.path);

      final manifest = await _readManifest(stagingDir.path);
      final artifactBytesById = await _collectArtifactBytesById(stagingDir.path);
      final checksumMismatches = manifest.checksumMismatches(artifactBytesById);
      if (checksumMismatches.isNotEmpty) {
        return RestoreApplyResult(
          applied: false,
          errorCode: RestoreErrorCode.checksumMismatch,
          checksumMismatches: checksumMismatches,
          errorMessage: 'Checksum validation failed. Restore aborted.',
        );
      }

      await _applyValidatedRestore(stagingDir.path);
      return const RestoreApplyResult(applied: true);
    } on FormatException catch (error) {
      return RestoreApplyResult(
        applied: false,
        errorCode: RestoreErrorCode.invalidManifest,
        errorMessage: error.message,
      );
    } on StateError catch (error) {
      return RestoreApplyResult(
        applied: false,
        errorCode: RestoreErrorCode.invalidManifest,
        errorMessage: error.message,
      );
    } catch (error) {
      return RestoreApplyResult(
        applied: false,
        errorCode: RestoreErrorCode.applyFailed,
        errorMessage: error.toString(),
      );
    } finally {
      await _storageService.cleanupStagingDir(stagingDir.path);
    }
  }

  Future<void> _extractArchive(String archivePath, String destinationPath) async {
    final archiveBytes = await File(archivePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(archiveBytes);

    for (final file in archive.files) {
      final safeName = file.name.replaceAll('\\', '/');
      final outputPath = p.normalize(p.join(destinationPath, safeName));
      if (!outputPath.startsWith(destinationPath)) {
        throw StateError('Archive contains invalid entry path: ${file.name}');
      }

      if (file.isFile) {
        final outFile = File(outputPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>, flush: true);
      } else {
        await Directory(outputPath).create(recursive: true);
      }
    }
  }

  Future<BackupManifest> _readManifest(String rootPath) async {
    final manifestFile = File(p.join(rootPath, BackupArchiveService.manifestEntry));
    if (!await manifestFile.exists()) {
      throw StateError('Backup manifest is missing from restore archive.');
    }

    final raw = await manifestFile.readAsString();
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Manifest must be a JSON object.');
    }

    return BackupManifest.fromJson(decoded);
  }

  Future<Map<String, List<int>>> _collectArtifactBytesById(String rootPath) async {
    final dbFile = File(p.join(rootPath, BackupArchiveService.databaseEntry));
    final settingsFile = File(p.join(rootPath, BackupArchiveService.settingsEntry));
    final filesDir = Directory(p.join(rootPath, BackupArchiveService.filesEntry));

    if (!await dbFile.exists()) {
      throw StateError('Restore archive database payload is missing.');
    }
    if (!await settingsFile.exists()) {
      throw StateError('Restore archive settings payload is missing.');
    }
    if (!await filesDir.exists()) {
      throw StateError('Restore archive files payload is missing.');
    }

    return {
      BackupArchiveService.databaseEntry: await dbFile.readAsBytes(),
      BackupArchiveService.filesEntry: await _computeDirectoryDigestBytes(filesDir),
      BackupArchiveService.settingsEntry: await settingsFile.readAsBytes(),
    };
  }

  Future<List<int>> _computeDirectoryDigestBytes(Directory directory) async {
    final rows = <String>[];

    await for (final entity in directory.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }

      final relativePath = p.relative(entity.path, from: directory.path).replaceAll('\\', '/');
      final bytes = await entity.readAsBytes();
      final fileHash = BackupManifest.computeSha256Hex(bytes);
      rows.add('$relativePath:$fileHash');
    }

    rows.sort();
    return utf8.encode(rows.join('\n'));
  }

  Future<int> _countExtractedFiles(String rootPath) async {
    final filesDir = Directory(p.join(rootPath, BackupArchiveService.filesEntry));
    if (!await filesDir.exists()) {
      return 0;
    }

    var count = 0;
    await for (final entity in filesDir.list(recursive: true, followLinks: false)) {
      if (entity is File) {
        count += 1;
      }
    }
    return count;
  }

  Future<void> _applyValidatedRestore(String stagingPath) async {
    if (_applyStagedRestore != null) {
      await _applyStagedRestore(stagingPath);
      return;
    }

    final liveDbPathProvider = _liveDatabasePathProvider;
    if (liveDbPathProvider == null) {
      throw StateError(
        'No restore apply strategy configured. Provide applyStagedRestore or live path providers.',
      );
    }

    final rollbackDir = Directory(p.join(stagingPath, '_rollback'));
    await rollbackDir.create(recursive: true);

    final liveDbPath = await liveDbPathProvider();
    final liveDbFile = File(liveDbPath);
    final stagedDbFile = File(p.join(stagingPath, BackupArchiveService.databaseEntry));
    final dbRollback = File(p.join(rollbackDir.path, 'mnemata_db.sqlite.bak'));

    final attachmentsProvider = _liveAttachmentsDirectoryPathProvider;
    final attachmentsPath = attachmentsProvider == null ? null : await attachmentsProvider();
    final stagedAttachmentsDir = Directory(
      p.join(stagingPath, BackupArchiveService.filesEntry),
    );
    final attachmentsRollbackDir = Directory(p.join(rollbackDir.path, 'files_backup'));

    final liveDbExisted = await liveDbFile.exists();
    final liveAttachmentsExisted =
        attachmentsPath != null && await Directory(attachmentsPath).exists();

    if (liveDbExisted) {
      await dbRollback.parent.create(recursive: true);
      await liveDbFile.copy(dbRollback.path);
    }

    if (attachmentsPath != null && liveAttachmentsExisted) {
      await _copyDirectory(
        Directory(attachmentsPath),
        attachmentsRollbackDir,
      );
    }

    try {
      await liveDbFile.parent.create(recursive: true);
      await stagedDbFile.copy(liveDbFile.path);

      if (attachmentsPath != null) {
        final liveAttachmentsDir = Directory(attachmentsPath);
        if (await liveAttachmentsDir.exists()) {
          await liveAttachmentsDir.delete(recursive: true);
        }
        await _copyDirectory(stagedAttachmentsDir, liveAttachmentsDir);
      }

      final settingsImporter = _settingsImporter;
      if (settingsImporter != null) {
        final settingsFile = File(p.join(stagingPath, BackupArchiveService.settingsEntry));
        final settingsRaw = await settingsFile.readAsString();
        final decoded = jsonDecode(settingsRaw);
        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('settings/settings.json must be a JSON object.');
        }
        await settingsImporter(decoded);
      }
    } catch (_) {
      await _restoreRollback(
        liveDbFile: liveDbFile,
        dbRollback: dbRollback,
        liveDbExisted: liveDbExisted,
        attachmentsPath: attachmentsPath,
        liveAttachmentsExisted: liveAttachmentsExisted,
        attachmentsRollbackDir: attachmentsRollbackDir,
      );
      rethrow;
    }
  }

  Future<void> _restoreRollback({
    required File liveDbFile,
    required File dbRollback,
    required bool liveDbExisted,
    required String? attachmentsPath,
    required bool liveAttachmentsExisted,
    required Directory attachmentsRollbackDir,
  }) async {
    if (liveDbExisted && await dbRollback.exists()) {
      await dbRollback.copy(liveDbFile.path);
    } else if (!liveDbExisted && await liveDbFile.exists()) {
      await liveDbFile.delete();
    }

    if (attachmentsPath == null) {
      return;
    }

    final liveAttachmentsDir = Directory(attachmentsPath);
    if (await liveAttachmentsDir.exists()) {
      await liveAttachmentsDir.delete(recursive: true);
    }

    if (liveAttachmentsExisted && await attachmentsRollbackDir.exists()) {
      await _copyDirectory(attachmentsRollbackDir, liveAttachmentsDir);
    }
  }

  Future<void> _copyDirectory(Directory source, Directory destination) async {
    await destination.create(recursive: true);
    await for (final entity in source.list(recursive: true, followLinks: false)) {
      final relativePath = p.relative(entity.path, from: source.path);
      final targetPath = p.join(destination.path, relativePath);

      if (entity is Directory) {
        await Directory(targetPath).create(recursive: true);
      } else if (entity is File) {
        await File(targetPath).parent.create(recursive: true);
        await entity.copy(targetPath);
      }
    }
  }
}