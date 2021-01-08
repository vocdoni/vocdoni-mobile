import 'dart:developer';

import 'package:dvote_common/widgets/spinner.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:vocdoni/data-models/content-cache.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/views/home-content-tab.dart';

class ContentListView extends StatefulWidget {
  @override
  _ContentListViewState createState() => _ContentListViewState();
}

class _ContentListViewState extends State<ContentListView> {
  static const _pageSize = 5;

  final PagingController<int, Bloc> _pagingController =
      PagingController(firstPageKey: 0, invisibleItemsThreshold: 2);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {
    try {
      final newItems = List<Bloc>();
      for (var i = 0; i < _pageSize; i++) {
        if (Globals.appState.contentCache.hasNextItem)
          newItems.add(Globals.appState.contentCache.getNextBloc());
      }
      final isLastPage = !Globals.appState.contentCache.hasNextItem;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = pageKey + 1;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
      log("Paging error: $error");
    }
  }

  @override
  Widget build(BuildContext context) => PagedListView<int, Bloc>(
        pagingController: _pagingController,
        builderDelegate: PagedChildBuilderDelegate<Bloc>(
          itemBuilder: (context, item, index) => item.toWidget(index),
          newPageProgressIndicatorBuilder: (context) => Padding(
              padding: const EdgeInsets.only(
                top: 16,
                bottom: 16,
              ),
              child: Center(child: SpinnerCircular())),
        ),
      );

  @override
  void dispose() {
    _pagingController.dispose();
    super.dispose();
  }
}
