import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/monthly_plan.dart';

abstract class MonthlyPlanRepository {
  Future<MonthlyPlan> loadPlan(String monthKey, int year, int month);
  Future<void> savePlan(MonthlyPlan plan);
}

class SharedPrefsMonthlyPlanRepository implements MonthlyPlanRepository {
  SharedPrefsMonthlyPlanRepository({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  String _storageKey(String monthKey) => 'monthly_plan_$monthKey';

  @override
  Future<MonthlyPlan> loadPlan(String monthKey, int year, int month) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_storageKey(monthKey));
    if (raw == null || raw.isEmpty) {
      return MonthlyPlan.empty(monthKey: monthKey, year: year, month: month);
    }
    try {
      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      final plan = MonthlyPlan.fromJson(jsonMap);
      return plan.monthKey.isEmpty
          ? MonthlyPlan.empty(monthKey: monthKey, year: year, month: month)
          : plan;
    } catch (_) {
      return MonthlyPlan.empty(monthKey: monthKey, year: year, month: month);
    }
  }

  @override
  Future<void> savePlan(MonthlyPlan plan) async {
    final prefs = await _getPrefs();
    final jsonString = jsonEncode(plan.toJson());
    await prefs.setString(_storageKey(plan.monthKey), jsonString);
  }
}
