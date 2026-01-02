import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../models/quick_note.dart';

class QuickNoteIndex {
  QuickNoteIndex({
    Map<String, String>? dayKeys,
    Map<String, String>? weekKeys,
    Map<String, String>? monthKeys,
  })  : dayKeys = dayKeys ?? {},
        weekKeys = weekKeys ?? {},
        monthKeys = monthKeys ?? {};

  final Map<String, String> dayKeys;
  final Map<String, String> weekKeys;
  final Map<String, String> monthKeys;

  factory QuickNoteIndex.empty() => QuickNoteIndex();

  factory QuickNoteIndex.fromJson(Map<String, dynamic> json) {
    return QuickNoteIndex(
      dayKeys: (json['dayKeys'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, value.toString())),
      weekKeys: (json['weekKeys'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, value.toString())),
      monthKeys: (json['monthKeys'] as Map<String, dynamic>? ?? {})
          .map((key, value) => MapEntry(key, value.toString())),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayKeys': dayKeys,
      'weekKeys': weekKeys,
      'monthKeys': monthKeys,
    };
  }
}

class QuickNoteRepository {
  Future<QuickNoteIndex> loadIndex() async {
    final file = await _indexFile();
    if (!await file.exists()) {
      return QuickNoteIndex.empty();
    }
    try {
      final raw = await file.readAsString();
      if (raw.isEmpty) return QuickNoteIndex.empty();
      return QuickNoteIndex.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return QuickNoteIndex.empty();
    }
  }

  Future<QuickNote?> loadNote(String id) async {
    final file = await _noteFile(id);
    if (!await file.exists()) return null;
    try {
      final raw = await file.readAsString();
      if (raw.isEmpty) return null;
      return QuickNote.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<QuickNote> openForDay(String dayKey) async {
    final index = await loadIndex();
    final noteId = index.dayKeys[dayKey];
    final note = noteId == null ? null : await loadNote(noteId);
    if (note != null) {
      note.dayKeys.add(dayKey);
      return note;
    }
    return _createNoteForDay(dayKey);
  }

  Future<QuickNote> openForWeek(String weekKey) async {
    final index = await loadIndex();
    final noteId = index.weekKeys[weekKey];
    final note = noteId == null ? null : await loadNote(noteId);
    if (note != null) {
      note.weekKeys.add(weekKey);
      return note;
    }
    return _createNoteForWeek(weekKey);
  }

  Future<QuickNote> openForMonth(String monthKey) async {
    final index = await loadIndex();
    final noteId = index.monthKeys[monthKey];
    final note = noteId == null ? null : await loadNote(noteId);
    if (note != null) {
      note.monthKeys.add(monthKey);
      return note;
    }
    return _createNoteForMonth(monthKey);
  }

  Future<void> saveNote(QuickNote note) async {
    note.updatedAtIso = DateTime.now().toIso8601String();
    await _writeNote(note);
    final index = await loadIndex();
    _removeNoteReferences(index, note.id);
    for (final key in note.dayKeys) {
      index.dayKeys[key] = note.id;
    }
    for (final key in note.weekKeys) {
      index.weekKeys[key] = note.id;
    }
    for (final key in note.monthKeys) {
      index.monthKeys[key] = note.id;
    }
    await _saveIndex(index);
  }

  Future<void> deleteNote(QuickNote note) async {
    final file = await _noteFile(note.id);
    if (await file.exists()) {
      await file.delete();
    }
    final index = await loadIndex();
    _removeNoteReferences(index, note.id);
    await _saveIndex(index);
  }

  Future<bool> hasDayNote(String dayKey) async {
    final index = await loadIndex();
    return index.dayKeys.containsKey(dayKey);
  }

  Future<bool> hasWeekNote(String weekKey) async {
    final index = await loadIndex();
    return index.weekKeys.containsKey(weekKey);
  }

  Future<bool> hasMonthNote(String monthKey) async {
    final index = await loadIndex();
    return index.monthKeys.containsKey(monthKey);
  }

  Future<Set<String>> dayKeysWithNotes(Iterable<String> dayKeys) async {
    final index = await loadIndex();
    return dayKeys.where(index.dayKeys.containsKey).toSet();
  }

  QuickNote _createNoteForDay(String dayKey) {
    final now = DateTime.now().toIso8601String();
    return QuickNote(
      id: _newId(),
      createdAtIso: now,
      updatedAtIso: now,
      dayKeys: {dayKey},
    );
  }

  QuickNote _createNoteForWeek(String weekKey) {
    final now = DateTime.now().toIso8601String();
    return QuickNote(
      id: _newId(),
      createdAtIso: now,
      updatedAtIso: now,
      weekKeys: {weekKey},
    );
  }

  QuickNote _createNoteForMonth(String monthKey) {
    final now = DateTime.now().toIso8601String();
    return QuickNote(
      id: _newId(),
      createdAtIso: now,
      updatedAtIso: now,
      monthKeys: {monthKey},
    );
  }

  void _removeNoteReferences(QuickNoteIndex index, String noteId) {
    index.dayKeys.removeWhere((_, value) => value == noteId);
    index.weekKeys.removeWhere((_, value) => value == noteId);
    index.monthKeys.removeWhere((_, value) => value == noteId);
  }

  Future<void> _writeNote(QuickNote note) async {
    final file = await _noteFile(note.id);
    await file.writeAsString(jsonEncode(note.toJson()));
  }

  Future<File> _noteFile(String id) async {
    final dir = await _notesDir();
    return File('${dir.path}/$id.json');
  }

  Future<File> _indexFile() async {
    final dir = await _notesDir();
    return File('${dir.path}/index.json');
  }

  Future<void> _saveIndex(QuickNoteIndex index) async {
    final file = await _indexFile();
    await file.writeAsString(jsonEncode(index.toJson()));
  }

  Future<Directory> _notesDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/quick_notes');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  String _newId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }
}
