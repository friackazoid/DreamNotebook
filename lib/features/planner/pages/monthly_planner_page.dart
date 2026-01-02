import 'package:flutter/material.dart';

import '../../../core/state/notebook_state.dart';
import '../../../models/planner_type.dart';
import '../../../models/notebook_data.dart';
import '../widgets/planner_sections.dart';

class MonthlyPlannerPage extends StatelessWidget {
  const MonthlyPlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return ValueListenableBuilder<NotebookData>(
      valueListenable: state,
      builder: (context, data, _) {
        final monthly = data.monthly;
        return PlannerPageLayout(
          title: 'Monthly Planner',
          schedule: ScheduleSection(
            entries: monthly.scheduleEntries,
            onAddEntry: (hour, title) =>
                state.addPlannerScheduleEntry(PlannerType.monthly, hour, title),
            onRemoveEntry: (id) =>
                state.removePlannerScheduleEntry(PlannerType.monthly, id),
          ),
          todo: TodoSection(
            items: monthly.todos,
            onAddItem: (title) =>
                state.addPlannerTodo(PlannerType.monthly, title),
            onToggleItem: (id) =>
                state.togglePlannerTodo(PlannerType.monthly, id),
          ),
          notes: NotesSection(
            initialText: monthly.notes,
            onChanged: (text) =>
                state.updatePlannerNotes(PlannerType.monthly, text),
          ),
        );
      },
    );
  }
}
