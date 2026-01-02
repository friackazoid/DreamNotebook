class TaskLine {
  TaskLine({this.text = '', this.done = false});

  bool done;
  String text;

  factory TaskLine.fromJson(Map<String, dynamic> json) {
    return TaskLine(
      text: json['text'] as String? ?? '',
      done: json['done'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'done': done,
    };
  }
}

class MonthlyPlan {
  MonthlyPlan({
    required this.monthKey,
    required this.year,
    required this.month,
    List<TaskLine>? priorities,
    this.habitName = '',
    List<bool>? habitChecks,
    this.notes = '',
  })  : priorities = priorities ?? List.generate(5, (_) => TaskLine()),
        habitChecks = habitChecks ?? List.filled(31, false) {
    if (this.priorities.length != 5) {
      throw ArgumentError('Monthly priorities need exactly 5 lines.');
    }
    if (this.habitChecks.length != 31) {
      throw ArgumentError('Habit checks need 31 days.');
    }
  }

  final String monthKey;
  final int year;
  final int month;
  final List<TaskLine> priorities;
  String habitName;
  final List<bool> habitChecks;
  String notes;

  factory MonthlyPlan.empty({
    required String monthKey,
    required int year,
    required int month,
  }) {
    return MonthlyPlan(monthKey: monthKey, year: year, month: month);
  }

  factory MonthlyPlan.fromJson(Map<String, dynamic> json) {
    final prioritiesJson = (json['priorities'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final habitJson = (json['habitChecks'] as List<dynamic>? ?? [])
        .map((value) => value == true)
        .toList();
    return MonthlyPlan(
      monthKey: json['monthKey'] as String? ?? '',
      year: json['year'] as int? ?? 0,
      month: json['month'] as int? ?? 1,
      priorities: List.generate(
        5,
        (index) => index < prioritiesJson.length
            ? TaskLine.fromJson(prioritiesJson[index])
            : TaskLine(),
      ),
      habitName: json['habitName'] as String? ?? '',
      habitChecks: List.generate(
        31,
        (index) => index < habitJson.length ? habitJson[index] : false,
      ),
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'monthKey': monthKey,
      'year': year,
      'month': month,
      'priorities': priorities.map((item) => item.toJson()).toList(),
      'habitName': habitName,
      'habitChecks': habitChecks,
      'notes': notes,
    };
  }
}
