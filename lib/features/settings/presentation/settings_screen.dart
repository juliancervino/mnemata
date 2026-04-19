import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/core/theme/app_theme.dart';
import 'package:mnemata/core/widgets/section_label.dart';
import 'package:mnemata/features/backup/presentation/restore_preview_sheet.dart';
import 'package:mnemata/features/backup/services/backup_archive_service.dart';
import 'package:mnemata/features/backup/services/backup_restore_service.dart';
import 'package:mnemata/features/backup/services/backup_storage_service.dart';
import 'package:mnemata/features/bookmarks/services/bookmark_export_service.dart';
import 'package:mnemata/features/bookmarks/services/bookmark_import_service.dart';
import 'package:mnemata/features/backup/services/google_drive_auth_client.dart';
import 'package:mnemata/features/backup/services/cloud_backup_provider.dart';
import 'package:mnemata/features/intelligence/services/api_key_store.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.settingsService,
    this.backupRestoreService,
    this.createBackupArchiveAction,
    this.uploadBackupAction,
    this.createBookmarkExportAction,
    this.shareBookmarkExportAction,
    this.pickBookmarkImportFileAction,
    this.importBookmarksFromFileAction,
    this.nowProvider,
    this.apiKeyStore,
  });

  final SettingsService? settingsService;
  final BackupRestoreService? backupRestoreService;
  final Future<String> Function()? createBackupArchiveAction;
  final Future<CloudBackupUploadReceipt> Function(String archivePath)?
  uploadBackupAction;
  final Future<String> Function()? createBookmarkExportAction;
  final Future<void> Function(String exportFilePath)? shareBookmarkExportAction;
  final Future<String?> Function()? pickBookmarkImportFileAction;
  final Future<BookmarkImportResult> Function(String importFilePath)?
  importBookmarksFromFileAction;
  final DateTime Function()? nowProvider;
  final ApiKeyStore? apiKeyStore;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _autoTagDomain;
  late bool _autoTagYear;
  late bool _autoBackupEnabled;
  late bool _backupRequireWifi;
  late bool _backupRequireCharging;
  late int _backupMaxCount;
  late int _recycleRetentionDays;
  late bool _aiSummaryEnabled;
  late bool _semanticSearchEnabled;
  late bool _aiTagSuggestionsEnabled;
  late String _selectedAiProvider;
  late final SettingsService _settingsService;
  late final ApiKeyStore _apiKeyStore;
  bool _hasApiKey = false;
  String? _googleUserEmail;
  BackupArchiveService? _backupArchiveService;
  CloudBackupProvider? _cloudBackupProvider;
  late final BackupRestoreService _backupRestoreService;
  bool _isCreatingBackup = false;
  bool _isPreparingRestore = false;
  bool _isExportingBookmarks = false;
  bool _isImportingBookmarks = false;
  String? _restoreProgressMessage;
  BookmarkExportService? _bookmarkExportService;
  BookmarkImportService? _bookmarkImportService;

  @override
  void initState() {
    super.initState();
    _settingsService =
        widget.settingsService ?? GetIt.instance<SettingsService>();
    _autoTagDomain = _settingsService.autoTagDomain;
    _autoTagYear = _settingsService.autoTagYear;
    _autoBackupEnabled = _settingsService.autoBackupEnabled;
    _backupRequireWifi = _settingsService.backupRequireWifi;
    _backupRequireCharging = _settingsService.backupRequireCharging;
    _backupMaxCount = _settingsService.backupMaxCount;
    _recycleRetentionDays = _settingsService.recycleBinRetentionDays;
    _aiSummaryEnabled = _settingsService.aiSummaryEnabled;
    _semanticSearchEnabled = _settingsService.semanticSearchEnabled;
    _aiTagSuggestionsEnabled = _settingsService.aiTagSuggestionsEnabled;
    _selectedAiProvider = _settingsService.aiProvider;
    _apiKeyStore =
      widget.apiKeyStore ??
      (GetIt.instance.isRegistered<ApiKeyStore>()
        ? GetIt.instance<ApiKeyStore>()
        : ApiKeyStore(secureStore: _InMemorySecureKeyValueStore()));
    _loadApiKeyState();
    _loadGoogleAccountState();

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

    if (widget.uploadBackupAction == null &&
        GetIt.instance.isRegistered<CloudBackupProvider>()) {
      _cloudBackupProvider = GetIt.instance<CloudBackupProvider>();
    }

  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              child: Text(
                'Settings',
                style: theme.textTheme.displaySmall,
              ),
            ),
            _SettingsGroup(
              label: 'Ingestion',
              children: [
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
              ],
            ),
            _SettingsGroup(
              label: 'Intelligence',
              children: [
                ListTile(
                  leading: const Icon(Icons.hub_outlined),
                  title: const Text('LLM provider'),
                  subtitle: const Text(
                    'Choose which provider your API key and AI calls will use.',
                  ),
                  trailing: DropdownButton<String>(
                    value: _selectedAiProvider,
                    underline: const SizedBox.shrink(),
                    items: const [
                      DropdownMenuItem(value: 'gemini', child: Text('Gemini')),
                      DropdownMenuItem(value: 'openai', child: Text('ChatGPT')),
                      DropdownMenuItem(value: 'claude', child: Text('Claude')),
                    ],
                    onChanged: (value) async {
                      if (value == null || value == _selectedAiProvider) {
                        return;
                      }
                      await _settingsService.setAiProvider(value);
                      if (!mounted) {
                        return;
                      }
                      setState(() {
                        _selectedAiProvider = value;
                      });
                      await _loadApiKeyState();
                    },
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.key_outlined),
                  title: const Text('LLM provider API key'),
                  subtitle: Text(
                    _hasApiKey
                        ? 'Configured for ${_providerDisplayName(_selectedAiProvider)} in secure storage'
                        : 'Required for AI summaries, semantic search, and tag suggestions',
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
              ],
            ),
            _SettingsGroup(
              label: 'Backup & Restore',
              children: [
                if (_googleUserEmail == null)
                  ListTile(
                    leading: const Icon(Icons.login),
                    title: const Text('Sign in to Google Drive'),
                    subtitle: const Text(
                      'Connect your account to enable cloud backups.',
                    ),
                    onTap: _signInGoogle,
                  )
                else
                  ListTile(
                    leading: const Icon(Icons.account_circle_outlined),
                    title: Text(_googleUserEmail!),
                    subtitle: const Text('Signed in to Google Drive.'),
                    trailing: TextButton(
                      onPressed: _signOutGoogle,
                      child: const Text('Sign out'),
                    ),
                  ),
                SwitchListTile(
                  secondary: const Icon(Icons.sync),
                  title: const Text('Auto-backup to Google Drive'),
                  subtitle: const Text(
                    'Automatically back up your data every 24 hours when conditions are met.',
                  ),
                  value: _autoBackupEnabled,
                  onChanged: _googleUserEmail == null
                      ? null
                      : (value) {
                          setState(() {
                            _autoBackupEnabled = value;
                          });
                          _settingsService.setAutoBackupEnabled(value);
                        },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.wifi),
                  title: const Text('Require Wi-Fi'),
                  subtitle: const Text(
                    'Only perform auto-backup when connected to Wi-Fi.',
                  ),
                  value: _backupRequireWifi,
                  onChanged: _googleUserEmail == null
                      ? null
                      : (value) {
                          setState(() {
                            _backupRequireWifi = value;
                          });
                          _settingsService.setBackupRequireWifi(value);
                        },
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.battery_charging_full),
                  title: const Text('Require charging'),
                  subtitle: const Text(
                    'Only perform auto-backup when the device is charging.',
                  ),
                  value: _backupRequireCharging,
                  onChanged: _googleUserEmail == null
                      ? null
                      : (value) {
                          setState(() {
                            _backupRequireCharging = value;
                          });
                          _settingsService.setBackupRequireCharging(value);
                        },
                ),
                ListTile(
                  leading: const Icon(Icons.backup_outlined),
                  title: const Text('Upload backup now'),
                  subtitle: const Text(
                    'Create a full backup archive and upload it to your Drive immediately.',
                  ),
                  enabled: !_isCreatingBackup && _googleUserEmail != null,
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
                  enabled: !_isPreparingRestore && _googleUserEmail != null,
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
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            _SettingsGroup(
              label: 'Recycle Bin',
              children: [
                ListTile(
                  leading: const Icon(Icons.auto_delete_outlined),
                  title: const Text('Retention window (days)'),
                  subtitle: const Text(
                    'Items older than this in recycle bin are permanently deleted at startup.',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Slider(
                          min: SettingsService.minRecycleBinRetentionDays
                              .toDouble(),
                          max: SettingsService.maxRecycleBinRetentionDays
                              .toDouble(),
                          divisions:
                              SettingsService.maxRecycleBinRetentionDays -
                              SettingsService.minRecycleBinRetentionDays,
                          label: '$_recycleRetentionDays',
                          value: _recycleRetentionDays.toDouble(),
                          onChanged: (value) {
                            setState(() {
                              _recycleRetentionDays = value.round();
                            });
                          },
                          onChangeEnd: (value) {
                            _settingsService
                                .setRecycleBinRetentionDays(value.round());
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$_recycleRetentionDays',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                if (_isPreparingRestore)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      _restoreProgressMessage ?? 'Preparing restore...',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
              ],
            ),
            _SettingsGroup(
              label: 'Bookmarks',
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file_outlined),
                  title: const Text('Export URL bookmarks (HTML)'),
                  subtitle: const Text(
                    'Create a Netscape bookmark HTML file with saved URLs only.',
                  ),
                  enabled: !_isExportingBookmarks,
                  onTap: _isExportingBookmarks ? null : _exportBookmarks,
                  trailing: _isExportingBookmarks
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('Import URL bookmarks (HTML)'),
                  subtitle: const Text(
                    'Import only valid http/https bookmark URLs from HTML files.',
                  ),
                  enabled: !_isImportingBookmarks,
                  onTap: _isImportingBookmarks ? null : _importBookmarks,
                  trailing: _isImportingBookmarks
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : null,
                ),
              ],
            ),
            _SettingsGroup(
              label: 'Backup diagnostics',
              children: [
                _buildDiagnosticsTile(
                  label: 'Last backup attempt',
                  value: _formatTimestamp(_settingsService.lastBackupAttemptAt),
                ),
                _buildDiagnosticsTile(
                  label: 'Last successful backup',
                  value: _formatTimestamp(
                    _settingsService.lastSuccessfulBackupAt,
                  ),
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
          ],
        ),
      ),
    );
  }

  void _loadGoogleAccountState() {
    try {
      final authClient = GetIt.instance<GoogleDriveAuthClient>();
      final user = authClient.currentUser;
      if (mounted) {
        setState(() {
          _googleUserEmail = user?.email;
        });
      }
    } catch (_) {}
  }

  Future<void> _signInGoogle() async {
    try {
      final authClient = GetIt.instance<GoogleDriveAuthClient>();
      final user = await authClient.signIn();
      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Google sign in was cancelled.')),
          );
        }
        return;
      }

      await authClient.getAccessToken();

      if (mounted) {
        setState(() {
          _googleUserEmail = user.email;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Signed in as ${user.email}')),
        );
      }
    } on GoogleDriveAuthException catch (error) {
      if (mounted) {
        setState(() {
          _googleUserEmail = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: ${error.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _googleUserEmail = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sign in failed: $e')),
        );
      }
    }
  }

  Future<void> _signOutGoogle() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign out from Google?'),
        content: const Text(
          'This will disconnect your Google account. You will need to sign in again to perform backups or restores.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SIGN OUT'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    try {
      final authClient = GetIt.instance<GoogleDriveAuthClient>();
      await authClient.signOut();
      if (!mounted) {
        return;
      }
      setState(() {
        _googleUserEmail = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully signed out from Google.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e')),
      );
    }
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

      final createdArchivePath =
          await (widget.createBackupArchiveAction?.call() ??
              _backupArchiveService!.createBackupArchive());
      archivePath = createdArchivePath;

      final CloudBackupUploadReceipt receipt;
      final uploadAction = widget.uploadBackupAction;
      if (uploadAction != null) {
        receipt = await uploadAction(createdArchivePath);
      } else {
        final cloudProvider = _cloudBackupProvider;
        if (cloudProvider == null) {
          throw StateError('Cloud backup provider is not configured.');
        }
        receipt = await cloudProvider.uploadBackup(
          archivePath: createdArchivePath,
        );
      }

      archiveSizeBytes = _resolveArchiveSizeBytes(createdArchivePath);

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

      _setRestoreBusy(false, null);

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
              'Unable to list cloud backups (${error.code.name}).',
            ),
          ),
        );
      }
      return null;
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
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Text(
                      'Choose a backup from Google Drive',
                      style: Theme.of(context).textTheme.titleMedium,
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

  int? _resolveArchiveSizeBytes(String archivePath) {
    try {
      final file = File(archivePath);
      if (!file.existsSync()) {
        return null;
      }
      return file.lengthSync();
    } catch (_) {
      return null;
    }
  }

  Future<void> _exportBookmarks() async {
    setState(() {
      _isExportingBookmarks = true;
    });

    try {
      final exportPath =
          await (widget.createBookmarkExportAction?.call() ??
              (() async {
                final service =
                    _bookmarkExportService ??
                    BookmarkExportService(database: GetIt.instance<AppDatabase>());
                _bookmarkExportService = service;
                final file = await service.exportBookmarksFile();
                return file.path;
              })());

      await (widget.shareBookmarkExportAction?.call(exportPath) ??
          Share.shareXFiles(
            <XFile>[XFile(exportPath)],
            subject: 'Mnemata URL Bookmarks',
            text: 'Exported URL bookmarks from Mnemata.',
          ));

      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bookmarks exported: $exportPath')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bookmark export failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isExportingBookmarks = false;
        });
      }
    }
  }

  Future<void> _importBookmarks() async {
    setState(() {
      _isImportingBookmarks = true;
    });

    try {
      final importPath =
          await (widget.pickBookmarkImportFileAction?.call() ??
              _pickBookmarkImportFilePath());
      if (importPath == null || importPath.isEmpty) {
        return;
      }

      final result =
          await (widget.importBookmarksFromFileAction?.call(importPath) ??
              (() {
                final service =
                    _bookmarkImportService ??
                    BookmarkImportService(database: GetIt.instance<AppDatabase>());
                _bookmarkImportService = service;
                return service.importBookmarksFile(importPath);
              })());

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${result.importedCount} bookmarks (${result.duplicateCount} duplicates, ${result.invalidCount} invalid).',
          ),
        ),
      );
    } on BookmarkImportException catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bookmark import failed: ${error.message}')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bookmark import failed: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isImportingBookmarks = false;
        });
      }
    }
  }

  Future<String?> _pickBookmarkImportFilePath() async {
    final selected = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const <String>['html', 'htm'],
    );
    if (selected == null || selected.files.isEmpty) {
      return null;
    }

    final path = selected.files.single.path;
    if (path == null || path.trim().isEmpty) {
      return null;
    }

    return path;
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
    final hasKey = await _apiKeyStore.hasKeyForProvider(_selectedAiProvider);
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
        title: Text('Set ${_providerDisplayName(_selectedAiProvider)} API key'),
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

    await _apiKeyStore.saveKeyForProvider(
      provider: _selectedAiProvider,
      apiKey: value,
    );
    await _loadApiKeyState();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'API key for ${_providerDisplayName(_selectedAiProvider)} saved to secure storage.',
        ),
      ),
    );
  }

  Future<void> _removeApiKey() async {
    await _apiKeyStore.clearKeyForProvider(provider: _selectedAiProvider);
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
      SnackBar(
        content: Text(
          '${_providerDisplayName(_selectedAiProvider)} API key removed. Intelligence features remain disabled until key is configured again.',
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
        SnackBar(
          content: Text(
            'Configure a ${_providerDisplayName(_selectedAiProvider)} API key to enable intelligence features.',
          ),
        ),
      );
      return;
    }

    await currentSetter(value);
  }

  String _providerDisplayName(String provider) {
    switch (provider) {
      case 'openai':
        return 'ChatGPT';
      case 'claude':
        return 'Claude';
      case 'gemini':
      default:
        return 'Gemini';
    }
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(const Divider(height: 1));
      }
      rows.add(children[i]);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: SectionLabel(label),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(MnemataRadii.lg),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                borderRadius: BorderRadius.circular(MnemataRadii.lg),
                border: Border.all(color: cs.outline, width: 0.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InMemorySecureKeyValueStore implements SecureKeyValueStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<String?> read(String key) async {
    return _values[key];
  }

  @override
  Future<void> write({required String key, required String value}) async {
    _values[key] = value;
  }
}
