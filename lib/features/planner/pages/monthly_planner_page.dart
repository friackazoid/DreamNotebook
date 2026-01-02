import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/storage/monthly_plan_repository.dart';
import '../../../models/monthly_plan.dart';
import '../widgets/monthly_planner_spread.dart';

class MonthlyPlannerPage extends StatefulWidget {
  const MonthlyPlannerPage({
    super.key,
    this.repository,
  });

  final MonthlyPlanRepository? repository;

  @override
  State<MonthlyPlannerPage> createState() => _MonthlyPlannerPageState();
}

class _MonthlyPlannerPageState extends State<MonthlyPlannerPage> {
  late final MonthlyPlanRepository _repository;
  late DateTime _currentMonth;
  MonthlyPlan? _plan;
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SharedPrefsMonthlyPlanRepository();
    _currentMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    _loadPlan();
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
            : MonthlyPlannerSpread(
                key: ValueKey(_plan!.monthKey),
                initialPlan: _plan!,
                onChanged: _onPlanChanged,
                onPreviousMonth: () => _changeMonth(_prevMonth(_currentMonth)),
                onNextMonth: () => _changeMonth(_nextMonth(_currentMonth)),
                onThisMonth: _isThisMonth(_currentMonth) ? null : _goToThisMonth,
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
}

String _monthKeyFrom(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  return '${date.year}-$month';
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
