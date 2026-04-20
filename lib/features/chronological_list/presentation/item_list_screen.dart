import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:mnemata/core/database/app_database.dart';
import 'package:mnemata/core/theme/app_theme.dart';
import 'package:mnemata/core/widgets/item_card.dart'
    show ItemCard, ItemCardData;
import 'package:mnemata/core/widgets/section_label.dart';
import 'package:mnemata/core/widgets/tag_chip.dart';
import 'package:mnemata/features/chronological_list/presentation/item_editor_screen.dart';
import 'package:mnemata/features/chronological_list/presentation/item_quick_actions_menu.dart';
import 'package:mnemata/features/chronological_list/presentation/recycle_bin_screen.dart';
import 'package:mnemata/features/chronological_list/presentation/search_result_tile.dart';
import 'package:mnemata/features/chronological_list/presentation/widgets/item_list_header.dart';
import 'package:mnemata/features/chronological_list/services/list_pagination_controller.dart';
import 'package:mnemata/features/chronological_list/services/list_state_snapshot.dart';
import 'package:mnemata/features/chronological_list/services/search_snippet_builder.dart';
import 'package:mnemata/features/ingestion/presentation/web_add_item_sheet.dart';
import 'package:mnemata/features/ingestion/services/share_service.dart';
import 'package:mnemata/features/intelligence/presentation/semantic_mode_toggle.dart';
import 'package:mnemata/features/intelligence/services/api_key_store.dart';
import 'package:mnemata/features/intelligence/services/semantic_search_service.dart';
import 'package:mnemata/features/organization/presentation/label_manager_screen.dart';
import 'package:mnemata/features/organization/presentation/label_selector_sheet.dart';
import 'package:mnemata/features/reader/presentation/reader_screen.dart';
import 'package:mnemata/features/settings/presentation/settings_screen.dart';
import 'package:mnemata/features/settings/presentation/about_screen.dart';
import 'package:mnemata/features/settings/services/settings_service.dart';
import 'package:mnemata/core/utils/share_utils.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Palette of tag dot colors used when a label has no explicit color set.
// Keeps the visual language editorial (see MnemataColors.tagN in
// lib/core/theme/app_theme.dart).
const List<Color> _fallbackTagPalette = <Color>[
  MnemataColors.tag1,
  MnemataColors.tag2,
  MnemataColors.tag3,
  MnemataColors.tag4,
  MnemataColors.tag5,
  MnemataColors.tag6,
];

Color _tagColorFor(Label label) {
  if (label.color != null) {
    return Color(label.color!);
  }
  // Deterministic pick from the fallback palette based on id so the same
  // label keeps the same color across rebuilds.
  return _fallbackTagPalette[label.id.abs() % _fallbackTagPalette.length];
}

// Pick a dominant thumb tone for the card placeholder. Prefers the first
// label's color, then falls back to the id-hashed palette.
Color _toneFor(MnemataItem item, List<Label> labels) {
  if (labels.isNotEmpty) {
    return _tagColorFor(labels.first);
  }
  return _fallbackTagPalette[item.id.abs() % _fallbackTagPalette.length];
}

String _typeGlyphFor(MnemataItem item) {
  if (item.type == 'file') {
    final path = (item.filePath ?? '').toLowerCase();
    if (path.endsWith('.pdf')) return 'pdf';
    return 'F';
  }
  return 'A';
}

// Rough read-time estimate. Word-based approximation keeps the cost trivial
// and matches the editorial look ("5 min read").
String _estimateReadTime(MnemataItem item) {
  final text = item.content ?? '';
  if (text.trim().isEmpty) {
    return '—';
  }
  final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  // ~220 wpm — comfortable pace for long-form articles.
  final minutes = (words / 220).ceil().clamp(1, 99);
  return '$minutes min read';
}

// Derive the host / source label shown in the item card's meta row.
String _sourceFor(MnemataItem item) {
  final author = item.author?.trim();
  if (author != null && author.isNotEmpty) {
    return author;
  }

  if (item.type == 'url' && item.url != null && item.url!.isNotEmpty) {
    try {
      final host = Uri.parse(item.url!).host;
      return host.replaceFirst('www.', '');
    } catch (_) {
      return item.url!;
    }
  }
  return item.filePath?.split('/').last ?? '';
}

