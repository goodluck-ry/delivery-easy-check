// 用户设置持久化（SharedPreferences）。
// DAY5：读取周期（默认近14天）。以后可扩展更多设置项。
// 全局单例 settingsStore，变化时通知监听者（首页重读）。

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore extends ChangeNotifier {
  static const _keyReadDays = 'sms_read_days';
  int _readDays = 14; // 默认近14天
  bool _initialized = false;

  int get readDays => _readDays;
  bool get initialized => _initialized;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _readDays = prefs.getInt(_keyReadDays) ?? 14;
    _initialized = true;
    notifyListeners();
  }

  Future<void> setReadDays(int days) async {
    if (days < 1) return;
    _readDays = days;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyReadDays, days);
    notifyListeners();
  }
}

final settingsStore = SettingsStore();
