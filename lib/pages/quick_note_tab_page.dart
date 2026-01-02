import 'dart:async';

import 'package:flutter/material.dart';

import '../core/quick_note_helpers.dart';
import '../models/quick_note.dart';
import '../widgets/dotted_background.dart';
import '../widgets/handwriting_canvas.dart';

class QuickNoteTabPage extends StatefulWidget {
  const QuickNoteTabPage({super.key});

  @override
  State<QuickNoteTabPage> createState() => _QuickNoteTabPageState();
}

class _QuickNoteTabPageState extends State<QuickNoteTabPage> {
  late final HandwritingController _controller;
  QuickNote? _note;
  bool _loading = true;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _controller = HandwritingController();
    _controller.addListener(_onStrokesChanged);
    _loadNote();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _saveCurrentNote();
    _controller.removeListener(_onStrokesChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Text(
                      'Quick Note',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(DateTime.now()),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).hintColor,
                          ),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final isErasing =
                            _controller.tool == HandwritingTool.eraser;
                        return Row(
                          children: [
                            FilledButton.tonalIcon(
                              onPressed: () =>
                                  _controller.setTool(HandwritingTool.pen),
                              icon: Icon(
                                Icons.edit,
                                color: isErasing
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(context).colorScheme.primary,
                              ),
                              label: const Text('Pen'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton.tonalIcon(
                              onPressed: () => _controller.setTool(
                                HandwritingTool.eraser,
                              ),
                              icon: Icon(
                                Icons.auto_fix_high,
                                color: isErasing
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                              label: const Text('Eraser'),
                            ),
                            const SizedBox(width: 12),
                            OutlinedButton.icon(
                              onPressed: _controller.clear,
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Clear'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        border: Border.all(
                          color: Theme.of(context).dividerColor,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DottedBackground(
                        child: HandwritingCanvas(controller: _controller),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
  }

  Future<void> _loadNote() async {
    setState(() => _loading = true);
    final dayKey = _dateKey(DateTime.now());
    final note = await quickNoteRepository.openForDay(dayKey);
    _note = note;
    _controller.loadStrokes(note.strokes);
    setState(() => _loading = false);
  }

  void _onStrokesChanged() {
    _scheduleSave();
  }

  void _scheduleSave() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 650), _saveCurrentNote);
  }

  Future<void> _saveCurrentNote() async {
    _debounce?.cancel();
    final note = _note;
    if (note == null) return;
    note.strokes = _controller.strokes;
    if (note.isEmpty) {
      await quickNoteRepository.deleteNote(note);
      return;
    }
    await quickNoteRepository.saveNote(note);
  }
}

String _dateKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

String _formatDate(DateTime date) {
  const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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
  final weekday = weekdayNames[date.weekday - 1];
  final month = monthNames[date.month - 1];
  return '$weekday, $month ${date.day}, ${date.year}';
}
