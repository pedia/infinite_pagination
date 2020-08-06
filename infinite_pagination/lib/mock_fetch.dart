import 'dart:math';
import 'infinite_pagination.dart';

/// This function emulates a REST API call. You can imagine replacing its
/// contents with an actual network call, keeping the signature the same.
///
/// It will fetch a page of items from [startingIndex].
Future<Pagination<T>> fetchPage<T>({
  int startingIndex,
  int total = 100,
  int countPerPage = 10,
  T mock(int index),
  int delay = 300,
}) async {
  // We're emulating the delay inherent to making a network call.
  await Future<void>.delayed(Duration(milliseconds: delay));

  // If the [startingIndex] is beyond the bounds of the catalog, an
  // empty page will be returned.
  if (startingIndex > total) {
    return Pagination<T>(
      items: <T>[],
      startingIndex: startingIndex,
      hasNext: false,
    );
  }

  int left = min(total - startingIndex, countPerPage);

  // The page of items is generated here.
  return Pagination<T>(
    items: List<T>.generate(left, (index) => mock(startingIndex + index)),
    startingIndex: startingIndex,
    // Returns `false` if we've reached the [total].
    hasNext: startingIndex + countPerPage < total,
  );
}
