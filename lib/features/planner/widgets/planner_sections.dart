import 'dart:async';

import 'package:flutter/material.dart';

import '../../../models/planner_entry.dart';
import '../../../models/task_item.dart';
import '../../../widgets/section_card.dart';

class PlannerPageLayout extends StatelessWidget {
  const PlannerPageLayout({
    super.key,
    required this.title,
    required this.schedule,
    required this.todo,
    required this.notes,
    this.extras = const [],
  });

  final String title;
  final Widget schedule;
  final Widget todo;
  final Widget notes;
  final List<Widget> extras;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 1000;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              if (isWide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: schedule),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          todo,
                          const SizedBox(height: 16),
                          notes,
                          if (extras.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            ...extras,
                          ],
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    schedule,
                    const SizedBox(height: 16),
                    todo,
                    const SizedBox(height: 16),
                    notes,
                    if (extras.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      ...extras,
                    ],
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

class ScheduleSection extends StatelessWidget {
  const ScheduleSection({
    super.key,
    required this.entries,
    required this.onAddEntry,
    required this.onRemoveEntry,
  });

  final List<PlannerEntry> entries;
  final void Function(int hour, String title) onAddEntry;
  final void Function(String id) onRemoveEntry;

  @override
  Widget build(BuildContext context) {
    final hours = List.generate(18, (index) => index + 6);
    return SectionCard(
      title: 'Schedule',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: () => _showAddDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Add schedule item'),
            ),
          ),
          const SizedBox(height: 12),
          ...hours.map((hour) => _ScheduleRow(
                hour: hour,
                entries: entries.where((e) => e.hour == hour).toList(),
                onRemoveEntry: onRemoveEntry,
              )),
        ],
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final controller = TextEditingController();
    var selectedHour = 9;
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('New schedule entry'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<int>(
                value: selectedHour,
                items: List.generate(
                  18,
                  (index) => DropdownMenuItem(
                    value: index + 6,
                    child: Text('${index + 6}:00'),
                  ),
                ),
                onChanged: (value) => selectedHour = value ?? 9,
                decoration: const InputDecoration(labelText: 'Hour'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Title'),
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
    if (result != true || controller.text.trim().isEmpty) return;
    onAddEntry(selectedHour, controller.text.trim());
  }
}

class _ScheduleRow extends StatelessWidget {
  const _ScheduleRow({
    required this.hour,
    required this.entries,
    required this.onRemoveEntry,
  });

  final int hour;
  final List<PlannerEntry> entries;
  final void Function(String id) onRemoveEntry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Text(
              '${hour.toString().padLeft(2, '0')}:00',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
          Expanded(
            child: entries.isEmpty
                ? Text(
                    'Open',
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: entries
                        .map(
                          (entry) => Row(
                            children: [
                              Expanded(child: Text(entry.title)),
                              IconButton(
                                icon: const Icon(Icons.close, size: 18),
                                tooltip: 'Remove',
                                onPressed: () => onRemoveEntry(entry.id),
                              ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}

class TodoSection extends StatefulWidget {
  const TodoSection({
    super.key,
    required this.items,
    required this.onAddItem,
    required this.onToggleItem,
  });

  final List<TaskItem> items;
  final ValueChanged<String> onAddItem;
  final ValueChanged<String> onToggleItem;

  @override
  State<TodoSection> createState() => _TodoSectionState();
}

class _TodoSectionState extends State<TodoSection> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onAddItem(text);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Todo',
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Add a task',
                  ),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _submit,
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.items.isEmpty)
            Text(
              'No tasks yet.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...widget.items.map(
              (item) => CheckboxListTile(
                value: item.isDone,
                onChanged: (_) => widget.onToggleItem(item.id),
                title: Text(item.title),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
        ],
      ),
    );
  }
}

class NotesSection extends StatefulWidget {
  const NotesSection({
    super.key,
    required this.initialText,
    required this.onChanged,
  });

  final String initialText;
  final ValueChanged<String> onChanged;

  @override
  State<NotesSection> createState() => _NotesSectionState();
}

class _NotesSectionState extends State<NotesSection> {
  late final TextEditingController _controller;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
  }

  @override
  void didUpdateWidget(covariant NotesSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialText != widget.initialText &&
        _controller.text != widget.initialText) {
      _controller.text = widget.initialText;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      widget.onChanged(value.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Notes',
      child: TextField(
        controller: _controller,
        minLines: 6,
        maxLines: 12,
        onChanged: _onChanged,
        decoration: const InputDecoration(
          hintText: 'Write notes for this planner page',
          border: OutlineInputBorder(),
        ),
      ),
    );
  }
}
