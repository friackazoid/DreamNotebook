import 'drawing_stroke.dart';

class QuickNote {
  QuickNote({
    required this.id,
    required this.createdAtIso,
    required this.updatedAtIso,
    List<Stroke>? strokes,
    Set<String>? dayKeys,
    Set<String>? weekKeys,
    Set<String>? monthKeys,
  })  : strokes = strokes ?? [],
        dayKeys = dayKeys ?? {},
        weekKeys = weekKeys ?? {},
        monthKeys = monthKeys ?? {};

  final String id;
  final String createdAtIso;
  String updatedAtIso;
  List<Stroke> strokes;
  final Set<String> dayKeys;
  final Set<String> weekKeys;
  final Set<String> monthKeys;

  bool get isEmpty {
    if (strokes.isEmpty) return true;
    return strokes.every((stroke) => stroke.points.isEmpty);
  }

  factory QuickNote.fromJson(Map<String, dynamic> json) {
    return QuickNote(
      id: json['id'] as String? ?? '',
      createdAtIso: json['createdAtIso'] as String? ?? '',
      updatedAtIso: json['updatedAtIso'] as String? ?? '',
      strokes: (json['strokes'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .map(Stroke.fromJson)
          .toList(),
      dayKeys: (json['dayKeys'] as List<dynamic>? ?? [])
          .map((key) => key.toString())
          .toSet(),
      weekKeys: (json['weekKeys'] as List<dynamic>? ?? [])
          .map((key) => key.toString())
          .toSet(),
      monthKeys: (json['monthKeys'] as List<dynamic>? ?? [])
          .map((key) => key.toString())
          .toSet(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'createdAtIso': createdAtIso,
      'updatedAtIso': updatedAtIso,
      'strokes': strokes.map((stroke) => stroke.toJson()).toList(),
      'dayKeys': dayKeys.toList(),
      'weekKeys': weekKeys.toList(),
      'monthKeys': monthKeys.toList(),
    };
  }
}
