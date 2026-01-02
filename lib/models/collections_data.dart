import 'collection_item.dart';

class CollectionsData {
  const CollectionsData({
    required this.movies,
    required this.books,
    required this.games,
  });

  final List<CollectionItem> movies;
  final List<CollectionItem> books;
  final List<CollectionItem> games;

  factory CollectionsData.empty() => const CollectionsData(
        movies: [],
        books: [],
        games: [],
      );

  CollectionsData copyWith({
    List<CollectionItem>? movies,
    List<CollectionItem>? books,
    List<CollectionItem>? games,
  }) {
    return CollectionsData(
      movies: movies ?? this.movies,
      books: books ?? this.books,
      games: games ?? this.games,
    );
  }

  factory CollectionsData.fromJson(Map<String, dynamic> json) {
    return CollectionsData(
      movies: (json['movies'] as List<dynamic>? ?? [])
          .map((item) => CollectionItem.fromJson(item))
          .toList(),
      books: (json['books'] as List<dynamic>? ?? [])
          .map((item) => CollectionItem.fromJson(item))
          .toList(),
      games: (json['games'] as List<dynamic>? ?? [])
          .map((item) => CollectionItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'movies': movies.map((item) => item.toJson()).toList(),
      'books': books.map((item) => item.toJson()).toList(),
      'games': games.map((item) => item.toJson()).toList(),
    };
  }
}
