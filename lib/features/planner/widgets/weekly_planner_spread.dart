import 'package:flutter/material.dart';

class TaskLine {
  TaskLine({this.text = '', this.done = false});

  bool done;
  String text;
}

class DayPlan {
  DayPlan({
    required this.dayLabel,
    this.dateLabel,
    List<TaskLine>? mits,
  }) : mits = mits ?? List.generate(3, (_) => TaskLine()) {
    assert(this.mits.length == 3, 'Each day must have exactly 3 MIT lines.');
  }

  final String dayLabel;
  final String? dateLabel;
  final List<TaskLine> mits;
}

class MatrixQuadrant {
  MatrixQuadrant({
    required this.label,
    List<String>? lines,
  }) : lines = lines ?? List.filled(2, '') {
    assert(this.lines.length == 2, 'Each quadrant must have exactly 2 lines.');
  }

  final String label;
  final List<String> lines;
}

class WeeklyPlan {
  WeeklyPlan({
    List<DayPlan>? days,
    List<String>? goals,
    this.notes = '',
    List<MatrixQuadrant>? matrix,
  })  : days = days ?? _defaultDays(),
        goals = goals ?? List.filled(5, ''),
        matrix = matrix ?? _defaultMatrix() {
    assert(this.days.length == 7, 'Weekly plan needs 7 days.');
    assert(this.goals.length == 5, 'Weekly goals need exactly 5 lines.');
    assert(this.matrix.length == 4, 'Matrix needs 4 quadrants.');
  }

  final List<DayPlan> days;
  final List<String> goals;
  String notes;
  final List<MatrixQuadrant> matrix;

  static List<DayPlan> _defaultDays() {
    const labels = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return labels.map((label) => DayPlan(dayLabel: label)).toList();
  }

  static List<MatrixQuadrant> _defaultMatrix() {
    return [
      MatrixQuadrant(label: 'Urgent + Important'),
      MatrixQuadrant(label: 'Not Urgent + Important'),
      MatrixQuadrant(label: 'Urgent + Not Important'),
      MatrixQuadrant(label: 'Not Urgent + Not Important'),
    ];
  }
}

class WeeklyPlannerSpread extends StatefulWidget {
  const WeeklyPlannerSpread({super.key, this.initialPlan});

  final WeeklyPlan? initialPlan;

  @override
  State<WeeklyPlannerSpread> createState() => _WeeklyPlannerSpreadState();
}

class _WeeklyPlannerSpreadState extends State<WeeklyPlannerSpread> {
  late final WeeklyPlan _plan;
  late final List<List<TextEditingController>> _mitControllers;
  late final List<List<bool>> _mitChecks;
  late final List<TextEditingController> _goalControllers;
  late final TextEditingController _notesController;
  late final List<List<TextEditingController>> _matrixControllers;

  @override
  void initState() {
    super.initState();
    _plan = widget.initialPlan ?? WeeklyPlan();
    _mitControllers = List.generate(
      _plan.days.length,
      (dayIndex) => List.generate(
        _plan.days[dayIndex].mits.length,
        (lineIndex) =>
            TextEditingController(text: _plan.days[dayIndex].mits[lineIndex].text),
      ),
    );
    _mitChecks = List.generate(
      _plan.days.length,
      (dayIndex) => List.generate(
        _plan.days[dayIndex].mits.length,
        (lineIndex) => _plan.days[dayIndex].mits[lineIndex].done,
      ),
    );
    _goalControllers = List.generate(
      _plan.goals.length,
      (index) => TextEditingController(text: _plan.goals[index]),
    );
    _notesController = TextEditingController(text: _plan.notes);
    _matrixControllers = List.generate(
      _plan.matrix.length,
      (quadIndex) => List.generate(
        _plan.matrix[quadIndex].lines.length,
        (lineIndex) =>
            TextEditingController(text: _plan.matrix[quadIndex].lines[lineIndex]),
      ),
    );
  }

