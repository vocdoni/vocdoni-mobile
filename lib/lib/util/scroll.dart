import 'package:flutter/material.dart';

Function({GlobalKey expansionTileKey}) onScrollToSelectedContent(
    ScrollController controller) {
  return ({GlobalKey expansionTileKey}) {
    scrollToSelectedContent(controller, expansionTileKey: expansionTileKey);
  };
}

void scrollToSelectedContent(ScrollController controller,
    {GlobalKey expansionTileKey}) {
  final keyContext = expansionTileKey.currentContext;
  // if (keyContext != null) {
  Future.delayed(Duration(milliseconds: 200)).then((value) {
    Scrollable.ensureVisible(keyContext,
        duration: Duration(milliseconds: 500), curve: Curves.easeOut);
  });
}
