import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class LoadingSpinner extends StatelessWidget {
  final double size;
  final Color color;

  LoadingSpinner({this.size = 25.0, this.color = Colors.black54});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 25.0,
      height: 25.0,
      child: SpinKitRing(
        lineWidth: 2,
        size: 25.0,
        color: Colors.black54,
      ),
    );

    // Alternative:

    // return SizedBox(
    //   height: size,
    //   width: size,
    //   child: CircularProgressIndicator(
    //     strokeWidth: 2,
    //     // backgroundColor: color,
    //     valueColor: new AlwaysStoppedAnimation<Color>(color),
    //   ),
    // );
  }
}
