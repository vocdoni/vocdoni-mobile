import "package:flutter/material.dart";
import 'package:vocdoni/constants/colors.dart';

class Pager extends StatefulWidget {
  final List<Widget> pages;
  final bool swipeEnabled;
  final bool dotTapEnabled;
  final PageController controller = PageController();

  Pager({this.pages, this.swipeEnabled = true, this.dotTapEnabled = true});

  @override
  _PagerState createState() => _PagerState();
}

class _PagerState extends State<Pager> {
  int _currentIndex;

  onPageChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      PageView(
        onPageChanged: onPageChange,
        physics: widget.swipeEnabled ? null : NeverScrollableScrollPhysics(),
        children: widget.pages,
        controller: widget.controller,
      ),
      Positioned.fill(
        bottom: 0.5,
        right: .5,
        child: Column(
          children: <Widget>[
            Spacer(),
            Indicator(
                length: widget.pages.length,
                currentIndex: _currentIndex,
                onDotTap: (int index) {
                  if (widget.dotTapEnabled)
                    widget.controller.animateToPage(index,
                        curve: Curves.easeInOutCubic,
                        duration: Duration(milliseconds: 500));
                },
                dotSize: 20),
          ],
        ),
      ),
    ]);
  }
}

class Indicator extends StatelessWidget {
  final int currentIndex;
  final int length;
  final double dotSize;
  final double spacing = 20;
  final void Function(int) onDotTap;

  Indicator({this.currentIndex, this.length, this.dotSize, this.onDotTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.transparent,
      height: 100,
      width: (spacing + dotSize) * length,
      child: makeDots(),
    );
  }

  Widget makeDots() {
    List<Widget> dots = [];
    for (int i = 0; i < length; i++) {
      dots.add(makeDot(i));
    }
    return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: dots);
  }

  Widget makeDot(int index) {
    return InkWell(
      onTap: () {
        if (onDotTap != null) onDotTap(index);
      },
      child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          width: index == currentIndex ? dotSize * 1.5 : dotSize,
          height: index == currentIndex ? dotSize * 1.5 : dotSize,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                  index == currentIndex ? dotSize : dotSize * 0.5),
              color: index == currentIndex
                  ? colorDescription.withOpacity(0.8)
                  : colorDescription.withOpacity(0.5))),
    );
  }
}
