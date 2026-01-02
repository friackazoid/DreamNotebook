import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/notebook_data.dart';

class StorageService {
  static const _key = 'notebook_data_v1';

  Future<NotebookData?> loadNotebookData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return null;
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return NotebookData.fromJson(json);
  }

  Future<void> saveNotebookData(NotebookData data) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(data.toJson());
    await prefs.setString(_key, raw);
  }
}
