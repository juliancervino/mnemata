class ListStateSnapshot {
  const ListStateSnapshot({
    required this.query,
    required this.selectedLabelIds,
    required this.isHistoryMode,
    required this.isSearching,
    required this.scrollOffset,
    this.visibleItemCount,
  });

  final String query;
  final List<int> selectedLabelIds;
  final bool isHistoryMode;
  final bool isSearching;
  final double scrollOffset;
  final int? visibleItemCount;
}

class ListStateSnapshotStore {
  static ListStateSnapshot? _snapshot;

  static ListStateSnapshot? get current => _snapshot;

  static void save(ListStateSnapshot snapshot) {
    _snapshot = snapshot;
  }

  static void clear() {
    _snapshot = null;
  }
}
