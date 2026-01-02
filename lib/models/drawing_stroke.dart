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

  factory InputMeta.fromJson(Map<String, dynamic> json) {
    final kindName = json['kind'] as String? ?? 'unknown';
    return InputMeta(
      pointerId: json['pointerId'] as int? ?? 0,
      kind: _pointerKindFromString(kindName),
      pressure: (json['pressure'] as num?)?.toDouble() ?? 1.0,
      tilt: (json['tilt'] as num?)?.toDouble() ?? 0.0,
      orientation: (json['orientation'] as num?)?.toDouble() ?? 0.0,
      buttons: json['buttons'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pointerId': pointerId,
      'kind': _pointerKindToString(kind),
      'pressure': pressure,
      'tilt': tilt,
      'orientation': orientation,
      'buttons': buttons,
    };
  }
}

class StrokePoint {
  const StrokePoint({required this.position, required this.meta});

  final Offset position;
  final InputMeta meta;

  factory StrokePoint.fromJson(Map<String, dynamic> json) {
    return StrokePoint(
      position: Offset(
        (json['dx'] as num?)?.toDouble() ?? 0,
        (json['dy'] as num?)?.toDouble() ?? 0,
      ),
      meta: InputMeta.fromJson(
        (json['meta'] as Map<String, dynamic>? ?? const {}),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dx': position.dx,
      'dy': position.dy,
      'meta': meta.toJson(),
    };
  }
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

  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      points: (json['points'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(StrokePoint.fromJson)
          .toList(),
      color: Color(json['color'] as int? ?? 0xFF000000),
      width: (json['width'] as num?)?.toDouble() ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'points': points.map((point) => point.toJson()).toList(),
      'color': color.value,
      'width': width,
    };
  }
}

PointerDeviceKind _pointerKindFromString(String value) {
  return switch (value) {
    'stylus' => PointerDeviceKind.stylus,
    'touch' => PointerDeviceKind.touch,
    'mouse' => PointerDeviceKind.mouse,
    'invertedStylus' => PointerDeviceKind.invertedStylus,
    'trackpad' => PointerDeviceKind.trackpad,
    _ => PointerDeviceKind.unknown,
  };
}

String _pointerKindToString(PointerDeviceKind kind) {
  return switch (kind) {
    PointerDeviceKind.stylus => 'stylus',
    PointerDeviceKind.touch => 'touch',
    PointerDeviceKind.mouse => 'mouse',
    PointerDeviceKind.invertedStylus => 'invertedStylus',
    PointerDeviceKind.trackpad => 'trackpad',
    PointerDeviceKind.unknown => 'unknown',
  };
}
