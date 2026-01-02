import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_router.dart';
import '../../../core/quick_note_helpers.dart';
import '../../../core/storage/weekly_plan_repository.dart';
import '../../../models/weekly_plan.dart';
import '../widgets/weekly_planner_spread.dart';

class WeeklyPlannerPage extends StatefulWidget {
  const WeeklyPlannerPage({
    super.key,
    this.repository,
    this.initialDate,
  });

  final WeeklyPlanRepository? repository;
  final DateTime? initialDate;

  @override
  State<WeeklyPlannerPage> createState() => _WeeklyPlannerPageState();
}

class _WeeklyPlannerPageState extends State<WeeklyPlannerPage> {
  late final WeeklyPlanRepository _repository;
  late DateTime _weekStart;
  WeeklyPlan? _plan;
  bool _loading = true;
  Timer? _debounce;
  bool _hasWeekQuickNote = false;
  Set<String> _dayQuickNotes = {};

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SharedPrefsWeeklyPlanRepository();
    _weekStart = _startOfWeekMonday(widget.initialDate ?? DateTime.now());
    _loadPlan();
  }

  @override
  void didUpdateWidget(covariant WeeklyPlannerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate == null) return;
    final incomingStart = _startOfWeekMonday(widget.initialDate!);
    if (incomingStart.year == _weekStart.year &&
        incomingStart.month == _weekStart.month &&
        incomingStart.day == _weekStart.day) {
      return;
    }
    _changeToWeek(incomingStart);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _WeekHeader(
                          label: _weekRangeLabel(_weekStart),
                          onPrevious: () => _changeWeek(-7),
                          onNext: () => _changeWeek(7),
                          onThisWeek:
                              _isThisWeek(_weekStart) ? null : _goToThisWeek,
                          hasNote: _hasWeekQuickNote,
                          onNoteTap: _openQuickNoteForWeek,
                        ),
                      ),
                      Expanded(
                        child: WeeklyPlannerSpread(
                          key: ValueKey(_plan!.weekKey),
                          initialPlan: _plan!,
                          onChanged: _onPlanChanged,
                          onDaySelected: _openDaily,
                          onDayNoteSelected: _openQuickNoteForDay,
                          dayKeysWithNotes: _dayQuickNotes,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _loadPlan() async {
    setState(() => _loading = true);
    final weekKey = _dateKey(_weekStart);
    final plan = await _repository.loadPlan(weekKey);
    _plan = plan.weekKey.isEmpty ? WeeklyPlan.empty(weekKey) : plan;
    await _refreshQuickNotes();
    setState(() => _loading = false);
  }

  void _onPlanChanged(WeeklyPlan plan) {
    _plan = plan;
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
    await _repository.savePlan(plan);
  }

  Future<void> _changeWeek(int deltaDays) async {
    await _saveCurrentPlan();
    _weekStart = _weekStart.add(Duration(days: deltaDays));
    await _loadPlan();
  }

  Future<void> _changeToWeek(DateTime start) async {
    await _saveCurrentPlan();
    _weekStart = _startOfWeekMonday(start);
    await _loadPlan();
  }

  Future<void> _goToThisWeek() async {
    await _saveCurrentPlan();
    _weekStart = _startOfWeekMonday(DateTime.now());
    await _loadPlan();
  }

  Future<void> _openDaily(DateTime date) async {
    await _saveCurrentPlan();
    if (!mounted) return;
    routeToDaily(context, date);
  }

  Future<void> _openQuickNoteForDay(DateTime date) async {
    await _saveCurrentPlan();
    await openQuickNoteForDay(context, date);
    await _refreshQuickNotes();
  }

  Future<void> _openQuickNoteForWeek() async {
    await _saveCurrentPlan();
    await openQuickNoteForWeek(context, _weekStart);
    await _refreshQuickNotes();
  }

  Future<void> _refreshQuickNotes() async {
    final weekKey = _dateKey(_weekStart);
    final hasWeek = await quickNoteRepository.hasWeekNote(weekKey);
    final dayKeys = _plan?.days.map((day) => day.dateKey).toSet() ?? {};
    final dayNotes = await quickNoteRepository.dayKeysWithNotes(dayKeys);
    if (!mounted) return;
    setState(() {
      _hasWeekQuickNote = hasWeek;
      _dayQuickNotes = dayNotes;
    });
  }
}

class _WeekHeader extends StatelessWidget {
  const _WeekHeader({
    required this.label,
    required this.onPrevious,
    required this.onNext,
    this.onThisWeek,
    this.hasNote = false,
    this.onNoteTap,
  });

  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback? onThisWeek;
  final bool hasNote;
  final VoidCallback? onNoteTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous week',
        ),
        Expanded(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next week',
        ),
        const SizedBox(width: 8),
        if (onThisWeek != null)
          OutlinedButton(
            onPressed: onThisWeek,
            child: const Text('This week'),
          ),
        if (hasNote)
          IconButton(
            onPressed: onNoteTap,
            icon: const Icon(Icons.sticky_note_2_outlined),
            tooltip: 'Open quick note',
          ),
      ],
    );
  }
}

DateTime _startOfWeekMonday(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final diff = normalized.weekday - DateTime.monday;
  return normalized.subtract(Duration(days: diff));
}

String _weekRangeLabel(DateTime weekStart) {
  final end = weekStart.add(const Duration(days: 6));
  return 'Week of ${_formatDay(weekStart)}–${_formatDay(end)}';
}

String _formatDay(DateTime date) {
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

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

bool _isThisWeek(DateTime weekStart) {
  final nowStart = _startOfWeekMonday(DateTime.now());
  return nowStart.year == weekStart.year &&
      nowStart.month == weekStart.month &&
      nowStart.day == weekStart.day;
}
