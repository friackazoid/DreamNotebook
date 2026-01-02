import 'package:flutter/material.dart';

import '../../../core/state/notebook_state.dart';
import '../../../models/planner_type.dart';
import '../../../models/notebook_data.dart';
import '../../../widgets/urgent_important_matrix.dart';
import '../widgets/planner_sections.dart';

class DailyPlannerPage extends StatelessWidget {
  const DailyPlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return ValueListenableBuilder<NotebookData>(
      valueListenable: state,
      builder: (context, data, _) {
        final daily = data.daily;
        return PlannerPageLayout(
          title: 'Daily Planner',
          schedule: ScheduleSection(
            entries: daily.scheduleEntries,
            onAddEntry: (hour, title) =>
                state.addPlannerScheduleEntry(PlannerType.daily, hour, title),
            onRemoveEntry: (id) =>
                state.removePlannerScheduleEntry(PlannerType.daily, id),
          ),
          todo: TodoSection(
            items: daily.todos,
            onAddItem: (title) =>
                state.addPlannerTodo(PlannerType.daily, title),
            onToggleItem: (id) =>
                state.togglePlannerTodo(PlannerType.daily, id),
          ),
          notes: NotesSection(
            initialText: daily.notes,
            onChanged: (text) =>
                state.updatePlannerNotes(PlannerType.daily, text),
          ),
          extras: [
            UrgentImportantMatrix(
              values: daily.matrixNotes,
              onChanged: state.updateMatrixNote,
            ),
          ],
        );
      },
    );
  }
}
