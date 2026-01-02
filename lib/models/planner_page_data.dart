import 'planner_entry.dart';
import 'task_item.dart';

class PlannerPageData {
  const PlannerPageData({
    required this.scheduleEntries,
    required this.todos,
    required this.notes,
    required this.matrixNotes,
  });

  final List<PlannerEntry> scheduleEntries;
  final List<TaskItem> todos;
  final String notes;
  final Map<String, String> matrixNotes;

  factory PlannerPageData.empty() => const PlannerPageData(
        scheduleEntries: [],
        todos: [],
        notes: '',
        matrixNotes: {},
      );

  PlannerPageData copyWith({
    List<PlannerEntry>? scheduleEntries,
    List<TaskItem>? todos,
    String? notes,
    Map<String, String>? matrixNotes,
  }) {
    return PlannerPageData(
      scheduleEntries: scheduleEntries ?? this.scheduleEntries,
      todos: todos ?? this.todos,
      notes: notes ?? this.notes,
      matrixNotes: matrixNotes ?? this.matrixNotes,
    );
  }

  factory PlannerPageData.fromJson(Map<String, dynamic> json) {
    return PlannerPageData(
      scheduleEntries: (json['scheduleEntries'] as List<dynamic>? ?? [])
          .map((item) => PlannerEntry.fromJson(item))
          .toList(),
      todos: (json['todos'] as List<dynamic>? ?? [])
          .map((item) => TaskItem.fromJson(item))
          .toList(),
      notes: json['notes'] as String? ?? '',
      matrixNotes:
          Map<String, String>.from(json['matrixNotes'] as Map? ?? const {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'scheduleEntries':
          scheduleEntries.map((entry) => entry.toJson()).toList(),
      'todos': todos.map((todo) => todo.toJson()).toList(),
      'notes': notes,
      'matrixNotes': matrixNotes,
    };
  }
}
