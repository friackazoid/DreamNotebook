import 'dart:ui';

class StrokePoint {
  const StrokePoint({required this.position, required this.pressure});

  final Offset position;
  // Stored for future pressure-sensitive brushes.
  final double pressure;
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
