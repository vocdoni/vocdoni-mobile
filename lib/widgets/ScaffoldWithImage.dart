import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/widgets/pageTitle.dart';

class ScaffoldWithImage extends StatefulWidget {
  final String title;
  final String subtitle;
  final String collapsedTitle;
  final String headerImageUrl;
  final String avatarUrl;
  final List<Widget> children;
  final Builder builder;
  final Widget leftElement;
  final List<Widget> Function(BuildContext) actionsBuilder;

  const ScaffoldWithImage({
    this.title,
    this.collapsedTitle,
    this.headerImageUrl,
    this.children,
    this.subtitle,
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
    double headerImageHeight = 400;
    double titleHeight = 86;
    double avatarHeight = widget.avatarUrl == null ? 0 : 128;
    double avatarY = headerImageHeight - avatarHeight * 0.5;
    double titleY = widget.avatarUrl == null
        ? headerImageHeight + spaceElement
        : headerImageHeight + spaceElement + avatarHeight * 0.5;
    double totalHeaderHeight = titleY + titleHeight;
    double interpolationHeight = 96;
    double pos = 0;
    double interpolation = 0;
    double collapseTrigger = 0.9;

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
                backgroundColor: Colors.transparent,
                expandedHeight: totalHeaderHeight,
                leading: InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      FeatherIcons.arrowLeft,
                      color: collapsed ? colorDescription : Colors.white,
                    )),
                actions: buildActions(context),
                flexibleSpace: LayoutBuilder(builder:
                    (BuildContext context, BoxConstraints constraints) {
                  pos = constraints.biggest.height;

                  double minAppBarHeight = 48;
                  double o = ((pos - minAppBarHeight) / (interpolationHeight));
                  interpolation = o < 1 ? o : 1;
                  debugPrint(interpolation.toString());

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
                  return FlexibleSpaceBar(
                      collapseMode: CollapseMode.pin,
                      centerTitle: true,
                      title: Text(
                        widget.collapsedTitle,
                        style: TextStyle(
                            color:
                                colorDescription.withOpacity(1 - interpolation),
                            fontWeight: fontWeightLight),
                      ),
                      background: Stack(children: [
                        Container(
                          child: Image.network(widget.headerImageUrl,
                              fit: BoxFit.cover,
                              height: headerImageHeight,
                              width: double.infinity),
                        ),
                        Container(
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
                                Colors.black.withOpacity(0.5),
                                Colors.black.withOpacity(0)
                              ],
                            ),
                          ),
                        ),
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
                                  Container(
                                    constraints: BoxConstraints(
                                        minWidth: avatarHeight,
                                        minHeight: avatarHeight),
                                    child: CircleAvatar(
                                        backgroundColor: Colors.indigo,
                                        backgroundImage:
                                            NetworkImage(widget.avatarUrl)),
                                  ),
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
                          Container(
                            //color: Colors.green,
                            padding: EdgeInsets.fromLTRB(0, 0, 0, 0),
                            width: double.infinity,
                            child: PageTitle(
                              title: widget.title,
                              subtitle: widget.subtitle,
                              titleColor: colorTitle.withOpacity(interpolation),
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
    return widget.actionsBuilder(context);
  }
}
