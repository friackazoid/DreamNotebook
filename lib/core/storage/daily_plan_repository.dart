import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/daily_plan.dart';

abstract class DailyPlanRepository {
  Future<DailyPlan> loadPlan(String dateKey);
  Future<void> savePlan(DailyPlan plan);
}

class SharedPrefsDailyPlanRepository implements DailyPlanRepository {
  SharedPrefsDailyPlanRepository({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  String _storageKey(String dateKey) => 'daily_plan_$dateKey';

  @override
  Future<DailyPlan> loadPlan(String dateKey) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_storageKey(dateKey));
    if (raw == null || raw.isEmpty) {
      return DailyPlan.empty(dateKey);
    }
    try {
      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      final plan = DailyPlan.fromJson(jsonMap);
      return plan.dateKey.isEmpty ? DailyPlan.empty(dateKey) : plan;
    } catch (_) {
      return DailyPlan.empty(dateKey);
    }
  }

  @override
  Future<void> savePlan(DailyPlan plan) async {
    final prefs = await _getPrefs();
    final jsonString = jsonEncode(plan.toJson());
    await prefs.setString(_storageKey(plan.dateKey), jsonString);
  }
}
