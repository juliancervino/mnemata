import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/backup/presentation/restore_preview_sheet.dart';
import 'package:mnemata/features/backup/services/backup_archive_service.dart';
import 'package:mnemata/features/backup/services/backup_restore_service.dart';
import 'package:mnemata/features/backup/services/backup_storage_service.dart';
import 'package:mnemata/features/backup/services/cloud_backup_provider.dart';
import 'package:mnemata/features/intelligence/services/api_key_store.dart';
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
    this.apiKeyStore,
  });

  final SettingsService? settingsService;
  final BackupRestoreService? backupRestoreService;
  final Future<String> Function()? createBackupArchiveAction;
  final Future<CloudBackupUploadReceipt> Function(String archivePath)?
  uploadBackupAction;
  final DateTime Function()? nowProvider;
  final ApiKeyStore? apiKeyStore;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _autoTagDomain;
  late bool _autoTagYear;
  late int _backupMaxCount;
  late bool _aiSummaryEnabled;
  late bool _semanticSearchEnabled;
  late bool _aiTagSuggestionsEnabled;
  late final SettingsService _settingsService;
  late final ApiKeyStore _apiKeyStore;
  bool _hasApiKey = false;
  BackupArchiveService? _backupArchiveService;
  CloudBackupProvider? _cloudBackupProvider;
  late final BackupRestoreService _backupRestoreService;
  bool _isCreatingBackup = false;
  bool _isPreparingRestore = false;
  String? _restoreProgressMessage;

  @override
  void initState() {
    super.initState();
    _settingsService =
        widget.settingsService ?? GetIt.instance<SettingsService>();
    _autoTagDomain = _settingsService.autoTagDomain;
    _autoTagYear = _settingsService.autoTagYear;
    _backupMaxCount = _settingsService.backupMaxCount;
    _aiSummaryEnabled = _settingsService.aiSummaryEnabled;
    _semanticSearchEnabled = _settingsService.semanticSearchEnabled;
    _aiTagSuggestionsEnabled = _settingsService.aiTagSuggestionsEnabled;
    _apiKeyStore = widget.apiKeyStore ?? GetIt.instance<ApiKeyStore>();
    _loadApiKeyState();

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
              final rows = await GetIt.instance<AppDatabase>()
                  .customSelect('PRAGMA database_list')
                  .get();
              for (final row in rows) {
                final name = (row.data['name'] as String?)?.trim();
                final filePath = (row.data['file'] as String?)?.trim();
                if (name == 'main' && filePath != null && filePath.isNotEmpty) {
                  return filePath;
                }
              }

              final supportDir = await getApplicationSupportDirectory();
              return p.join(
                supportDir.path,
                '${AppDatabase.databaseName}.sqlite',
              );
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
              'Intelligence',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.key_outlined),
            title: const Text('LLM provider API key'),
            subtitle: Text(
              _hasApiKey
                  ? 'Configured in secure storage'
                  : 'Required for AI summaries and semantic search',
            ),
            trailing: TextButton(
              onPressed: _hasApiKey ? _removeApiKey : _promptForApiKey,
              child: Text(_hasApiKey ? 'Remove' : 'Set key'),
            ),
            onTap: _hasApiKey ? _removeApiKey : _promptForApiKey,
          ),
          SwitchListTile(
            title: const Text('Enable AI summaries'),
            subtitle: const Text(
              'Generate on-demand TL;DR, key points, and why-it-matters blocks.',
            ),
            value: _aiSummaryEnabled,
            onChanged: (value) => _onIntelligenceToggleChanged(
              value: value,
              currentSetter: (enabled) async {
                await _settingsService.setAiSummaryEnabled(enabled);
                if (!mounted) {
                  return;
                }
                setState(() {
                  _aiSummaryEnabled = enabled;
                });
              },
            ),
          ),
          SwitchListTile(
            title: const Text('Enable semantic search mode'),
            subtitle: const Text(
              'Keeps keyword search available and unlocks semantic matching when configured.',
            ),
            value: _semanticSearchEnabled,
            onChanged: (value) => _onIntelligenceToggleChanged(
              value: value,
              currentSetter: (enabled) async {
                await _settingsService.setSemanticSearchEnabled(enabled);
                if (!mounted) {
                  return;
                }
                setState(() {
                  _semanticSearchEnabled = enabled;
                });
              },
            ),
          ),
          SwitchListTile(
            title: const Text('Enable AI tag suggestions'),
            subtitle: const Text('Suggests from existing tags only.'),
            value: _aiTagSuggestionsEnabled,
            onChanged: (value) => _onIntelligenceToggleChanged(
              value: value,
              currentSetter: (enabled) async {
                await _settingsService.setAiTagSuggestionsEnabled(enabled);
                if (!mounted) {
                  return;
                }
                setState(() {
                  _aiTagSuggestionsEnabled = enabled;
                });
              },
            ),
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
            enabled: !_isPreparingRestore,
            onTap: _isPreparingRestore ? null : _openRestorePreviewFlow,
            trailing: _isPreparingRestore
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.layers_outlined),
            title: const Text('Maximum backups to keep'),
            subtitle: Text(
              'Rotate old backups automatically (default 7, max ${SettingsService.maxBackupMaxCount}).',
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Expanded(
                  child: Slider(
                    min: 1,
                    max: SettingsService.maxBackupMaxCount.toDouble(),
                    divisions: SettingsService.maxBackupMaxCount - 1,
                    label: '$_backupMaxCount',
                    value: _backupMaxCount.toDouble(),
                    onChanged: (value) {
                      final next = value.round();
                      setState(() {
                        _backupMaxCount = next;
                      });
                    },
                    onChangeEnd: (value) {
                      _settingsService.setBackupMaxCount(value.round());
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$_backupMaxCount',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          if (_isPreparingRestore)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _restoreProgressMessage ?? 'Preparing restore...',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Backup diagnostics',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildDiagnosticsTile(
            label: 'Last backup attempt',
            value: _formatTimestamp(_settingsService.lastBackupAttemptAt),
          ),
          _buildDiagnosticsTile(
            label: 'Last successful backup',
            value: _formatTimestamp(_settingsService.lastSuccessfulBackupAt),
          ),
          _buildDiagnosticsTile(
            label: 'Last backup remote id',
            value: _settingsService.lastBackupRemoteId ?? 'n/a',
          ),
          _buildDiagnosticsTile(
            label: 'Last backup size',
            value: _formatBytes(_settingsService.lastBackupSizeBytes),
          ),
          _buildDiagnosticsTile(
            label: 'Last backup result',
            value: _settingsService.lastBackupResultStatus ?? 'n/a',
          ),
          _buildDiagnosticsTile(
            label: 'Last backup failure reason',
            value: _settingsService.lastBackupFailureReason ?? 'n/a',
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
    int? archiveSizeBytes;

    try {
      await _settingsService.setLastBackupAttemptAt(now);

      archivePath =
          await (widget.createBackupArchiveAction?.call() ??
              _backupArchiveService!.createBackupArchive());
      archiveSizeBytes = await _resolveArchiveSizeBytes(archivePath);

      final receipt =
          await (widget.uploadBackupAction?.call(archivePath) ??
              _cloudBackupProvider!.uploadBackup(archivePath: archivePath));

      final cloudProvider = _cloudBackupProvider;
      if (cloudProvider != null) {
        await _rotateCloudBackupsIfNeeded(cloudProvider);
      }

      await _settingsService.setLastSuccessfulBackupAt(receipt.uploadedAt);
      await _settingsService.setLastBackupRemoteId(receipt.remoteId);
      await _settingsService.setLastBackupResultStatus('manual_upload_success');
      await _settingsService.setLastBackupSizeBytes(archiveSizeBytes);
      await _settingsService.clearLastBackupFailureReason();

      if (!mounted) {
        return;
      }

      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Backup uploaded to Google Drive (${_formatBytes(archiveSizeBytes)}): ${receipt.remoteId}',
          ),
        ),
      );
    } on CloudBackupProviderException catch (error) {
      final status = 'manual_upload_${error.code.name}';
      await _settingsService.setLastBackupResultStatus(status);
      await _settingsService.setLastBackupFailureReason(status);
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
      await _settingsService.setLastBackupResultStatus('manual_upload_unknown');
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

  ListTile _buildDiagnosticsTile({
    required String label,
    required String value,
  }) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(label),
      subtitle: Text(value),
    );
  }

  String _formatTimestamp(DateTime? value) {
    if (value == null) {
      return 'n/a';
    }
    return value.toUtc().toIso8601String();
  }

  Future<void> _openRestorePreviewFlow() async {
    _setRestoreBusy(true, 'Fetching backups from Google Drive...');
    try {
      final archivePath = await _resolveRestoreArchivePath();
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
    } finally {
      _setRestoreBusy(false, null);
    }
  }

  Future<String?> _resolveRestoreArchivePath() async {
    final cloudProvider = _cloudBackupProvider;
    if (cloudProvider == null) {
      return _promptForArchivePathFallback();
    }

    try {
      _setRestoreBusy(true, 'Fetching backups from Google Drive...');
      final backups = await cloudProvider.listBackups();
      if (backups.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No backups found on Google Drive.')),
          );
        }
        return null;
      }

      final sorted = backups.toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _setRestoreBusy(false, null);
      final selected = await _promptForCloudBackupSelection(sorted);
      if (selected == null) {
        return null;
      }

      _setRestoreBusy(true, 'Downloading selected backup...');
      final archiveBytes = await cloudProvider.downloadBackup(
        backupId: selected.backupId,
      );
      _setRestoreBusy(true, 'Preparing restore preview...');
      return _backupRestoreService.stageDownloadedArchive(
        archiveBytes,
        backupId: selected.backupId,
      );
    } on CloudBackupProviderException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Unable to list cloud backups (${error.code.name}). You can use local archive fallback.',
            ),
          ),
        );
      }
      return _promptForArchivePathFallback();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to list cloud backups. Please try again.'),
          ),
        );
      }
      return null;
    }
  }

  Future<CloudBackupDescriptor?> _promptForCloudBackupSelection(
    List<CloudBackupDescriptor> backups,
  ) {
    final cloudProvider = _cloudBackupProvider;
    final entries = backups.toList(growable: true);
    return showModalBottomSheet<CloudBackupDescriptor>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Padding(
                    padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Choose a backup from Google Drive',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final backup = entries[index];
                        return ListTile(
                          leading: const Icon(Icons.cloud_done_outlined),
                          title: Text(_formatTimestamp(backup.createdAt)),
                          subtitle: Text(
                            'Size: ${_formatBytes(backup.sizeBytes)}\nID: ${backup.remoteId}',
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            tooltip: 'Delete backup',
                            onPressed: cloudProvider == null
                                ? null
                                : () async {
                                    final confirmed =
                                        await _confirmDeleteCloudBackup(backup);
                                    if (!confirmed) {
                                      return;
                                    }

                                    try {
                                      await cloudProvider.deleteBackup(
                                        backupId: backup.backupId,
                                      );
                                      setModalState(() {
                                        entries.removeAt(index);
                                      });
                                      if (!context.mounted) {
                                        return;
                                      }

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text('Backup deleted.'),
                                        ),
                                      );
                                      if (entries.isEmpty) {
                                        Navigator.of(context).pop();
                                      }
                                    } on CloudBackupProviderException catch (
                                      error
                                    ) {
                                      if (!context.mounted) {
                                        return;
                                      }

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Could not delete backup (${error.code.name}).',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                          ),
                          onTap: () => Navigator.of(context).pop(backup),
                        );
                      },
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<bool> _confirmDeleteCloudBackup(CloudBackupDescriptor backup) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete backup?'),
          content: Text(
            'This will permanently remove the backup created at ${_formatTimestamp(backup.createdAt)} from Google Drive.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> _rotateCloudBackupsIfNeeded(
    CloudBackupProvider cloudProvider,
  ) async {
    final maxBackups = _settingsService.backupMaxCount;
    if (maxBackups < 1) {
      return;
    }

    final backups = await cloudProvider.listBackups();
    if (backups.length <= maxBackups) {
      return;
    }

    final sorted = backups.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final backupsToDelete = sorted.skip(maxBackups).toList(growable: false);
    for (final backup in backupsToDelete) {
      await cloudProvider.deleteBackup(backupId: backup.backupId);
    }
  }

  Future<String?> _promptForArchivePathFallback() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Fallback: Open local backup archive'),
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

  Future<int?> _resolveArchiveSizeBytes(String archivePath) async {
    try {
      final file = File(archivePath);
      if (!await file.exists()) {
        return null;
      }
      return file.length();
    } catch (_) {
      return null;
    }
  }

  void _setRestoreBusy(bool value, String? message) {
    if (!mounted) {
      return;
    }

    setState(() {
      _isPreparingRestore = value;
      _restoreProgressMessage = value ? message : null;
    });
  }

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes < 0) {
      return 'n/a';
    }

    const units = <String>['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var unitIndex = 0;
    while (value >= 1024 && unitIndex < units.length - 1) {
      value /= 1024;
      unitIndex += 1;
    }

    final decimals = value >= 100 || unitIndex == 0 ? 0 : 1;
    return '${value.toStringAsFixed(decimals)} ${units[unitIndex]}';
  }

  Future<void> _loadApiKeyState() async {
    final hasKey = await _apiKeyStore.hasKey();
    if (!mounted) {
      return;
    }
    setState(() {
      _hasApiKey = hasKey;
    });
  }

  Future<void> _promptForApiKey() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Set provider API key'),
        content: TextField(
          controller: controller,
          autofocus: true,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Paste API key'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('SAVE'),
          ),
        ],
      ),
    );

    if (value == null || value.isEmpty) {
      return;
    }

    await _apiKeyStore.saveKey(value);
    await _loadApiKeyState();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('API key saved to secure storage.')),
    );
  }

  Future<void> _removeApiKey() async {
    await _apiKeyStore.clearKey();
    await _settingsService.setAiSummaryEnabled(false);
    await _settingsService.setSemanticSearchEnabled(false);
    await _settingsService.setAiTagSuggestionsEnabled(false);
    if (!mounted) {
      return;
    }
    setState(() {
      _hasApiKey = false;
      _aiSummaryEnabled = false;
      _semanticSearchEnabled = false;
      _aiTagSuggestionsEnabled = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'API key removed. Intelligence features remain disabled until key is configured again.',
        ),
      ),
    );
  }

  Future<void> _onIntelligenceToggleChanged({
    required bool value,
    required Future<void> Function(bool enabled) currentSetter,
  }) async {
    if (value && !_hasApiKey) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Configure an API key in Intelligence settings to enable AI summaries and semantic search.',
          ),
        ),
      );
      return;
    }

    await currentSetter(value);
  }
}
