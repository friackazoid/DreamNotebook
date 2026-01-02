import 'package:flutter/material.dart';

class CalendarDay {
  CalendarDay({required this.date, required this.inCurrentMonth});

  final DateTime date;
  final bool inCurrentMonth;
}

class MonthlyPlan {
  MonthlyPlan({
    required this.year,
    required this.month,
    List<String>? priorities,
    this.habitName = '',
    List<bool>? habitChecks,
    this.notes = '',
  })  : priorities = priorities ?? List.filled(5, ''),
        habitChecks = habitChecks ?? List.filled(31, false) {
    assert(this.priorities.length == 5, 'Monthly priorities need 5 lines.');
    assert(this.habitChecks.length == 31, 'Habit checks need 31 days.');
  }

  factory MonthlyPlan.current() {
    final now = DateTime.now();
    return MonthlyPlan(year: now.year, month: now.month);
  }

  final int year;
  final int month;
  final List<String> priorities;
  String habitName;
  final List<bool> habitChecks;
  String notes;
}

List<CalendarDay> generateCalendarGrid({
  required int year,
  required int month,
}) {
  final firstDay = DateTime(year, month, 1);
  final startOffset = firstDay.weekday - 1;
  final daysInMonth = DateTime(year, month + 1, 0).day;
  final totalCells = ((startOffset + daysInMonth) / 7).ceil() * 7;

  return List.generate(totalCells, (index) {
    final dayNumber = index - startOffset + 1;
    final date = DateTime(year, month, dayNumber);
    final inCurrentMonth = dayNumber >= 1 && dayNumber <= daysInMonth;
    return CalendarDay(date: date, inCurrentMonth: inCurrentMonth);
  });
}

class MonthlyPlannerSpread extends StatefulWidget {
  const MonthlyPlannerSpread({
    super.key,
    this.initialPlan,
    this.onPreviousMonth,
    this.onNextMonth,
  });

  final MonthlyPlan? initialPlan;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;

  @override
  State<MonthlyPlannerSpread> createState() => _MonthlyPlannerSpreadState();
}

