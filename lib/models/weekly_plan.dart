class WeeklyTodo {
  WeeklyTodo({
    required this.id,
    this.text = '',
    this.done = false,
  });

  final String id;
  bool done;
  String text;

  factory WeeklyTodo.fromJson(Map<String, dynamic> json) {
    return WeeklyTodo(
      id: json['id'] as String? ?? '',
      text: json['text'] as String? ?? '',
      done: json['done'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'done': done,
    };
  }
}

class DayPlan {
  DayPlan({
    required this.dateKey,
    List<WeeklyTodo>? mits,
  }) : mits = mits ?? _defaultMits(dateKey) {
    if (this.mits.length != 3) {
      throw ArgumentError('Each day must have exactly 3 MIT lines.');
    }
  }

  final String dateKey;
  final List<WeeklyTodo> mits;

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    final mitsJson = (json['mits'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return DayPlan(
      dateKey: json['dateKey'] as String? ?? '',
      mits: List.generate(
        3,
        (index) {
          if (index >= mitsJson.length) {
            return WeeklyTodo(id: _fallbackId(json['dateKey'] as String?, index));
          }
          final todo = WeeklyTodo.fromJson(mitsJson[index]);
          if (todo.id.isNotEmpty) return todo;
          return WeeklyTodo(
            id: _fallbackId(json['dateKey'] as String?, index),
            text: todo.text,
            done: todo.done,
          );
        },
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

enum MatrixQuadrantType {
  iu,
  inu,
  niu,
  ninu,
}

class MatrixPlacement {
  MatrixPlacement({
    required this.goalId,
    required this.quadrant,
    required this.orderIndex,
  });

  final String goalId;
  final MatrixQuadrantType quadrant;
  final int orderIndex;

  factory MatrixPlacement.fromJson(Map<String, dynamic> json) {
    return MatrixPlacement(
      goalId: json['goalId'] as String? ?? '',
      quadrant: _quadrantFromString(json['quadrant'] as String? ?? 'iu'),
      orderIndex: json['orderIndex'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'goalId': goalId,
      'quadrant': _quadrantToString(quadrant),
      'orderIndex': orderIndex,
    };
  }
}

class WeeklyPlan {
  WeeklyPlan({
    required this.weekKey,
    List<DayPlan>? days,
    List<WeeklyTodo>? weeklyGoals,
    List<MatrixQuadrant>? matrix,
    List<MatrixPlacement>? matrixPlacements,
  })  : days = days ?? _defaultDays(weekKey),
        weeklyGoals = weeklyGoals ?? _defaultGoals(),
        matrix = matrix ?? _defaultMatrix(),
        matrixPlacements = matrixPlacements ?? [] {
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
  final List<WeeklyTodo> weeklyGoals;
  final List<MatrixQuadrant> matrix;
  final List<MatrixPlacement> matrixPlacements;

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
    final placementsJson = (json['matrixPlacements'] as List<dynamic>? ?? [])
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
        (index) {
          if (index >= goalsJson.length) {
            return WeeklyTodo(id: _goalId(index));
          }
          final goal = WeeklyTodo.fromJson(goalsJson[index]);
          if (goal.id.isNotEmpty) return goal;
          return WeeklyTodo(
            id: _goalId(index),
            text: goal.text,
            done: goal.done,
          );
        },
      ),
      matrix: List.generate(
        4,
        (index) => index < matrixJson.length
            ? MatrixQuadrant.fromJson(matrixJson[index])
            : MatrixQuadrant(label: ''),
      ),
      matrixPlacements:
          placementsJson.map((item) => MatrixPlacement.fromJson(item)).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'weekKey': weekKey,
      'days': days.map((day) => day.toJson()).toList(),
      'weeklyGoals': weeklyGoals.map((goal) => goal.toJson()).toList(),
      'matrix': matrix.map((quad) => quad.toJson()).toList(),
      'matrixPlacements':
          matrixPlacements.map((item) => item.toJson()).toList(),
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

List<WeeklyTodo> _defaultMits(String dateKey) {
  return List.generate(3, (index) {
    return WeeklyTodo(id: _mitId(dateKey, index));
  });
}

List<WeeklyTodo> _defaultGoals() {
  return List.generate(5, (index) => WeeklyTodo(id: _goalId(index)));
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

String _mitId(String dateKey, int index) {
  return 'mit-$dateKey-$index';
}

String _goalId(int index) {
  return 'goal-$index';
}

String _fallbackId(String? dateKey, int index) {
  if (dateKey == null || dateKey.isEmpty) {
    return 'mit-unknown-$index';
  }
  return _mitId(dateKey, index);
}

MatrixQuadrantType _quadrantFromString(String value) {
  return switch (value) {
    'iu' => MatrixQuadrantType.iu,
    'inu' => MatrixQuadrantType.inu,
    'niu' => MatrixQuadrantType.niu,
    'ninu' => MatrixQuadrantType.ninu,
    _ => MatrixQuadrantType.iu,
  };
}

String _quadrantToString(MatrixQuadrantType quadrant) {
  return switch (quadrant) {
    MatrixQuadrantType.iu => 'iu',
    MatrixQuadrantType.inu => 'inu',
    MatrixQuadrantType.niu => 'niu',
    MatrixQuadrantType.ninu => 'ninu',
  };
}
