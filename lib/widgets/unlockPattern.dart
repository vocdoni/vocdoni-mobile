import 'dart:math';

import 'package:flutter/material.dart';

class UnlockPattern extends StatefulWidget {
  final LocalKey key;
  final int gridSize;
  final double widthSize;
  final double dotRadius;
  final bool canRepeatDot;
  final bool canDraw;
  final Color patternColor;
  final Color dotsColor;
  final void Function(List<int> pattern) onPatternStopped;

  UnlockPattern(
      {this.key,
      this.gridSize,
      this.widthSize,
      this.dotRadius,
      this.canRepeatDot,
      this.onPatternStopped,
      this.canDraw,
      this.patternColor,
      this.dotsColor});

  @override
  _UnlockPatternState createState() => _UnlockPatternState();
}

class _UnlockPatternState extends State<UnlockPattern> {
  List<int> pattern = <int>[];
  List<Offset> dots = [];
  Offset fingerPos;

  initState() {
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
                pattern: pattern,
                dotRadius: widget.dotRadius,
                dots: dots,
                fingerPos: fingerPos,
                dotsColor: widget.dotsColor,
                patternColor: widget.patternColor)));

    return Container(
      height: widget.widthSize,
      width: widget.widthSize,
      child: GestureDetector(
        onPanUpdate: (DragUpdateDetails details) {
          setState(() {
            if (!widget.canDraw) return;

            RenderBox box = context.findRenderObject();
            Offset point = box.globalToLocal(details.globalPosition);

            fingerPos = point;
            for (int i = 0; i < dots.length; i++) {
              if (isPointInCircle(point, dots[i], widget.dotRadius)) {
                if (pattern.length == 0) pattern.add(i);

                if (pattern.last != i) {
                  if (widget.canRepeatDot) {
                    pattern.add(i);
                  } else {
                    if (!pattern.contains(i)) {
                      pattern.add(i);
                    }
                  }
                }
              }
            }

            //pattern = List.from(pattern)..add(point);
          });
        },
        onPanEnd: (DragEndDetails details) {
          setState(() {
            fingerPos = null;
          });

          widget.onPatternStopped(pattern);
        },
        child: sketchArea,
      ),
    );
  }

  List<Offset> getDosOffsets() {
    double margin = widget.dotRadius;
    double spaceBetweenDots =
        (widget.widthSize - widget.dotRadius * 2) / (widget.gridSize - 1);

    List<Offset> dots = [];
    for (int j = 0; j < widget.gridSize; j++) {
      for (int i = 0; i < widget.gridSize; i++) {
        dots.add(Offset(
            margin + spaceBetweenDots * i, margin + spaceBetweenDots * j));
      }
    }
    return dots;
  }

  isPointInCircle(Offset point, Offset circleOffset, double circleRadius) {
    return pow(point.dx - circleOffset.dx, 2) +
            pow(point.dy - circleOffset.dy, 2) <
        pow(circleRadius, 2);
  }

  clearPattern() {
    setState(() {
      pattern = [];
    });
  }
}

class Sketcher extends CustomPainter {
  final List<int> pattern;
  final double dotRadius;
  final List<Offset> dots;
  final Offset fingerPos;
  final Color dotsColor;
  final Color patternColor;

  Sketcher({
    this.pattern,
    this.dotRadius,
    this.dots,
    this.fingerPos,
    this.dotsColor,
    this.patternColor,
  });

  @override
  bool shouldRepaint(Sketcher oldDelegate) {
    return oldDelegate.pattern != pattern || oldDelegate.fingerPos != fingerPos;
  }

  void paint(Canvas canvas, Size size) {
    Paint dotsPaint = Paint()
      ..color = dotsColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    Paint patternPaint = Paint()
      ..color = patternColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    //Draw static dots
    for (int i = 0; i < dots.length; i++) {
      canvas.drawCircle(dots[i], dotRadius, dotsPaint);
    }

    //Draw pattern lines
    for (int i = 0; i < pattern.length - 1; i++) {
      if (pattern[i] != null && pattern[i + 1] != null) {
        canvas.drawLine(dots[pattern[i]], dots[pattern[i + 1]], patternPaint);
      }
    }

    //Draw pattern dots
    for (int i = 0; i <= pattern.length - 1; i++) {
      if (pattern[i] != null) {
        canvas.drawCircle(dots[pattern[i]], dotRadius, patternPaint);
      }
    }

    //Draw from last point to finger
    if (fingerPos != null) {
      if (pattern.length > 0)
        canvas.drawLine(dots[pattern.last], fingerPos, patternPaint);
    }
  }
}
