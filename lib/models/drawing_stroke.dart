import 'dart:ui';

class InputMeta {
  const InputMeta({
    required this.pointerId,
    required this.kind,
    required this.pressure,
    required this.tilt,
    required this.orientation,
    required this.buttons,
  });

  final int pointerId;
  final PointerDeviceKind kind;
  final double pressure;
  final double tilt;
  final double orientation;
  final int buttons;
}

class StrokePoint {
  const StrokePoint({required this.position, required this.meta});

  final Offset position;
  final InputMeta meta;
}

class Stroke {
  Stroke({
    required this.points,
    required this.color,
    required this.width,
  });

  final List<StrokePoint> points;
  final Color color;
  final double width;
}
