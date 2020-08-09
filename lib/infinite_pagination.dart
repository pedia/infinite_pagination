library infinite_pagination;

import 'package:flutter/material.dart';

/// Contained one page of items
class Pagination<T> {
  Pagination({
    this.items,
    this.startingIndex = 0,
    this.hasNext = false,
  });

  final List<T> items;
  final int startingIndex;
  final bool hasNext;
}

class InfinitePagination<T> extends ChangeNotifier {
  InfinitePagination({
    this.fetcher,
    this.itemsPerPage = 10,
    this.maxCacheDistance = 100,
  }) : assert(maxCacheDistance > itemsPerPage);

  /// Async function for fetching a page of items, usually this is an Http
  /// request.
  ///
  /// ```dart
  /// Future <Pagination<T>> fetchPage(int startingIndex, int itemsPerPage) async
  /// ```
  /// If [fetcher] is provide, we should extend from [InfinitePagination] and
  /// implement [fetch].
  final Future<Pagination<T>> Function(int, int) fetcher;

  ///
  final int itemsPerPage;

  /// This is the maximum number of the items we want in memory in each
  /// direction from the current position. For example, if the user
  /// is currently looking at item number 400, we don't want item number
  /// 0 to be kept in memory.
  /// [maxCacheDistance] should bigger than item count in a screen
  final int maxCacheDistance;

  /// The internal store of pages that we got from [fetchPage].
  /// The key of the map is the starting index of the page, for faster
  /// access.
  final Map<int, Pagination<T>> _pages = {};

  @visibleForTesting
  get pages => _pages;

  /// A set of pages (represented by their starting index) that have started
  /// the fetch process but haven't ended it yet.
  ///
  /// This is to prevent fetching of a page several times in a row. When a page
  /// is already being fetched, we don't initiate another fetch request.
  final Set<int> _pagesBeingFetched = {};

  /// Total size of items. This is `null` at first, and only when the user
  /// reaches the end, it will hold the actual number.
  int itemCount;

  /// After disposed, we don't allow it to call
  /// [notifyListeners].
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<Pagination<T>> fetch(int startingIndex, int itemsPerPage) async {
    assert(fetcher != null);
    return fetcher(startingIndex, itemsPerPage);
  }

  /// This is a synchronous method that returns the item at [index].
  ///
  /// If the item is already in memory, this will just return it. Otherwise,
  /// this method will initiate a fetch of the corresponding page, and will
  /// return [Item.loading].
  ///
  /// The UI will be notified via [notifyListeners] when the fetch
  /// is completed. At that time, calling this method will return the newly
  /// fetched item.
  T getByIndex(int index) {
    // Compute the starting index of the page where this item is located.
    // For example, if [index] is `42` and [itemsPerPage] is `20`,
    // then `index ~/ itemsPerPage` (integer division)
    // evaluates to `2`, and `2 * 20` is `40`.
    var startingIndex = (index ~/ itemsPerPage) * itemsPerPage;

    // If the corresponding page is already in memory, return immediately.
    if (_pages.containsKey(startingIndex)) {
      if (index - startingIndex < _pages[startingIndex].items.length) {
        var item = _pages[startingIndex].items[index - startingIndex];
        return item;
      }
    }

    // We don't have the data yet. Start fetching it.
    if (itemCount == null) {
      _fetchPage(startingIndex).then((_) {});
    }

    // In the meantime, return a placeholder.
    return null;
  }

  /// This method initiates fetching of the [ItemPage] at [startingIndex].
  Future<void> _fetchPage(int startingIndex) async {
    if (_pagesBeingFetched.contains(startingIndex)) {
      // Page is already being fetched. Ignore the redundant call.
      return;
    }

    _pagesBeingFetched.add(startingIndex);
    final page = await fetch(startingIndex, itemsPerPage);
    _pagesBeingFetched.remove(startingIndex);

    if (!page.hasNext && itemCount == null) {
      // The returned page has no next page. This means we now know the size.
      itemCount = startingIndex + page.items.length;
    }

    // Store the new page.
    _pages[startingIndex] = page;
    _pruneCache(startingIndex);

    if (!_isDisposed) {
      // Notify the widgets that are listening to that they
      // should rebuild.
      notifyListeners();
    }
  }

  /// Removes item pages that are too far away from [currentStartingIndex].
  void _pruneCache(int currentStartingIndex) {
    // It's bad practice to modify collections while iterating over them.
    // So instead, we'll store the keys to remove in a separate Set.
    final keysToRemove = <int>{};
    for (final key in _pages.keys) {
      if ((key - currentStartingIndex).abs() > maxCacheDistance) {
        // This page's starting index is too far away from the current one.
        // We'll remove it.
        keysToRemove.add(key);
      }
    }
    for (final key in keysToRemove) {
      _pages.remove(key);
    }
  }

  bool get isEmpty => _pages.isNotEmpty && itemCount == 0;

  @override
  String toString() {
    return 'InfinitePagination(total: $itemCount page: ${_pages.length}/${_pages.keys} '
        'fetched page: $_pagesBeingFetched/${_pagesBeingFetched})';
  }

  void clear() {
    _pages.clear();
    _pagesBeingFetched.clear();
    itemCount = null;

    if (!_isDisposed) notifyListeners();
  }
}

/// This is the widget responsible for building the "still loading" item
/// in the list (represented with "..." and a crossed square).
class LoadingTile extends StatelessWidget {
  const LoadingTile({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).backgroundColor.computeLuminance() < 0.179;

    final color = isDark ? Colors.grey[850] : Colors.grey[200];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: ListTile(
        leading: AspectRatio(
          aspectRatio: 1,
          child: Container(color: color),
        ),
        title: Container(
          color: color,
          margin: EdgeInsets.only(right: 100),
          height: 24,
        ),
        subtitle: Container(
          color: color,
          height: 14,
        ),
      ),
    );
  }
}
