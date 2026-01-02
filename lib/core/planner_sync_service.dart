import 'storage/daily_plan_repository.dart';
import 'storage/weekly_plan_repository.dart';
import '../models/daily_plan.dart';
import '../models/weekly_plan.dart';

class DailySyncViewModel {
  DailySyncViewModel({
    required this.dayKey,
    required this.weekKey,
    required this.dailyPlan,
    required this.weeklyPlan,
    required this.weeklyTodosForDay,
  });

  final String dayKey;
  final String weekKey;
  final DailyPlan dailyPlan;
  final WeeklyPlan weeklyPlan;
  final List<WeeklyTodo> weeklyTodosForDay;
}

class PlannerSyncService {
  PlannerSyncService({
    required DailyPlanRepository dailyRepository,
    required WeeklyPlanRepository weeklyRepository,
  })  : _dailyRepository = dailyRepository,
        _weeklyRepository = weeklyRepository;

  final DailyPlanRepository _dailyRepository;
  final WeeklyPlanRepository _weeklyRepository;

  Future<DailySyncViewModel> loadDailyWithWeekly(DateTime date) async {
    final dayKey = _dateKey(date);
    final weekKey = _dateKey(_startOfWeekMonday(date));

    final dailyPlan = await _dailyRepository.loadPlan(dayKey);
    final weeklyPlan = await _weeklyRepository.loadPlan(weekKey);
    final dayPlan = weeklyPlan.days.firstWhere(
      (day) => day.dateKey == dayKey,
      orElse: () => DayPlan(dateKey: dayKey),
    );

    // Sync rule A: ensure mirror entries exist for weekly todos with text.
    // If a weekly todo is cleared, its mirror is kept but ignored in the UI.
    for (final todo in dayPlan.mits) {
      if (todo.text.trim().isEmpty) continue;
      dailyPlan.weeklyTodos.putIfAbsent(
        todo.id,
        () => WeeklyTodoMirror(weeklyTodoId: todo.id),
      );
    }

    final weeklyTodosForDay = dayPlan.mits
        .where((todo) => todo.text.trim().isNotEmpty)
        .toList();

    return DailySyncViewModel(
      dayKey: dayKey,
      weekKey: weekKey,
      dailyPlan: dailyPlan,
      weeklyPlan: weeklyPlan,
      weeklyTodosForDay: weeklyTodosForDay,
    );
  }

  Future<void> saveDaily(DailyPlan plan) async {
    await _dailyRepository.savePlan(plan);
  }

  Future<void> saveWeekly(WeeklyPlan plan) async {
    await _weeklyRepository.savePlan(plan);
  }
}

DateTime _startOfWeekMonday(DateTime date) {
  final normalized = DateTime(date.year, date.month, date.day);
  final diff = normalized.weekday - DateTime.monday;
  return normalized.subtract(Duration(days: diff));
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}
