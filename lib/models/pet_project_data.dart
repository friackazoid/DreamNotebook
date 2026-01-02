import 'task_item.dart';

class PetProjectData {
  const PetProjectData({required this.tasks, required this.notes});

  final List<TaskItem> tasks;
  final String notes;

  factory PetProjectData.empty() => const PetProjectData(tasks: [], notes: '');

  PetProjectData copyWith({List<TaskItem>? tasks, String? notes}) {
    return PetProjectData(
      tasks: tasks ?? this.tasks,
      notes: notes ?? this.notes,
    );
  }

  factory PetProjectData.fromJson(Map<String, dynamic> json) {
    return PetProjectData(
      tasks: (json['tasks'] as List<dynamic>? ?? [])
          .map((item) => TaskItem.fromJson(item))
          .toList(),
      notes: json['notes'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tasks': tasks.map((task) => task.toJson()).toList(),
      'notes': notes,
    };
  }
}
