import 'dart:developer';

import 'package:dvote_common/widgets/spinner.dart';
import 'package:eventual/eventual-notifier.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:vocdoni/data-models/content-cache.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:vocdoni/lib/logger.dart';

class ContentListView extends StatefulWidget {
  final EventualNotifier<int> scrollSignal;
  ContentListView(this.scrollSignal);

  @override
  _ContentListViewState createState() => _ContentListViewState();
}

class _ContentListViewState extends State<ContentListView> {
  static const _pageSize = 5;

  final PagingController<int, Bloc> _pagingController =
      PagingController(firstPageKey: 0, invisibleItemsThreshold: 2);

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    widget.scrollSignal.addListener(() {
      _scrollToTop();
    });
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    // _scrollController.addListener(_scrollListener);
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
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () {
        // TODO don't just reload current blocs, add new ones
        return Globals.appState.contentCache.loadBlocsFromStorage().then((_) {
          Globals.appState.contentCache.resetIndex();
          _pagingController.refresh();
          return Future.value();
        });
      },
      child: PagedListView<int, Bloc>(
        pagingController: _pagingController,
        scrollController: _scrollController,
        builderDelegate: PagedChildBuilderDelegate<Bloc>(
          itemBuilder: (context, item, index) => item.toWidget(index),
          newPageProgressIndicatorBuilder: (context) => Padding(
              padding: const EdgeInsets.only(
                top: 16,
                bottom: 16,
              ),
              child: Center(child: SpinnerCircular())),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pagingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToTop() {
    try {
      _scrollController.animateTo(0,
          duration: Duration(milliseconds: 300), curve: Curves.ease);
    } catch (err) {
      logger.log("Scroll controller error: $err");
    }
  }
}
