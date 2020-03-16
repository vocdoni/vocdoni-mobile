import "package:flutter/material.dart";

extension NumberParsing on Widget {
  /// Returns the current widget wrapped with the given padding
  Widget withPadding(double padding) {
    return Padding(padding: EdgeInsets.all(padding), child: this);
  }

  Widget withHPadding(double padding) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: padding), child: this);
  }

  Widget withVPadding(double padding) {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: padding), child: this);
  }

  Widget withTopPadding(double padding) {
    return Padding(padding: EdgeInsets.only(top: padding), child: this);
  }

  Widget withLeftPadding(double padding) {
    return Padding(padding: EdgeInsets.only(left: padding), child: this);
  }

  Widget withRightPadding(double padding) {
    return Padding(padding: EdgeInsets.only(right: padding), child: this);
  }

  Widget withBottomPadding(double padding) {
    return Padding(padding: EdgeInsets.only(bottom: padding), child: this);
  }

  /// Returns the current widget wrapped within a Center widget
  Widget centered() {
    return Center(child: this);
  }

  /// Returns the current widget wrapped within a Center widget
  Widget expanded() {
    return Expanded(child: this);
  }
}