class _MonthlyPlannerSpreadState extends State<MonthlyPlannerSpread> {
  late final MonthlyPlan _plan;
  late final List<TextEditingController> _priorityControllers;
  late final List<bool> _priorityChecks;
  late final TextEditingController _habitNameController;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _plan = widget.initialPlan ?? MonthlyPlan.current();
    _priorityControllers = List.generate(
      _plan.priorities.length,
      (index) => TextEditingController(text: _plan.priorities[index]),
    );
    _priorityChecks = List<bool>.filled(_plan.priorities.length, false);
    _habitNameController = TextEditingController(text: _plan.habitName);
    _notesController = TextEditingController(text: _plan.notes);
  }

  @override
  void dispose() {
    for (final controller in _priorityControllers) {
      controller.dispose();
    }
    _habitNameController.dispose();
    _notesController.dispose();
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
    final days =
        generateCalendarGrid(year: _plan.year, month: _plan.month);
    final rows = days.length ~/ 7;
    return _PlannerPageFrame(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _MonthHeader(
              title: '${_monthNames[_plan.month - 1]} ${_plan.year}',
              onPrevious: widget.onPreviousMonth,
              onNext: widget.onNextMonth,
            ),
            const SizedBox(height: 12),
            _WeekdayLabels(theme: theme),
            const SizedBox(height: 8),
            Expanded(
              child: _CalendarGrid(
                days: days,
                rows: rows,
                today: DateTime.now(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRightPage(ThemeData theme) {
    return _PlannerPageFrame(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(title: 'Monthly Priorities'),
            const SizedBox(height: 8),
            _PriorityList(
              controllers: _priorityControllers,
              checks: _priorityChecks,
              onToggle: _onTogglePriority,
              onChanged: _onChangePriority,
            ),
            const SizedBox(height: 16),
            _SectionTitle(title: 'Habit Tracker'),
            const SizedBox(height: 8),
            _HabitTrackerStrip(
              habitNameController: _habitNameController,
              habitChecks: _plan.habitChecks,
              onToggleDay: _onToggleHabitDay,
              onNameChanged: _onChangeHabitName,
            ),
            const SizedBox(height: 16),
            _SectionTitle(title: 'Notes / Reminders'),
            const SizedBox(height: 8),
            Expanded(
              child: _LinedNotesField(
                controller: _notesController,
                onChanged: _onChangeNotes,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onTogglePriority(int index, bool value) {
    setState(() {
      _priorityChecks[index] = value;
      // TODO: Wire priority completion to persistence/state management.
    });
  }

  void _onChangePriority(int index, String value) {
    _plan.priorities[index] = value;
    // TODO: Wire priority text to persistence/state management.
  }

  void _onToggleHabitDay(int index, bool value) {
    setState(() {
      _plan.habitChecks[index] = value;
      // TODO: Wire habit tracking to persistence/state management.
    });
  }

  void _onChangeHabitName(String value) {
    _plan.habitName = value;
    // TODO: Wire habit name to persistence/state management.
  }

  void _onChangeNotes(String value) {
    _plan.notes = value;
    // TODO: Wire notes to persistence/state management.
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

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.title,
    this.onPrevious,
    this.onNext,
  });

  final String title;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrevious,
          tooltip: 'Previous month',
          visualDensity: VisualDensity.compact,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
          tooltip: 'Next month',
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _WeekdayLabels extends StatelessWidget {
  const _WeekdayLabels({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: labels
            .map(
              (label) => Expanded(
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.days,
    required this.rows,
    required this.today,
  });

  final List<CalendarDay> days;
  final int rows;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cellHeight = constraints.maxHeight / rows;
        return Column(
          children: List.generate(rows, (row) {
            return SizedBox(
              height: cellHeight,
              child: Row(
                children: List.generate(7, (col) {
                  final day = days[row * 7 + col];
                  final isToday = day.date.year == today.year &&
                      day.date.month == today.month &&
                      day.date.day == today.day &&
                      day.inCurrentMonth;
                  return Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                      ),
                      child: _CalendarCell(
                        day: day,
                        isToday: isToday,
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        );
      },
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.day,
    required this.isToday,
  });

  final CalendarDay day;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dayColor =
        day.inCurrentMonth ? theme.textTheme.bodySmall?.color : theme.hintColor;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: isToday
          ? BoxDecoration(
              border: Border.all(color: theme.colorScheme.primary),
              borderRadius: BorderRadius.circular(6),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.date.day}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: dayColor,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Expanded(child: SizedBox()),
        ],
      ),
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

class _PriorityList extends StatelessWidget {
  const _PriorityList({
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

class _HabitTrackerStrip extends StatelessWidget {
  const _HabitTrackerStrip({
    required this.habitNameController,
    required this.habitChecks,
    required this.onToggleDay,
    required this.onNameChanged,
  });

  final TextEditingController habitNameController;
  final List<bool> habitChecks;
  final void Function(int index, bool value) onToggleDay;
  final ValueChanged<String> onNameChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: TextField(
              controller: habitNameController,
              maxLines: 1,
              decoration: const InputDecoration(
                hintText: 'Habit name',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onChanged: onNameChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(31, (index) {
                  final isChecked = habitChecks[index];
                  return Padding(
                    padding: EdgeInsets.only(right: index == 30 ? 0 : 4),
                    child: _HabitDayBox(
                      dayNumber: index + 1,
                      checked: isChecked,
                      onToggle: (value) => onToggleDay(index, value),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitDayBox extends StatelessWidget {
  const _HabitDayBox({
    required this.dayNumber,
    required this.checked,
    required this.onToggle,
  });

  final int dayNumber;
  final bool checked;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onToggle(!checked),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: checked ? theme.colorScheme.primary.withOpacity(0.18) : null,
          border: Border.all(
            color: checked ? theme.colorScheme.primary : theme.dividerColor,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          '$dayNumber',
          style: theme.textTheme.labelSmall?.copyWith(
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _LinedNotesField extends StatelessWidget {
  const _LinedNotesField({
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CustomPaint(
          painter: _LinedPaperPainter(
            lineColor: theme.dividerColor.withOpacity(0.6),
          ),
          child: TextField(
            controller: controller,
            maxLines: null,
            expands: true,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(8),
            ),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}

class _LinedPaperPainter extends CustomPainter {
  _LinedPaperPainter({required this.lineColor});

  final Color lineColor;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 1;
    const lineHeight = 24.0;
    for (double y = lineHeight; y < size.height; y += lineHeight) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _LinedPaperPainter oldDelegate) {
    return oldDelegate.lineColor != lineColor;
  }
}

const List<String> _monthNames = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];
