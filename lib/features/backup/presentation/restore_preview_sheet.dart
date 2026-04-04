import 'package:flutter/material.dart';
import 'package:mnemata/features/backup/services/backup_restore_service.dart';

class RestorePreviewSheet extends StatefulWidget {
  const RestorePreviewSheet({
    super.key,
    required this.archivePath,
    required this.restoreService,
  });

  final String archivePath;
  final BackupRestoreService restoreService;

  @override
  State<RestorePreviewSheet> createState() => _RestorePreviewSheetState();
}

class _RestorePreviewSheetState extends State<RestorePreviewSheet> {
  late final Future<RestorePreview> _previewFuture;
  bool _confirmed = false;
  bool _isApplying = false;

  @override
  void initState() {
    super.initState();
    _previewFuture = widget.restoreService.previewBackup(widget.archivePath);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: FutureBuilder<RestorePreview>(
          future: _previewFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return _PreviewErrorBody(
                message: 'Failed to inspect backup archive. ${snapshot.error}',
              );
            }

            final preview = snapshot.requireData;
            final canApply = preview.validationPassed && _confirmed && !_isApplying;
            final statusColor = preview.validationPassed ? Colors.green : colorScheme.error;
            final statusLabel = preview.validationPassed ? 'Validation passed' : 'Validation failed';

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Restore Preview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  widget.archivePath,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                _PreviewRow(label: 'Created at', value: preview.createdAtIso),
                _PreviewRow(label: 'Backup app version', value: preview.appVersion),
                _PreviewRow(label: 'Manifest entries', value: '${preview.archiveEntryCount}'),
                _PreviewRow(label: 'Files in backup', value: '${preview.fileCount}'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.verified_user, color: statusColor),
                    const SizedBox(width: 8),
                    Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                if (preview.missingRequiredEntries.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Missing entries: ${preview.missingRequiredEntries.join(', ')}',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ],
                if (preview.checksumMismatches.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Checksum mismatches: ${preview.checksumMismatches.join(', ')}',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ],
                const SizedBox(height: 12),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _confirmed,
                  onChanged: (value) {
                    setState(() {
                      _confirmed = value ?? false;
                    });
                  },
                  title: const Text('I understand this will replace local data.'),
                  subtitle: const Text('Restore only proceeds when validation passes.'),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: canApply ? () => _applyRestore(context) : null,
                    icon: _isApplying
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.restore),
                    label: Text(_isApplying ? 'Applying restore...' : 'Apply restore now'),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _applyRestore(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isApplying = true;
    });
    final result = await widget.restoreService.applyRestore(
      widget.archivePath,
      confirmed: _confirmed,
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _isApplying = false;
    });

    if (result.applied) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Restore applied. Please restart the app.')),
      );
      navigator.pop(true);
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.errorMessage ?? 'Restore failed due to validation or IO error.',
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewErrorBody extends StatelessWidget {
  const _PreviewErrorBody({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 36),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}