// Collapse createdAt into a relative bucket label. Items within the same
// bucket share a SectionLabel header in the list.
String _groupKey(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return 'today';
  if (diff < 7) return 'week';
  if (diff < 30) return 'month';
  return DateFormat('yyyy-MM').format(d);
}

String _groupLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = DateTime(d.year, d.month, d.day);
  final diff = today.difference(day).inDays;
  if (diff <= 0) return 'Today · ${DateFormat('MMM d').format(d)}';
  if (diff < 7) return 'Earlier this week';
  if (diff < 30) {
    // Rough rolling 4-week window — format as "MMM dd – MMM dd".
    final weekEnd = d;
    final weekStart = d.subtract(const Duration(days: 6));
    return '${DateFormat('MMM dd').format(weekEnd)} – '
        '${DateFormat('MMM dd').format(weekStart)}';
  }
  return DateFormat('MMMM yyyy').format(d);
}

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  static const int _pageSize = 40;
  static const Duration _searchDebounceDelay = Duration(milliseconds: 300);

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _listScrollController = ScrollController();
  final ListPaginationController _paginationController =
      ListPaginationController(pageSize: _pageSize);
  bool _isSearching = false;
  String _searchQuery = '';
  final Set<int> _selectedLabelIds = {};
  bool _isHistoryMode = false;
  double? _pendingScrollOffset;
  int _latestStreamItemCount = 0;

  bool _isMultiSelectMode = false;
  final Set<int> _selectedItemIds = {};
  List<String> _searchHistory = [];
  bool _showSearchHistory = false;
  Timer? _searchDebounce;
  bool _semanticMode = false;
  bool _semanticModeAvailable = false;
  bool _semanticSettingEnabled = false;

  @override
  void initState() {
    super.initState();
    _restoreListStateSnapshot();
    if (!kIsWeb) {
      _loadSearchHistory();
    }
    unawaited(_loadSemanticAvailability());
    _searchFocusNode.addListener(() {
      setState(() {
        _showSearchHistory = !kIsWeb && _searchFocusNode.hasFocus;
      });
      _persistListStateSnapshot();
    });
    _listScrollController.addListener(_handleListScroll);
  }

  Future<void> _loadSemanticAvailability() async {
    final keyStore = GetIt.instance<ApiKeyStore>();
    final settings = GetIt.instance<SettingsService>();
    final hasKey = await keyStore.hasKeyForProvider(settings.aiProvider);
    if (!mounted) {
      return;
    }
    setState(() {
      _semanticSettingEnabled = settings.semanticSearchEnabled;
      _semanticModeAvailable = hasKey && settings.semanticSearchEnabled;
      if (!_semanticModeAvailable) {
        _semanticMode = false;
      }
    });
  }

  Future<void> _loadSearchHistory() async {
    if (kIsWeb) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveSearchToHistory(String query) async {
    if (kIsWeb) {
      return;
    }

    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory.remove(trimmed);
      _searchHistory.insert(0, trimmed);
      if (_searchHistory.length > 10) {
        _searchHistory = _searchHistory.sublist(0, 10);
      }
      _showSearchHistory = false;
    });
    await prefs.setStringList('search_history', _searchHistory);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _persistListStateSnapshot();
    _listScrollController.removeListener(_handleListScroll);
    _listScrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _restoreListStateSnapshot() {
    final snapshot = ListStateSnapshotStore.current;
    if (snapshot == null) {
      return;
    }

    _searchQuery = snapshot.query;
    _searchController.text = snapshot.query;
    _selectedLabelIds
      ..clear()
      ..addAll(snapshot.selectedLabelIds);
    _isHistoryMode = snapshot.isHistoryMode;
    _isSearching = snapshot.isSearching;
    _pendingScrollOffset = snapshot.scrollOffset;
  }

  void _persistListStateSnapshot() {
    final selectedLabelIds = _selectedLabelIds.toList()..sort();
    final scrollOffset = _listScrollController.hasClients
        ? _listScrollController.offset
        : (_pendingScrollOffset ?? 0);

    ListStateSnapshotStore.save(
      ListStateSnapshot(
        query: _searchQuery,
        selectedLabelIds: selectedLabelIds,
        isHistoryMode: _isHistoryMode,
        isSearching: _isSearching,
        scrollOffset: scrollOffset,
      ),
    );
  }

  void _resetPagination() {
    _paginationController.reset();
  }

  void _handleListScroll() {
    _persistListStateSnapshot();

    if (!_listScrollController.hasClients) {
      return;
    }

    final position = _listScrollController.position;
    if (position.maxScrollExtent <= 0) {
      return;
    }

    final remaining = position.maxScrollExtent - position.pixels;
    if (remaining > 600) {
      return;
    }

    final loadedMore = _paginationController.loadNextPage(
      _latestStreamItemCount,
    );
    if (loadedMore && mounted) {
      setState(() {});
    }
  }

  @visibleForTesting
  void debugLoadNextPageForTests() {
    final loadedMore = _paginationController.loadNextPage(
      _latestStreamItemCount,
    );
    if (loadedMore && mounted) {
      setState(() {});
    }
  }

  @visibleForTesting
  String get debugSearchQueryForTests => _searchQuery;

  void _restorePendingScrollOffset() {
    final targetOffset = _pendingScrollOffset;
    if (targetOffset == null || !_listScrollController.hasClients) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_listScrollController.hasClients) {
        return;
      }
      final max = _listScrollController.position.maxScrollExtent;
      final clamped = targetOffset.clamp(0.0, max).toDouble();
      _listScrollController.jumpTo(clamped);
      _pendingScrollOffset = null;
    });
  }

  void _toggleSelection(int id) {
    if (kIsWeb) {
      return;
    }

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
    if (kIsWeb) {
      return;
    }

    setState(() {
      _isMultiSelectMode = true;
      _selectedItemIds.add(id);
    });
  }

  bool _hasReservedLabel(List<Label> labels, String name) {
    final needle = name.toLowerCase();
    return labels.any((label) => label.name.toLowerCase() == needle);
  }

  Future<void> _toggleReservedLabel({
    required int itemId,
    required List<Label> currentLabels,
    required String labelName,
  }) async {
    final database = GetIt.instance<AppDatabase>();
    final normalizedName = labelName.toLowerCase();
    final current = currentLabels
        .where((label) => label.name.toLowerCase() == normalizedName)
        .toList(growable: false);

    if (current.isNotEmpty) {
      for (final label in current) {
        await database.removeLabelFromItem(itemId, label.id);
      }
      return;
    }

    final labelId = await database.getOrCreateLabel(labelName);
    await database.assignLabelToItem(itemId, labelId);
  }

  Future<bool> _confirmDeleteWithUndo(MnemataItem item) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Move item to recycle bin?'),
        content: const Text('You can restore this item with Undo.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: cs.error),
            child: const Text('MOVE'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return false;
    }

    final database = GetIt.instance<AppDatabase>();
    await database.deleteItem(item.id);

    if (!mounted) {
      return true;
    }

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Item moved to recycle bin'),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            unawaited(database.restoreItemFromRecycle(item.id));
          },
        ),
      ),
    );

    return true;
  }

  Future<void> _openItem(MnemataItem item) async {
    final database = GetIt.instance<AppDatabase>();
    await database.updateLastOpenedAt(item.id);

    if (!mounted) {
      return;
    }

    try {
      if (item.type == 'url' && item.url != null) {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ReaderScreen(item: item)),
        );
        return;
      }

      if (item.type == 'file' && item.filePath != null) {
        final result = await OpenFilex.open(item.filePath!);
        if (result.type != ResultType.done) {
          throw Exception('Could not open file: ${result.message}');
        }
        return;
      }

      throw Exception('Unknown item type or missing path/URL');
    } catch (error) {
      if (!mounted) {
        return;
      }

      final cs = Theme.of(context).colorScheme;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error'), backgroundColor: cs.error),
      );
    }
  }

  Future<void> _handleQuickAction(
    MnemataItem item,
    List<Label> labels,
    ItemQuickAction action,
  ) async {
    switch (action) {
      case ItemQuickAction.openReader:
        await _openItem(item);
        return;
      case ItemQuickAction.toggleRead:
        await _toggleReservedLabel(
          itemId: item.id,
          currentLabels: labels,
          labelName: 'read',
        );
        return;
      case ItemQuickAction.toggleFavorite:
        await _toggleReservedLabel(
          itemId: item.id,
          currentLabels: labels,
          labelName: 'favorite',
        );
        return;
      case ItemQuickAction.delete:
        await _confirmDeleteWithUndo(item);
        return;
      case ItemQuickAction.share:
        await ShareUtils.shareItem(context, item);
        return;
    }
  }

  Future<void> _confirmBulkDelete(
    BuildContext context,
    AppDatabase database,
  ) async {
    final cs = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Move Items To Recycle Bin?'),
        content: Text(
          'Are you sure you want to move ${_selectedItemIds.length} items to the recycle bin?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('MOVE', style: TextStyle(color: cs.error)),
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
          const SnackBar(content: Text('Items moved to recycle bin')),
        );
      }
    }
  }

  Future<void> _bulkShare(AppDatabase database) async {
    final ids = _selectedItemIds.toList();
    final itemsStream = await database.watchAllItems().first;
    final itemsToShare = itemsStream
        .where((item) => ids.contains(item.id))
        .toList();

    final shareLines = itemsToShare
        .map((item) {
          if (item.url != null) return item.url!;
          if (item.title != null) return item.title!;
          return '';
        })
        .where((s) => s.isNotEmpty)
        .join('\n\n');

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
          decoration: const InputDecoration(hintText: 'https://example.com'),
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

  Future<void> _showAddItemEntry(BuildContext context) async {
    if (!kIsWeb) {
      _showAddUrlDialog(context);
      return;
    }

    final cs = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MnemataRadii.xl),
        ),
      ),
      builder: (context) => const WebAddItemSheet(),
    );
  }

  void _updateSearch(String query) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(_searchDebounceDelay, () {
      if (!mounted) {
        return;
      }
      _applySearchQuery(query);
    });
  }

  void _applySearchQuery(String query) {
    setState(() {
      _searchQuery = query;
      _resetPagination();
      if (query.isNotEmpty) {
        _isHistoryMode = false;
        _showSearchHistory = false;
      } else if (!kIsWeb && _searchFocusNode.hasFocus) {
        _showSearchHistory = true;
      }
    });
    _persistListStateSnapshot();
  }

  Stream<List<MnemataItem>> _getStream(AppDatabase database) {
    if (_searchQuery.isNotEmpty) {
      if (_semanticMode && _semanticModeAvailable) {
        final semanticSearch = GetIt.instance<SemanticSearchService>();
        return semanticSearch.searchAsStream(
          _searchQuery,
          labelIds: _selectedLabelIds.toList(),
        );
      }
      return database.searchItems(
        _searchQuery,
        labelIds: _selectedLabelIds.toList(),
      );
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

  // Kicker shown above the big serif title. Reflects the current filter.
  String _kickerFor(int itemCount) {
    if (_isHistoryMode) {
      return 'Recently opened · $itemCount items';
    }
    if (_selectedLabelIds.isEmpty) {
      return 'Your library · $itemCount items';
    }
    return '${_selectedLabelIds.length} tags selected · $itemCount items';
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
      _showSearchHistory = !kIsWeb && _searchFocusNode.hasFocus;
      _resetPagination();
    });
    _persistListStateSnapshot();
    _searchFocusNode.requestFocus();
  }

  void _closeSearch() {
    _searchDebounce?.cancel();
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchQuery = '';
      _showSearchHistory = false;
      _resetPagination();
    });
    _persistListStateSnapshot();
  }

  void _openMoreFiltersFromChips(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null) {
      scaffold.openDrawer();
    }
  }

  void _showMoreMenu(BuildContext context) {
    // Simple overflow menu — mirrors what used to live behind the Label
    // Manager icon button and doubles as an entry point for the drawer.
    final scaffold = Scaffold.of(context);
    showMenu<_MoreAction>(
      context: context,
      position: const RelativeRect.fromLTRB(1000, 60, 8, 0),
      items: const [
        PopupMenuItem(
          value: _MoreAction.openDrawer,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.menu),
            title: Text('Menu'),
          ),
        ),
        PopupMenuItem(
          value: _MoreAction.manageLabels,
          child: ListTile(
            dense: true,
            leading: Icon(Icons.label),
            title: Text('Manage Labels'),
          ),
        ),
      ],
    ).then((value) {
      if (!mounted || value == null) return;
      switch (value) {
        case _MoreAction.openDrawer:
          scaffold.openDrawer();
          break;
        case _MoreAction.manageLabels:
          if (!context.mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LabelManagerScreen()),
          );
          break;
      }
    });
  }

  void _clearFiltersOnly() {
    setState(() {
      _selectedLabelIds.clear();
      _isHistoryMode = false;
      _resetPagination();
    });
    _persistListStateSnapshot();
  }

  Widget _buildSearchErrorState(ColorScheme cs) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 52, color: cs.error),
            const SizedBox(height: 12),
            Text(
              'Search is temporarily unavailable.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Try running the same query again or return to the full list.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => _applySearchQuery(_searchController.text),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry Search'),
                ),
                OutlinedButton.icon(
                  onPressed: _closeSearch,
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Back to list'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchEmptyState(ColorScheme cs) {
    final canClearFilters = _selectedLabelIds.isNotEmpty || _isHistoryMode;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.manage_search, size: 64, color: cs.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'No search results',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different phrase or widen your current filters.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () {
                    _searchController.clear();
                    _applySearchQuery('');
                  },
                  child: const Text('Clear query'),
                ),
                if (canClearFilters)
                  OutlinedButton(
                    onPressed: _clearFiltersOnly,
                    child: const Text('Clear filters'),
                  ),
                FilledButton(
                  onPressed: () {
                    _searchController.clear();
                    _closeSearch();
                    _clearFiltersOnly();
                  },
                  child: const Text('View all items'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLibraryEmptyState(ColorScheme cs) {
    final canClearFilters = _selectedLabelIds.isNotEmpty || _isHistoryMode;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No items found.',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                FilledButton.icon(
                  onPressed: () => _showAddItemEntry(context),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
                if (canClearFilters)
                  OutlinedButton(
                    onPressed: _clearFiltersOnly,
                    child: const Text('Clear filters'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final database = GetIt.instance<AppDatabase>();
    final cs = Theme.of(context).colorScheme;

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
            )
          : null,
      drawer: _isMultiSelectMode ? null : _buildDrawer(context, database),
      floatingActionButton: _isMultiSelectMode
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddItemEntry(context),
              tooltip: 'Add Item',
              child: Icon(kIsWeb ? Icons.add : Icons.add_link),
            ),
      bottomNavigationBar: _isMultiSelectMode
          ? BottomAppBar(
              child: SafeArea(
                top: false,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton.icon(
                      icon: Icon(Icons.delete, color: cs.error),
                      label: Text('Delete', style: TextStyle(color: cs.error)),
                      onPressed: _selectedItemIds.isEmpty
                          ? null
                          : () => _confirmBulkDelete(context, database),
                    ),
                    TextButton.icon(
                      icon: const Icon(Icons.label),
                      label: const Text('Tags'),
                      onPressed: _selectedItemIds.isEmpty
                          ? null
                          : () {
                              BulkLabelSelectorSheet.show(
                                context,
                                _selectedItemIds.toList(),
                              ).then((_) {
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
                      onPressed: _selectedItemIds.isEmpty
                          ? null
                          : () => _bulkShare(database),
                    ),
                  ],
                ),
              ),
            )
          : null,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                if (!_isMultiSelectMode) _buildTopArea(context, database),
                if (_isSearching && _semanticSettingEnabled)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        SemanticModeToggle(
                          enabled: _semanticModeAvailable,
                          semanticSelected: _semanticMode,
                          onChanged: (isSemantic) {
                            setState(() {
                              _semanticMode = isSemantic;
                            });
                          },
                        ),
                        if (!_semanticModeAvailable)
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(left: 12),
                              child: Text(
                                'Set API key + enable semantic search in Settings.',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                Expanded(
                  child: StreamBuilder<List<MnemataItem>>(
                    stream: _getStream(database),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return _buildSearchErrorState(cs);
                      }

                      final items = snapshot.data ?? [];

                      if (items.isEmpty) {
                        if (_searchQuery.trim().isNotEmpty) {
                          return _buildSearchEmptyState(cs);
                        }
                        return _buildLibraryEmptyState(cs);
                      }

                      return _buildItemsList(database, items);
                    },
                  ),
                ),
              ],
            ),
            if (!kIsWeb && _showSearchHistory && _searchHistory.isNotEmpty)
              Positioned(
                top: 60,
                left: 0,
                right: 0,
                child: Material(
                  elevation: 4,
                  color: cs.surface,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _searchHistory.length,
                    itemBuilder: (context, index) {
                      final historyItem = _searchHistory[index];
                      return ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(historyItem),
                        onTap: () {
                          _searchController.text = historyItem;
                          _updateSearch(historyItem);
                          _saveSearchToHistory(historyItem);
                          FocusScope.of(context).unfocus();
                        },
                        trailing: IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () async {
                            final prefs = await SharedPreferences.getInstance();
                            setState(() {
                              _searchHistory.removeAt(index);
                            });
                            _persistListStateSnapshot();
                            await prefs.setStringList(
                              'search_history',
                              _searchHistory,
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Composite top area: custom header + large title + tag filter row.
  Widget _buildTopArea(BuildContext context, AppDatabase database) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    // Search mode — the header shows an inline text field instead of monogram.
    if (_isSearching) {
      return Builder(
        builder: (innerContext) => ItemListHeader(
          onSearchPressed: () {},
          onMorePressed: () {},
          leading: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            autofocus: true,
            decoration: InputDecoration(
              hintText: 'Search...',
              hintStyle: theme.textTheme.bodyLarge?.copyWith(
                color: cs.onSurfaceVariant,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              filled: false,
              contentPadding: EdgeInsets.zero,
            ),
            style: theme.textTheme.bodyLarge,
            cursorColor: cs.secondary,
            onChanged: _updateSearch,
            onSubmitted: _saveSearchToHistory,
          ),
          trailing: IconButton(
            icon: const Icon(Icons.close),
            tooltip: 'Close search',
            onPressed: _closeSearch,
          ),
        ),
      );
    }

    // Default mode — monogram header + title block + tag filter row.
    return StreamBuilder<List<MnemataItem>>(
      stream: _getStream(database),
      builder: (context, snapshot) {
        final count = snapshot.data?.length ?? 0;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (innerContext) => ItemListHeader(
                onSearchPressed: _startSearch,
                onMorePressed: () => _showMoreMenu(innerContext),
              ),
            ),
            LibraryTitleBlock(
              itemCount: count,
              kickerOverride: _kickerFor(count),
            ),
            const SizedBox(height: 14),
            _buildTagFilterRow(context, database),
          ],
        );
      },
    );
  }

  Widget _buildTagFilterRow(BuildContext context, AppDatabase database) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 44,
      child: StreamBuilder<List<Label>>(
        stream: database.watchAllLabels(),
        builder: (context, snapshot) {
          final labels = snapshot.data ?? const <Label>[];
          return ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TagChip(
                  label: 'all',
                  color: cs.onSurfaceVariant,
                  active: _selectedLabelIds.isEmpty && !_isHistoryMode,
                  onTap: () {
                    setState(() {
                      _selectedLabelIds.clear();
                      _isHistoryMode = false;
                      _resetPagination();
                    });
                    _persistListStateSnapshot();
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TagChip(
                  label: 'history',
                  color: cs.onSurfaceVariant,
                  active: _isHistoryMode,
                  onTap: () {
                    setState(() {
                      _selectedLabelIds.clear();
                      _isHistoryMode = true;
                      _resetPagination();
                    });
                    _persistListStateSnapshot();
                  },
                ),
              ),
              ...labels.map((label) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: TagChip(
                    label: label.name,
                    color: _tagColorFor(label),
                    active: _selectedLabelIds.contains(label.id),
                    onTap: () {
                      setState(() {
                        if (_selectedLabelIds.contains(label.id)) {
                          _selectedLabelIds.remove(label.id);
                        } else {
                          _selectedLabelIds.add(label.id);
                          _isHistoryMode = false;
                        }
                        _resetPagination();
                      });
                      _persistListStateSnapshot();
                    },
                  ),
                );
              }),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TagChip(
                  label: 'more filters',
                  color: cs.secondary,
                  onTap: () => _openMoreFiltersFromChips(context),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildItemsList(AppDatabase database, List<MnemataItem> items) {
    _latestStreamItemCount = items.length;
    _paginationController.clampToTotal(items.length);
    final pagedItems = items.take(_paginationController.visibleCount).toList();
    final itemIds = pagedItems.map((e) => e.id).toList(growable: false);
    final isSearchMode = _searchQuery.trim().isNotEmpty;
    const snippetBuilder = SearchSnippetBuilder();

    return StreamBuilder<Map<int, List<Label>>>(
      stream: database.watchLabelsForItems(itemIds),
      builder: (context, labelsSnapshot) {
        final labelsByItem = labelsSnapshot.data ?? const <int, List<Label>>{};

        // Precompute group keys/labels so section headers render inside the
        // reorderable list without changing the reorder semantics — each
        // visual row still represents exactly one [MnemataItem].
        final groupHeaders = <int, String>{};
        String? lastKey;
        for (var i = 0; i < pagedItems.length; i++) {
          final key = _groupKey(pagedItems[i].createdAt);
          if (key != lastKey) {
            groupHeaders[i] = _groupLabel(pagedItems[i].createdAt);
            lastKey = key;
          }
        }

        _restorePendingScrollOffset();

        Widget listView;

        if (isSearchMode) {
          listView = ListView.builder(
            key: const PageStorageKey<String>('item-list-search-results'),
            controller: _listScrollController,
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: pagedItems.length,
            itemBuilder: (context, index) {
              final item = pagedItems[index];
              final itemLabels = labelsByItem[item.id] ?? const <Label>[];
              final title = item.title?.trim().isNotEmpty == true
                  ? item.title!
                  : (item.type == 'url'
                        ? (item.url ?? 'Link')
                        : (item.filePath?.split('/').last ?? 'File'));
              final snippet = snippetBuilder.build(
                item: item,
                query: _searchQuery,
              );

              final tile = SearchResultTile(
                title: title,
                source: _sourceFor(item),
                snippet: snippet,
                onTap: _isMultiSelectMode
                    ? () => _toggleSelection(item.id)
                    : () => _openItem(item),
                trailing: _isMultiSelectMode
                    ? Checkbox(
                        value: _selectedItemIds.contains(item.id),
                        onChanged: (_) => _toggleSelection(item.id),
                      )
                    : ItemQuickActionsMenu(
                        isRead: _hasReservedLabel(itemLabels, 'read'),
                        isFavorite: _hasReservedLabel(itemLabels, 'favorite'),
                        onSelected: (action) =>
                            _handleQuickAction(item, itemLabels, action),
                      ),
              );

              return GestureDetector(
                onLongPress: _isMultiSelectMode || kIsWeb
                    ? null
                    : () => _enterMultiSelectMode(item.id),
                behavior: HitTestBehavior.opaque,
                child: KeyedSubtree(key: ValueKey(item.id), child: tile),
              );
            },
          );
        } else {
          listView = ReorderableListView.builder(
            key: const PageStorageKey<String>('item-list-reorderable'),
            scrollController: _listScrollController,
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: pagedItems.length,
            buildDefaultDragHandles: false,
            onReorder: (oldIndex, newIndex) async {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final List<MnemataItem> updatedList = List.from(pagedItems);
              final MnemataItem item = updatedList.removeAt(oldIndex);
              updatedList.insert(newIndex, item);

              await database.updateItemsSortOrderInBatch(updatedList);
            },
            itemBuilder: (context, index) {
              final item = pagedItems[index];
              final itemLabels = labelsByItem[item.id] ?? const <Label>[];
              final header = groupHeaders[index];
              return _ItemTile(
                key: ValueKey(item.id),
                item: item,
                index: index,
                labels: itemLabels,
                isSelected: _selectedItemIds.contains(item.id),
                isMultiSelectMode: _isMultiSelectMode,
                groupHeader: header,
                onLongPress: () => _enterMultiSelectMode(item.id),
                onTap: () =>
                    _isMultiSelectMode ? _toggleSelection(item.id) : null,
                onOpenItem: () => _openItem(item),
                onQuickActionSelected: (action) =>
                    _handleQuickAction(item, itemLabels, action),
                canUseMultiSelect: !kIsWeb,
              );
            },
          );
        }

        return Stack(
          children: [
            listView,
            Positioned(
              left: 0,
              top: 0,
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0,
                  child: Text(
                    'visible:${_paginationController.visibleCount}',
                    key: const Key('pagination-visible-count'),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, AppDatabase database) {
    final cs = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Drawer(
      backgroundColor: cs.surface,
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 24),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLow,
                border: Border(
                  bottom: BorderSide(color: cs.outline, width: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MNEMATA',
                    style: theme.textTheme.tracked(cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 8),
                  Text('Library', style: theme.textTheme.headlineMedium),
                ],
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
                  _resetPagination();
                });
                _persistListStateSnapshot();
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
                  _resetPagination();
                });
                _persistListStateSnapshot();
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Recycle Bin'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RecycleBinScreen(),
                  ),
                );
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
                        padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                        child: SectionLabel('Tags'),
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
              onTap: () async {
                Navigator.pop(context);
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
                await _loadSemanticAvailability();
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
      leading: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: _tagColorFor(label),
          shape: BoxShape.circle,
        ),
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
          _resetPagination();
        });
        _persistListStateSnapshot();
      },
    );
  }
}

