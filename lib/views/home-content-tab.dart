import 'package:dvote_common/widgets/spinner.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:eventual/eventual-builder.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import "package:vocdoni/lib/extensions.dart";
import 'package:vocdoni/widgets/infinite-content-feed.dart';

class HomeContentTab extends StatefulWidget {
  HomeContentTab();

  @override
  _HomeContentTabState createState() => _HomeContentTabState();
}

class _HomeContentTabState extends State<HomeContentTab> {
  final RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  @override
  void initState() {
    super.initState();
    Globals.analytics.trackPage("Home");
  }

  void _onRefresh() {
    print("refresh");
    // TODO refresh account + data, store all cached posts
    // final currentAccount = Globals.appState.currentAccount;
    Globals.appState.contentCache.loadBlocsFromStorage();
    // currentAccount.refresh().then((_) {
    // _refreshController.refreshCompleted();
    // }).catchError((err) {
    //   _refreshController.refreshFailed();
    // });
  }

  @override
  Widget build(ctx) {
    return EventualBuilder(
      notifiers: [
        Globals.appState.selectedAccount,
        Globals.appState.contentCache.storedBlocs,
      ],
      builder: (context, _, __) {
        final currentAccount = Globals.appState.currentAccount;
        if (currentAccount == null) return buildNoEntries(ctx);
        if (!currentAccount.entities.hasValue ||
            currentAccount.entities.value.length == 0)
          return buildNoEntries(ctx);

        if (Globals?.appState?.contentCache == null) return buildLoading(ctx);
        Globals.appState.contentCache.resetIndex();
        if (!Globals.appState.contentCache.hasNextItem)
          return buildNoEntries(ctx);
        return SmartRefresher(
          enablePullDown: true,
          enablePullUp: false,
          header: WaterDropHeader(
            complete: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.done, color: Colors.grey),
                  Container(width: 10.0),
                  Text(getText(context, "main.refreshCompleted"),
                      style: TextStyle(color: Colors.grey))
                ]),
            failed: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.close, color: Colors.grey),
                  Container(width: 10.0),
                  Text(getText(context, "main.couldNotRefresh"),
                      style: TextStyle(color: Colors.grey))
                ]),
          ),
          controller: _refreshController,
          onRefresh: _onRefresh,
          child: ContentListView(),
        );
      },
    );
  }

  Widget buildNoEntries(BuildContext ctx) {
    return Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.rss_feed,
              size: 50.0,
              color: Colors.black38,
            ),
            Text(getText(context, "main.prettyLonleyInHere") + "   ¯\\_(ツ)_/¯")
                .withTopPadding(20),
          ],
        ));
  }

  Widget buildLoading(BuildContext ctx) {
    return Container(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SpinnerCircular(),
            Text(getText(context, "main.loading") + "...").withTopPadding(20),
          ],
        ));
  }
}
