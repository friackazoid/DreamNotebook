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
    required this.busyHours,
    required this.freeHours,
    required this.sleepHours,
    required this.totalHours,
  });

  final WeeklyPlan initialPlan;
  final ValueChanged<WeeklyPlan>? onChanged;
  final ValueChanged<DateTime>? onDaySelected;
  final ValueChanged<DateTime>? onDayNoteSelected;
  final Set<String> dayKeysWithNotes;
  final int busyHours;
  final int freeHours;
  final int sleepHours;
  final int totalHours;

  @override
  State<WeeklyPlannerSpread> createState() => _WeeklyPlannerSpreadState();
}

class _WeeklyPlannerSpreadState extends State<WeeklyPlannerSpread> {
  // Acceptance checklist:
  // - Weekly goals can be dragged into any quadrant and re-ordered by re-dropping.
  // - Quadrants hold up to 5 items; empty goals are not placeable.
  // - Placements persist via WeeklyPlan.matrixPlacements.
  late final WeeklyPlan _plan;
  late final List<List<TextEditingController>> _mitControllers;
  late final List<List<bool>> _mitChecks;
  late final List<TextEditingController> _goalControllers;
  late final List<bool> _goalChecks;

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
                _SectionTitle(title: 'Week Load'),
                const SizedBox(height: 8),
                _WeeklyHoursBar(
                  busyHours: widget.busyHours,
                  freeHours: widget.freeHours,
                  sleepHours: widget.sleepHours,
                  totalHours: widget.totalHours,
                ),
                const SizedBox(height: 16),
                _SectionTitle(title: 'Weekly Goals'),
                const SizedBox(height: 8),
                DragTarget<_GoalDragData>(
                  onWillAccept: (data) =>
                      data?.sourceQuadrant != null && data != null,
                  onAccept: (data) => _removeGoalFromMatrix(data.goalId),
                  builder: (context, candidates, rejected) {
                    return _GoalsSection(
                      controllers: _goalControllers,
                      checks: _goalChecks,
                      goalIds:
                          _plan.weeklyGoals.map((goal) => goal.id).toList(),
                      onToggle: _onToggleGoal,
                      onChanged: _onChangeGoal,
                    );
                  },
                ),
                const SizedBox(height: 16),
                _SectionTitle(title: 'Urgent / Important'),
                const SizedBox(height: 8),
                SizedBox(
                  height: matrixHeight,
                  child: _MatrixBoard(
                    placements: _plan.matrixPlacements,
                    goals: _plan.weeklyGoals,
                    onMoveGoal: _placeGoalInQuadrant,
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
    if (value.trim().isEmpty) {
      _removeGoalFromMatrix(_plan.weeklyGoals[index].id);
    }
    widget.onChanged?.call(_plan);
  }

  void _placeGoalInQuadrant(String goalId, MatrixQuadrantType quadrant) {
    // Acceptance: allow placing goals in quadrants, enforce max 5, and ignore empty goals.
    final goal = _plan.weeklyGoals.firstWhere(
      (goal) => goal.id == goalId,
      orElse: () => WeeklyTodo(id: goalId),
    );
    if (goal.text.trim().isEmpty) return;
    final current = _plan.matrixPlacements
        .where((item) => item.quadrant == quadrant)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final alreadyInQuadrant =
        current.any((placement) => placement.goalId == goalId);
    if (!alreadyInQuadrant && current.length >= 5) return;
    setState(() {
      _plan.matrixPlacements.removeWhere((item) => item.goalId == goalId);
      final orderIndex = current.length;
      _plan.matrixPlacements.add(
        MatrixPlacement(
          goalId: goalId,
          quadrant: quadrant,
          orderIndex: orderIndex,
        ),
      );
      _normalizeQuadrantOrder(quadrant);
    });
    widget.onChanged?.call(_plan);
  }

  void _removeGoalFromMatrix(String goalId) {
    final removed = _plan.matrixPlacements
        .where((item) => item.goalId == goalId)
        .toList();
    if (removed.isEmpty) return;
    final quadrants = removed.map((item) => item.quadrant).toSet();
    setState(() {
      _plan.matrixPlacements.removeWhere((item) => item.goalId == goalId);
      for (final quadrant in quadrants) {
        _normalizeQuadrantOrder(quadrant);
      }
    });
    widget.onChanged?.call(_plan);
  }

  void _normalizeQuadrantOrder(MatrixQuadrantType quadrant) {
    final items = _plan.matrixPlacements
        .where((item) => item.quadrant == quadrant)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      _plan.matrixPlacements.remove(item);
      _plan.matrixPlacements.add(
        MatrixPlacement(
          goalId: item.goalId,
          quadrant: quadrant,
          orderIndex: i,
        ),
      );
    }
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
    required this.goalIds,
    required this.onToggle,
    required this.onChanged,
  });

  final List<TextEditingController> controllers;
  final List<bool> checks;
  final List<String> goalIds;
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
              LongPressDraggable<_GoalDragData>(
                data: _GoalDragData(goalId: goalIds[index]),
                feedback: _DragChip(text: controllers[index].text),
                childWhenDragging: Icon(
                  Icons.drag_indicator,
                  size: 16,
                  color: theme.hintColor,
                ),
                child: Icon(
                  Icons.drag_indicator,
                  size: 16,
                  color: theme.hintColor,
                ),
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

class _MatrixBoard extends StatelessWidget {
  const _MatrixBoard({
    required this.placements,
    required this.goals,
    required this.onMoveGoal,
  });

  final List<MatrixPlacement> placements;
  final List<WeeklyTodo> goals;
  final void Function(String goalId, MatrixQuadrantType quadrant) onMoveGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Table(
      border: TableBorder.all(color: theme.dividerColor),
      children: [
        TableRow(
          children: [
            _MatrixQuadrantCell(
              label: 'Important + Urgent',
              quadrant: MatrixQuadrantType.iu,
              placements: placements,
              goals: goals,
              onMoveGoal: onMoveGoal,
            ),
            _MatrixQuadrantCell(
              label: 'Important + Not Urgent',
              quadrant: MatrixQuadrantType.inu,
              placements: placements,
              goals: goals,
              onMoveGoal: onMoveGoal,
            ),
          ],
        ),
        TableRow(
          children: [
            _MatrixQuadrantCell(
              label: 'Not Important + Urgent',
              quadrant: MatrixQuadrantType.niu,
              placements: placements,
              goals: goals,
              onMoveGoal: onMoveGoal,
            ),
            _MatrixQuadrantCell(
              label: 'Not Important + Not Urgent',
              quadrant: MatrixQuadrantType.ninu,
              placements: placements,
              goals: goals,
              onMoveGoal: onMoveGoal,
            ),
          ],
        ),
      ],
    );
  }
}

