import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:mnemata/core/database/app_database.dart';

class RecycleBinScreen extends StatelessWidget {
  const RecycleBinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final database = GetIt.instance<AppDatabase>();

    return Scaffold(
      appBar: AppBar(title: const Text('Recycle Bin')),
      body: StreamBuilder<List<MnemataItem>>(
        stream: database.watchRecycleBinItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final items = snapshot.data ?? const <MnemataItem>[];
          if (items.isEmpty) {
            return const Center(
              child: Text('Recycle bin is empty.'),
            );
          }

          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final deletedAt = item.deletedAt;
              final title = item.title?.trim().isNotEmpty == true
                  ? item.title!
                  : (item.url ?? item.filePath ?? 'Untitled item');
              final deletedLabel = deletedAt == null
                  ? 'Unknown deletion time'
                  : 'Deleted ${DateFormat('MMM d, yyyy - HH:mm').format(deletedAt.toLocal())}';

              return ListTile(
                leading: const Icon(Icons.delete_outline),
                title: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(deletedLabel),
                trailing: Wrap(
                  spacing: 8,
                  children: [
                    IconButton(
                      tooltip: 'Restore item',
                      icon: const Icon(Icons.restore_from_trash),
                      onPressed: () => _restoreItem(context, database, item),
                    ),
                    IconButton(
                      tooltip: 'Delete permanently',
                      icon: const Icon(Icons.delete_forever, color: Colors.red),
                      onPressed: () => _confirmPermanentDelete(
                        context,
                        database,
                        item,
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
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
            child: const Text('DELETE', style: TextStyle(color: Colors.red)),
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
