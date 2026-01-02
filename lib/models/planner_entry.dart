class PlannerEntry {
  const PlannerEntry({
    required this.id,
    required this.hour,
    required this.title,
  });

  final String id;
  final int hour;
  final String title;

  PlannerEntry copyWith({String? id, int? hour, String? title}) {
    return PlannerEntry(
      id: id ?? this.id,
      hour: hour ?? this.hour,
      title: title ?? this.title,
    );
  }

  factory PlannerEntry.fromJson(Map<String, dynamic> json) {
    return PlannerEntry(
      id: json['id'] as String,
      hour: json['hour'] as int,
      title: json['title'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hour': hour,
      'title': title,
    };
  }
}
