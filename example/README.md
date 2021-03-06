# Truly infinite list

This package maybe is the Most *Simplest* Wrap for truly infinite list.

## Features:

- Fixed memory consumption, only cache fixed number of items in mempory.
- Progressive placeholder for async loading.
- An async fetching function for a page of items.
- Support ListView, GridView and SliverList.
 
## Screenshot

When Pull up, the progressive placeholder indicate loading.

![loading placeholder](https://github.com/pedia/infinite_pagination/raw/master/images/pull-up.png)

When Drag down, out of screen items was evicted is loading again.

![loading placeholder](https://github.com/pedia/infinite_pagination/raw/master/images/drag-down.png)

Animation demo.

![gif](https://github.com/pedia/infinite_pagination/raw/master/images/full-demo.gif)


## How to use

To use this plugin, add infinite_pagination as a dependency in your pubspec.yaml file. For example:

```
dependencies:
  infinite_pagination:
  provider:
```

Usually we use [provider](https://pub.dev/packages/provider) as State Management.


```dart
import 'package:infinite_pagination/infinite_pagination.dart';


class Catalog extends InfinitePagination<Chapter> {
  Catalog()
      : super(
          fetcher: (int startingIndex, int itemsPerPage) async => 
              fetchPage<Chapter>(
            startingIndex: startingIndex,
            countPerPage: 10,
            total: 142,
            mock: (i) => Chapter(i),
            delay: 500,
          ),
        );
}

Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => Catalog(),
      child: Selector<Catalog, int>(
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
    );
}
```

## Best experience of saving memory

- Use [file_cache](https://pub.dev/packages/file_cache) cache Http Request in file system.
- Use this package indicate loading and infinite paging.


This package is inspired by(copy from) [official sample](https://github.com/flutter/samples/tree/master/infinite_list) 


## Build Demo

```shell
git clone --depth 1 https://github.com/pedia/infinite_pagination
cd infinite_pagination

# Recreate demo app for add ios/android/macos/web file back.
flutter create -t app .

# Start this demo, or `-d xx` for other device
flutter run -d macos
```