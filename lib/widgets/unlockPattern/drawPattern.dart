import 'dart:math';

import 'package:flutter/material.dart';

class DrawPattern extends StatefulWidget {
  final LocalKey key;
  final int gridSize;
  final double widthSize;
  final double dotRadius;
  final double hitRadius;
  final bool canRepeatDot;
  final bool canDraw;
  final Color patternColor;
  final Color dotColor;
  final Color hitColor;
  final void Function(BuildContext context, List<int> pattern) onPatternStopped;
  final void Function(BuildContext context) onPatternStarted;

  DrawPattern(
      {this.key,
      this.gridSize,
      this.widthSize,
      this.dotRadius,
      this.hitRadius,
      this.canRepeatDot,
      this.onPatternStopped,
      this.onPatternStarted,
      this.canDraw,
      this.patternColor,
      this.hitColor,
      this.dotColor});

  @override
  _DrawPatternState createState() => _DrawPatternState();
}

class _DrawPatternState extends State<DrawPattern> {
  List<int> pattern = <int>[];
  List<Offset> dots = [];
  Offset fingerPos;
  bool isStopped = true;

  initState() {
    dots = getDosOffsets();
  }

  @override
  Widget build(BuildContext context) {
    final Container sketchArea = Container(
        alignment: Alignment.topLeft,
        child: CustomPaint(
            painter: Sketcher(
                pattern: pattern,
                dotRadius: widget.dotRadius,
                hitRadius: widget.hitRadius,
                hitColor: widget.hitColor,
                dots: dots,
                fingerPos: fingerPos,
                dotColor: widget.dotColor,
                patternColor: widget.patternColor)));

    return Container(
      height: widget.widthSize,
      width: widget.widthSize,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onPanUpdate: (DragUpdateDetails details) {
          setState(() {
            if (!widget.canDraw) return;

            RenderBox box = context.findRenderObject();
            Offset point = box.globalToLocal(details.globalPosition);

            if (isStopped) {
              pattern = [];
              isStopped = false;
              widget.onPatternStarted(context);
            }

            fingerPos = point;
            for (int i = 0; i < dots.length; i++) {
              if (isPointInCircle(point, dots[i], widget.hitRadius)) {
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
          });
        },
        onPanEnd: (DragEndDetails details) {
          setState(() {
            fingerPos = null;
            isStopped = true;
          });

          widget.onPatternStopped(context, pattern);
        },
        child: sketchArea,
      ),
    );
  }

  List<Offset> getDosOffsets() {
    double margin =widget.hitRadius;
    double spaceBetweenDots =
        (widget.widthSize - widget.hitRadius * 2) / (widget.gridSize - 1);

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
  final double hitRadius;
  final List<Offset> dots;
  final Offset fingerPos;
  final Color dotColor;
  final Color hitColor;
  final Color patternColor;

  Sketcher({
    this.pattern,
    this.dotRadius,
    this.hitRadius,
    this.dots,
    this.fingerPos,
    this.dotColor,
    this.hitColor,
    this.patternColor,
  });

  @override
  bool shouldRepaint(Sketcher oldDelegate) {
    return oldDelegate.pattern != pattern || oldDelegate.fingerPos != fingerPos;
  }

  void paint(Canvas canvas, Size size) {

    Paint hitPaint = Paint()
      ..color = hitColor;
      
    Paint dotsPaint = Paint()
      ..color = dotColor;

    Paint patternPaint = Paint()
      ..color = patternColor
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3.0;

    
    //Draw static dots
    for (int i = 0; i < dots.length; i++) {
      canvas.drawCircle(dots[i], hitRadius, hitPaint);
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
