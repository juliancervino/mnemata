import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/core/theme/app_theme.dart';
import 'package:mnemata/core/widgets/item_card.dart' as item_card;
import 'package:mnemata/core/widgets/section_label.dart';

class RecycleBinScreen extends StatelessWidget {
  const RecycleBinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final database = GetIt.instance<AppDatabase>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<List<MnemataItem>>(
          stream: database.watchRecycleBinItems(),
          builder: (context, snapshot) {
            final header = Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 8, bottom: 8),
                    child: SectionLabel('Recycle bin'),
                  ),
                  Text(
                    'Trashed items',
                    style: theme.textTheme.displaySmall,
                  ),
                ],
              ),
            );

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  header,
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return Column(
                children: [
                  header,
                  Expanded(
                    child: Center(
                      child: Text(
                        'Error: ${snapshot.error}',
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ),
                ],
              );
            }

            final items = snapshot.data ?? const <MnemataItem>[];
            if (items.isEmpty) {
              return Column(
                children: [
                  header,
                  Expanded(
                    child: Center(
                      child: Text(
                        'Recycle bin is empty.',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: items.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return header;
                final item = items[index - 1];
                return _RecycleRow(
                  item: item,
                  onRestore: () => _restoreItem(context, database, item),
                  onDelete: () => _confirmPermanentDelete(
                    context,
                    database,
                    item,
                  ),
                  showDivider: index < items.length,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _restoreItem(
    BuildContext context,
    AppDatabase database,
    MnemataItem item,
  ) async {
    final restored = await database.restoreItemFromRecycle(item.id);
    debugPrint('recycle_bin.restore item=${item.id} restored=$restored');
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          restored > 0 ? 'Item restored' : 'Item was already restored',
        ),
      ),
    );
  }

  Future<void> _confirmPermanentDelete(
    BuildContext context,
    AppDatabase database,
    MnemataItem item,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete permanently?'),
        content: const Text(
          'This action cannot be undone and removes the item forever.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'DELETE',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    final deleted = await database.permanentlyDeleteItem(item.id);
    debugPrint('recycle_bin.permanent_delete item=${item.id} deleted=$deleted');
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          deleted > 0 ? 'Item permanently deleted' : 'Item no longer exists',
        ),
      ),
    );
  }
}

class _RecycleRow extends StatelessWidget {
  const _RecycleRow({
    required this.item,
    required this.onRestore,
    required this.onDelete,
    required this.showDivider,
  });

  final MnemataItem item;
  final VoidCallback onRestore;
  final VoidCallback onDelete;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final deletedAt = item.deletedAt;
    final title = item.title?.trim().isNotEmpty == true
        ? item.title!
        : (item.url ?? item.filePath ?? 'Untitled item');
    final source = _sourceLabel(item);
    final deletedLabel = deletedAt == null
        ? 'unknown'
        : DateFormat('MMM d, yyyy').format(deletedAt.toLocal());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: item_card.ItemCard(
                data: item_card.ItemCardData(
                  title: title,
                  source: source,
                  readTime: 'deleted $deletedLabel',
                  tags: const [],
                  thumbTone: MnemataColors.ink4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: 'Restore item',
                    icon: const Icon(Icons.restore_from_trash),
                    color: cs.onSurfaceVariant,
                    onPressed: onRestore,
                  ),
                  IconButton(
                    tooltip: 'Delete permanently',
                    icon: const Icon(Icons.delete_forever),
                    color: cs.error,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ),
          ],
        ),
        if (showDivider) const Divider(height: 1),
      ],
    );
  }

  String _sourceLabel(MnemataItem item) {
    final url = item.url;
    if (url != null && url.isNotEmpty) {
      try {
        final host = Uri.parse(url).host;
        if (host.isNotEmpty) return host;
      } catch (_) {}
    }
    final path = item.filePath;
    if (path != null && path.isNotEmpty) return 'local file';
    return 'item';
  }
}
