import 'package:hive_flutter/hive_flutter.dart';

class LocalStorage {
  static const _resumeBox  = 'resumeBox';
  static const _websiteBox = 'websiteBox';
  static const _chatBox    = 'chatBox';
  static const _settingsBox = 'settingsBox';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox<Map>(_resumeBox);
    await Hive.openBox<Map>(_websiteBox);
    await Hive.openBox<Map>(_chatBox);
    await Hive.openBox<dynamic>(_settingsBox);
  }

  // ── Settings (key/value) ─────────────────────────────────────────────────

  Future<T?> getSetting<T>(String key) async {
    final box = Hive.box<dynamic>(_settingsBox);
    final v = box.get(key);
    return v is T ? v : null;
  }

  Future<void> setSetting<T>(String key, T value) =>
      Hive.box<dynamic>(_settingsBox).put(key, value);

  // ── Resume ───────────────────────────────────────────────────────────────

  Future<Map<dynamic, dynamic>?> loadResume() {
    final box = Hive.box<Map>(_resumeBox);
    return Future.value(
        box.isNotEmpty ? Map<String, dynamic>.from(box.values.first) : null);
  }

  Future<void> saveResume(Map<String, dynamic> json) async {
    final box = Hive.box<Map>(_resumeBox);
    await box.clear();
    await box.add(json);
  }

  Future<void> deleteResume() => Hive.box<Map>(_resumeBox).clear();

  // ── Website ──────────────────────────────────────────────────────────────

  Future<Map<dynamic, dynamic>?> loadWebsite() {
    final box = Hive.box<Map>(_websiteBox);
    return Future.value(
        box.isNotEmpty ? Map<String, dynamic>.from(box.values.first) : null);
  }

  Future<void> saveWebsite(Map<String, dynamic> json) async {
    final box = Hive.box<Map>(_websiteBox);
    await box.clear();
    await box.add(json);
  }

  // ── Chat ─────────────────────────────────────────────────────────────────

  Future<Map<dynamic, dynamic>?> loadChat() {
    final box = Hive.box<Map>(_chatBox);
    return Future.value(
        box.isNotEmpty ? Map<String, dynamic>.from(box.values.first) : null);
  }

  Future<void> saveChat(Map<String, dynamic> json) async {
    final box = Hive.box<Map>(_chatBox);
    await box.clear();
    await box.add(json);
  }
}
