import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:infinite_pagination/infinite_pagination.dart';
import 'package:infinite_pagination/mock_fetch.dart';

void main() {
  runApp(DemoApp());
}

/// Fake item for Demo
class Chapter {
  Chapter(this.i);

  final int i;
}

/// Catelog container some chapters.
///
/// For simply lately used, declare a class instead use [InfinitePagination] directly.
class Catalog extends InfinitePagination<Chapter> {
  Catalog()
      : super(
          fetcher: (int startingIndex, int itemsPerPage) async =>

              // fake fetching
              fetchPage<Chapter>(
            startingIndex: startingIndex,
            countPerPage: 10,
            total: 142,
            mock: (i) => Chapter(i),
            delay: 500,
          ),
        );
}

class DemoApp extends StatefulWidget {
  @override
  _DemoAppState createState() => _DemoAppState();
}

class _DemoAppState extends State<DemoApp> with SingleTickerProviderStateMixin {
  TabController _tabController;

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Catalog(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Material(
          child: Scaffold(
              appBar: AppBar(
                title: Text('Truly Infinite List Demo'),
                bottom: TabBar(
                  isScrollable: true,
                  controller: _tabController,
                  tabs: [
                    Text('ListView'),
                    Text('GridView'),
                    // Text('SliverList'),
                  ],
                ),
                elevation: 0,
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  Selector<Catalog, int>(
                    selector: (context, catalog) => catalog.itemCount,
                    builder: (context, itemCount, child) => ListView.builder(
                      key: PageStorageKey('ListView'),
                      itemCount: itemCount,
                      itemBuilder: (context, index) {
                        // Every item of the `ListView` is individually listening
                        // to the catalog.
                        var catalog = Provider.of<Catalog>(context);

                        // Catalog provides a single synchronous method for getting
                        // the current data.
                        var item = catalog.getByIndex(index);

                        if (item == null) {
                          return LoadingTile();
                        }

                        return ListTile(
                          leading: CircleAvatar(child: Text('${item.i}')),
                          title: Text('Chapter #${item.i}'),
                          subtitle: Text('subtitle ${item.i}'),
                        );
                      },
                    ),
                  ),
                  Selector<Catalog, int>(
                    selector: (context, catalog) => catalog.itemCount,
                    builder: (context, itemCount, child) => GridView.builder(
                      key: PageStorageKey('GridView'),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 5,
                        mainAxisSpacing: 5,
                      ),
                      itemBuilder: (context, index) {
                        var catalog = Provider.of<Catalog>(context);

                        var item = catalog.getByIndex(index);

                        if (item == null) {
                          return CircleAvatar(
                            child: Text('...'),
                            backgroundColor: Colors.grey[200],
                          );
                        }

                        return CircleAvatar(child: Text('${item.i}'));
                      },
                      itemCount: itemCount,
                    ),
                  ),
                ],
              )),
        ),
      ),
    );
  }
}