  @override
  void dispose() {
    for (final dayControllers in _mitControllers) {
      for (final controller in dayControllers) {
        controller.dispose();
      }
    }
    for (final controller in _goalControllers) {
      controller.dispose();
    }
    _notesController.dispose();
    for (final quadControllers in _matrixControllers) {
      for (final controller in quadControllers) {
        controller.dispose();
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final orientation = MediaQuery.of(context).orientation;
        final isSideBySide =
            orientation == Orientation.landscape && constraints.maxWidth >= 700;
        final pages = [
          _buildLeftPage(theme),
          _buildRightPage(theme),
        ];
        return Padding(
          padding: const EdgeInsets.all(16),
          child: isSideBySide
              ? Row(
                  children: [
                    Expanded(child: pages[0]),
                    const SizedBox(width: 16),
                    Expanded(child: pages[1]),
                  ],
                )
              : Column(
                  children: [
                    Expanded(child: pages[0]),
                    const SizedBox(height: 16),
                    Expanded(child: pages[1]),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildLeftPage(ThemeData theme) {
    return _PlannerPageFrame(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: List.generate(
            _plan.days.length,
            (index) {
              final day = _plan.days[index];
              return Padding(
                padding: EdgeInsets.only(bottom: index == _plan.days.length - 1 ? 0 : 12),
                child: _DaySection(
                  day: day,
                  dayIndex: index,
                  mitControllers: _mitControllers[index],
                  mitChecks: _mitChecks[index],
                  onToggle: _onToggleMit,
                  onChanged: _onChangeMit,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRightPage(ThemeData theme) {
    return _PlannerPageFrame(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final matrixHeight = (constraints.maxHeight * 0.32).clamp(140.0, 220.0);
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: 'Weekly Goals'),
                const SizedBox(height: 8),
                _GoalsSection(
                  controllers: _goalControllers,
                  onChanged: _onChangeGoal,
                ),
                const SizedBox(height: 16),
                _SectionTitle(title: 'Notes'),
                const SizedBox(height: 8),
                Expanded(
                  child: _NotesField(
                    controller: _notesController,
                    onChanged: _onChangeNotes,
                  ),
                ),
                const SizedBox(height: 16),
                _SectionTitle(title: 'Urgent / Important'),
                const SizedBox(height: 8),
                SizedBox(
                  height: matrixHeight,
                  child: _MatrixGrid(
                    quadrants: _plan.matrix,
                    controllers: _matrixControllers,
                    onChanged: _onChangeMatrixLine,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _onToggleMit(int dayIndex, int lineIndex, bool value) {
    setState(() {
      _mitChecks[dayIndex][lineIndex] = value;
      _plan.days[dayIndex].mits[lineIndex].done = value;
      // TODO: Wire MIT completion to persistence/state management.
    });
  }

  void _onChangeMit(int dayIndex, int lineIndex, String value) {
    _plan.days[dayIndex].mits[lineIndex].text = value;
    // TODO: Wire MIT text changes to persistence/state management.
  }

  void _onChangeGoal(int index, String value) {
    _plan.goals[index] = value;
    // TODO: Wire goals to persistence/state management.
  }

  void _onChangeNotes(String value) {
    _plan.notes = value;
    // TODO: Wire notes to persistence/state management.
  }

  void _onChangeMatrixLine(int quadIndex, int lineIndex, String value) {
    _plan.matrix[quadIndex].lines[lineIndex] = value;
    // TODO: Wire matrix entries to persistence/state management.
  }
}

class _PlannerPageFrame extends StatelessWidget {
  const _PlannerPageFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        letterSpacing: 0.2,
      ),
    );
  }
}

class _DaySection extends StatelessWidget {
  const _DaySection({
    required this.day,
    required this.dayIndex,
    required this.mitControllers,
    required this.mitChecks,
    required this.onToggle,
    required this.onChanged,
  });

  final DayPlan day;
  final int dayIndex;
  final List<TextEditingController> mitControllers;
  final List<bool> mitChecks;
  final void Function(int dayIndex, int lineIndex, bool value) onToggle;
  final void Function(int dayIndex, int lineIndex, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              day.dayLabel,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            if (day.dateLabel != null) ...[
              const SizedBox(width: 8),
              Text(
                day.dateLabel!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 6),
        Column(
          children: List.generate(
            mitControllers.length,
            (index) => _MitLine(
              controller: mitControllers[index],
              checked: mitChecks[index],
              onChanged: (value) => onChanged(dayIndex, index, value),
              onToggle: (value) => onToggle(dayIndex, index, value),
            ),
          ),
        ),
      ],
    );
  }
}

class _MitLine extends StatelessWidget {
  const _MitLine({
    required this.controller,
    required this.checked,
    required this.onChanged,
    required this.onToggle,
  });

  final TextEditingController controller;
  final bool checked;
  final ValueChanged<String> onChanged;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Checkbox(
            value: checked,
            onChanged: (value) => onToggle(value ?? false),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: 1,
              style: theme.textTheme.bodySmall?.copyWith(
                overflow: TextOverflow.ellipsis,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalsSection extends StatelessWidget {
  const _GoalsSection({
    required this.controllers,
    required this.onChanged,
  });

  final List<TextEditingController> controllers;
  final void Function(int index, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: List.generate(
        controllers.length,
        (index) => Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: theme.dividerColor),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Text(
                '-',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: TextField(
                  controller: controllers[index],
                  maxLines: 1,
                  style: theme.textTheme.bodySmall?.copyWith(
                    overflow: TextOverflow.ellipsis,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                  ),
                  onChanged: (value) => onChanged(index, value),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotesField extends StatelessWidget {
  const _NotesField({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: TextField(
        controller: controller,
        maxLines: null,
        expands: true,
        decoration: const InputDecoration(
          border: InputBorder.none,
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _MatrixGrid extends StatelessWidget {
  const _MatrixGrid({
    required this.quadrants,
    required this.controllers,
    required this.onChanged,
  });

  final List<MatrixQuadrant> quadrants;
  final List<List<TextEditingController>> controllers;
  final void Function(int quadIndex, int lineIndex, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Table(
      border: TableBorder.all(color: theme.dividerColor),
      children: [
        TableRow(
          children: [
            _MatrixCell(
              quadrant: quadrants[0],
              controllers: controllers[0],
              onChanged: (lineIndex, value) => onChanged(0, lineIndex, value),
            ),
            _MatrixCell(
              quadrant: quadrants[1],
              controllers: controllers[1],
              onChanged: (lineIndex, value) => onChanged(1, lineIndex, value),
            ),
          ],
        ),
        TableRow(
          children: [
            _MatrixCell(
              quadrant: quadrants[2],
              controllers: controllers[2],
              onChanged: (lineIndex, value) => onChanged(2, lineIndex, value),
            ),
            _MatrixCell(
              quadrant: quadrants[3],
              controllers: controllers[3],
              onChanged: (lineIndex, value) => onChanged(3, lineIndex, value),
            ),
          ],
        ),
      ],
    );
  }
}

class _MatrixCell extends StatelessWidget {
  const _MatrixCell({
    required this.quadrant,
    required this.controllers,
    required this.onChanged,
  });

  final MatrixQuadrant quadrant;
  final List<TextEditingController> controllers;
  final void Function(int lineIndex, String value) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            quadrant.label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          ...List.generate(
            controllers.length,
            (index) => Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: theme.dividerColor),
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: TextField(
                controller: controllers[index],
                maxLines: 1,
                style: theme.textTheme.labelSmall?.copyWith(
                  overflow: TextOverflow.ellipsis,
                ),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                ),
                onChanged: (value) => onChanged(index, value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
