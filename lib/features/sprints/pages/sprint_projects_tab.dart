import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/storage/sprint_repository.dart';
import '../../../models/sprint.dart';
import '../widgets/sprint_table_layout.dart';

class SprintProjectsTab extends StatefulWidget {
  const SprintProjectsTab({super.key, this.repository});

  final SprintRepository? repository;

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

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? SharedPrefsSprintRepository();
    _titleController = TextEditingController();
    _loadSprints();
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
            child: SprintTableLayout(
              key: ValueKey(sprint.id),
              sprint: sprint,
              isEditable: isEditable,
              onChanged: _onSprintChanged,
            ),
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
    setState(() {
      _currentIndex = index;
      _titleController.text = _sprints[_currentIndex].title;
    });
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
    final startDate = _normalizeDate(DateTime.now());
    sprint.status = SprintStatus.current;
    sprint.startDate = startDate;
    sprint.endDate = startDate.add(const Duration(days: 28));
    _scheduleSave();
    setState(() {});
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
}

DateTime _normalizeDate(DateTime date) {
  return DateTime(date.year, date.month, date.day);
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
