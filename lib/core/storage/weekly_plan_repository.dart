import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/weekly_plan.dart';

abstract class WeeklyPlanRepository {
  Future<WeeklyPlan> loadPlan(String weekKey);
  Future<void> savePlan(WeeklyPlan plan);
}

class SharedPrefsWeeklyPlanRepository implements WeeklyPlanRepository {
  SharedPrefsWeeklyPlanRepository({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  String _storageKey(String weekKey) => 'weekly_plan_$weekKey';

  @override
  Future<WeeklyPlan> loadPlan(String weekKey) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_storageKey(weekKey));
    if (raw == null || raw.isEmpty) {
      return WeeklyPlan.empty(weekKey);
    }
    try {
      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      final plan = WeeklyPlan.fromJson(jsonMap);
      return plan.weekKey.isEmpty ? WeeklyPlan.empty(weekKey) : plan;
    } catch (_) {
      return WeeklyPlan.empty(weekKey);
    }
  }

  @override
  Future<void> savePlan(WeeklyPlan plan) async {
    final prefs = await _getPrefs();
    final jsonString = jsonEncode(plan.toJson());
    await prefs.setString(_storageKey(plan.weekKey), jsonString);
  }
}
