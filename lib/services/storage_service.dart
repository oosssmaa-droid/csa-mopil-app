import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/course.dart';

/// Handles on-device persistence of per-user status and the immutable
/// decision log. In production this should be mirrored to the Oracle
/// backend (see PKG_APPROVAL_ENGINE in the capstone's DB layer) so the
/// audit trail survives device loss — this local store is for the
/// standalone mobile demo.
class StorageService {
  static String _statusKey(String user) => 'csa_status_$user';
  static String _logKey(String user) => 'csa_log_$user';
  static String _attemptsKey(String user, String deptKey) =>
      'csa_attempts_${user}_$deptKey';
  static const String _allUsersKey = 'csa_all_employee_users';
  static const String _themeKey = 'csa_theme_pref';

  /// Registers an employee name in a lightweight local directory so the
  /// Manager dashboard can enumerate everyone tracked on this device.
  /// (In production this directory lives in Oracle/EMPLOYEES, not on-device.)
  static Future<void> registerUser(String user) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_allUsersKey) ?? [];
    if (!list.contains(user)) {
      list.add(user);
      await prefs.setStringList(_allUsersKey, list);
    }
  }

  static Future<List<String>> getAllUsers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_allUsersKey) ?? [];
  }

  static Future<String> getTheme() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_themeKey) ?? 'dark';
  }

  static Future<void> setTheme(String theme) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme);
  }

  static Future<Map<String, String>> getStatus(String user) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_statusKey(user));
    if (raw == null) return {};
    return Map<String, String>.from(jsonDecode(raw));
  }

  static Future<void> setStatus(
      String user, String deptKey, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final map = await getStatus(user);
    map[deptKey] = status;
    await prefs.setString(_statusKey(user), jsonEncode(map));
  }

  static Future<int> getAttempts(String user, String deptKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_attemptsKey(user, deptKey)) ?? 0;
  }

  static Future<int> incrementAttempts(String user, String deptKey) async {
    final prefs = await SharedPreferences.getInstance();
    final next = (await getAttempts(user, deptKey)) + 1;
    await prefs.setInt(_attemptsKey(user, deptKey), next);
    return next;
  }

  static Future<List<DecisionLogEntry>> getLog(String user) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_logKey(user)) ?? [];
    return raw
        .map((s) => DecisionLogEntry.fromJson(jsonDecode(s)))
        .toList()
        .reversed
        .toList();
  }

  /// Appends only — never edits or removes prior entries, matching the
  /// "immutable approval log" requirement in the project proposal.
  static Future<void> appendLog(String user, DecisionLogEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_logKey(user)) ?? [];
    raw.add(jsonEncode(entry.toJson()));
    await prefs.setStringList(_logKey(user), raw);
  }
}
