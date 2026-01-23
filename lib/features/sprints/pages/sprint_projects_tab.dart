import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/storage/sprint_repository.dart';
import '../../../models/sprint.dart';
import '../../../models/sprint_week_plan.dart';
import '../../../models/sprint_week_results.dart';
import '../widgets/sprint_table_layout.dart';
import '../widgets/sprint_week_results_page.dart';
import '../widgets/week_schedule_widgets.dart';

class SprintProjectsTab extends StatefulWidget {
  const SprintProjectsTab({
    super.key,
    this.repository,
    this.weekIndex = 0,
  });

  final SprintRepository? repository;
  final int weekIndex;

  @override
  State<SprintProjectsTab> createState() => _SprintProjectsTabState();
}

class _SprintProjectsTabState extends State<SprintProjectsTab> {
  late final SprintRepository _repository;
  late final TextEditingController _titleController;
  List<Sprint> _sprints = [];
  int _currentIndex = 0;
  bool _loading = true;
  Timer? _debounce;
  SprintWeekPlan? _weekPlan;
  SprintWeekResults? _weekResults;
  bool _weekLoading = false;
  Timer? _weekPlanDebounce;
  Timer? _weekResultsDebounce;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SharedPrefsSprintRepository();
    _titleController = TextEditingController();
    _loadSprints();
  }

  @override
  void didUpdateWidget(covariant SprintProjectsTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.weekIndex != oldWidget.weekIndex) {
      _saveWeekPlan();
      _saveWeekResults();
      _loadWeekPlanIfNeeded();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _weekPlanDebounce?.cancel();
    _weekResultsDebounce?.cancel();
    _saveWeekPlan();
    _saveWeekResults();
    _saveSprints();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    final sprint = _sprints[_currentIndex];
    final isEditable = sprint.status != SprintStatus.archived;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    isEditable
                        ? TextField(
                            controller: _titleController,
                            onChanged: _onTitleChanged,
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                            ),
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          )
                        : Text(
                            sprint.title,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                    const SizedBox(height: 6),
                    Text(
                      'Start: ${_formatDate(sprint.startDate)}  •  '
                      'End: ${_formatDate(sprint.endDate)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    ),
                  ],
                ),
              ),
              if (sprint.status == SprintStatus.planned)
                FilledButton(
                  onPressed: _startSprint,
                  child: const Text('Start Sprint'),
                ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _currentIndex > 0 ? _goToPreviousSprint : null,
                child: const Text('Previous Sprint'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _goToNextSprint,
                child: const Text('Next Sprint'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: _buildContentArea(sprint, isEditable),
          ),
        ),
      ],
    );
  }

  Future<void> _loadSprints() async {
    setState(() => _loading = true);
    final loaded = await _repository.loadSprints();
    if (loaded.isEmpty) {
      loaded.add(_createSprint(1));
    }
    _normalizeCurrentSprint(loaded);
    _sprints = loaded;
    _currentIndex = _indexToShow(loaded);
    _titleController.text = _sprints[_currentIndex].title;
    await _loadWeekPlanIfNeeded();
    setState(() => _loading = false);
    _saveSprints();
  }

  void _normalizeCurrentSprint(List<Sprint> sprints) {
    // Ensure only one sprint is current; demote extras to archived.
    var hasCurrent = false;
    for (final sprint in sprints) {
      if (sprint.status == SprintStatus.current) {
        if (!hasCurrent) {
          hasCurrent = true;
        } else {
          sprint.status = SprintStatus.archived;
        }
      }
    }
  }

  int _indexToShow(List<Sprint> sprints) {
    final currentIndex =
        sprints.indexWhere((sprint) => sprint.status == SprintStatus.current);
    if (currentIndex != -1) return currentIndex;
    return sprints.length - 1;
  }

  void _setCurrentIndex(int index) {
    _saveWeekPlan();
    _saveWeekResults();
    setState(() {
      _currentIndex = index;
      _titleController.text = _sprints[_currentIndex].title;
    });
    _loadWeekPlanIfNeeded();
  }

  void _onTitleChanged(String value) {
    _sprints[_currentIndex].title = value;
    _scheduleSave();
  }

  void _onSprintChanged() {
    setState(() {});
    _scheduleSave();
  }

  void _startSprint() {
    final sprint = _sprints[_currentIndex];
    if (sprint.status != SprintStatus.planned) return;
    // Transition: planned -> current, archive previous current sprint.
    for (final entry in _sprints) {
      if (entry.status == SprintStatus.current) {
        entry.status = SprintStatus.archived;
      }
    }
    final startDate = _nextMonday(_normalizeDate(DateTime.now()));
    sprint.status = SprintStatus.current;
    sprint.startDate = startDate;
    sprint.endDate = startDate.add(const Duration(days: 28));
    _scheduleSave();
    setState(() {});
    _loadWeekPlanIfNeeded();
  }

  void _goToPreviousSprint() {
    if (_currentIndex <= 0) return;
    _setCurrentIndex(_currentIndex - 1);
  }

  void _goToNextSprint() {
    if (_currentIndex < _sprints.length - 1) {
      _setCurrentIndex(_currentIndex + 1);
      return;
    }
    final nextNumber = _sprints.length + 1;
    _sprints.add(_createSprint(nextNumber));
    _setCurrentIndex(_sprints.length - 1);
    _scheduleSave();
  }

  Sprint _createSprint(int number) {
    final startDate = _normalizeDate(DateTime.now());
    return Sprint(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: 'Sprint #$number',
      startDate: startDate,
      endDate: startDate.add(const Duration(days: 28)),
      status: SprintStatus.planned,
    );
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), _saveSprints);
  }

  Future<void> _saveSprints() async {
    _debounce?.cancel();
    await _repository.saveSprints(_sprints);
  }

  Widget _buildContentArea(Sprint sprint, bool isEditable) {
    if (widget.weekIndex == 0 || sprint.status == SprintStatus.planned) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SprintTableLayout(
            key: ValueKey(sprint.id),
            sprint: sprint,
            isEditable: isEditable,
            onChanged: _onSprintChanged,
          ),
          const SizedBox(height: 24),
          if (sprint.status == SprintStatus.planned)
            Text(
              'Start the sprint to unlock weekly schedules.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
            ),
        ],
      );
    }
    if (_weekLoading || _weekPlan == null || _weekResults == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final selection = _weekSelection(widget.weekIndex);
    if (selection.isResults) {
      return _buildResultsContent(
        sprint,
        _weekResults!,
        selection.weekIndex,
        isEditable,
      );
    }
    return _buildWeekContent(
      sprint,
      _weekPlan!,
      selection.weekIndex,
      isEditable,
    );
  }

  Widget _buildWeekContent(
    Sprint sprint,
    SprintWeekPlan plan,
    int weekIndex,
    bool isEditable,
  ) {
    final range = _weekRange(sprint.startDate, weekIndex);
    final isIntegration = weekIndex == 4;
    final title =
        isIntegration ? 'INTEGRATION WEEK' : 'WEEK #$weekIndex';
    final subtitle =
        '${isIntegration ? 'Integration Week' : 'Week #$weekIndex'} '
        '(${_formatShortDate(range.start)}–${_formatShortDate(range.end)})';
    return WeekSchedulePageBase(
      title: title,
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TaskTableSection(
            title: isIntegration ? 'TASKS' : 'SPRINT TASKS',
            rows: plan.sprintTasks,
            isEditable: isEditable,
            onChanged: _onWeekPlanChanged,
          ),
          if (!isIntegration) ...[
            const SizedBox(height: 16),
            TaskTableSection(
              title: 'OTHER TASKS',
              rows: plan.otherTasks,
              isEditable: isEditable,
              onChanged: _onWeekPlanChanged,
            ),
          ],
          const SizedBox(height: 16),
          StateTrackerSection(
            stateTracker: plan.stateTracker,
            isEditable: isEditable,
            onChanged: _onWeekPlanChanged,
          ),
        ],
      ),
    );
  }

  void _onWeekPlanChanged() {
    setState(() {});
    _scheduleWeekPlanSave();
  }

  void _onWeekResultsChanged() {
    setState(() {});
    _scheduleWeekResultsSave();
  }

  void _scheduleWeekPlanSave() {
    _weekPlanDebounce?.cancel();
    _weekPlanDebounce =
        Timer(const Duration(milliseconds: 600), _saveWeekPlan);
  }

  Future<void> _saveWeekPlan() async {
    _weekPlanDebounce?.cancel();
    final plan = _weekPlan;
    if (plan == null) return;
    await _repository.saveWeekPlan(plan);
  }

  void _scheduleWeekResultsSave() {
    _weekResultsDebounce?.cancel();
    _weekResultsDebounce =
        Timer(const Duration(milliseconds: 600), _saveWeekResults);
  }

  Future<void> _saveWeekResults() async {
    _weekResultsDebounce?.cancel();
    final results = _weekResults;
    if (results == null) return;
    await _repository.saveWeekResults(results);
  }

  Future<void> _loadWeekPlanIfNeeded() async {
    final sprint = _sprints[_currentIndex];
    if (sprint.status == SprintStatus.planned || widget.weekIndex == 0) {
      setState(() {
        _weekPlan = null;
        _weekResults = null;
        _weekLoading = false;
      });
      return;
    }
    final selection = _weekSelection(widget.weekIndex);
    await _loadWeekData(selection.weekIndex);
  }

  Future<void> _loadWeekData(int weekIndex) async {
    setState(() => _weekLoading = true);
    final sprint = _sprints[_currentIndex];
    final plan = await _repository.loadWeekPlan(sprint.id, weekIndex);
    final results = await _repository.loadWeekResults(sprint.id, weekIndex);
    if (!mounted) return;
    setState(() {
      _weekPlan = plan;
      _weekResults = results;
      _weekLoading = false;
    });
  }

  Widget _buildResultsContent(
    Sprint sprint,
    SprintWeekResults results,
    int weekIndex,
    bool isEditable,
  ) {
    final range = _weekRange(sprint.startDate, weekIndex);
    final isIntegration = weekIndex == 4;
    final title = isIntegration
        ? 'INTEGRATION WEEK RESULTS'
        : 'WEEK #$weekIndex RESULTS';
    final subtitle =
        '${isIntegration ? 'Integration Week' : 'Week #$weekIndex'} '
        '(${_formatShortDate(range.start)}–${_formatShortDate(range.end)})';
    return SprintWeekResultsPage(
      title: title,
      subtitle: subtitle,
      results: results,
      isEditable: isEditable,
      onChanged: _onWeekResultsChanged,
    );
  }

}

