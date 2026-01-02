import 'package:flutter/material.dart';

import '../../../models/task_item.dart';
import '../../../widgets/section_card.dart';

class PetProjectSection extends StatefulWidget {
  const PetProjectSection({
    super.key,
    required this.tasks,
    required this.notes,
    required this.onAddTask,
    required this.onToggleTask,
    required this.onNotesChanged,
  });

  final List<TaskItem> tasks;
  final String notes;
  final void Function(String title, DateTime? dueDate) onAddTask;
  final ValueChanged<TaskItem> onToggleTask;
  final ValueChanged<String> onNotesChanged;

  @override
  State<PetProjectSection> createState() => _PetProjectSectionState();
}

class _PetProjectSectionState extends State<PetProjectSection> {
  late final TextEditingController _taskController;
  late final TextEditingController _notesController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _taskController = TextEditingController();
    _notesController = TextEditingController(text: widget.notes);
  }

  @override
  void didUpdateWidget(covariant PetProjectSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.notes != widget.notes &&
        _notesController.text != widget.notes) {
      _notesController.text = widget.notes;
    }
  }

  @override
  void dispose() {
    _taskController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _submitTask() {
    final title = _taskController.text.trim();
    if (title.isEmpty) return;
    widget.onAddTask(title, _selectedDate);
    _taskController.clear();
    setState(() => _selectedDate = null);
  }

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'PET project planner',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _taskController,
                  decoration: const InputDecoration(
                    hintText: 'Add a project task',
                  ),
                  onSubmitted: (_) => _submitTask(),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: _pickDate,
                child: Text(
                  _selectedDate == null
                      ? 'Deadline'
                      : '${_selectedDate!.month}/${_selectedDate!.day}',
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _submitTask,
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (widget.tasks.isEmpty)
            Text(
              'No project tasks yet.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          else
            ...widget.tasks.map(
              (task) => CheckboxListTile(
                value: task.isDone,
                onChanged: (_) => widget.onToggleTask(task),
                title: Text(task.title),
                subtitle: task.dueDate == null
                    ? null
                    : Text(
                        'Due ${task.dueDate!.month}/${task.dueDate!.day}/${task.dueDate!.year}',
                      ),
                controlAffinity: ListTileControlAffinity.leading,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            minLines: 4,
            maxLines: 8,
            onChanged: (text) => widget.onNotesChanged(text.trim()),
            decoration: const InputDecoration(
              hintText: 'Project notes and next steps',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
