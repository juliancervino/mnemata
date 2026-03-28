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
import 'package:mnemata/features/settings/presentation/settings_screen.dart';
import 'package:mnemata/features/settings/presentation/about_screen.dart';
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

  bool _isMultiSelectMode = false;
  final Set<int> _selectedItemIds = {};

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelection(int id) {
    setState(() {
      if (_selectedItemIds.contains(id)) {
        _selectedItemIds.remove(id);
        if (_selectedItemIds.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedItemIds.add(id);
      }
    });
  }

  void _enterMultiSelectMode(int id) {
    setState(() {
      _isMultiSelectMode = true;
      _selectedItemIds.add(id);
    });
  }

  Future<void> _confirmBulkDelete(BuildContext context, AppDatabase database) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Items?'),
        content: Text('Are you sure you want to delete ${_selectedItemIds.length} items?'),
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

    if (confirmed == true && context.mounted) {
      await database.deleteItems(_selectedItemIds.toList());
      setState(() {
        _isMultiSelectMode = false;
        _selectedItemIds.clear();
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Items deleted')),
        );
      }
    }
  }

  Future<void> _bulkShare(AppDatabase database) async {
    final ids = _selectedItemIds.toList();
    // Fetch items to get URLs or titles
    // Since we only have IDs, we need to query them. For simplicity, we can get them from the stream or do a quick query.
    // Actually, sharing multiple links natively might just be sharing a text block with multiple URLs.
    // Let's build a combined text.
    final itemsStream = await database.watchAllItems().first;
    final itemsToShare = itemsStream.where((item) => ids.contains(item.id)).toList();
    
    final shareLines = itemsToShare.map((item) {
      if (item.url != null) return item.url!;
      if (item.title != null) return item.title!;
      return '';
    }).where((s) => s.isNotEmpty).join('\n\n');

    if (shareLines.isNotEmpty) {
      await Share.share(shareLines);
    }
    setState(() {
      _isMultiSelectMode = false;
      _selectedItemIds.clear();
    });
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
      appBar: _isMultiSelectMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isMultiSelectMode = false;
                    _selectedItemIds.clear();
                  });
                },
              ),
              title: Text('${_selectedItemIds.length} Selected'),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
            )
          : AppBar(
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
      drawer: _isMultiSelectMode ? null : _buildDrawer(context, database),
      floatingActionButton: _isMultiSelectMode
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddUrlDialog(context),
              child: const Icon(Icons.add_link),
              tooltip: 'Add URL',
            ),
      bottomNavigationBar: _isMultiSelectMode
          ? BottomAppBar(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    label: const Text('Delete', style: TextStyle(color: Colors.red)),
                    onPressed: _selectedItemIds.isEmpty ? null : () => _confirmBulkDelete(context, database),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.label),
                    label: const Text('Tags'),
                    onPressed: _selectedItemIds.isEmpty ? null : () {
                      BulkLabelSelectorSheet.show(context, _selectedItemIds.toList()).then((_) {
                        setState(() {
                          _isMultiSelectMode = false;
                          _selectedItemIds.clear();
                        });
                      });
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Share'),
                    onPressed: _selectedItemIds.isEmpty ? null : () => _bulkShare(database),
                  ),
                ],
              ),
            )
          : null,
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
              isSelected: _selectedItemIds.contains(item.id),
              isMultiSelectMode: _isMultiSelectMode,
              onLongPress: () => _enterMultiSelectMode(item.id),
              onTap: () => _isMultiSelectMode ? _toggleSelection(item.id) : null,
            );
          },
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, AppDatabase database) {
    return Drawer(
      child: SafeArea(
        top: false, // AppBar usually handles the top
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AboutScreen()),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
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
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onLongPress;
  final VoidCallback onTap;

  const _ItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.labels,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onLongPress,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUrl = item.type == 'url';
    final String title = item.title ?? (isUrl ? (item.url ?? 'Link') : (item.filePath ?? 'File'));
    
    String subtitle = '';
    if (isUrl && item.url != null) {
      try {
        final uri = Uri.parse(item.url!);
        String host = uri.host.replaceFirst('www.', '');
        
        // Archive.today / archive.ph logic: extract original domain
        if (host.startsWith('archive.') || host == 'archive.today' || host == 'archive.ph' || host == 'archive.is' || host == 'archive.li' || host == 'archive.vn') {
          final segments = uri.pathSegments;
          if (segments.isNotEmpty) {
            // Usually the last segment or the one after the timestamp is the original URL
            for (final segment in segments.reversed) {
              if (segment.contains('.')) {
                try {
                  final potentialUri = Uri.parse(segment.startsWith('http') ? segment : 'https://$segment');
                  if (potentialUri.host.isNotEmpty) {
                    host = potentialUri.host.replaceFirst('www.', '');
                    break;
                  }
                } catch (_) {}
              }
            }
          }
        }
        subtitle = host;
      } catch (_) {
        subtitle = item.url!;
      }
    } else {
      subtitle = item.filePath?.split('/').last ?? '';
    }

    final String dateStr = DateFormat('MMM dd, yyyy').format(item.createdAt);

    Future<void> shareRichContent() async {
      String shareText = '*$title*';
      if (subtitle.isNotEmpty) shareText += '\n_${subtitle}_';
      if (item.url != null) shareText += '\n\nSource: ${item.url}';
      
      if (item.content != null && item.content!.isNotEmpty) {
        // Convert HTML to WhatsApp-compatible markdown
        String plainText = item.content!
            .replaceAll(RegExp(r'<(strong|b)>'), '*')
            .replaceAll(RegExp(r'<\/(strong|b)>'), '*')
            .replaceAll(RegExp(r'<(em|i)>'), '_')
            .replaceAll(RegExp(r'<\/(em|i)>'), '_')
            .replaceAll(RegExp(r'<(br|br \/)>'), '\n')
            .replaceAll(RegExp(r'<\/(p|div|h[1-6])>'), '\n\n')
            .replaceAll(RegExp(r'<[^>]*>'), '')
            .replaceAll('&nbsp;', ' ')
            .replaceAll('&amp;', '&')
            .replaceAll('&lt;', '<')
            .replaceAll('&gt;', '>')
            .replaceAll('&quot;', '"')
            .replaceAll('&#39;', "'")
            .replaceAll(RegExp(r'[ \t]+'), ' ')
            .replaceAll(RegExp(r'\n{3,}'), '\n\n')
            .trim();
        
        final snippet = plainText.length > 3000 ? '${plainText.substring(0, 3000)}...' : plainText;
        shareText += '\n\n---\n\n$snippet';
      }
      
      await Share.share(shareText, subject: item.title);
    }

    return Slidable(
      key: ValueKey(item.id),
      enabled: !isMultiSelectMode,
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
              await shareRichContent();
            });
            return false;
          },
        ),
        children: [
          SlidableAction(
            onPressed: (context) {
              Slidable.of(context)?.close();
              Future.microtask(() async {
                await shareRichContent();
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
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        elevation: isSelected ? 4 : 0.5,
        color: isSelected ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5) : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isSelected 
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide(color: Colors.grey.shade200),
        ),
        child: InkWell(
          onLongPress: isMultiSelectMode ? null : onLongPress,
          onTap: isMultiSelectMode ? onTap : () => _handleOpen(context),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                if (isMultiSelectMode)
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => onTap(),
                  )
                else
                  item.thumbnailUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: CachedNetworkImage(
                            imageUrl: item.thumbnailUrl!,
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                            memCacheWidth: 100,
                            memCacheHeight: 100,
                            placeholder: (context, url) => _buildThumbnailPlaceholder(context, size: 36),
                            errorWidget: (context, url, error) => _buildThumbnailFallback(context, size: 36),
                          ),
                        )
                      : _buildThumbnailFallback(context, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  flex: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (subtitle.isNotEmpty)
                            Text(
                              subtitle,
                              style: TextStyle(
                                fontSize: 11,
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          if (subtitle.isNotEmpty)
                            const Text(' • ', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(
                            dateStr,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isMultiSelectMode) ...[
                  if (labels.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Wrap(
                        spacing: 2,
                        children: labels.take(3).map((label) {
                          return Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: label.color != null
                                  ? Color(label.color!)
                                  : Colors.blue,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ReorderableDragStartListener(
                    index: index,
                    child: const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnailPlaceholder(BuildContext context, {double size = 40}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildThumbnailFallback(BuildContext context, {double size = 40}) {
    final isUrlItem = item.type == 'url';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Icon(
        isUrlItem ? Icons.link : Icons.file_present,
        size: size * 0.6,
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
