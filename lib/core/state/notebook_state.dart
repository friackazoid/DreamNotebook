import 'package:flutter/material.dart';

import '../../models/collection_item.dart';
import '../../models/notebook_data.dart';
import '../../models/planner_entry.dart';
import '../../models/planner_page_data.dart';
import '../../models/planner_type.dart';
import '../../models/task_item.dart';
import '../storage/storage_service.dart';

enum CollectionType { movies, books, games }

class NotebookState extends ValueNotifier<NotebookData> {
  // ValueNotifier keeps state management lightweight while still enabling
  // reactive UI updates without extra dependencies.
  NotebookState(this._storage) : super(NotebookData.empty());

  final StorageService _storage;

  Future<void> load() async {
    final data = await _storage.loadNotebookData();
    if (data != null) value = data;
  }

  PlannerPageData _plannerFor(PlannerType type) => value.plannerFor(type);

  void addPlannerScheduleEntry(PlannerType type, int hour, String title) {
    final entry = PlannerEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      hour: hour,
      title: title,
    );
    final planner = _plannerFor(type);
    _updatePlanner(
      type,
      planner.copyWith(
        scheduleEntries: [...planner.scheduleEntries, entry],
      ),
    );
  }

  void removePlannerScheduleEntry(PlannerType type, String id) {
    final planner = _plannerFor(type);
    _updatePlanner(
      type,
      planner.copyWith(
        scheduleEntries:
            planner.scheduleEntries.where((entry) => entry.id != id).toList(),
      ),
    );
  }

  void addPlannerTodo(PlannerType type, String title) {
    final todo = TaskItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      isDone: false,
    );
    final planner = _plannerFor(type);
    _updatePlanner(
      type,
      planner.copyWith(todos: [...planner.todos, todo]),
    );
  }

  void togglePlannerTodo(PlannerType type, String id) {
    final planner = _plannerFor(type);
    final updated = planner.todos
        .map((todo) =>
            todo.id == id ? todo.copyWith(isDone: !todo.isDone) : todo)
        .toList();
    _updatePlanner(type, planner.copyWith(todos: updated));
  }

  void updatePlannerNotes(PlannerType type, String notes) {
    final planner = _plannerFor(type);
    _updatePlanner(type, planner.copyWith(notes: notes));
  }

  void updateMatrixNote(String key, String text) {
    final planner = _plannerFor(PlannerType.daily);
    final next = Map<String, String>.from(planner.matrixNotes);
    next[key] = text;
    _updatePlanner(
      PlannerType.daily,
      planner.copyWith(matrixNotes: next),
    );
  }

  void addCollectionItem(CollectionType type, String title) {
    final item = CollectionItem(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      isDone: false,
    );
    final collections = value.collections;
    final updated = switch (type) {
      CollectionType.movies =>
        collections.copyWith(movies: [...collections.movies, item]),
      CollectionType.books =>
        collections.copyWith(books: [...collections.books, item]),
      CollectionType.games =>
        collections.copyWith(games: [...collections.games, item]),
    };
    value = value.copyWith(collections: updated);
    _persist();
  }

  void toggleCollectionItem(CollectionType type, String id) {
    final collections = value.collections;
    List<CollectionItem> toggle(List<CollectionItem> items) => items
        .map((item) =>
            item.id == id ? item.copyWith(isDone: !item.isDone) : item)
        .toList();
    final updated = switch (type) {
      CollectionType.movies =>
        collections.copyWith(movies: toggle(collections.movies)),
      CollectionType.books =>
        collections.copyWith(books: toggle(collections.books)),
      CollectionType.games =>
        collections.copyWith(games: toggle(collections.games)),
    };
    value = value.copyWith(collections: updated);
    _persist();
  }

  void _updatePlanner(PlannerType type, PlannerPageData data) {
    value = value.copyWithPlanner(type, data);
    _persist();
  }

  Future<void> _persist() => _storage.saveNotebookData(value);
}

class AppStateScope extends InheritedNotifier<NotebookState> {
  const AppStateScope({
    super.key,
    required NotebookState notifier,
    required Widget child,
  }) : super(notifier: notifier, child: child);

  static NotebookState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppStateScope>();
    return scope!.notifier!;
  }
}
