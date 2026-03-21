import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/organization/presentation/label_manager_screen.dart';
import 'package:mnemata/features/organization/presentation/label_selector_sheet.dart';
import 'package:mnemata/features/reader/presentation/reader_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:open_file_plus/open_file_plus.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  Label? _selectedLabel;
  bool _isHistoryMode = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isNotEmpty) {
        _selectedLabel = null;
        _isHistoryMode = false;
      }
    });
  }

  Stream<List<MnemataItem>> _getStream(AppDatabase database) {
    if (_searchQuery.isNotEmpty) {
      return database.searchItems(_searchQuery);
    }
    if (_isHistoryMode) {
      return database.watchRecentlyOpened(20);
    }
    if (_selectedLabel != null) {
      return database.watchItemsByLabel(_selectedLabel!.id);
    }
    return database.watchAllItems();
  }

  String _getTitle() {
    if (_isHistoryMode) return 'Recently Opened';
    return _selectedLabel?.name ?? 'Mnemata';
  }

  @override
  Widget build(BuildContext context) {
    final database = GetIt.instance<AppDatabase>();

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.black),
                onChanged: _updateSearch,
              )
            : Text(_getTitle()),
        backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.folder_open),
              tooltip: 'Manage Labels',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LabelManagerScreen()),
                );
              },
            ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context, database),
      body: StreamBuilder<List<MnemataItem>>(
        stream: _getStream(database),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}'),
                ],
              ),
            );
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: Theme.of(context).disabledColor,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No items found.',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return _ItemTile(item: item);
            },
          );
        },
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AppDatabase database) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
            ),
            child: const Center(
              child: Text(
                'Mnemata',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.all_inbox),
            title: const Text('All Items'),
            selected: _selectedLabel == null && !_isHistoryMode,
            onTap: () {
              setState(() {
                _selectedLabel = null;
                _isHistoryMode = false;
              });
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Recently Opened'),
            selected: _isHistoryMode,
            onTap: () {
              setState(() {
                _selectedLabel = null;
                _isHistoryMode = true;
              });
              Navigator.pop(context);
            },
          ),
          const Divider(),
          Expanded(
            child: StreamBuilder<List<Label>>(
              stream: database.watchAllLabels(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                final labels = snapshot.data!;
                final folders = labels.where((l) => l.isFolder).toList();
                final tags = labels.where((l) => !l.isFolder).toList();

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    if (folders.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Folders', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...folders.map((f) => _buildLabelTile(context, f)),
                    ],
                    if (tags.isNotEmpty) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                      ...tags.map((t) => _buildLabelTile(context, t)),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabelTile(BuildContext context, Label label) {
    return ListTile(
      leading: Icon(
        label.isFolder ? Icons.folder : Icons.label,
        color: label.isFolder ? Colors.amber : Colors.blue,
      ),
      title: Text(label.name),
      selected: _selectedLabel?.id == label.id,
      onTap: () {
        setState(() => _selectedLabel = label);
        Navigator.pop(context);
      },
    );
  }
}

class _ItemTile extends StatelessWidget {
  final MnemataItem item;

  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final bool isUrl = item.type == 'url';
    final String title = item.title ?? (isUrl ? (item.url ?? 'Link') : (item.filePath ?? 'File'));
    final String subtitle = isUrl ? (item.url ?? '') : (item.filePath ?? '');
    final String dateStr = DateFormat('MMM dd, yyyy • HH:mm').format(item.createdAt);
    final database = GetIt.instance<AppDatabase>();

    return Slidable(
      key: ValueKey(item.id),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) => database.deleteItem(item.id),
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            icon: Icons.delete,
            label: 'Delete',
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (context) {
              if (item.url != null) {
                Share.share(item.url!, subject: item.title);
              } else if (item.title != null) {
                Share.share(item.title!);
              }
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.share,
            label: 'Share',
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            isUrl ? Icons.link : Icons.file_present,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (subtitle.isNotEmpty)
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            const SizedBox(height: 4),
            Text(
              dateStr,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.label_outline),
          onPressed: () => LabelSelectorSheet.show(context, item),
        ),
        onTap: () => _handleOpen(context),
      ),
    ),
  );
}

  Future<void> _handleOpen(BuildContext context) async {
    final database = GetIt.instance<AppDatabase>();
    await database.updateLastOpenedAt(item.id);

    try {
      if (item.type == 'url' && item.url != null) {
        if (item.content != null && item.content!.isNotEmpty) {
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ReaderScreen(item: item),
              ),
            );
          }
        } else {
          final uri = Uri.parse(item.url!);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          } else {
            throw Exception('Could not launch ${item.url}');
          }
        }
      } else if (item.type == 'file' && item.filePath != null) {
        // final result = await OpenFile.open(item.filePath);
        // if (result.type != ResultType.done) {
        //   throw Exception('Could not open file: ${result.message}');
        // }
        throw Exception('Opening files is temporarily disabled in this build.');
      } else {
        throw Exception('Unknown item type or missing path/URL');
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
