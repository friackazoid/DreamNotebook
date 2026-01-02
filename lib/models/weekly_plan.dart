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

class DayPlan {
  DayPlan({
    required this.dateKey,
    List<TaskLine>? mits,
  }) : mits = mits ?? List.generate(3, (_) => TaskLine()) {
    if (this.mits.length != 3) {
      throw ArgumentError('Each day must have exactly 3 MIT lines.');
    }
  }

  final String dateKey;
  final List<TaskLine> mits;

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    final mitsJson = (json['mits'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return DayPlan(
      dateKey: json['dateKey'] as String? ?? '',
      mits: List.generate(
        3,
        (index) => index < mitsJson.length
            ? TaskLine.fromJson(mitsJson[index])
            : TaskLine(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'mits': mits.map((mit) => mit.toJson()).toList(),
    };
  }
}

class MatrixQuadrant {
  MatrixQuadrant({
    required this.label,
    List<String>? lines,
  }) : lines = lines ?? List.filled(2, '') {
    if (this.lines.length != 2) {
      throw ArgumentError('Each quadrant must have exactly 2 lines.');
    }
  }

  final String label;
  final List<String> lines;

  factory MatrixQuadrant.fromJson(Map<String, dynamic> json) {
    final linesJson = (json['lines'] as List<dynamic>? ?? [])
        .map((line) => line.toString())
        .toList();
    return MatrixQuadrant(
      label: json['label'] as String? ?? '',
      lines: List.generate(2, (index) {
        return index < linesJson.length ? linesJson[index] : '';
      }),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'lines': lines,
    };
  }
}

class WeeklyPlan {
  WeeklyPlan({
    required this.weekKey,
    List<DayPlan>? days,
    List<TaskLine>? weeklyGoals,
    this.notes = '',
    List<MatrixQuadrant>? matrix,
  })  : days = days ?? _defaultDays(weekKey),
        weeklyGoals = weeklyGoals ?? List.generate(5, (_) => TaskLine()),
        matrix = matrix ?? _defaultMatrix() {
    if (this.days.length != 7) {
      throw ArgumentError('Weekly plan needs 7 days.');
    }
    if (this.weeklyGoals.length != 5) {
      throw ArgumentError('Weekly goals need exactly 5 lines.');
    }
    if (this.matrix.length != 4) {
      throw ArgumentError('Matrix needs 4 quadrants.');
    }
  }

  final String weekKey;
  final List<DayPlan> days;
  final List<TaskLine> weeklyGoals;
  String notes;
  final List<MatrixQuadrant> matrix;

  factory WeeklyPlan.empty(String weekKey) {
    return WeeklyPlan(weekKey: weekKey);
  }

  factory WeeklyPlan.fromJson(Map<String, dynamic> json) {
    final daysJson = (json['days'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final goalsJson = (json['weeklyGoals'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final matrixJson = (json['matrix'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return WeeklyPlan(
      weekKey: json['weekKey'] as String? ?? '',
      days: List.generate(
        7,
        (index) => index < daysJson.length
            ? DayPlan.fromJson(daysJson[index])
            : DayPlan(dateKey: ''),
      ),
      weeklyGoals: List.generate(
        5,
        (index) => index < goalsJson.length
            ? TaskLine.fromJson(goalsJson[index])
            : TaskLine(),
      ),
      notes: json['notes'] as String? ?? '',
      matrix: List.generate(
        4,
        (index) => index < matrixJson.length
            ? MatrixQuadrant.fromJson(matrixJson[index])
            : MatrixQuadrant(label: ''),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekKey': weekKey,
      'days': days.map((day) => day.toJson()).toList(),
      'weeklyGoals': weeklyGoals.map((goal) => goal.toJson()).toList(),
      'notes': notes,
      'matrix': matrix.map((quad) => quad.toJson()).toList(),
    };
  }
}

List<DayPlan> _defaultDays(String weekKey) {
  final start = _parseDateKey(weekKey);
  return List.generate(7, (index) {
    final date = start.add(Duration(days: index));
    return DayPlan(dateKey: _dateKey(date));
  });
}

List<MatrixQuadrant> _defaultMatrix() {
  return [
    MatrixQuadrant(label: 'Urgent + Important'),
    MatrixQuadrant(label: 'Not Urgent + Important'),
    MatrixQuadrant(label: 'Urgent + Not Important'),
    MatrixQuadrant(label: 'Not Urgent + Not Important'),
  ];
}

DateTime _parseDateKey(String dateKey) {
  final parts = dateKey.split('-');
  if (parts.length != 3) return DateTime.now();
  final year = int.tryParse(parts[0]) ?? DateTime.now().year;
  final month = int.tryParse(parts[1]) ?? DateTime.now().month;
  final day = int.tryParse(parts[2]) ?? DateTime.now().day;
  return DateTime(year, month, day);
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
