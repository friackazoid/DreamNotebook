import 'package:flutter/material.dart';

import '../models/drawing_stroke.dart';
import '../models/quick_note.dart';
import '../widgets/quick_note_panel.dart';
import 'storage/quick_note_repository.dart';

final QuickNoteRepository quickNoteRepository = QuickNoteRepository();

Future<bool> openQuickNoteForDay(BuildContext context, DateTime date) async {
  final dayKey = _dateKey(date);
  final note = await quickNoteRepository.openForDay(dayKey);
  return _openAndSave(context, note);
}

Future<bool> openQuickNoteForWeek(
  BuildContext context,
  DateTime weekStartMonday,
) async {
  final weekKey = _dateKey(_startOfWeekMonday(weekStartMonday));
  final note = await quickNoteRepository.openForWeek(weekKey);
  return _openAndSave(context, note);
}

Future<bool> openQuickNoteForMonth(
  BuildContext context,
  int year,
  int month,
) async {
  final monthKey = _monthKey(DateTime(year, month, 1));
  final note = await quickNoteRepository.openForMonth(monthKey);
  return _openAndSave(context, note);
}

Future<bool> _openAndSave(BuildContext context, QuickNote note) async {
  final strokes = await showQuickNotePanel(
    context,
    initialStrokes: List<Stroke>.from(note.strokes),
  );
  if (strokes == null) {
    return note.strokes.isNotEmpty;
  }
  note.strokes = strokes;
  // If the note is empty, delete it instead of saving.
  if (note.isEmpty) {
    await quickNoteRepository.deleteNote(note);
    return false;
  }
  await quickNoteRepository.saveNote(note);
  return true;
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

String _monthKey(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  return '${date.year}-$month';
}
