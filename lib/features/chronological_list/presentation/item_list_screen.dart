import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/features/chronological_list/presentation/item_editor_screen.dart';
import 'package:mnemata/features/ingestion/services/share_service.dart';
import 'package:mnemata/features/organization/presentation/label_manager_screen.dart';
import 'package:mnemata/features/organization/presentation/label_selector_sheet.dart';
import 'package:mnemata/features/reader/presentation/reader_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';
  final Set<int> _selectedLabelIds = {};
  bool _isHistoryMode = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddUrlDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add URL'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'https://example.com',
          ),
          autofocus: true,
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              final url = controller.text.trim();
              if (url.isNotEmpty) {
                GetIt.instance<ShareService>().handleUrl(url);
              }
              Navigator.pop(context);
            },
            child: const Text('ADD'),
          ),
        ],
      ),
    );
  }

  void _updateSearch(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isNotEmpty) {
        _selectedLabelIds.clear();
        _isHistoryMode = false;
      }
    });
  }

  Stream<List<MnemataItem>> _getStream(AppDatabase database) {
    if (_searchQuery.isNotEmpty) {
      return database.searchItems(_searchQuery);
    }
    if (_isHistoryMode) {
      if (_selectedLabelIds.isNotEmpty) {
        // For history, we'll just filter by the first selected label for simplicity if multiple are selected,
        // or we could implement watchRecentlyOpenedByMultipleLabels.
        // Let's stick to the first one for now as per v1 logic but with multi-select capability.
        return database.watchRecentlyOpenedByLabel(_selectedLabelIds.first, 20);
      }
      return database.watchRecentlyOpened(20);
    }
    if (_selectedLabelIds.isNotEmpty) {
      return database.watchItemsByMultipleLabels(_selectedLabelIds.toList());
    }
    return database.watchAllItems();
  }

  String _getTitle() {
    if (_isHistoryMode) return 'Recently Opened';
    if (_selectedLabelIds.isEmpty) return 'Mnemata';
    return '${_selectedLabelIds.length} Tags Selected';
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
            : Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.asset(
                      'assets/mnemata.jpg',
                      height: 32,
                      width: 32,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(_getTitle()),
                ],
              ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          if (!_isSearching)
            IconButton(
              icon: const Icon(Icons.label),
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddUrlDialog(context),
        child: const Icon(Icons.add_link),
        tooltip: 'Add URL',
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildQuickFilterBar(context, database),
            Expanded(
              child: StreamBuilder<List<MnemataItem>>(
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

                  return _buildItemsList(database, items);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilterBar(BuildContext context, AppDatabase database) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: Theme.of(context).colorScheme.surface,
      child: StreamBuilder<List<Label>>(
        stream: database.watchAllLabels(),
        builder: (context, snapshot) {
          final labels = snapshot.data ?? [];
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedLabelIds.isEmpty && !_isHistoryMode,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedLabelIds.clear();
                        _isHistoryMode = false;
                      });
                    }
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: const Icon(Icons.history, size: 16),
                  label: const Text('History'),
                  selected: _isHistoryMode,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedLabelIds.clear();
                        _isHistoryMode = true;
                      });
                    }
                  },
                ),
              ),
              ...labels.map((label) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    avatar: Icon(
                      Icons.label,
                      size: 16,
                      color: label.color != null ? Color(label.color!) : null,
                    ),
                    label: Text(label.name),
                    selected: _selectedLabelIds.contains(label.id),
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedLabelIds.add(label.id);
                          _isHistoryMode = false;
                        } else {
                          _selectedLabelIds.remove(label.id);
                        }
                      });
                    },
                  ),
                );
              }),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemsList(AppDatabase database, List<MnemataItem> items) {
    final itemIds = items.map((e) => e.id).toList(growable: false);

    return StreamBuilder<Map<int, List<Label>>>(
      stream: database.watchLabelsForItems(itemIds),
      builder: (context, labelsSnapshot) {
        final labelsByItem = labelsSnapshot.data ?? const <int, List<Label>>{};

        return ReorderableListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: items.length,
          buildDefaultDragHandles: false,
          onReorder: (oldIndex, newIndex) async {
            if (oldIndex < newIndex) {
              newIndex -= 1;
            }
            final List<MnemataItem> updatedList = List.from(items);
            final MnemataItem item = updatedList.removeAt(oldIndex);
            updatedList.insert(newIndex, item);

            await database.updateItemsSortOrderInBatch(updatedList);
          },
          itemBuilder: (context, index) {
            final item = items[index];
            return _ItemTile(
              key: ValueKey(item.id),
              item: item,
              index: index,
              labels: labelsByItem[item.id] ?? const <Label>[],
            );
          },
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, AppDatabase database) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.asset(
                      'assets/mnemata.jpg',
                      height: 64,
                      width: 64,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mnemata',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.all_inbox),
            title: const Text('All Items'),
            selected: _selectedLabelIds.isEmpty && !_isHistoryMode,
            onTap: () {
              setState(() {
                _selectedLabelIds.clear();
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
                _selectedLabelIds.clear();
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

                return ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Text('Tags', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    ...labels.map((l) => _buildLabelTile(context, l)),
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
    final isSelected = _selectedLabelIds.contains(label.id);
    return ListTile(
      leading: Icon(
        Icons.label,
        color: label.color != null ? Color(label.color!) : Colors.blue,
      ),
      title: Text(label.name),
      selected: isSelected,
      trailing: isSelected ? const Icon(Icons.check, size: 16) : null,
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedLabelIds.remove(label.id);
          } else {
            _selectedLabelIds.add(label.id);
            _isHistoryMode = false;
          }
        });
      },
    );
  }
}

class _ItemTile extends StatelessWidget {
  final MnemataItem item;
  final int index;
  final List<Label> labels;

  const _ItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUrl = item.type == 'url';
    final String title = item.title ?? (isUrl ? (item.url ?? 'Link') : (item.filePath ?? 'File'));
    final String subtitle = isUrl ? (item.url ?? '') : (item.filePath ?? '');
    final String dateStr = DateFormat('MMM dd, yyyy • HH:mm').format(item.createdAt);
    return Slidable(
      key: ValueKey(item.id),
      startActionPane: ActionPane(
        motion: const StretchMotion(),
        dismissible: DismissiblePane(
          onDismissed: () {},
          closeOnCancel: true,
          confirmDismiss: () async {
            Future.microtask(() {
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ItemEditorScreen(item: item)),
                );
              }
            });
            return false;
          },
        ),
        children: [
          SlidableAction(
            onPressed: (context) {
              Slidable.of(context)?.close();
              Future.microtask(() {
                if (context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ItemEditorScreen(item: item)),
                  );
                }
              });
            },
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            icon: Icons.edit,
            label: 'Edit',
            autoClose: false,
          ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const StretchMotion(),
        dismissible: DismissiblePane(
          onDismissed: () {},
          closeOnCancel: true,
          confirmDismiss: () async {
            Future.microtask(() async {
              if (item.url != null) {
                await Share.share(item.url!, subject: item.title);
              } else if (item.title != null) {
                await Share.share(item.title!);
              }
            });
            return false;
          },
        ),
        children: [
          SlidableAction(
            onPressed: (context) {
              Slidable.of(context)?.close();
              Future.microtask(() async {
                if (item.url != null) {
                  await Share.share(item.url!, subject: item.title);
                } else if (item.title != null) {
                  await Share.share(item.title!);
                }
              });
            },
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            icon: Icons.share,
            label: 'Share',
            autoClose: false,
          ),
        ],
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: item.thumbnailUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: item.thumbnailUrl!,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    memCacheWidth: 120,
                    memCacheHeight: 120,
                    fadeInDuration: Duration.zero,
                    fadeOutDuration: Duration.zero,
                    placeholder: (context, url) => _buildThumbnailPlaceholder(context),
                    errorWidget: (context, url, error) => _buildThumbnailFallback(context),
                  ),
                )
              : _buildThumbnailFallback(context),
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
              const SizedBox(height: 4),
              if (labels.isNotEmpty)
                Row(
                  children: labels.map((label) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: label.color != null
                              ? Color(label.color!)
                              : (label.isFolder ? Colors.amber : Colors.blue),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.label_outline),
                onPressed: () => LabelSelectorSheet.show(context, item),
              ),
              ReorderableDragStartListener(
                index: index,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Icon(Icons.drag_handle, color: Colors.grey),
                ),
              ),
            ],
          ),
          onTap: () => _handleOpen(context),
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
    );
  }

  Widget _buildThumbnailFallback(BuildContext context) {
    final isUrlItem = item.type == 'url';
    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      child: Icon(
        isUrlItem ? Icons.link : Icons.file_present,
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }

  Future<void> _handleOpen(BuildContext context) async {
    final database = GetIt.instance<AppDatabase>();
    await database.updateLastOpenedAt(item.id);

    try {
      if (item.type == 'url' && item.url != null) {
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReaderScreen(item: item),
            ),
          );
        }
      } else if (item.type == 'file' && item.filePath != null) {
        final result = await OpenFilex.open(item.filePath!);
        if (result.type != ResultType.done) {
          throw Exception('Could not open file: ${result.message}');
        }
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
