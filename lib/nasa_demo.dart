// import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:infinite_pagination/infinite_pagination.dart';
import 'package:file_cache/file_cache.dart';

void main() {
  // In Nasa image Http Header:
  //    cache-control: public, max-age=300, s-max-age=600
  // This is too short, force to cache 10 days.
  FileCache.forceCacheSeconds = 86400 * 100;

  runApp(NasaDemoApp());
}

class Link {
  Link({this.url, this.rel, this.render});

  final String url;
  final String rel;
  final String render;
}

class NasaMedia {
  NasaMedia({
    this.url,
    this.creator,
    this.description,
    this.id,
    this.created,
    this.keywords,
    this.title,
    this.center,
    this.mediaType,
    this.links,
  });

  final String url;
  final String creator;
  final String description;
  final String id;
  final DateTime created;
  final List<String> keywords;
  final String title;
  final String center;
  final String mediaType;
  final List<Link> links;

  factory NasaMedia.fromJson(Map map) {
    if (map is Map) {
      final data = map['data'].first as Map;

      return NasaMedia(
        url: map['href'],
        creator: data['creator'],
        description: data['description'],
        id: data['nasa_id'],
        created: DateTime.parse(data['date_created']),
        keywords: (data['keywords'] as List).cast<String>(),
        title: data['title'],
        center: data['center'],
        mediaType: data['media_type'],
        links: (map['links'] as List).map((i) {
          return Link(
            url: i['href'],
            rel: i['preview'],
            render: i['image'],
          );
        }).toList(),
      );
    } else
      throw ArgumentError('Map must be Map, current is ${map.runtimeType}');
  }
}

class NasaLibrary extends InfinitePagination<NasaMedia> {
  NasaLibrary() : super(itemsPerPage: 100, maxCacheDistance: 200);

  final Future<FileCache> fileCache = FileCache.fromDefault();

  fetch(int startingIndex, int itemsPerPage) async {
    // Since Nasa does not support this argument, fixed as 100
    itemsPerPage = 100;

    String url = startingIndex == 0
        ? 'https://images-api.nasa.gov/search?q=earth&media_type=image'
        : 'https://images-api.nasa.gov/search?q=earth&media_type=image&page=${startingIndex ~/ itemsPerPage}';

    Map jd = await (await fileCache).getJson(url);

    final items = (jd['collection']['items'] as List)
        .map((i) => NasaMedia.fromJson(i))
        .toList();

    return Pagination(
      items: items,
      startingIndex: startingIndex,
      hasNext: items.length == itemsPerPage,
    );
  }
}

class NasaDemoApp extends StatefulWidget {
  @override
  _DemoAppState createState() => _DemoAppState();
}

class _DemoAppState extends State<NasaDemoApp>
    with SingleTickerProviderStateMixin {
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
      create: (_) => NasaLibrary(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Material(
          child: Selector<NasaLibrary, int>(
            selector: (context, catalog) => catalog.itemCount,
            builder: (context, itemCount, child) => ListView.builder(
              key: PageStorageKey('ListView'),
              itemCount: itemCount,
              itemBuilder: (context, index) {
                // Every item of the `ListView` is individually listening
                // to the catalog.
                var catalog = Provider.of<NasaLibrary>(context);

                // Catalog provides a single synchronous method for getting
                // the current data.
                var item = catalog.getByIndex(index);

                if (item == null) {
                  return LoadingTile();
                }

                return Card(
                    color: Colors.black,
                    child: Stack(
                      children: [
                        Center(
                          child: Image(
                            image: FileCacheImage(item.links[0].url),
                            fit: BoxFit.fitWidth,
                          ),
                        ),
                        Positioned(
                          left: 8,
                          right: 8,
                          top: 8,
                          child: Text(
                            item.description,
                            style: TextStyle(color: Colors.white),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Positioned(
                          left: 8,
                          right: 8,
                          bottom: 8,
                          child: Text(
                            '${item.title} | ${item.created}',
                            style: TextStyle(color: Colors.white),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ));
              },
            ),
          ),
        ),
      ),
    );
  }
}
