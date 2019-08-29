import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/widgets/baseAvatar.dart';
import 'package:vocdoni/widgets/pageTitle.dart';

class ScaffoldWithImage extends StatefulWidget {
  final String appBarTitle;
  final String avatarText;
  final String avatarHexSource;
  final String headerImageUrl;
  final String headerTag;
  final String avatarUrl;
  final List<Widget> children;
  final Builder builder;
  final Widget leftElement;
  final List<Widget> Function(BuildContext) actionsBuilder;

  const ScaffoldWithImage({
    this.appBarTitle,
    this.avatarText,
    this.avatarHexSource,
    this.headerImageUrl,
    this.headerTag,
    this.children,
    this.avatarUrl,
    this.builder,
    this.leftElement,
    this.actionsBuilder,
  });

  @override
  _ScaffoldWithImageState createState() => _ScaffoldWithImageState();
}

class _ScaffoldWithImageState extends State<ScaffoldWithImage> {
  bool collapsed = false;
  @override
  Widget build(context) {
    bool hasAvatar = widget.avatarUrl != null || widget.avatarHexSource != null;
    bool hasHeaderImage = widget.headerImageUrl != null;
    double headerImageHeight = hasHeaderImage?400:300;
    double avatarHeight = hasAvatar ? iconSizeHuge : 16;
    double totalHeaderHeight = headerImageHeight + avatarHeight * 0.5;
    double interpolationHeight = 64;
    double pos = 0;
    double interpolation = 0;
    double collapseTrigger = 1;

    return Scaffold(body: new Builder(
      builder: (BuildContext context) {
        return CustomScrollView(
          controller: ScrollController(),
          slivers: [
            SliverAppBar(
                floating: false,
                snap: false,
                pinned: true,
                elevation: 0,
                backgroundColor: colorBaseBackground.withOpacity(0.9),
                expandedHeight: totalHeaderHeight,
                leading: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      FeatherIcons.arrowLeft,
                      color: collapsed ? colorDescription : Colors.white,
                    )),
                actions: widget.actionsBuilder == null
                    ? null
                    : buildActions(context),
                flexibleSpace: LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                  pos = constraints.biggest.height;

                  double minAppBarHeight = 48;
                  double o = ((pos - minAppBarHeight) / (interpolationHeight));
                  interpolation = o < 1 ? o : 1;

                  if (o < collapseTrigger && collapsed == false) {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      setState(() {
                        collapsed = true;
                      });
                    });
                  } else if (o >= collapseTrigger && collapsed == true) {
                    Future.delayed(const Duration(milliseconds: 100), () {
                      setState(() {
                        collapsed = false;
                      });
                    });
                  }

                  double blackShadeHeight = 96 +
                      headerImageHeight *
                          (1.4 * (1 - (pos / totalHeaderHeight)));

                  double interpolationOpacity = 1 - interpolation;
                  return FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      centerTitle: true,
                      title: Text(
                        widget.appBarTitle,
                        style: TextStyle(
                            color: colorDescription
                                .withOpacity(interpolationOpacity),
                            fontWeight: fontWeightLight),
                      ),
                      background: Stack(children: [
                        Container(child: buildHeader(headerImageHeight)),
                        hasHeaderImage
                            ? Container(
                                height: blackShadeHeight,
                                //color: collapsed ? Colors.blue : Colors.red,
                                decoration: BoxDecoration(
                                  // Box decoration takes a gradient
                                  gradient: LinearGradient(
                                    // Where the linear gradient begins and ends
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    // Add one stop foopacityr each color. Stops should increase from 0 to 1
                                    stops: [1 - (pos / totalHeaderHeight), 1],
                                    colors: [
                                      // Colors are easy thanks to Flutter's Colors class.
                                      Colors.black
                                          .withOpacity(0.5 * interpolation),
                                      Colors.black
                                          .withOpacity(0 * interpolation)
                                    ],
                                  ),
                                ),
                              )
                            : Container(),
                        Column(children: [
                          Spacer(
                            flex: 1,
                          ),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                                paddingPage, 0, paddingPage, 0),
                            child: Container(
                              height: avatarHeight,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: <Widget>[
                                  buildAvatar(hasAvatar, avatarHeight),
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: <Widget>[
                                      widget.leftElement == null
                                          ? Container()
                                          : widget.leftElement,
                                    ],
                                  )
                                ],
                              ),
                            ),
                          ),
                          //Text((1-(pos/totalHeaderHeight)).toString()),
                        ]),
                      ]));
                })),
            widget.builder
            /* SliverList(
              delegate: SliverChildListDelegate(widget.children),
            ), */
          ],
        );
      },
    ));
  }

  List<Widget> buildActions(BuildContext context) {
    return collapsed ? null : widget.actionsBuilder(context);
  }

  Widget buildAvatar(bool hasAvatar, double avatarHeight) {
    return hasAvatar
        ? BaseAvatar(
            text: widget.avatarText,
            size: iconSizeHuge,
            hexSource: widget.avatarHexSource,
            avatarUrl: widget.avatarUrl,
          )
        : Container();
  }

  Widget buildHeader(headerImageHeight) {
    return widget.headerImageUrl == null
        ? Container(
            color: getHeaderColor(widget.avatarHexSource),
            height: headerImageHeight,
            width: double.infinity,
          )
        : Hero(
            tag: widget.headerTag,
            child: Image.network(widget.headerImageUrl,
                fit: BoxFit.cover,
                height: headerImageHeight,
                width: double.infinity),
          );
  }
}
