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
    List<DailyTaskItem>? localTodos,
    Map<int, String>? hourlyNotes,
    List<DayScheduleEvent>? events,
  })  : localTodos = localTodos ?? List.generate(10, (_) => DailyTaskItem()),
        hourlyNotes = hourlyNotes ?? {},
        events = events ?? [] {
    if (this.localTodos.length != 10) {
      throw ArgumentError('DailyPlan requires exactly 10 todo items.');
    }
  }

  final String dateKey;
  final List<DailyTaskItem> localTodos;
  final Map<int, String> hourlyNotes;
  final List<DayScheduleEvent> events;

  factory DailyPlan.empty(String dateKey) {
    return DailyPlan(dateKey: dateKey);
  }

  factory DailyPlan.fromJson(Map<String, dynamic> json) {
    final todosJson = (json['localTodos'] as List<dynamic>? ??
            json['todos'] as List<dynamic>? ??
            [])
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
    final eventsJson = (json['events'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return DailyPlan(
      dateKey: json['dateKey'] as String? ?? '',
      localTodos: todos,
      hourlyNotes: hourly,
      events: eventsJson.map((item) => DayScheduleEvent.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'localTodos': localTodos.map((item) => item.toJson()).toList(),
      'hourlyNotes': hourlyNotes.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
      'events': events.map((event) => event.toJson()).toList(),
    };
  }
}


class DayScheduleEvent {
  DayScheduleEvent({
    required this.id,
    required this.title,
    required this.startHour,
    required this.endHour,
  });

  final String id;
  String title;
  int startHour;
  int endHour;

  factory DayScheduleEvent.fromJson(Map<String, dynamic> json) {
    return DayScheduleEvent(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      startHour: json['startHour'] as int? ?? 6,
      endHour: json['endHour'] as int? ?? 7,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startHour': startHour,
      'endHour': endHour,
    };
  }
}