enum _MoreAction { openDrawer, manageLabels }

class _ItemTile extends StatelessWidget {
  final MnemataItem item;
  final int index;
  final List<Label> labels;
  final bool isSelected;
  final bool isMultiSelectMode;
  final String? groupHeader;
  final VoidCallback onLongPress;
  final VoidCallback onTap;
  final VoidCallback onOpenItem;
  final ValueChanged<ItemQuickAction> onQuickActionSelected;
  final bool canUseMultiSelect;

  const _ItemTile({
    super.key,
    required this.item,
    required this.index,
    required this.labels,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.groupHeader,
    required this.onLongPress,
    required this.onTap,
    required this.onOpenItem,
    required this.onQuickActionSelected,
    required this.canUseMultiSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isRead = labels.any((l) => l.name.toLowerCase() == 'read');
    final isFavorite = labels.any((l) => l.name.toLowerCase() == 'favorite');

    final cardData = ItemCardData(
      title: item.title?.trim().isNotEmpty == true
          ? item.title!
          : (item.type == 'url'
                ? (item.url ?? 'Link')
                : (item.filePath?.split('/').last ?? 'File')),
      source: _sourceFor(item),
      readTime: _estimateReadTime(item),
      tags: labels.map((l) => (label: l.name, color: _tagColorFor(l))).toList(),
      thumbTone: _toneFor(item, labels),
      thumbUrl: item.thumbnailUrl,
      typeGlyph: _typeGlyphFor(item),
    );

    final tile = Slidable(
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
                  MaterialPageRoute(
                    builder: (context) => ItemEditorScreen(item: item),
                  ),
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
                    MaterialPageRoute(
                      builder: (context) => ItemEditorScreen(item: item),
                    ),
                  );
                }
              });
            },
            backgroundColor: cs.primary,
            foregroundColor: cs.onPrimary,
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
              if (context.mounted) {
                await ShareUtils.shareItem(context, item);
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
                if (context.mounted) {
                  await ShareUtils.shareItem(context, item);
                }
              });
            },
            backgroundColor: cs.onSurface,
            foregroundColor: cs.surface,
            icon: Icons.share,
            label: 'Share',
            autoClose: false,
          ),
        ],
      ),
      child: _ItemRow(
        index: index,
        cardData: cardData,
        isSelected: isSelected,
        isMultiSelectMode: isMultiSelectMode,
        onTap: onTap,
        onLongPress: onLongPress,
        onOpenItem: onOpenItem,
        canUseMultiSelect: canUseMultiSelect,
        trailingAction: ItemQuickActionsMenu(
          isRead: isRead,
          isFavorite: isFavorite,
          onSelected: onQuickActionSelected,
        ),
      ),
    );

    if (groupHeader == null) {
      return KeyedSubtree(key: ValueKey(item.id), child: tile);
    }

    return KeyedSubtree(
      key: ValueKey(item.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
            child: SectionLabel(groupHeader!),
          ),
          tile,
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({
    required this.index,
    required this.cardData,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onTap,
    required this.onLongPress,
    required this.onOpenItem,
    required this.canUseMultiSelect,
    required this.trailingAction,
  });

  final int index;
  final ItemCardData cardData;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback onOpenItem;
  final bool canUseMultiSelect;
  final Widget trailingAction;

  @override
  Widget build(BuildContext context) {
    final card = ItemCard(
      data: cardData,
      active: isSelected,
      onTap: isMultiSelectMode ? onTap : onOpenItem,
    );

    // Wrap the card so we can attach long-press (for multi-select entry)
    // and stack a drag handle over its right edge without mutating the
    // shared ItemCard widget.
    return GestureDetector(
      onLongPress: isMultiSelectMode || !canUseMultiSelect ? null : onLongPress,
      behavior: HitTestBehavior.opaque,
      child: Stack(
        children: [
          card,
          if (isMultiSelectMode)
            Positioned(
              top: 0,
              bottom: 0,
              right: 8,
              child: Center(
                child: Checkbox(value: isSelected, onChanged: (_) => onTap()),
              ),
            )
          else
            Positioned(
              top: 0,
              bottom: 0,
              right: 6,
              child: Center(child: trailingAction),
            ),
        ],
      ),
    );
  }
}
