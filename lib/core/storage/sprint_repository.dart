import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/sprint.dart';
import '../../models/sprint_week_plan.dart';

abstract class SprintRepository {
  Future<List<Sprint>> loadSprints();
  Future<void> saveSprints(List<Sprint> sprints);
  Future<SprintWeekPlan> loadWeekPlan(String sprintId, int weekIndex);
  Future<void> saveWeekPlan(SprintWeekPlan plan);
}

class SharedPrefsSprintRepository implements SprintRepository {
  SharedPrefsSprintRepository({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const int _schemaVersion = 2;
  static const String _versionKey = 'sprint_projects_version';

  Future<SharedPreferences> _getPrefs() async {
    return _prefs ??= await SharedPreferences.getInstance();
  }

  static const String _storageKey = 'sprint_projects';

  @override
  Future<List<Sprint>> loadSprints() async {
    final prefs = await _getPrefs();
    final storedVersion = prefs.getInt(_versionKey) ?? 0;
    if (storedVersion != _schemaVersion) {
      await prefs.remove(_storageKey);
      await prefs.setInt(_versionKey, _schemaVersion);
      return [];
    }
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      final items = (jsonMap['sprints'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>();
      return items.map(Sprint.fromJson).toList();
    } catch (_) {
      await prefs.remove(_storageKey);
      return [];
    }
  }

  @override
  Future<void> saveSprints(List<Sprint> sprints) async {
    final prefs = await _getPrefs();
    final payload = jsonEncode({
      'sprints': sprints.map((sprint) => sprint.toJson()).toList(),
    });
    await prefs.setInt(_versionKey, _schemaVersion);
    await prefs.setString(_storageKey, payload);
  }

  @override
  Future<SprintWeekPlan> loadWeekPlan(String sprintId, int weekIndex) async {
    final prefs = await _getPrefs();
    final raw = prefs.getString(_weekStorageKey(sprintId, weekIndex));
    if (raw == null || raw.isEmpty) {
      return SprintWeekPlan(sprintId: sprintId, weekIndex: weekIndex);
    }
    try {
      final jsonMap = jsonDecode(raw) as Map<String, dynamic>;
      final plan = SprintWeekPlan.fromJson(jsonMap);
      if (plan.sprintId.isEmpty) {
        return SprintWeekPlan(sprintId: sprintId, weekIndex: weekIndex);
      }
      return plan;
    } catch (_) {
      return SprintWeekPlan(sprintId: sprintId, weekIndex: weekIndex);
    }
  }

  @override
  Future<void> saveWeekPlan(SprintWeekPlan plan) async {
    final prefs = await _getPrefs();
    final payload = jsonEncode(plan.toJson());
    await prefs.setString(_weekStorageKey(plan.sprintId, plan.weekIndex), payload);
  }

  String _weekStorageKey(String sprintId, int weekIndex) {
    return 'sprint_week_${sprintId}_$weekIndex';
  }
}
