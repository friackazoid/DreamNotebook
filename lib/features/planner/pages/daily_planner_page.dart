import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/quick_note_helpers.dart';
import '../../../core/storage/daily_plan_repository.dart';
import '../../../models/daily_plan.dart';

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

  late final DailyPlanRepository _dailyRepository;
  late DateTime _currentDate;
  DailyPlan? _plan;
  bool _loading = true;
  bool _hasQuickNote = false;
  Timer? _debounce;
  int? _dragStartHour;
  int? _dragCurrentHour;
  bool _isDragging = false;


  @override
  void initState() {
    super.initState();
    _dailyRepository = widget.repository ?? SharedPrefsDailyPlanRepository();
    _currentDate = _normalizeDate(
      widget.initialDate ??
          _parseDateKey(widget.initialDateKey) ??
          DateTime.now(),
    );
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
    _saveCurrentPlan();
    _debounce?.cancel();
    super.dispose();
  }

  List<int> get _hours =>
      List.generate(_endHour - _startHour + 1, (i) => _startHour + i);

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(
                      formattedDate: _formatDate(_currentDate),
                      onPrevious: () => _changeDay(-1),
                      onNext: () => _changeDay(1),
                      onToday: _isToday(_currentDate) ? null : _goToToday,
                      hasQuickNote: _hasQuickNote,
                      onQuickNoteTap: _openQuickNoteForCurrentDay,
                    ),
                    const SizedBox(height: 16),
                    _ScheduleSection(
                      hours: _hours,
                      events: _plan?.events ?? [],
                      dragStartHour: _dragStartHour,
                      dragCurrentHour: _dragCurrentHour,
                      isDragging: _isDragging,
                      onHourTap: _onHourTap,
                      onEventTap: _onEventTap,
                      onDragStart: _onDragStart,
                      onDragUpdate: _onDragUpdate,
                      onDragEnd: _onDragEnd,
                    ),
                  ],
                ),
              ),
            ],
          );
  }

  Future<void> _loadPlanForDate(DateTime date) async {
    setState(() => _loading = true);
    _plan = await _dailyRepository.loadPlan(_dateKey(date));
    await _refreshQuickNoteIndicator();
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

  Future<void> _openQuickNoteForCurrentDay() async {
    await _saveCurrentPlan();
    await openQuickNoteForDay(context, _currentDate);
    await _refreshQuickNoteIndicator();
  }

  Future<void> _refreshQuickNoteIndicator() async {
    _hasQuickNote = await quickNoteRepository.hasDayNote(_dateKey(_currentDate));
    if (!mounted) return;
    setState(() {});
  }

  void _scheduleAutoSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 650), _saveCurrentPlan);
  }

  Future<void> _saveCurrentPlan() async {
    _debounce?.cancel();
    final plan = _plan;
    if (plan == null) return;
    await _dailyRepository.savePlan(plan);
  }

  void _onHourTap(int hour) {
    _openEventEditor(
      startHour: hour,
      endHour: hour + 1,
    );
  }

  void _onEventTap(DayScheduleEvent event) {
    _openEventEditor(existing: event);
  }

  void _onDragStart(Offset localPosition, double rowHeight) {
    final hour = _hourFromOffset(localPosition, rowHeight);
    if (hour == null) return;
    setState(() {
      _isDragging = true;
      _dragStartHour = hour;
      _dragCurrentHour = hour;
    });
  }

  void _onDragUpdate(Offset localPosition, double rowHeight) {
    final hour = _hourFromOffset(localPosition, rowHeight);
    if (hour == null || !_isDragging) return;
    setState(() {
      _dragCurrentHour = hour;
    });
  }

  void _onDragEnd() {
    if (!_isDragging || _dragStartHour == null || _dragCurrentHour == null) {
      _resetDrag();
      return;
    }
    final start = _dragStartHour!;
    final end = _dragCurrentHour!;
    final startHour = start < end ? start : end;
    final endHour = (start > end ? start : end) + 1;
    _resetDrag();
    _openEventEditor(startHour: startHour, endHour: endHour);
  }

  void _resetDrag() {
    setState(() {
      _isDragging = false;
      _dragStartHour = null;
      _dragCurrentHour = null;
    });
  }

  int? _hourFromOffset(Offset localPosition, double rowHeight) {
    final index = localPosition.dy ~/ rowHeight;
    final hour = _startHour + index;
    if (hour < _startHour || hour > _endHour) return null;
    return hour;
  }

  Future<void> _openEventEditor({
    DayScheduleEvent? existing,
    int? startHour,
    int? endHour,
  }) async {
    final plan = _plan;
    if (plan == null) return;
    final result = await showDialog<_EventEditorResult>(
      context: context,
      builder: (context) {
        return _EventEditorDialog(
          existing: existing,
          startHour: startHour,
          endHour: endHour,
          minHour: _startHour,
          maxHour: _endHour + 1,
        );
      },
    );
    if (result == null) return;
    if (result.delete && existing != null) {
      setState(() => plan.events.removeWhere((e) => e.id == existing.id));
      await _saveCurrentPlan();
      return;
    }
    final newEvent = result.event;
    if (newEvent == null) return;
    final overlaps = plan.events.any((event) {
      if (existing != null && event.id == existing.id) return false;
      return _eventsOverlap(event, newEvent);
    });
    if (overlaps) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Event overlaps with another event.')),
      );
      return;
    }
    setState(() {
      if (existing == null) {
        plan.events.add(newEvent);
      } else {
        existing.title = newEvent.title;
        existing.startHour = newEvent.startHour;
        existing.endHour = newEvent.endHour;
      }
    });
    await _saveCurrentPlan();
  }

  bool _eventsOverlap(DayScheduleEvent a, DayScheduleEvent b) {
    return a.startHour < b.endHour && b.startHour < a.endHour;
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.formattedDate,
    required this.onPrevious,
    required this.onNext,
    this.onToday,
    this.onQuickNoteTap,
    this.hasQuickNote = false,
  });

  final String formattedDate;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onToday;
  final VoidCallback? onQuickNoteTap;
  final bool hasQuickNote;

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
        if (hasQuickNote && onQuickNoteTap != null)
          IconButton(
            onPressed: onQuickNoteTap,
            icon: const Icon(Icons.sticky_note_2_outlined),
            tooltip: 'Open quick note',
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
    required this.events,
    required this.dragStartHour,
    required this.dragCurrentHour,
    required this.isDragging,
    required this.onHourTap,
    required this.onEventTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
  });

  final List<int> hours;
  final List<DayScheduleEvent> events;
  final int? dragStartHour;
  final int? dragCurrentHour;
  final bool isDragging;
  final ValueChanged<int> onHourTap;
  final ValueChanged<DayScheduleEvent> onEventTap;
  final void Function(Offset localPosition, double rowHeight) onDragStart;
  final void Function(Offset localPosition, double rowHeight) onDragUpdate;
  final VoidCallback onDragEnd;

  @override
  Widget build(BuildContext context) {
    const rowHeight = 56.0;
    const labelWidth = 64.0;
    return _SectionCard(
      title: '',
      child: SizedBox(
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
            child: GestureDetector(
              onPanStart: (details) =>
                  onDragStart(details.localPosition, rowHeight),
              onPanUpdate: (details) =>
                  onDragUpdate(details.localPosition, rowHeight),
              onPanEnd: (_) => onDragEnd(),
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: hours.length,
                itemBuilder: (context, index) {
                  final hour = hours[index];
                  final event = _eventForHour(events, hour);
                  final isSelected = _isHourInDrag(
                    hour,
                    dragStartHour,
                    dragCurrentHour,
                    isDragging,
                  );
                  final isCovered = event != null;
                  const busyHourColor = Color(0xFFFF6163);
                  return _HourRow(
                    hourLabel: _formatHour(hour),
                    labelWidth: labelWidth,
                    rowHeight: rowHeight,
                    highlight: isSelected || isCovered,
                    highlightColor: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primary
                            .withOpacity(0.12)
                        : (isCovered
                            ? busyHourColor
                            : Theme.of(context)
                                .colorScheme
                                .surfaceVariant
                                .withOpacity(0.5)),
                    title: event?.title ?? '',
                    onTap: () {
                      if (event != null) {
                        onEventTap(event);
                      } else {
                        onHourTap(hour);
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ),
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

class _HourRow extends StatelessWidget {
  const _HourRow({
    required this.hourLabel,
    required this.labelWidth,
    required this.rowHeight,
    required this.highlight,
    required this.highlightColor,
    required this.title,
    required this.onTap,
  });

  final String hourLabel;
  final double labelWidth;
  final double rowHeight;
  final bool highlight;
  final Color highlightColor;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Container(
        height: rowHeight,
        decoration: BoxDecoration(
          color: highlight ? highlightColor : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: theme.dividerColor),
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: labelWidth,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  hourLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

DayScheduleEvent? _eventForHour(List<DayScheduleEvent> events, int hour) {
  for (final event in events) {
    if (hour >= event.startHour && hour < event.endHour) {
      return event;
    }
  }
  return null;
}

bool _isHourInDrag(
  int hour,
  int? start,
  int? current,
  bool isDragging,
) {
  if (!isDragging || start == null || current == null) return false;
  final minHour = start < current ? start : current;
  final maxHour = start > current ? start : current;
  return hour >= minHour && hour <= maxHour;
}

class _EventEditorResult {
  const _EventEditorResult({this.event, this.delete = false});

  final DayScheduleEvent? event;
  final bool delete;
}

class _EventEditorDialog extends StatefulWidget {
  const _EventEditorDialog({
    this.existing,
    this.startHour,
    this.endHour,
    required this.minHour,
    required this.maxHour,
  });

  final DayScheduleEvent? existing;
  final int? startHour;
  final int? endHour;
  final int minHour;
  final int maxHour;

  @override
  State<_EventEditorDialog> createState() => _EventEditorDialogState();
}

class _EventEditorDialogState extends State<_EventEditorDialog> {
  late final TextEditingController _titleController;
  late int _startHour;
  late int _endHour;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existing?.title ?? '');
    _startHour = widget.existing?.startHour ??
        widget.startHour ??
        widget.minHour;
    _endHour = widget.existing?.endHour ??
        widget.endHour ??
        (_startHour + 1).clamp(widget.minHour + 1, widget.maxHour);
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existing == null ? 'New Event' : 'Edit Event'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(labelText: 'Title'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _startHour,
                  decoration: const InputDecoration(labelText: 'Start'),
                  items: _hourItems(widget.minHour, widget.maxHour - 1),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _startHour = value;
                      if (_endHour <= _startHour) {
                        _endHour = _startHour + 1;
                      }
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _endHour,
                  decoration: const InputDecoration(labelText: 'End'),
                  items: _hourItems(widget.minHour + 1, widget.maxHour),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() {
                      _endHour = value;
                      if (_endHour <= _startHour) {
                        _startHour = _endHour - 1;
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (widget.existing != null)
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              const _EventEditorResult(delete: true),
            ),
            child: const Text('Delete'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final title = _titleController.text.trim();
            if (title.isEmpty) {
              Navigator.pop(context);
              return;
            }
            final event = DayScheduleEvent(
              id: widget.existing?.id ?? _newEventId(),
              title: title,
              startHour: _startHour,
              endHour: _endHour,
            );
            Navigator.pop(context, _EventEditorResult(event: event));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

List<DropdownMenuItem<int>> _hourItems(int start, int end) {
  return List.generate(end - start + 1, (index) {
    final hour = start + index;
    return DropdownMenuItem(
      value: hour,
      child: Text(_formatHour(hour)),
    );
  });
}

String _newEventId() {
  return DateTime.now().microsecondsSinceEpoch.toString();
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
