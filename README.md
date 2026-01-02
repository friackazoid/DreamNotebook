# Notebook

A tablet-first digital notebook with planners, collections, and handwriting.

## Structure

```
lib/
  core/
    app_router.dart
    state/notebook_state.dart
    storage/storage_service.dart
    theme.dart
  features/
    collections/
      pages/collections_page.dart
      widgets/pet_project_section.dart
    planner/
      pages/daily_planner_page.dart
      pages/weekly_planner_page.dart
      pages/monthly_planner_page.dart
      widgets/planner_sections.dart
  models/
    collection_item.dart
    collections_data.dart
    drawing_stroke.dart
    notebook_data.dart
    pet_project_data.dart
    planner_entry.dart
    planner_page_data.dart
    planner_type.dart
    task_item.dart
  pages/
    drawing_page.dart
    home_shell_page.dart
  widgets/
    handwriting_canvas.dart
    notebook_background.dart
    section_card.dart
    urgent_important_matrix.dart
  main.dart
```

## Architecture

- Routing uses a simple Navigator 2.0 setup in `lib/core/app_router.dart`.
- State management is handled by `ValueNotifier` in `lib/core/state/notebook_state.dart` for minimal dependencies and clear data flow.
- Local persistence uses `shared_preferences` in `lib/core/storage/storage_service.dart`.

## Planner Pages

Each planner page includes:
- A time-based schedule
- A todo list
- A notes area

The daily planner also includes the urgent/important matrix template.

## Handwriting

`lib/widgets/handwriting_canvas.dart` provides a CustomPainter-based canvas with:
- Smooth stroke rendering
- Finger and stylus input
- Eraser and clear controls
- Stored pressure values per point for future brush upgrades

## Extension Points

- Add new sections by creating feature folders under `lib/features/`.
- Persist drawings by serializing `Stroke` objects in `lib/models/drawing_stroke.dart`.
- Add new planner types by extending `PlannerType` and adding a page + route.

## Run

```
flutter pub get
flutter run
```
