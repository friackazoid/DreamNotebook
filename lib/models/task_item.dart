class TaskItem {
  const TaskItem({
    required this.id,
    required this.title,
    required this.isDone,
    this.dueDate,
  });

  final String id;
  final String title;
  final bool isDone;
  final DateTime? dueDate;

  TaskItem copyWith({String? id, String? title, bool? isDone, DateTime? dueDate}) {
    return TaskItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
      dueDate: dueDate ?? this.dueDate,
    );
  }

  factory TaskItem.fromJson(Map<String, dynamic> json) {
    return TaskItem(
      id: json['id'] as String,
      title: json['title'] as String,
      isDone: json['isDone'] as bool? ?? false,
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.parse(json['dueDate'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone,
      'dueDate': dueDate?.toIso8601String(),
    };
  }
}
