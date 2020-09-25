import "package:flutter/material.dart";

extension UIHelpers on Widget {
  /// Returns the current widget wrapped with the given padding
  Widget withPadding(double padding) {
    return Padding(padding: EdgeInsets.all(padding), child: this);
  }

  /// Returns the current widget wrapped with the given horizontal padding
  Widget withHPadding(double padding) {
    return Padding(
        padding: EdgeInsets.symmetric(horizontal: padding), child: this);
  }

  /// Returns the current widget wrapped with the given vertical padding
  Widget withVPadding(double padding) {
    return Padding(
        padding: EdgeInsets.symmetric(vertical: padding), child: this);
  }

  /// Returns the current widget wrapped with the given top padding
  Widget withTopPadding(double padding) {
    return Padding(padding: EdgeInsets.only(top: padding), child: this);
  }

  /// Returns the current widget wrapped with the given left padding
  Widget withLeftPadding(double padding) {
    return Padding(padding: EdgeInsets.only(left: padding), child: this);
  }

  /// Returns the current widget wrapped with the given right padding
  Widget withRightPadding(double padding) {
    return Padding(padding: EdgeInsets.only(right: padding), child: this);
  }

  /// Returns the current widget wrapped with the given bottom padding
  Widget withBottomPadding(double padding) {
    return Padding(padding: EdgeInsets.only(bottom: padding), child: this);
  }

  /// Returns the widget only when the given condition evaluates to true
  Widget when(bool condition) {
    return condition ? this : Container();
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
