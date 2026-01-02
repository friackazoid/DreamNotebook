import 'package:flutter/material.dart';

import '../../../core/state/notebook_state.dart';
import '../../../models/planner_type.dart';
import '../../../models/notebook_data.dart';
import '../../../widgets/handwriting_canvas.dart';
import '../../../widgets/section_card.dart';
import '../../../widgets/urgent_important_matrix.dart';
import '../widgets/planner_sections.dart';

class DailyPlannerPage extends StatefulWidget {
  const DailyPlannerPage({super.key});

  @override
  State<DailyPlannerPage> createState() => _DailyPlannerPageState();
}

class _DailyPlannerPageState extends State<DailyPlannerPage> {
  late final HandwritingController _scheduleController;

  @override
  void initState() {
    super.initState();
    _scheduleController = HandwritingController();
  }

  @override
  void dispose() {
    _scheduleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppStateScope.of(context);
    return ValueListenableBuilder<NotebookData>(
      valueListenable: state,
      builder: (context, data, _) {
        final daily = data.daily;
        return PlannerPageLayout(
          title: 'Daily Planner',
          schedule: _HourlyHandwritingSchedule(
            controller: _scheduleController,
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

class _HourlyHandwritingSchedule extends StatelessWidget {
  const _HourlyHandwritingSchedule({required this.controller});

  final HandwritingController controller;

  @override
  Widget build(BuildContext context) {
    const startHour = 6;
    const endHour = 23;
    const rowHeight = 56.0;
    const labelWidth = 64.0;
    final hours = List.generate(endHour - startHour + 1, (i) => startHour + i);
    return SectionCard(
      title: 'Daily Schedule',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              final isErasing = controller.tool == HandwritingTool.eraser;
              return Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => controller.setTool(HandwritingTool.pen),
                    icon: Icon(
                      Icons.edit,
                      color: isErasing
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.primary,
                    ),
                    label: const Text('Pen'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.tonalIcon(
                    onPressed: () => controller.setTool(HandwritingTool.eraser),
                    icon: Icon(
                      Icons.auto_fix_high,
                      color: isErasing
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                    label: const Text('Eraser'),
                  ),
                  const Spacer(),
                  OutlinedButton.icon(
                    onPressed: () {
                      controller.clear();
                      // TODO: Persist daily schedule handwriting.
                    },
                    icon: const Icon(Icons.delete_outline),
                    label: const Text('Clear'),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: hours.length * rowHeight,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: Theme.of(context).dividerColor,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    CustomPaint(
                      painter: _HourlyGridPainter(
                        hours: hours,
                        rowHeight: rowHeight,
                        labelWidth: labelWidth,
                        textStyle: Theme.of(context).textTheme.labelMedium ??
                            const TextStyle(fontSize: 12),
                        lineColor: Theme.of(context).dividerColor,
                        labelColor: Theme.of(context).hintColor,
                      ),
                      size: Size.infinite,
                    ),
                    Positioned.fill(
                      child: Padding(
                        padding: const EdgeInsets.only(left: labelWidth + 8),
                        child: HandwritingCanvas(controller: controller),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HourlyGridPainter extends CustomPainter {
  _HourlyGridPainter({
    required this.hours,
    required this.rowHeight,
    required this.labelWidth,
    required this.textStyle,
    required this.lineColor,
    required this.labelColor,
  });

  final List<int> hours;
  final double rowHeight;
  final double labelWidth;
  final TextStyle textStyle;
  final Color lineColor;
  final Color labelColor;

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    final labelPaint = Paint()
      ..color = labelColor
      ..strokeWidth = 1;

    canvas.drawLine(
      Offset(labelWidth, 0),
      Offset(labelWidth, size.height),
      labelPaint,
    );

    for (var i = 0; i < hours.length; i++) {
      final y = rowHeight * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

      final hour = hours[i];
      final label = '${hour.toString().padLeft(2, '0')}.00';
      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: textStyle.copyWith(color: labelColor),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: labelWidth - 8);
      textPainter.paint(
        canvas,
        Offset(8, y + (rowHeight - textPainter.height) / 2),
      );
    }

    canvas.drawLine(
      Offset(0, rowHeight * hours.length),
      Offset(size.width, rowHeight * hours.length),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _HourlyGridPainter oldDelegate) {
    return oldDelegate.hours.length != hours.length ||
        oldDelegate.rowHeight != rowHeight ||
        oldDelegate.labelWidth != labelWidth ||
        oldDelegate.textStyle != textStyle ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.labelColor != labelColor;
  }
}
