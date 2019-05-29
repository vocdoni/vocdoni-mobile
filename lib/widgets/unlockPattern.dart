import 'package:flutter/material.dart';

class UnlockPattern extends StatefulWidget {
  final int gridSize;

  UnlockPattern({this.gridSize});

  @override
  _UnlockPatternState createState() => _UnlockPatternState();
}

class _UnlockPatternState extends State<UnlockPattern> {
  List<Offset> points = <Offset>[];

  @override
  Widget build(BuildContext context) {
    final Container sketchArea = Container(
      margin: EdgeInsets.all(1.0),
      alignment: Alignment.topLeft,
      color: Colors.blueGrey[50],
      child: CustomPaint(
        painter: Sketcher(points: points, gridSize: widget.gridSize),
      ),
    );

    return Container(
      height: 300,
      child: GestureDetector(
        onPanUpdate: (DragUpdateDetails details) {
          setState(() {
            RenderBox box = context.findRenderObject();
            Offset point = box.globalToLocal(details.globalPosition);
            //point = point.translate(0.0, -(AppBar().preferredSize.height));

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
}

class Sketcher extends CustomPainter {
  final List<Offset> points;
  final int gridSize;

  Sketcher({this.points, this.gridSize});

  @override
  bool shouldRepaint(Sketcher oldDelegate) {
    return oldDelegate.points != points;
  }

  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.0;

    double space = 30;

    for (int i = 0; i < gridSize ; i++) {
      for (int j = 0; j < gridSize ; j++) {
        canvas.drawCircle(Offset(space * i, space * j), 10, paint);
      }
    }

    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i], points[i + 1], paint);
      }
    }
  }
}
