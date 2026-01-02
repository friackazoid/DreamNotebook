import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_router.dart';
import '../../../core/quick_note_helpers.dart';
import '../../../core/storage/monthly_plan_repository.dart';
import '../../../models/monthly_plan.dart';
import '../widgets/monthly_planner_spread.dart';

class MonthlyPlannerPage extends StatefulWidget {
  const MonthlyPlannerPage({
    super.key,
    this.repository,
    this.initialDate,
  });

  final MonthlyPlanRepository? repository;
  final DateTime? initialDate;

  @override
  State<MonthlyPlannerPage> createState() => _MonthlyPlannerPageState();
}

class _MonthlyPlannerPageState extends State<MonthlyPlannerPage> {
  late final MonthlyPlanRepository _repository;
  late DateTime _currentMonth;
  MonthlyPlan? _plan;
  bool _loading = true;
  Timer? _debounce;
  bool _hasMonthQuickNote = false;
  Set<String> _dayQuickNotes = {};

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SharedPrefsMonthlyPlanRepository();
    final now = widget.initialDate ?? DateTime.now();
    _currentMonth = DateTime(now.year, now.month, 1);
    _loadPlan();
  }

  @override
  void didUpdateWidget(covariant MonthlyPlannerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialDate == null) return;
    final incoming = DateTime(
      widget.initialDate!.year,
      widget.initialDate!.month,
      1,
    );
    if (incoming.year == _currentMonth.year &&
        incoming.month == _currentMonth.month) {
      return;
    }
    _changeMonth(incoming);
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
                  MonthlyPlannerSpread(
                    key: ValueKey(_plan!.monthKey),
                    initialPlan: _plan!,
                    onChanged: _onPlanChanged,
                    onPreviousMonth: () => _changeMonth(_prevMonth(_currentMonth)),
                    onNextMonth: () => _changeMonth(_nextMonth(_currentMonth)),
                    onThisMonth:
                        _isThisMonth(_currentMonth) ? null : _goToThisMonth,
                    onDaySelected: _openDaily,
                    onDayNoteSelected: _openQuickNoteForDay,
                    onMonthNoteTap:
                        _hasMonthQuickNote ? _openQuickNoteForMonth : null,
                    dayKeysWithNotes: _dayQuickNotes,
                    hasMonthNote: _hasMonthQuickNote,
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _loadPlan() async {
    setState(() => _loading = true);
    final monthKey = _monthKeyFrom(_currentMonth);
    final plan = await _repository.loadPlan(
      monthKey,
      _currentMonth.year,
      _currentMonth.month,
    );
    _plan = plan.monthKey.isEmpty
        ? MonthlyPlan.empty(
            monthKey: monthKey,
            year: _currentMonth.year,
            month: _currentMonth.month,
          )
        : plan;
    await _refreshQuickNotes();
    setState(() => _loading = false);
  }

  void _onPlanChanged(MonthlyPlan plan) {
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

  Future<void> _changeMonth(DateTime newMonth) async {
    await _saveCurrentPlan();
    _currentMonth = newMonth;
    await _loadPlan();
  }

  Future<void> _goToThisMonth() async {
    await _saveCurrentPlan();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
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

  Future<void> _openQuickNoteForMonth() async {
    await _saveCurrentPlan();
    await openQuickNoteForMonth(
      context,
      _currentMonth.year,
      _currentMonth.month,
    );
    await _refreshQuickNotes();
  }

  Future<void> _refreshQuickNotes() async {
    final monthKey = _monthKeyFrom(_currentMonth);
    final hasMonth = await quickNoteRepository.hasMonthNote(monthKey);
    final days = generateCalendarGrid(
      year: _currentMonth.year,
      month: _currentMonth.month,
    );
    final dayKeys = days.map((day) => _dateKey(day.date)).toSet();
    final dayNotes = await quickNoteRepository.dayKeysWithNotes(dayKeys);
    if (!mounted) return;
    setState(() {
      _hasMonthQuickNote = hasMonth;
      _dayQuickNotes = dayNotes;
    });
  }
}

String _monthKeyFrom(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  return '${date.year}-$month';
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

DateTime _nextMonth(DateTime date) {
  if (date.month == 12) {
    return DateTime(date.year + 1, 1, 1);
  }
  return DateTime(date.year, date.month + 1, 1);
}

DateTime _prevMonth(DateTime date) {
  if (date.month == 1) {
    return DateTime(date.year - 1, 12, 1);
  }
  return DateTime(date.year, date.month - 1, 1);
}

bool _isThisMonth(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month;
}
