import 'drawing_stroke.dart';

class DailyTaskItem {
  DailyTaskItem({this.done = false, this.text = ''});

  bool done;
  String text;

  factory DailyTaskItem.fromJson(Map<String, dynamic> json) {
    return DailyTaskItem(
      done: json['done'] as bool? ?? false,
      text: json['text'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'done': done,
      'text': text,
    };
  }
}

class DailyPlan {
  DailyPlan({
    required this.dateKey,
    List<DailyTaskItem>? todos,
    this.notes = '',
    Map<int, String>? hourlyNotes,
    List<Stroke>? scheduleStrokes,
  })  : todos = todos ?? List.generate(10, (_) => DailyTaskItem()),
        hourlyNotes = hourlyNotes ?? {},
        scheduleStrokes = scheduleStrokes ?? [] {
    if (this.todos.length != 10) {
      throw ArgumentError('DailyPlan requires exactly 10 todo items.');
    }
  }

  final String dateKey;
  final List<DailyTaskItem> todos;
  String notes;
  final Map<int, String> hourlyNotes;
  final List<Stroke> scheduleStrokes;

  factory DailyPlan.empty(String dateKey) {
    return DailyPlan(dateKey: dateKey);
  }

  factory DailyPlan.fromJson(Map<String, dynamic> json) {
    final todosJson = (json['todos'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final todos = List.generate(
      10,
      (index) => index < todosJson.length
          ? DailyTaskItem.fromJson(todosJson[index])
          : DailyTaskItem(),
    );
    final hourly = <int, String>{};
    final hourlyJson = json['hourlyNotes'] as Map<String, dynamic>? ?? {};
    for (final entry in hourlyJson.entries) {
      final hour = int.tryParse(entry.key);
      if (hour == null) continue;
      hourly[hour] = entry.value as String? ?? '';
    }
    final strokesJson = (json['scheduleStrokes'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return DailyPlan(
      dateKey: json['dateKey'] as String? ?? '',
      todos: todos,
      notes: json['notes'] as String? ?? '',
      hourlyNotes: hourly,
      scheduleStrokes:
          strokesJson.map((item) => Stroke.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'todos': todos.map((item) => item.toJson()).toList(),
      'notes': notes,
      'hourlyNotes': hourlyNotes.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'scheduleStrokes': scheduleStrokes.map((stroke) => stroke.toJson()).toList(),
    };
  }
}
