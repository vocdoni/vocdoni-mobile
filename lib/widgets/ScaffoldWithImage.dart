import 'package:feather_icons_flutter/feather_icons_flutter.dart';
import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';
import 'package:vocdoni/widgets/pageTitle.dart';

class ScaffoldWithImage extends StatefulWidget {
  final String title;
  final String subtitle;
  final String collapsedTitle;
  final String headerImageUrl;
  final List<Widget> children;

  const ScaffoldWithImage(
      {this.title,
      this.collapsedTitle,
      this.headerImageUrl,
      this.children,
      this.subtitle});

  @override
  _ScaffoldWithImageState createState() => _ScaffoldWithImageState();
}

class _ScaffoldWithImageState extends State<ScaffoldWithImage> {
  bool collapsed = false;
  @override
  Widget build(context) {
    double totalHeaderHeight = 350;
    double interpolationHeight = 40;
    double headerImageHeight = totalHeaderHeight - interpolationHeight;
    double pos = 0;
    double interpolation = 0;
    double collapseTrigger =0.9;

    return Scaffold(
      backgroundColor: baseBackgroundColor,
      body: CustomScrollView(
        controller: ScrollController(),
        slivers: [
          SliverAppBar(
              floating: false,
              snap: false,
              pinned: true,
              elevation: 0,
              backgroundColor: baseBackgroundColor,
              expandedHeight: totalHeaderHeight,
              leading: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: Icon(
                    FeatherIcons.arrowLeft,
                    color: collapsed ? descriptionColor : Colors.white,
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
                              descriptionColor.withOpacity(1 - interpolation),
                          fontWeight: lightFontWeight),
                    ),
                    background: Column(children: [
                      Expanded(
                        child: Image.network(widget.headerImageUrl,
                            fit: BoxFit.cover,
                            height: headerImageHeight,
                            width: double.infinity),
                      ),
                      Container(
                        width: double.infinity,
                        child: PageTitle(
                          title: widget.title,
                          subtitle: widget.subtitle,
                          titleColor: titleColor.withOpacity(interpolation),
                        ),
                      )
                    ]));
              })),
          SliverList(
            delegate: SliverChildListDelegate(widget.children),
          ),
        ],
      ),
    );
  }
}
