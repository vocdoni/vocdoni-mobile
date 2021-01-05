import "package:vocdoni/lib/extensions.dart";
import 'dart:developer';

import 'package:dvote_common/widgets/spinner.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/views/home-content-tab.dart';

class ContentListView extends StatefulWidget {
  @override
  _ContentListViewState createState() => _ContentListViewState();
}

class _ContentListViewState extends State<ContentListView> {
  static const _pageSize = 5;

  final PagingController<int, CardItem> _pagingController =
      PagingController(firstPageKey: 0, invisibleItemsThreshold: 2);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  // @override
  // void didUpdateWidget(ContentListView oldWidget) {
  //   Globals.oldProcessFeed.resetIndex();
  //   _pagingController.refresh();
  //   super.didUpdateWidget(oldWidget);
  // }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = List<CardItem>();
      for (var i = 0; i < _pageSize; i++) {
        if (Globals.oldProcessFeed.hasNextItem)
          newItems.add(
              CardItem.fromProcess(Globals.oldProcessFeed.getNextProcess()));
      }
      final isLastPage = !Globals.oldProcessFeed.hasNextItem;
      if (isLastPage) {
        print("Last page");
        _pagingController.appendLastPage(newItems);
      } else {
        print("next page");
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
      log("Paging error: $error");
    }
  }

  @override
  Widget build(BuildContext context) => PagedListView<int, CardItem>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<CardItem>(
          // itemBuilder: (context, item, index) => item.toWidget(index),
          itemBuilder: (context, item, index) =>
              Text(item.process.processId).withTopPadding(300),
          newPageProgressIndicatorBuilder: (context) => Padding(
              padding: const EdgeInsets.only(
                top: 16,
                bottom: 16,
              ),
              child: Center(child: SpinnerCircular())),
          // newPageProgressIndicatorBuilder: (_) => NewPageProgressIndicator(),
        ),
      );

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
