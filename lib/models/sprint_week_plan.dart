enum SprintZone {
  red,
  orange,
  yellow,
  green,
  turquoise,
  blue,
  purple,
}

class WeeklyTaskRow {
  WeeklyTaskRow({
    this.done = false,
    this.text = '',
    List<double>? dayMarks,
  }) : dayMarks = _normalizeDayMarks(dayMarks);

  bool done;
  String text;
  List<double> dayMarks;

  factory WeeklyTaskRow.fromJson(Map<String, dynamic> json) {
    final marks = (json['dayMarks'] as List<dynamic>? ?? [])
        .map((value) {
          if (value is num) return value.toDouble();
          if (value is bool) return 0.0;
          return double.tryParse('$value') ?? 0.0;
        })
        .toList();
    return WeeklyTaskRow(
      done: json['done'] as bool? ?? false,
      text: json['text'] as String? ?? '',
      dayMarks: marks,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'done': done,
      'text': text,
      'dayMarks': dayMarks,
    };
  }
}

class StateTracker {
  StateTracker({List<SprintZone?>? selectedZoneByDay})
      : selectedZoneByDay = _normalizeZones(selectedZoneByDay);

  List<SprintZone?> selectedZoneByDay;

  factory StateTracker.fromJson(Map<String, dynamic> json) {
    final raw = (json['selectedZoneByDay'] as List<dynamic>? ?? [])
        .map((value) => value == null ? null : _zoneFromString('$value'))
        .toList();
    return StateTracker(selectedZoneByDay: raw);
  }

  Map<String, dynamic> toJson() {
    return {
      'selectedZoneByDay':
          selectedZoneByDay.map((zone) => zone == null ? null : _zoneToString(zone)).toList(),
    };
  }
}

class SprintWeekPlan {
  SprintWeekPlan({
    required this.sprintId,
    required this.weekIndex,
    List<WeeklyTaskRow>? sprintTasks,
    List<WeeklyTaskRow>? otherTasks,
    StateTracker? stateTracker,
  })  : sprintTasks =
            sprintTasks ?? _defaultTaskRows(_rowsForWeek(weekIndex, true)),
        otherTasks =
            otherTasks ?? _defaultTaskRows(_rowsForWeek(weekIndex, false)),
        stateTracker = stateTracker ?? StateTracker();

  final String sprintId;
  final int weekIndex;
  final List<WeeklyTaskRow> sprintTasks;
  final List<WeeklyTaskRow> otherTasks;
  final StateTracker stateTracker;

  factory SprintWeekPlan.fromJson(Map<String, dynamic> json) {
    final sprintId = json['sprintId'] as String? ?? '';
    final weekIndex = json['weekIndex'] as int? ?? 1;
    final sprintJson = (json['sprintTasks'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final otherJson = (json['otherTasks'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final sprintTasks = List.generate(
      _rowsForWeek(weekIndex, true),
      (index) => index < sprintJson.length
          ? WeeklyTaskRow.fromJson(sprintJson[index])
          : WeeklyTaskRow(),
    );
    final otherTasks = List.generate(
      _rowsForWeek(weekIndex, false),
      (index) => index < otherJson.length
          ? WeeklyTaskRow.fromJson(otherJson[index])
          : WeeklyTaskRow(),
    );
    return SprintWeekPlan(
      sprintId: sprintId,
      weekIndex: weekIndex,
      sprintTasks: sprintTasks,
      otherTasks: otherTasks,
      stateTracker: StateTracker.fromJson(
        (json['stateTracker'] as Map<String, dynamic>? ?? {}),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sprintId': sprintId,
      'weekIndex': weekIndex,
      'sprintTasks': sprintTasks.map((row) => row.toJson()).toList(),
      'otherTasks': otherTasks.map((row) => row.toJson()).toList(),
      'stateTracker': stateTracker.toJson(),
    };
  }
}

int _rowsForWeek(int weekIndex, bool isSprintTasks) {
  if (weekIndex == 4) {
    return isSprintTasks ? 17 : 0;
  }
  return isSprintTasks ? 6 : 11;
}

List<WeeklyTaskRow> _defaultTaskRows(int count) {
  return List.generate(count, (_) => WeeklyTaskRow());
}

List<double> _normalizeDayMarks(List<double>? values) {
  final normalized = List<double>.filled(7, 0);
  if (values == null) return normalized;
  for (var i = 0; i < values.length && i < 7; i++) {
    normalized[i] = values[i];
  }
  return normalized;
}

List<SprintZone?> _normalizeZones(List<SprintZone?>? values) {
  final normalized = List<SprintZone?>.filled(7, null);
  if (values == null) return normalized;
  for (var i = 0; i < values.length && i < 7; i++) {
    normalized[i] = values[i];
  }
  return normalized;
}

SprintZone _zoneFromString(String value) {
  return switch (value) {
    'red' => SprintZone.red,
    'orange' => SprintZone.orange,
    'yellow' => SprintZone.yellow,
    'green' => SprintZone.green,
    'turquoise' => SprintZone.turquoise,
    'blue' => SprintZone.blue,
    'purple' => SprintZone.purple,
    _ => SprintZone.red,
  };
}

String _zoneToString(SprintZone zone) {
  return switch (zone) {
    SprintZone.red => 'red',
    SprintZone.orange => 'orange',
    SprintZone.yellow => 'yellow',
    SprintZone.green => 'green',
    SprintZone.turquoise => 'turquoise',
    SprintZone.blue => 'blue',
    SprintZone.purple => 'purple',
  };
}
