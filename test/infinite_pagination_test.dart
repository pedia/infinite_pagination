import 'package:flutter_test/flutter_test.dart';

import 'package:infinite_pagination/infinite_pagination.dart';

class Pool extends InfinitePagination<int> {
  Pool({this.values});

  final List<int> values;

  Future<Pagination<int>> fetch(int startingIndex, int itemsPerPage) async {
    final results = values.length > startingIndex
        ? values.sublist(startingIndex, startingIndex + itemsPerPage)
        : <int>[];

    return Pagination<int>(
      items: results,
      startingIndex: startingIndex,
      hasNext: values.length > startingIndex + itemsPerPage,
    );
  }
}

void main() {
  test('init state', () {
    final pool = InfinitePagination<int>();
    expect(pool.fetcher, isNull);
    expect(pool.itemsPerPage, equals(10));
    expect(pool.itemCount, isNull);

    // TODO:
    // expect(pool.getByIndex(0), isNull);
    // expect(pool.getByIndex(1), throwsException);
  });

  testWidgets('normal pool', (WidgetTester tester) async {
    final pool = Pool(values: List.generate(200, (i) => i));
    expect(pool.fetcher, isNull);
    expect(pool.itemsPerPage, equals(10));
    expect(pool.itemCount, isNull);

    expect(pool.getByIndex(0), isNull);
    await tester.pump(Duration.zero);
    expect(pool.getByIndex(0), 0);
    expect(pool.itemCount, isNull);

    expect(pool.pages.length, equals(1));
    expect(
        pool.toString(),
        equals(
            'InfinitePagination(total: null page: 1/(0) fetched page: {}/{})'));

    expect(pool.getByIndex(1), 1);
    expect(pool.getByIndex(9), 9);
    expect(pool.getByIndex(10), isNull);

    for (int page = 1; page < 200 ~/ 10; page++) {
      expect(pool.getByIndex(page * pool.itemsPerPage), isNull);
      await tester.pump(Duration.zero);
      expect(
          pool.getByIndex(page * pool.itemsPerPage), page * pool.itemsPerPage);

      for (int n = page * pool.itemsPerPage;
          n < page * pool.itemsPerPage + pool.itemsPerPage;
          n++) expect(pool.getByIndex(n), n);
    }
  });

  testWidgets('empty pool', (tester) async {
    final pool = Pool(values: <int>[]);

    final page = await pool.fetch(0, 10);
    expect(page.items.isEmpty, isTrue);

    expect(pool.fetcher, isNull);
    expect(pool.itemsPerPage, equals(10));
    expect(pool.itemCount, isNull);

    expect(pool.getByIndex(0), isNull);
    await tester.pump(Duration.zero);
    expect(pool.getByIndex(0), isNull);

    expect(pool.itemCount, 0);
    expect(pool.toString(),
        equals('InfinitePagination(total: 0 page: 1/(0) fetched page: {}/{})'));
    expect(pool.pages[0].hasNext, isFalse);
    expect(pool.itemCount, 0);

    expect(pool.getByIndex(1), isNull);
    expect(pool.getByIndex(2), isNull);
    expect(pool.itemCount, equals(0));

    expect(pool.getByIndex(10), isNull);
    await tester.pump(Duration.zero);
    expect(pool.getByIndex(10), isNull);
    expect(pool.toString(),
        equals('InfinitePagination(total: 0 page: 1/(0) fetched page: {}/{})'));
    expect(pool.getByIndex(11), isNull);
    expect(pool.getByIndex(100), isNull);
    expect(pool.getByIndex(200), isNull);
    expect(pool.itemCount, equals(0));
  });
}
