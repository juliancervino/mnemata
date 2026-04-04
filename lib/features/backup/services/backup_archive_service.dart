import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/backup/domain/backup_manifest.dart';
import 'package:mnemata/features/backup/services/backup_storage_service.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class BackupArchiveService {
  BackupArchiveService({
    required BackupStorageService storageService,
    Future<List<int>> Function()? databaseBytesProvider,
    Future<Map<String, dynamic>> Function()? settingsJsonProvider,
    Future<String?> Function()? attachmentsDirectoryPathProvider,
    DateTime Function()? nowProvider,
    Future<String> Function()? appVersionProvider,
    AppDatabase? database,
    SettingsService? settingsService,
  })  : _storageService = storageService,
        _databaseBytesProvider = databaseBytesProvider,
        _settingsJsonProvider = settingsJsonProvider,
        _attachmentsDirectoryPathProvider = attachmentsDirectoryPathProvider,
        _nowProvider = nowProvider ?? DateTime.now,
        _appVersionProvider = appVersionProvider,
        _database = database,
        _settingsService = settingsService;

  final BackupStorageService _storageService;
  final Future<List<int>> Function()? _databaseBytesProvider;
  final Future<Map<String, dynamic>> Function()? _settingsJsonProvider;
  final Future<String?> Function()? _attachmentsDirectoryPathProvider;
  final DateTime Function() _nowProvider;
  final Future<String> Function()? _appVersionProvider;
  final AppDatabase? _database;
  final SettingsService? _settingsService;

  static const String manifestEntry = 'manifest.json';
  static const String databaseEntry = 'database/mnemata_db.sqlite';
  static const String filesEntry = 'files/';
  static const String settingsEntry = 'settings/settings.json';

  static const List<String> requiredEntries = <String>[
    manifestEntry,
    databaseEntry,
    filesEntry,
    settingsEntry,
  ];

  Future<String> createBackupArchive() async {
    final stagingDir = await _storageService.createStagingDir();

    try {
      final dbBytes = await _resolveDatabaseBytes();
      final settingsJson = await _resolveSettingsJson();
      final appVersion = await _resolveAppVersion();
      final timestamp = _nowProvider().toUtc();

      final dbFile = File(p.join(stagingDir.path, databaseEntry));
      await dbFile.parent.create(recursive: true);
      await dbFile.writeAsBytes(dbBytes, flush: true);

      final settingsFile = File(p.join(stagingDir.path, settingsEntry));
      await settingsFile.parent.create(recursive: true);
      await settingsFile.writeAsString(jsonEncode(settingsJson), flush: true);

      final filesDir = Directory(p.join(stagingDir.path, filesEntry));
      await filesDir.create(recursive: true);
      await _copyAttachmentsIfPresent(filesDir.path);

      final manifest = BackupManifest(
        schemaVersion: 1,
        appVersion: appVersion,
        createdAtIso: timestamp.toIso8601String(),
        entries: [
          BackupManifestEntry(
            id: databaseEntry,
            relativePath: databaseEntry,
            sha256: BackupManifest.computeSha256Hex(dbBytes),
          ),
          BackupManifestEntry(
            id: filesEntry,
            relativePath: filesEntry,
            sha256: await _computeDirectorySha(filesDir),
          ),
          BackupManifestEntry(
            id: settingsEntry,
            relativePath: settingsEntry,
            sha256: BackupManifest.computeSha256Hex(
              utf8.encode(jsonEncode(settingsJson)),
            ),
          ),
        ],
      );

      final manifestFile = File(p.join(stagingDir.path, manifestEntry));
      await manifestFile.writeAsString(
        jsonEncode(manifest.toJson()),
        flush: true,
      );

      final archivePath = p.join(
        stagingDir.parent.path,
        'mnemata_backup_${timestamp.millisecondsSinceEpoch}.zip',
      );
      await _zipStagingToArchive(stagingDir.path, archivePath);
      return archivePath;
    } finally {
      await _storageService.cleanupStagingDir(stagingDir.path);
    }
  }

  Future<List<String>> inspectArchiveRequiredEntries(String archivePath) async {
    final archiveBytes = await File(archivePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(archiveBytes);
    final names = archive.files.map((f) => f.name).toSet();

    final missing = <String>[];
    for (final required in requiredEntries) {
      if (required == filesEntry) {
        final filesPresent = names.contains(filesEntry) ||
            names.any((name) => name.startsWith(filesEntry));
        if (!filesPresent) {
          missing.add(required);
        }
        continue;
      }

      if (!names.contains(required)) {
        missing.add(required);
      }
    }

    return missing;
  }

  Future<void> _zipStagingToArchive(String stagingPath, String archivePath) async {
    final root = Directory(stagingPath);
    final archive = Archive();

    archive.addFile(ArchiveFile.directory(filesEntry));

    await for (final entity in root.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }

      final relativePath = p.relative(entity.path, from: stagingPath).replaceAll('\\', '/');
      final bytes = await entity.readAsBytes();
      archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
    }

    final encoded = ZipEncoder().encode(archive);
    if (encoded == null) {
      throw StateError('Failed to encode backup archive');
    }

    await File(archivePath).writeAsBytes(encoded, flush: true);
  }

  Future<void> _copyAttachmentsIfPresent(String destinationPath) async {
    final sourcePath = await (_attachmentsDirectoryPathProvider?.call() ??
        Future<String?>.value(null));
    if (sourcePath == null || sourcePath.trim().isEmpty) {
      return;
    }

    final sourceDir = Directory(sourcePath);
    if (!await sourceDir.exists()) {
      return;
    }

    await for (final entity in sourceDir.list(recursive: true, followLinks: false)) {
      if (entity is! File) {
        continue;
      }

      final relative = p.relative(entity.path, from: sourcePath);
      final target = File(p.join(destinationPath, relative));
      await target.parent.create(recursive: true);
      await entity.copy(target.path);
    }
  }

  Future<String> _computeDirectorySha(Directory directory) async {
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
    return BackupManifest.computeSha256Hex(utf8.encode(rows.join('\n')));
  }

  Future<List<int>> _resolveDatabaseBytes() async {
    if (_databaseBytesProvider != null) {
      return _databaseBytesProvider();
    }

    if (_database != null) {
      final supportDir = await getApplicationSupportDirectory();
      final dbFile = File(p.join(supportDir.path, 'mnemata_db.sqlite'));
      if (await dbFile.exists()) {
        return dbFile.readAsBytes();
      }

      throw StateError(
        'Expected database file at ${dbFile.path}, but it does not exist.',
      );
    }

    throw StateError('databaseBytesProvider is required when no AppDatabase is supplied.');
  }

  Future<Map<String, dynamic>> _resolveSettingsJson() async {
    if (_settingsJsonProvider != null) {
      return _settingsJsonProvider();
    }

    if (_settingsService != null) {
      return {
        'autoTagDomain': _settingsService.autoTagDomain,
        'autoTagYear': _settingsService.autoTagYear,
      };
    }

    throw StateError(
      'settingsJsonProvider is required when no SettingsService is supplied.',
    );
  }

  Future<String> _resolveAppVersion() async {
    if (_appVersionProvider != null) {
      return _appVersionProvider();
    }

    final packageInfo = await PackageInfo.fromPlatform();
    return packageInfo.version;
  }
}
