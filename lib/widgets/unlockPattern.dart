import 'dart:math';

import 'package:flutter/material.dart';

class UnlockPattern extends StatefulWidget {
  final int gridSize;
  final double widthSize;
  final double dotRadius;

  UnlockPattern({this.gridSize, this.widthSize, this.dotRadius});

  @override
  _UnlockPatternState createState() => _UnlockPatternState();
}

class _UnlockPatternState extends State<UnlockPattern> {
  List<Offset> points = <Offset>[];
  List<Offset> dots = [];

  initState(){
    
    dots = getDosOffsets();
  }

  @override
  Widget build(BuildContext context) {
    final Container sketchArea = Container(
      // margin: EdgeInsets.all(20.0),
      alignment: Alignment.topLeft,
      color: Colors.blueGrey[50],
      child: CustomPaint(
        painter: Sketcher(
            points: points,
            gridSize: widget.gridSize,
            widthSize: widget.widthSize,
            dotRadius: widget.dotRadius,
            dots:dots)
      ),
    );

    return Container(
      height: widget.widthSize,
      width: widget.widthSize,
      child: GestureDetector(
        onPanUpdate: (DragUpdateDetails details) {
          setState(() {
            RenderBox box = context.findRenderObject();
            Offset point = box.globalToLocal(details.globalPosition);

           // if (isPointInCircle(point, widget.dotRadius * 4, widget.dotRadius))
              //point = point.translate(0.0, -(AppBar().preferredSize.height))

              points = List.from(points)..add(point);
          });
        },
        onPanEnd: (DragEndDetails details) {
          points.add(null);
        },
        child: sketchArea,
      ),
      /* floatingActionButton: FloatingActionButton(
        tooltip: 'clear Screen',
        backgroundColor: Colors.red,
        child: Icon(Icons.refresh),
        onPressed: () {
          setState(() => points.clear());
        }, */
    );
  }

  List<Offset> getDosOffsets (){
    double margin = widget.dotRadius;
    double spaceBetweenDots = (widget.widthSize - widget.dotRadius * 2) / (widget.gridSize - 1);

    List<Offset> dots = [];
    for (int i = 0; i < widget.gridSize; i++) {
      for (int j = 0; j < widget.gridSize; j++) {
            dots.add( Offset( margin + spaceBetweenDots * i, margin + spaceBetweenDots * j));
            //debugPrint(dots[dots.length-1].dx.toString()+','+dots[dots.length-1].dy.toString());
      }
    }
    return dots;
  }

  checkIfPanningDot() {
    
  }

  isPointInCircle(Offset point, Offset circleOffset, double circleRadius) {
    return pow(point.dy - circleOffset.dx, 2) +
            pow(point.dy - circleOffset.dy, 2) <
        pow(circleRadius, 2);
  }
}

class Sketcher extends CustomPainter {
  final List<Offset> points;
  final int gridSize;
  final double widthSize;
  final double dotRadius;
  final List<Offset> dots;

  Sketcher({this.points, this.gridSize, this.widthSize, this.dotRadius, this.dots});

  @override
  bool shouldRepaint(Sketcher oldDelegate) {
    return oldDelegate.points != points;
  }

  void paint(Canvas canvas, Size size) {
    
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    for (int i = 0; i < dots.length; i++) {
      canvas.drawCircle(dots[i], dotRadius, paint);
    }

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }
}
