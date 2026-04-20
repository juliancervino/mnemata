class ListPaginationController {
  ListPaginationController({this.pageSize = 40}) : _visibleCount = pageSize;

  final int pageSize;
  int _visibleCount;

  int get visibleCount => _visibleCount;

  void reset() {
    _visibleCount = pageSize;
  }

  void clampToTotal(int totalCount) {
    if (totalCount <= 0) {
      _visibleCount = 0;
      return;
    }

    if (_visibleCount <= 0) {
      _visibleCount = pageSize.clamp(1, totalCount);
      return;
    }

    if (_visibleCount > totalCount) {
      _visibleCount = totalCount;
    }
  }

  bool loadNextPage(int totalCount) {
    if (totalCount <= 0) {
      _visibleCount = 0;
      return false;
    }

    if (_visibleCount <= 0) {
      _visibleCount = pageSize.clamp(1, totalCount);
      return true;
    }

    if (_visibleCount >= totalCount) {
      return false;
    }

    _visibleCount = (_visibleCount + pageSize).clamp(0, totalCount);
    return true;
  }
}
