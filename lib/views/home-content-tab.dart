import 'package:dvote_common/widgets/spinner.dart';
import 'package:eventual/eventual-notifier.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/lib/i18n.dart';
import 'package:vocdoni/lib/globals.dart';
import 'package:eventual/eventual-builder.dart';
import "package:vocdoni/lib/extensions.dart";
import 'package:vocdoni/widgets/infinite-content-feed.dart';

class HomeContentTab extends StatefulWidget {
  final EventualNotifier<int> scrollSignal;

  HomeContentTab(this.scrollSignal);

  @override
  _HomeContentTabState createState() => _HomeContentTabState();
}

class _HomeContentTabState extends State<HomeContentTab>
    with AutomaticKeepAliveClientMixin<HomeContentTab> {
  @override
  void initState() {
    super.initState();
    Globals.analytics.trackPage("Home");
    updateKeepAlive();
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(ctx) {
    super.build(context);
    return EventualBuilder(
      notifiers: [
        Globals.appState.selectedAccount,
        // Globals.appState.contentCache.storedBlocs,
      ],
      builder: (context, _, __) {
        final currentAccount = Globals.appState.currentAccount;
        if (currentAccount == null) return buildNoEntries(ctx);
        if (!currentAccount.entities.hasValue ||
            currentAccount.entities.value.length == 0)
          return buildNoEntries(ctx);

        if (Globals?.appState?.contentCache == null ||
            Globals.appState.contentCache.storedBlocs.isLoading)
          return buildLoading(ctx);
        Globals.appState.contentCache.resetIndex();
        if (!Globals.appState.contentCache.hasNextItem)
          return buildNoEntries(ctx);
        return ContentListView(widget.scrollSignal);
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
