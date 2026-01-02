import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/storage/daily_plan_repository.dart';
import '../../../models/daily_plan.dart';
import '../../../widgets/handwriting_canvas.dart';

class DailyPlannerPage extends StatefulWidget {
  const DailyPlannerPage({
    super.key,
    this.repository,
    this.initialDate,
    this.initialDateKey,
  });

  final DailyPlanRepository? repository;
  final DateTime? initialDate;
  final String? initialDateKey;

  @override
  State<DailyPlannerPage> createState() => _DailyPlannerPageState();
}

class _DailyPlannerPageState extends State<DailyPlannerPage> {
  static const _startHour = 6;
  static const _endHour = 22;

  late final DailyPlanRepository _repository;
  late final HandwritingController _scheduleController;
  late DateTime _currentDate;
  DailyPlan? _plan;
  bool _loading = true;
  bool _isApplyingPlan = false;
  Timer? _debounce;

  late final List<TextEditingController> _todoControllers;
  late final List<bool> _todoChecks;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SharedPrefsDailyPlanRepository();
    _scheduleController = HandwritingController();
    _scheduleController.addListener(_onScheduleChanged);
    _currentDate = _normalizeDate(
      widget.initialDate ??
          _parseDateKey(widget.initialDateKey) ??
          DateTime.now(),
    );
    _todoControllers = List.generate(10, (_) => TextEditingController());
    _todoChecks = List.filled(10, false);
    _loadPlanForDate(_currentDate);
  }

  @override
  void didUpdateWidget(covariant DailyPlannerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final incomingDate = widget.initialDate ??
        _parseDateKey(widget.initialDateKey);
    if (incomingDate == null) return;
    final normalized = _normalizeDate(incomingDate);
    if (normalized == _currentDate) return;
    _changeToDate(normalized);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    for (final controller in _todoControllers) {
      controller.dispose();
    }
    _scheduleController.removeListener(_onScheduleChanged);
    _scheduleController.dispose();
    super.dispose();
  }

  List<int> get _hours =>
      List.generate(_endHour - _startHour + 1, (i) => _startHour + i);

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(
                  formattedDate: _formatDate(_currentDate),
                  onPrevious: () => _changeDay(-1),
                  onNext: () => _changeDay(1),
                  onToday: _isToday(_currentDate) ? null : _goToToday,
                ),
                const SizedBox(height: 16),
                _ScheduleSection(
                  hours: _hours,
                  controller: _scheduleController,
                ),
                const SizedBox(height: 16),
                _TodoSection(
                  controllers: _todoControllers,
                  checks: _todoChecks,
                  onToggle: _onTodoToggled,
                  onChanged: _onTodoChanged,
                ),
              ],
            ),
          );
  }

  Future<void> _loadPlanForDate(DateTime date) async {
    setState(() => _loading = true);
    final plan = await _repository.loadPlan(_dateKey(date));
    _plan = plan;
    _isApplyingPlan = true;
    _applyPlanToControllers(plan);
    _isApplyingPlan = false;
    setState(() => _loading = false);
  }

  Future<void> _changeDay(int deltaDays) async {
    await _saveCurrentPlan();
    _currentDate = _normalizeDate(_currentDate.add(Duration(days: deltaDays)));
    await _loadPlanForDate(_currentDate);
  }

  Future<void> _changeToDate(DateTime date) async {
    await _saveCurrentPlan();
    _currentDate = _normalizeDate(date);
    await _loadPlanForDate(_currentDate);
  }

  Future<void> _goToToday() async {
    await _saveCurrentPlan();
    _currentDate = _normalizeDate(DateTime.now());
    await _loadPlanForDate(_currentDate);
  }

  void _applyPlanToControllers(DailyPlan plan) {
    for (var i = 0; i < _todoControllers.length; i++) {
      final item = plan.todos[i];
      _todoControllers[i].text = item.text;
      _todoChecks[i] = item.done;
    }
    _scheduleController.loadStrokes(plan.scheduleStrokes);
  }

  void _onTodoChanged(int index, String value) {
    final plan = _plan;
    if (plan == null) return;
    plan.todos[index].text = value;
    _scheduleAutoSave();
  }

  void _onTodoToggled(int index, bool value) {
    final plan = _plan;
    if (plan == null) return;
    setState(() => _todoChecks[index] = value);
    plan.todos[index].done = value;
    _scheduleAutoSave();
  }

  void _onScheduleChanged() {
    if (_isApplyingPlan) return;
    _scheduleAutoSave();
  }

  void _scheduleAutoSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 650), _saveCurrentPlan);
  }

  Future<void> _saveCurrentPlan() async {
    _debounce?.cancel();
    final plan = _plan;
    if (plan == null) return;
    plan.scheduleStrokes
      ..clear()
      ..addAll(_scheduleController.strokes);
    await _repository.savePlan(plan);
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.formattedDate,
    required this.onPrevious,
    required this.onNext,
    this.onToday,
  });

  final String formattedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous day',
        ),
        Expanded(
          child: Text(
            formattedDate,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next day',
        ),
        const SizedBox(width: 8),
        if (onToday != null)
          OutlinedButton(
            onPressed: onToday,
            child: const Text('Today'),
          ),
      ],
    );
  }
}

class _ScheduleSection extends StatelessWidget {
  const _ScheduleSection({
    required this.hours,
    required this.controller,
  });

  final List<int> hours;
  final HandwritingController controller;

  @override
  Widget build(BuildContext context) {
    const rowHeight = 56.0;
    const labelWidth = 64.0;
    return _SectionCard(
      title: '',
      child: Column(
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
                    onPressed: () => controller.clear(),
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

class _TodoSection extends StatelessWidget {
  const _TodoSection({
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
    return _SectionCard(
      title: 'Tasks',
      child: Column(
        children: List.generate(controllers.length, (index) {
          return _TodoRow(
            checked: checks[index],
            controller: controllers[index],
            onToggle: (value) => onToggle(index, value),
            onChanged: (value) => onChanged(index, value),
          );
        }),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.isNotEmpty) ...[
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
            ],
            child,
          ],
        ),
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
      final label = _formatHour(hour);
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

class _TodoRow extends StatelessWidget {
  const _TodoRow({
    required this.checked,
    required this.controller,
    required this.onToggle,
    required this.onChanged,
  });

  final bool checked;
  final TextEditingController controller;
  final ValueChanged<bool> onToggle;
  final ValueChanged<String> onChanged;

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

String _dateKey(DateTime date) {
  final normalized = _normalizeDate(date);
  final month = normalized.month.toString().padLeft(2, '0');
  final day = normalized.day.toString().padLeft(2, '0');
  return '${normalized.year}-$month-$day';
}

DateTime _normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime? _parseDateKey(String? value) {
  if (value == null || value.isEmpty) return null;
  final parts = value.split('-');
  if (parts.length != 3) return null;
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

bool _isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year &&
      date.month == now.month &&
      date.day == now.day;
}

String _formatDate(DateTime date) {
  const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const monthNames = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final weekday = weekdayNames[date.weekday - 1];
  final month = monthNames[date.month - 1];
  return '$weekday, $month ${date.day}, ${date.year}';
}

String _formatHour(int hour) {
  return '${hour.toString().padLeft(2, '0')}:00';
}
