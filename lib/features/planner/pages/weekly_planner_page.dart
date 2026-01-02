import 'package:flutter/material.dart';

import '../../../core/state/notebook_state.dart';
import '../../../models/planner_type.dart';
import '../../../models/notebook_data.dart';
import '../widgets/planner_sections.dart';

class WeeklyPlannerPage extends StatelessWidget {
  const WeeklyPlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return ValueListenableBuilder<NotebookData>(
      valueListenable: state,
      builder: (context, data, _) {
        final weekly = data.weekly;
        return PlannerPageLayout(
          title: 'Weekly Planner',
          schedule: ScheduleSection(
            entries: weekly.scheduleEntries,
            onAddEntry: (hour, title) =>
                state.addPlannerScheduleEntry(PlannerType.weekly, hour, title),
            onRemoveEntry: (id) =>
                state.removePlannerScheduleEntry(PlannerType.weekly, id),
          ),
          todo: TodoSection(
            items: weekly.todos,
            onAddItem: (title) =>
                state.addPlannerTodo(PlannerType.weekly, title),
            onToggleItem: (id) =>
                state.togglePlannerTodo(PlannerType.weekly, id),
          ),
          notes: NotesSection(
            initialText: weekly.notes,
            onChanged: (text) =>
                state.updatePlannerNotes(PlannerType.weekly, text),
          ),
        );
      },
    );
  }
}
