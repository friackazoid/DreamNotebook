enum SprintStatus {
  planned,
  current,
  archived,
}

class SprintItem {
  SprintItem({
    this.done = false,
    this.text = '',
    List<double>? weekValues,
  }) : weekValues = _normalizeWeekValues(weekValues);

  bool done;
  String text;
  List<double> weekValues;

  factory SprintItem.fromJson(Map<String, dynamic> json) {
    final values = (json['weekValues'] as List<dynamic>? ?? [])
        .map((value) => value is num ? value.toDouble() : double.tryParse('$value') ?? 0)
        .toList();
    return SprintItem(
      done: json['done'] as bool? ?? false,
      text: json['text'] as String? ?? '',
      weekValues: values,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'done': done,
      'text': text,
      'weekValues': weekValues,
    };
  }
}

class SprintSection {
  SprintSection({
    required this.name,
    List<SprintItem>? items,
  }) : items = items ?? List.generate(6, (_) => SprintItem());

  final String name;
  final List<SprintItem> items;

  factory SprintSection.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return SprintSection(
      name: _normalizeSectionName(json['name'] as String? ?? ''),
      items: List.generate(
        6,
        (index) =>
            index < itemsJson.length ? SprintItem.fromJson(itemsJson[index]) : SprintItem(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}

class Sprint {
  Sprint({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.status,
    List<SprintSection>? sections,
  }) : sections = sections ?? _defaultSections();

  final String id;
  String title;
  DateTime startDate;
  DateTime endDate;
  SprintStatus status;
  final List<SprintSection> sections;

  factory Sprint.fromJson(Map<String, dynamic> json) {
    final sectionsJson = (json['sections'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return Sprint(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ??
          DateTime.now(),
      endDate:
          DateTime.tryParse(json['endDate'] as String? ?? '') ?? DateTime.now(),
      status: _statusFromString(json['status'] as String? ?? 'planned'),
      sections: List.generate(
        _sectionNames.length,
        (index) => index < sectionsJson.length
            ? SprintSection.fromJson(sectionsJson[index])
            : SprintSection(name: _sectionNames[index]),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': _statusToString(status),
      'sections': sections.map((section) => section.toJson()).toList(),
    };
  }
}

List<SprintSection> _defaultSections() {
  return _sectionNames.map((name) => SprintSection(name: name)).toList();
}

List<double> _normalizeWeekValues(List<double>? values) {
  final normalized = List<double>.filled(4, 0);
  if (values == null) return normalized;
  for (var i = 0; i < values.length && i < 4; i++) {
    normalized[i] = values[i];
  }
  return normalized;
}

const List<String> _sectionNames = ['Foundation', 'Drive', 'Joy'];

String _normalizeSectionName(String name) {
  return switch (name) {
    'ФУНДАМЕНТ' => 'Foundation',
    'ДРАЙВ' => 'Drive',
    'КАЙФ' => 'Joy',
    _ => name,
  };
}

SprintStatus _statusFromString(String value) {
  return switch (value) {
    'current' => SprintStatus.current,
    'archived' => SprintStatus.archived,
    _ => SprintStatus.planned,
  };
}

String _statusToString(SprintStatus status) {
  return switch (status) {
    SprintStatus.planned => 'planned',
    SprintStatus.current => 'current',
    SprintStatus.archived => 'archived',
  };
}
