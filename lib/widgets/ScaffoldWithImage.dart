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

  const ScaffoldWithImage({
    this.title,
    this.collapsedTitle,
    this.headerImageUrl,
    this.children,
    this.subtitle,
    this.avatarUrl,
    this.builder,
    this.leftElement,
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
    double interpolationHeight = 40;
    double pos = 0;
    double interpolation = 0;
    double collapseTrigger = 0.9;

    return Scaffold(
      body: CustomScrollView(
        controller: ScrollController(),
        slivers: [
          SliverAppBar(
              floating: false,
              snap: false,
              pinned: true,
              elevation: 0,
              backgroundColor: colorBaseBackground,
              expandedHeight: totalHeaderHeight,
              leading: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    FeatherIcons.arrowLeft,
                    color: collapsed ? colorDescription : Colors.white,
                  )),
              flexibleSpace: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
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
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                              paddingPage, avatarY, paddingPage, 0),
                          child: Container(
                            height: avatarHeight,
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                                   widget.leftElement==null?Container():widget.leftElement,
                                  ],
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        //color: Colors.green,
                        padding: EdgeInsets.fromLTRB(0, titleY, 0, 0),
                        width: double.infinity,
                        child: PageTitle(
                          title: widget.title,
                          subtitle: widget.subtitle,
                          titleColor: colorTitle.withOpacity(interpolation),
                        ),
                      )
                    ]));
              })),
          widget.builder
          /* SliverList(
            delegate: SliverChildListDelegate(widget.children),
          ), */
        ],
      ),
    );
  }
}
