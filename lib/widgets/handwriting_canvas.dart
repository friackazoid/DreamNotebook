import 'dart:collection';
import 'dart:math';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';

import '../models/drawing_stroke.dart';

enum HandwritingTool { pen, eraser }

class HandwritingController extends ChangeNotifier {
  final List<Stroke> _strokes = [];
  Stroke? _activeStroke;

  HandwritingTool _tool = HandwritingTool.pen;
  double strokeWidth = 3;
  Color strokeColor = Colors.black;
  double eraserRadius = 18;

  List<Stroke> get strokes => UnmodifiableListView(_strokes);
  HandwritingTool get tool => _tool;

  void setTool(HandwritingTool tool) {
    if (_tool == tool) return;
    _tool = tool;
    notifyListeners();
  }

  void setStrokeWidth(double value) {
    strokeWidth = value;
    notifyListeners();
  }

  void startStroke(Offset point, InputMeta meta) {
    if (_tool == HandwritingTool.eraser) {
      _eraseAt(point);
      return;
    }
    _activeStroke = Stroke(
      points: [StrokePoint(position: point, meta: meta)],
      color: strokeColor,
      width: strokeWidth,
    );
    _strokes.add(_activeStroke!);
    notifyListeners();
  }

  void addPoint(Offset point, InputMeta meta) {
    if (_tool == HandwritingTool.eraser) {
      _eraseAt(point);
      return;
    }
    if (_activeStroke == null) return;
    _activeStroke!.points.add(StrokePoint(position: point, meta: meta));
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

  void _eraseAt(Offset point) {
    final radiusSquared = pow(eraserRadius, 2);
    _strokes.removeWhere(
      (stroke) => stroke.points.any(
        (strokePoint) =>
            (strokePoint.position - point).distanceSquared < radiusSquared,
      ),
    );
    notifyListeners();
  }
}

class HandwritingCanvas extends StatefulWidget {
  const HandwritingCanvas({
    super.key,
    required this.controller,
    this.childOverlays = const [],
  });

  final HandwritingController controller;
  final List<Widget> childOverlays;

  @override
  State<HandwritingCanvas> createState() => _HandwritingCanvasState();
}

class _HandwritingCanvasState extends State<HandwritingCanvas> {
  int? _activePointer;
  PointerDeviceKind? _activeKind;

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      onPointerCancel: _handlePointerCancel,
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(
              painter: _StrokePainter(
                strokes: widget.controller.strokes,
                repaint: widget.controller,
              ),
              size: Size.infinite,
            ),
          ),
          ...widget.childOverlays,
        ],
      ),
    );
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_shouldIgnorePointer(event)) return;
    _activePointer = event.pointer;
    _activeKind = event.kind;
    widget.controller.startStroke(
      event.localPosition,
      _buildMeta(event),
    );
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer) return;
    widget.controller.addPoint(
      event.localPosition,
      _buildMeta(event),
    );
  }

  void _handlePointerUp(PointerUpEvent event) {
    if (event.pointer != _activePointer) return;
    widget.controller.endStroke();
    _activePointer = null;
    _activeKind = null;
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    if (event.pointer != _activePointer) return;
    widget.controller.endStroke();
    _activePointer = null;
    _activeKind = null;
  }

  bool _shouldIgnorePointer(PointerDownEvent event) {
    if (_activePointer == null) return false;

    final activeIsStylus = _activeKind == PointerDeviceKind.stylus;
    final incomingIsStylus = event.kind == PointerDeviceKind.stylus;

    // Palm rejection: once a stylus stroke is active, ignore touch inputs.
    // Platform-specific palm detection varies; this is a simple, predictable rule.
    if (activeIsStylus && !incomingIsStylus) return true;

    // Prefer stylus when it appears; end the non-stylus stroke and switch.
    if (!activeIsStylus && incomingIsStylus) {
      widget.controller.endStroke();
      _activePointer = null;
      _activeKind = null;
      return false;
    }

    // Ignore extra pointers of the same kind to avoid multi-touch collisions.
    return true;
  }

  InputMeta _buildMeta(PointerEvent event) {
    final pressure = event.pressure > 0 ? event.pressure : 1.0;
    return InputMeta(
      pointerId: event.pointer,
      kind: event.kind,
      pressure: pressure,
      tilt: event.tilt,
      orientation: event.orientation,
      buttons: event.buttons,
    );
  }
}

class _StrokePainter extends CustomPainter {
  _StrokePainter({
    required this.strokes,
    Listenable? repaint,
  }) : super(repaint: repaint);

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

      final path = Path()
        ..moveTo(
          stroke.points.first.position.dx,
          stroke.points.first.position.dy,
        );
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
