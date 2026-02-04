class ResultsSection {
  ResultsSection({
    this.foundationText = '',
    this.driveText = '',
    this.joyText = '',
  });

  String foundationText;
  String driveText;
  String joyText;

  factory ResultsSection.fromJson(Map<String, dynamic> json) {
    return ResultsSection(
      foundationText: json['foundationText'] as String? ?? '',
      driveText: json['driveText'] as String? ?? '',
      joyText: json['joyText'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foundationText': foundationText,
      'driveText': driveText,
      'joyText': joyText,
    };
  }
}

class SprintWeekResults {
  SprintWeekResults({
    required this.sprintId,
    required this.weekIndex,
    ResultsSection? done,
    ResultsSection? notDone,
    ResultsSection? adjustPlan,
    DateTime? updatedAt,
  })  : done = done ?? ResultsSection(),
        notDone = notDone ?? ResultsSection(),
        adjustPlan = adjustPlan ?? ResultsSection(),
        updatedAt = updatedAt ?? DateTime.now();

  final String sprintId;
  final int weekIndex;
  ResultsSection done;
  ResultsSection notDone;
  ResultsSection adjustPlan;
  DateTime updatedAt;

  factory SprintWeekResults.fromJson(Map<String, dynamic> json) {
    return SprintWeekResults(
      sprintId: json['sprintId'] as String? ?? '',
      weekIndex: json['weekIndex'] as int? ?? 1,
      done: ResultsSection.fromJson(
        (json['done'] as Map<String, dynamic>? ?? {}),
      ),
      notDone: ResultsSection.fromJson(
        (json['notDone'] as Map<String, dynamic>? ?? {}),
      ),
      adjustPlan: ResultsSection.fromJson(
        (json['adjustPlan'] as Map<String, dynamic>? ?? {}),
      ),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sprintId': sprintId,
      'weekIndex': weekIndex,
      'done': done.toJson(),
      'notDone': notDone.toJson(),
      'adjustPlan': adjustPlan.toJson(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}