class _MatrixQuadrantCell extends StatelessWidget {
  const _MatrixQuadrantCell({
    required this.label,
    required this.quadrant,
    required this.placements,
    required this.goals,
    required this.onMoveGoal,
  });

  final String label;
  final MatrixQuadrantType quadrant;
  final List<MatrixPlacement> placements;
  final List<WeeklyTodo> goals;
  final void Function(String goalId, MatrixQuadrantType quadrant) onMoveGoal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = placements
        .where((item) => item.quadrant == quadrant)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final goalById = {for (final goal in goals) goal.id: goal};

    return DragTarget<_GoalDragData>(
      onWillAccept: (data) {
        if (data == null) return false;
        final goal = goalById[data.goalId];
        if (goal == null || goal.text.trim().isEmpty) return false;
        if (items.length >= 5 && data.sourceQuadrant != quadrant) return false;
        return true;
      },
      onAccept: (data) {
        onMoveGoal(data.goalId, quadrant);
      },
      builder: (context, candidates, rejected) {
        final isActive = candidates.isNotEmpty;
        return Container(
          padding: const EdgeInsets.all(8),
          color: isActive
              ? theme.colorScheme.primary.withOpacity(0.08)
              : Colors.transparent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              if (items.isEmpty)
                Text(
                  isActive ? 'Drop here' : '—',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              if (items.isNotEmpty)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: items.map((item) {
                    final goal = goalById[item.goalId];
                    if (goal == null) return const SizedBox.shrink();
                    return LongPressDraggable<_GoalDragData>(
                      data: _GoalDragData(
                        goalId: goal.id,
                        sourceQuadrant: quadrant,
                      ),
                      feedback: _DragChip(text: goal.text),
                      child: _MatrixChip(goal: goal),
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MatrixChip extends StatelessWidget {
  const _MatrixChip({required this.goal});

  final WeeklyTodo goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.labelSmall?.copyWith(
      color: goal.done ? theme.hintColor : theme.colorScheme.onSurface,
      decoration: goal.done ? TextDecoration.lineThrough : null,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (goal.done)
            Icon(
              Icons.check_circle,
              size: 12,
              color: theme.colorScheme.primary,
            ),
          if (goal.done) const SizedBox(width: 4),
          Text(goal.text, style: textStyle),
        ],
      ),
    );
  }
}

class _DragChip extends StatelessWidget {
  const _DragChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Text(
          text.isEmpty ? 'Goal' : text,
          style: theme.textTheme.labelSmall,
        ),
      ),
    );
  }
}

class _GoalDragData {
  _GoalDragData({
    required this.goalId,
    this.sourceQuadrant,
  });

  final String goalId;
  final MatrixQuadrantType? sourceQuadrant;
}

class _WeeklyHoursBar extends StatelessWidget {
  const _WeeklyHoursBar({
    required this.busyHours,
    required this.freeHours,
    required this.sleepHours,
    required this.totalHours,
  });

  final int busyHours;
  final int freeHours;
  final int sleepHours;
  final int totalHours;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final segments = [
      _HoursSegmentData(
        label: 'Busy',
        hours: busyHours,
        color: theme.colorScheme.primary,
      ),
      _HoursSegmentData(
        label: 'Free',
        hours: freeHours,
        color: theme.colorScheme.secondaryContainer,
      ),
      _HoursSegmentData(
        label: 'Sleep 20-06',
        hours: sleepHours,
        color: theme.colorScheme.tertiaryContainer,
      ),
    ].where((segment) => segment.hours > 0).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 14,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Row(
              children: [
                for (final segment in segments)
                  Expanded(
                    flex: segment.hours,
                    child: Container(color: segment.color),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 6,
          children: [
            for (final segment in segments)
              _HoursLegendItem(segment: segment),
            Text(
              'Total ${totalHours}h',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.hintColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HoursLegendItem extends StatelessWidget {
  const _HoursLegendItem({required this.segment});

  final _HoursSegmentData segment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: segment.color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${segment.label}: ${segment.hours}h',
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.hintColor,
          ),
        ),
      ],
    );
  }
}

class _HoursSegmentData {
  const _HoursSegmentData({
    required this.label,
    required this.hours,
    required this.color,
  });

  final String label;
  final int hours;
  final Color color;
}
