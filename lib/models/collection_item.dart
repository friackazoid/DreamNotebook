class CollectionItem {
  const CollectionItem({
    required this.id,
    required this.title,
    required this.isDone,
  });

  final String id;
  final String title;
  final bool isDone;

  CollectionItem copyWith({String? id, String? title, bool? isDone}) {
    return CollectionItem(
      id: id ?? this.id,
      title: title ?? this.title,
      isDone: isDone ?? this.isDone,
    );
  }

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    return CollectionItem(
      id: json['id'] as String,
      title: json['title'] as String,
      isDone: json['isDone'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'isDone': isDone,
    };
  }
}
