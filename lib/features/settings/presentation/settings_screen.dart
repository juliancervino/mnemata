import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/backup/presentation/restore_preview_sheet.dart';
import 'package:mnemata/features/backup/services/backup_archive_service.dart';
import 'package:mnemata/features/backup/services/backup_restore_service.dart';
import 'package:mnemata/features/backup/services/backup_storage_service.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _autoTagDomain;
  late bool _autoTagYear;
  final SettingsService _settingsService = GetIt.instance<SettingsService>();
  final AppDatabase _database = GetIt.instance<AppDatabase>();
  late final BackupStorageService _backupStorageService;
  late final BackupArchiveService _backupArchiveService;
  late final BackupRestoreService _backupRestoreService;
  bool _isCreatingBackup = false;

  @override
  void initState() {
    super.initState();
    _autoTagDomain = _settingsService.autoTagDomain;
    _autoTagYear = _settingsService.autoTagYear;
    _backupStorageService = BackupStorageService();
    _backupArchiveService = BackupArchiveService(
      storageService: _backupStorageService,
      database: _database,
      settingsService: _settingsService,
      attachmentsDirectoryPathProvider: () async {
        final dir = await getApplicationDocumentsDirectory();
        return dir.path;
      },
    );
    _backupRestoreService = BackupRestoreService(
      archiveService: _backupArchiveService,
      storageService: _backupStorageService,
      liveDatabasePathProvider: () async {
        final supportDir = await getApplicationSupportDirectory();
        return p.join(supportDir.path, 'mnemata_db.sqlite');
      },
      liveAttachmentsDirectoryPathProvider: () async {
        final documentsDir = await getApplicationDocumentsDirectory();
        return documentsDir.path;
      },
      settingsImporter: (json) async {
        final autoTagDomain = json['autoTagDomain'];
        final autoTagYear = json['autoTagYear'];
        if (autoTagDomain is bool) {
          await _settingsService.setAutoTagDomain(autoTagDomain);
        }
        if (autoTagYear is bool) {
          await _settingsService.setAutoTagYear(autoTagYear);
        }
        if (!mounted) {
          return;
        }
        setState(() {
          _autoTagDomain = _settingsService.autoTagDomain;
          _autoTagYear = _settingsService.autoTagYear;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Ingestion Options',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Auto-tag by domain'),
            subtitle: const Text('Automatically assign a tag based on the URL domain (e.g. elpais.com)'),
            value: _autoTagDomain,
            onChanged: (value) {
              setState(() {
                _autoTagDomain = value;
              });
              _settingsService.setAutoTagDomain(value);
            },
          ),
          SwitchListTile(
            title: const Text('Auto-tag by year'),
            subtitle: const Text('Automatically assign a tag with the current year (e.g. 2026)'),
            value: _autoTagYear,
            onChanged: (value) {
              setState(() {
                _autoTagYear = value;
              });
              _settingsService.setAutoTagYear(value);
            },
          ),
          const Divider(height: 32),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Backup & Restore',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Create backup now'),
            subtitle: const Text('Generate a full backup archive on this device.'),
            enabled: !_isCreatingBackup,
            onTap: _isCreatingBackup ? null : _createBackupNow,
            trailing: _isCreatingBackup
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore from backup'),
            subtitle: const Text('Preview and validate a backup before applying restore.'),
            onTap: _openRestorePreviewFlow,
          ),
        ],
      ),
    );
  }

  Future<void> _createBackupNow() async {
    setState(() {
      _isCreatingBackup = true;
    });

    final messenger = ScaffoldMessenger.of(context);
    try {
      final archivePath = await _backupArchiveService.createBackupArchive();
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Backup created: $archivePath')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(content: Text('Backup failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingBackup = false;
        });
      }
    }
  }

  Future<void> _openRestorePreviewFlow() async {
    final archivePath = await _promptForArchivePath();
    if (!mounted || archivePath == null) {
      return;
    }

    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return RestorePreviewSheet(
          archivePath: archivePath,
          restoreService: _backupRestoreService,
        );
      },
    );
  }

  Future<String?> _promptForArchivePath() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Open backup archive'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Archive path',
              hintText: '/storage/.../mnemata_backup.zip',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text.trim()),
              child: const Text('Preview'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (value == null || value.isEmpty) {
      return null;
    }

    return value;
  }
}
