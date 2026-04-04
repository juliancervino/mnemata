import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/backup/presentation/restore_preview_sheet.dart';
import 'package:mnemata/features/backup/services/backup_archive_service.dart';
import 'package:mnemata/features/backup/services/backup_restore_service.dart';
import 'package:mnemata/features/backup/services/backup_storage_service.dart';
import 'package:mnemata/features/backup/services/cloud_backup_provider.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.settingsService,
    this.backupRestoreService,
    this.createBackupArchiveAction,
    this.uploadBackupAction,
    this.nowProvider,
  });

  final SettingsService? settingsService;
  final BackupRestoreService? backupRestoreService;
  final Future<String> Function()? createBackupArchiveAction;
  final Future<CloudBackupUploadReceipt> Function(String archivePath)?
  uploadBackupAction;
  final DateTime Function()? nowProvider;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _autoTagDomain;
  late bool _autoTagYear;
  late final SettingsService _settingsService;
  BackupArchiveService? _backupArchiveService;
  CloudBackupProvider? _cloudBackupProvider;
  late final BackupRestoreService _backupRestoreService;
  bool _isCreatingBackup = false;

  @override
  void initState() {
    super.initState();
    _settingsService =
        widget.settingsService ?? GetIt.instance<SettingsService>();
    _autoTagDomain = _settingsService.autoTagDomain;
    _autoTagYear = _settingsService.autoTagYear;

    if (widget.createBackupArchiveAction == null ||
        widget.backupRestoreService == null) {
      final backupStorageService = BackupStorageService();
      _backupArchiveService = BackupArchiveService(
        storageService: backupStorageService,
        database: GetIt.instance<AppDatabase>(),
        settingsService: _settingsService,
        attachmentsDirectoryPathProvider: () async {
          final dir = await getApplicationDocumentsDirectory();
          return dir.path;
        },
      );

      _backupRestoreService =
          widget.backupRestoreService ??
          BackupRestoreService(
            archiveService: _backupArchiveService!,
            storageService: backupStorageService,
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
    } else {
      _backupRestoreService = widget.backupRestoreService!;
    }

    if (widget.uploadBackupAction == null) {
      _cloudBackupProvider = GetIt.instance<CloudBackupProvider>();
    }
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
            subtitle: const Text(
              'Automatically assign a tag based on the URL domain (e.g. elpais.com)',
            ),
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
            subtitle: const Text(
              'Automatically assign a tag with the current year (e.g. 2026)',
            ),
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
            title: const Text('Upload backup to Google Drive'),
            subtitle: const Text(
              'Create a full backup archive and upload it to your Drive.',
            ),
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
            subtitle: const Text(
              'Preview and validate a backup before applying restore.',
            ),
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
    final now = (widget.nowProvider ?? DateTime.now).call().toUtc();
    String? archivePath;

    try {
      await _settingsService.setLastBackupAttemptAt(now);

      archivePath =
          await (widget.createBackupArchiveAction?.call() ??
              _backupArchiveService!.createBackupArchive());

      final receipt =
          await (widget.uploadBackupAction?.call(archivePath) ??
              _cloudBackupProvider!.uploadBackup(archivePath: archivePath));

      await _settingsService.setLastSuccessfulBackupAt(receipt.uploadedAt);
      await _settingsService.clearLastBackupFailureReason();

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text('Backup uploaded to Google Drive: ${receipt.remoteId}'),
        ),
      );
    } on CloudBackupProviderException catch (error) {
      await _settingsService.setLastBackupFailureReason(
        'manual_upload_${error.code.name}',
      );
      if (!mounted) {
        return;
      }

      final diagnostics = archivePath == null ? '' : ' Archive: $archivePath';
      messenger.showSnackBar(
        SnackBar(
          content: Text('Cloud backup failed: ${error.message}.$diagnostics'),
        ),
      );
    } catch (error) {
      await _settingsService.setLastBackupFailureReason(
        'manual_upload_unknown',
      );
      if (!mounted) {
        return;
      }

      final diagnostics = archivePath == null ? '' : ' Archive: $archivePath';
      messenger.showSnackBar(
        SnackBar(content: Text('Cloud backup failed: $error.$diagnostics')),
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
              onPressed: () =>
                  Navigator.of(context).pop(controller.text.trim()),
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