DateTime _normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime _nextMonday(DateTime date) {
  final weekday = date.weekday;
  final offset = weekday == DateTime.monday ? 0 : (8 - weekday);
  return date.add(Duration(days: offset));
}

_WeekRange _weekRange(DateTime sprintStart, int weekIndex) {
  final start = sprintStart.add(Duration(days: (weekIndex - 1) * 7));
  final end = start.add(const Duration(days: 6));
  return _WeekRange(start: start, end: end);
}

String _formatDate(DateTime date) {
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
  final month = monthNames[date.month - 1];
  return '$month ${date.day}, ${date.year}';
}

String _formatShortDate(DateTime date) {
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
  final month = monthNames[date.month - 1];
  return '$month ${date.day}';
}

class _WeekRange {
  const _WeekRange({required this.start, required this.end});

  final DateTime start;
  final DateTime end;
}

class _WeekSelection {
  const _WeekSelection({
    required this.weekIndex,
    required this.isResults,
  });

  final int weekIndex;
  final bool isResults;
}

_WeekSelection _weekSelection(int sidebarIndex) {
  return switch (sidebarIndex) {
    1 => const _WeekSelection(weekIndex: 1, isResults: false),
    2 => const _WeekSelection(weekIndex: 1, isResults: true),
    3 => const _WeekSelection(weekIndex: 2, isResults: false),
    4 => const _WeekSelection(weekIndex: 2, isResults: true),
    5 => const _WeekSelection(weekIndex: 3, isResults: false),
    6 => const _WeekSelection(weekIndex: 3, isResults: true),
    7 => const _WeekSelection(weekIndex: 4, isResults: false),
    8 => const _WeekSelection(weekIndex: 4, isResults: true),
    _ => const _WeekSelection(weekIndex: 1, isResults: false),
  };
}
