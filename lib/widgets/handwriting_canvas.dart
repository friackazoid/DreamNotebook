import 'dart:math';

import 'package:flutter/material.dart';

import '../models/drawing_stroke.dart';

class DrawingController extends ChangeNotifier {
  final List<Stroke> _strokes = [];
  Stroke? _activeStroke;

  bool isErasing = false;
  double strokeWidth = 3;
  Color strokeColor = Colors.black;
  double eraserRadius = 18;

  List<Stroke> get strokes => List.unmodifiable(_strokes);

  void startStroke(Offset position, double pressure) {
    if (isErasing) {
      _eraseAt(position);
      return;
    }
    _activeStroke = Stroke(
      points: [StrokePoint(position: position, pressure: pressure)],
      color: strokeColor,
      width: strokeWidth,
    );
    _strokes.add(_activeStroke!);
    notifyListeners();
  }

  void appendPoint(Offset position, double pressure) {
    if (isErasing) {
      _eraseAt(position);
      return;
    }
    if (_activeStroke == null) return;
    _activeStroke!.points
        .add(StrokePoint(position: position, pressure: pressure));
    notifyListeners();
  }

  void endStroke() {
    _activeStroke = null;
    notifyListeners();
  }

  void clear() {
    _strokes.clear();
    _activeStroke = null;
    notifyListeners();
  }

  void setEraser(bool value) {
    if (isErasing == value) return;
    isErasing = value;
    notifyListeners();
  }

  void setStrokeWidth(double value) {
    strokeWidth = value;
    notifyListeners();
  }

  void _eraseAt(Offset position) {
    final radiusSquared = pow(eraserRadius, 2);
    _strokes.removeWhere(
      (stroke) => stroke.points.any(
        (point) => (point.position - position).distanceSquared < radiusSquared,
      ),
    );
    notifyListeners();
  }
}

class HandwritingCanvas extends StatelessWidget {
  const HandwritingCanvas({super.key, required this.controller});

  final DrawingController controller;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) =>
          controller.startStroke(event.localPosition, event.pressure),
      onPointerMove: (event) =>
          controller.appendPoint(event.localPosition, event.pressure),
      onPointerUp: (_) => controller.endStroke(),
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _StrokePainter(controller.strokes),
            size: Size.infinite,
          );
        },
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter(this.strokes);

  final List<Stroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = stroke.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (stroke.points.length == 1) {
        canvas.drawCircle(stroke.points.first.position, stroke.width / 2, paint);
        continue;
      }

      final path = Path()..moveTo(
          stroke.points.first.position.dx, stroke.points.first.position.dy);
      for (var i = 1; i < stroke.points.length; i++) {
        final p0 = stroke.points[i - 1].position;
        final p1 = stroke.points[i].position;
        final mid = Offset((p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
        path.quadraticBezierTo(p0.dx, p0.dy, mid.dx, mid.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _StrokePainter oldDelegate) {
    return oldDelegate.strokes != strokes;
  }
}
