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
    Map<String, WeeklyTodoMirror>? weeklyTodos,
    List<DayScheduleEvent>? events,
  })  : localTodos = localTodos ?? List.generate(10, (_) => DailyTaskItem()),
        hourlyNotes = hourlyNotes ?? {},
        weeklyTodos = weeklyTodos ?? {},
        events = events ?? [] {
    if (this.localTodos.length != 10) {
      throw ArgumentError('DailyPlan requires exactly 10 todo items.');
    }
  }

  final String dateKey;
  final List<DailyTaskItem> localTodos;
  final Map<int, String> hourlyNotes;
  final Map<String, WeeklyTodoMirror> weeklyTodos;
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
    final weeklyJson = (json['weeklyTodos'] as Map<String, dynamic>? ?? {});
    final weeklyTodos = <String, WeeklyTodoMirror>{};
    for (final entry in weeklyJson.entries) {
      final value = entry.value;
      if (value is Map<String, dynamic>) {
        weeklyTodos[entry.key] = WeeklyTodoMirror.fromJson(value);
      }
    }
    final eventsJson = (json['events'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return DailyPlan(
      dateKey: json['dateKey'] as String? ?? '',
      localTodos: todos,
      hourlyNotes: hourly,
      weeklyTodos: weeklyTodos,
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
      'weeklyTodos': weeklyTodos.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'events': events.map((event) => event.toJson()).toList(),
    };
  }
}

class SubTask {
  SubTask({this.done = false, this.text = ''});

  bool done;
  String text;

  factory SubTask.fromJson(Map<String, dynamic> json) {
    return SubTask(
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

class WeeklyTodoMirror {
  WeeklyTodoMirror({
    required this.weeklyTodoId,
    List<SubTask>? subTasks,
    this.parentDoneOverride,
  }) : subTasks = subTasks ?? List.generate(2, (_) => SubTask()) {
    if (this.subTasks.length != 2) {
      throw ArgumentError('WeeklyTodoMirror requires exactly 2 subtasks.');
    }
  }

  final String weeklyTodoId;
  final List<SubTask> subTasks;
  bool? parentDoneOverride;

  factory WeeklyTodoMirror.fromJson(Map<String, dynamic> json) {
    final subtasksJson = (json['subTasks'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return WeeklyTodoMirror(
      weeklyTodoId: json['weeklyTodoId'] as String? ?? '',
      parentDoneOverride: json['parentDoneOverride'] as bool?,
      subTasks: List.generate(
        2,
        (index) => index < subtasksJson.length
            ? SubTask.fromJson(subtasksJson[index])
            : SubTask(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weeklyTodoId': weeklyTodoId,
      'parentDoneOverride': parentDoneOverride,
      'subTasks': subTasks.map((task) => task.toJson()).toList(),
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
