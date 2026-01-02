import 'package:flutter/material.dart';

import '../../../models/weekly_plan.dart';

class WeeklyPlannerSpread extends StatefulWidget {
  const WeeklyPlannerSpread({
    super.key,
    required this.initialPlan,
    this.onChanged,
    this.onDaySelected,
    this.onDayNoteSelected,
    this.dayKeysWithNotes = const {},
  });

  final WeeklyPlan initialPlan;
  final ValueChanged<WeeklyPlan>? onChanged;
  final ValueChanged<DateTime>? onDaySelected;
  final ValueChanged<DateTime>? onDayNoteSelected;
  final Set<String> dayKeysWithNotes;

  @override
  State<WeeklyPlannerSpread> createState() => _WeeklyPlannerSpreadState();
}

class _WeeklyPlannerSpreadState extends State<WeeklyPlannerSpread> {
  late final WeeklyPlan _plan;
  late final List<List<TextEditingController>> _mitControllers;
  late final List<List<bool>> _mitChecks;
  late final List<TextEditingController> _goalControllers;
  late final List<bool> _goalChecks;
  late final List<List<TextEditingController>> _matrixControllers;

  @override
  void initState() {
    super.initState();
    _plan = widget.initialPlan;
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
      _plan.weeklyGoals.length,
      (index) => TextEditingController(text: _plan.weeklyGoals[index].text),
    );
    _goalChecks = List.generate(
      _plan.weeklyGoals.length,
      (index) => _plan.weeklyGoals[index].done,
    );
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
                  dayLabel: _weekdayLabels[index],
                  dateLabel: _formatDateLabel(day.dateKey),
                  onTap: widget.onDaySelected == null
                      ? null
                      : () => widget.onDaySelected!(_parseDateKey(day.dateKey)),
                  hasQuickNote: widget.dayKeysWithNotes.contains(day.dateKey),
                  onQuickNoteTap: widget.onDayNoteSelected == null
                      ? null
                      : () => widget.onDayNoteSelected!(_parseDateKey(day.dateKey)),
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
                  checks: _goalChecks,
                  onToggle: _onToggleGoal,
                  onChanged: _onChangeGoal,
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
    });
    widget.onChanged?.call(_plan);
  }

  void _onChangeMit(int dayIndex, int lineIndex, String value) {
    _plan.days[dayIndex].mits[lineIndex].text = value;
    widget.onChanged?.call(_plan);
  }

  void _onToggleGoal(int index, bool value) {
    setState(() {
      _goalChecks[index] = value;
      _plan.weeklyGoals[index].done = value;
    });
    widget.onChanged?.call(_plan);
  }

  void _onChangeGoal(int index, String value) {
    _plan.weeklyGoals[index].text = value;
    widget.onChanged?.call(_plan);
  }

  void _onChangeMatrixLine(int quadIndex, int lineIndex, String value) {
    _plan.matrix[quadIndex].lines[lineIndex] = value;
    widget.onChanged?.call(_plan);
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
    required this.dayLabel,
    required this.dateLabel,
    this.onTap,
    this.onQuickNoteTap,
    this.hasQuickNote = false,
    required this.dayIndex,
    required this.mitControllers,
    required this.mitChecks,
    required this.onToggle,
    required this.onChanged,
  });

  final String dayLabel;
  final String dateLabel;
  final VoidCallback? onTap;
  final VoidCallback? onQuickNoteTap;
  final bool hasQuickNote;
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
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Row(
            children: [
              Text(
                dayLabel,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                dateLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.hintColor,
                ),
              ),
              const Spacer(),
              if (hasQuickNote && onQuickNoteTap != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onQuickNoteTap,
                  child: Icon(
                    Icons.sticky_note_2_outlined,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                ),
            ],
          ),
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
    required this.checks,
    required this.onToggle,
    required this.onChanged,
  });

  final List<TextEditingController> controllers;
  final List<bool> checks;
  final void Function(int index, bool value) onToggle;
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
              Checkbox(
                value: checks[index],
                onChanged: (value) => onToggle(index, value ?? false),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              const SizedBox(width: 4),
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

const List<String> _weekdayLabels = [
  'Mon',
  'Tue',
  'Wed',
  'Thu',
  'Fri',
  'Sat',
  'Sun',
];

String _formatDateLabel(String dateKey) {
  final parts = dateKey.split('-');
  if (parts.length != 3) return '';
  final day = parts[2];
  final month = parts[1];
  return '$day.$month';
}

DateTime _parseDateKey(String dateKey) {
  final parts = dateKey.split('-');
  if (parts.length != 3) return DateTime.now();
  final year = int.tryParse(parts[0]) ?? DateTime.now().year;
  final month = int.tryParse(parts[1]) ?? DateTime.now().month;
  final day = int.tryParse(parts[2]) ?? DateTime.now().day;
  return DateTime(year, month, day);
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
